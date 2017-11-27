#!/usr/bin/perl


package TUWF::XML;


use strict;
use warnings;
use Exporter 'import';
use Carp 'carp', 'croak';


our $VERSION = '1.1';
our(@EXPORT_OK, %EXPORT_TAGS, @htmltags, @htmlexport, @xmlexport, %htmlbool, $OBJ);


BEGIN {
  # xhtml 1.0 tags
  @htmltags = qw|
    a abbr acronym address area b base bdo big blockquote body br button caption
    cite code col colgroup dd del dfn div dl dt em fieldset form h1 h2 h3 h4 h5 h6
    head i img input ins kbd label legend li Link Map meta noscript object ol
    optgroup option p param pre q samp script Select small span strong style Sub
    sup table tbody td textarea tfoot th thead title Tr tt ul var
  |;

  # boolean (self-closing) tags
  %htmlbool = map +($_,1), qw| area base br img input Link param |;

  # functions to export
  @htmlexport = (@htmltags, qw| html lit txt tag end |);
  @xmlexport = qw| xml lit txt tag end |;

  # create the subroutines to map to the html tags
  no strict 'refs';
  for my $e (@htmltags) {
    *{__PACKAGE__."::$e"} = sub {
      my $s = ref($_[0]) eq __PACKAGE__ ? shift : $OBJ;
      $s->tag(lc($e), @_, $htmlbool{$e} && $#_%2 ? undef : ());
    }
  }

  @EXPORT_OK = (@htmlexport, @xmlexport, 'xml_escape', 'html_escape');
  %EXPORT_TAGS = (
    html => \@htmlexport,
    xml  => \@xmlexport,
  );
};


# the common XHTML doctypes, from http://www.w3.org/QA/2002/04/valid-dtd-list.html
my %doctypes = split /\r?\n/, <<__;
xhtml1-strict
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
xhtml1-transitional
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
xhtml1-frameset
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">
xhtml11
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
xhtml-basic11
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN" "http://www.w3.org/TR/xhtml-basic/xhtml-basic11.dtd">
xhtml-math-svg
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1 plus MathML 2.0 plus SVG 1.1//EN" "http://www.w3.org/2002/04/xhtml-math-svg/xhtml-math-svg.dtd">
__


sub new {
  my($pack, %o) = @_;
  $o{write} ||= sub { print @_ };
  my $self = bless {
    %o,
    stack => [],
  }, $pack;
  $OBJ = $self if $o{default};
  return $self;
};


# XML escape (not a method)
sub xml_escape {
  local $_ = shift;
  if(!defined $_) {
    carp "Attempting to XML-escape an undefined value";
    return '';
  }
  s/&/&amp;/g;
  s/</&lt;/g;
  s/>/&gt;/g;
  s/"/&quot;/g;
  return $_;
}

# HTML escape, also does \n to <br /> conversion
# (not a method)
sub html_escape {
  local $_ = xml_escape shift;
  s/\r?\n/<br \/>/g;
  return $_;
}


# output literal data (not HTML escaped)
sub lit {
  my $s = ref($_[0]) eq __PACKAGE__ ? shift : $OBJ;
  $s->{write}->($_) for @_;
}


# output text (HTML escaped)
sub txt {
  my $s = ref($_[0]) eq __PACKAGE__ ? shift : $OBJ;
  $s->lit(xml_escape $_) for @_;
}


# Output any XML or HTML tag.
# Arguments                           Output
#  'tagname'                           <tagname>
#  'tagname', id => "main"             <tagname id="main">
#  'tagname', '<bar>'                  <tagname>&lt;bar&gt;</tagname>
#  'tagname', id => 'main', '<bar>'    <tagname id="main">&lt;bar&gt;</tagname>
#  'tagname', id => 'main', undef      <tagname id="main" />
#  'tagname', undef                    <tagname />
sub tag {
  my $s = ref($_[0]) eq __PACKAGE__ ? shift : $OBJ;
  my $name = shift;
  croak "Invalid XML tag name" if !$name || $name =~ /^[^a-z]/i || $name =~ / /;

  my $t = $s->{pretty} ? "\n".(' 'x(@{$s->{stack}}*$s->{pretty})) : '';
  $t .= '<'.$name;
  while(@_ > 1) {
    my $attr = shift;
    croak "Invalid XML attribute name" if !$attr || $attr =~ /^[^a-z]/i || $attr =~ / /;
    $t .= qq{ $attr="}.xml_escape(shift).'"';
  }

  if(!@_) {
    $t .= '>';
    $s->lit($t);
    push @{$s->{stack}}, $name;
  } elsif(!defined $_[0]) {
    $s->lit($t.' />');
  } else {
    $s->lit($t.'>'.xml_escape(shift).'</'.$name.'>');
  } 
}


# Ends the last opened tag
sub end {
  my $s = ref($_[0]) eq __PACKAGE__ ? shift : $OBJ;
  my $w = shift;
  my $l = pop @{$s->{stack}};
  croak "No more tags to close" if !$l;
  croak "Specified tag to end ($w) is not equal to the last opened tag ($l)" if $w && $w ne $l;
  $s->lit("\n".(' 'x(@{$s->{stack}}*$s->{pretty}))) if $s->{pretty};
  $s->lit('</'.$l.'>');
}


sub html {
  my $s = ref($_[0]) eq __PACKAGE__ ? shift : $OBJ;
  my %o = @_;

  $s->lit($doctypes{ delete($o{doctype}) || 'xhtml1-strict' }."\n");
  my $lang = delete $o{lang};
  $s->tag('html',
    xmlns => 'http://www.w3.org/1999/xhtml',
    $lang ? ('xml:lang' => $lang, lang => $lang) : (),
    %o
  );
}


# Writes an xml header, doesn't open an <xml> tag, and doesn't need an
# end() either.
sub xml() {
  my $s = ref($_[0]) eq __PACKAGE__ ? shift : $OBJ;
  $s->lit(qq|<?xml version="1.0" encoding="UTF-8"?>|);
}


1;

