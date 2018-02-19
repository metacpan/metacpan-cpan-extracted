#!/usr/bin/perl


package TUWF::XML;


use strict;
use warnings;
use Exporter 'import';
use Carp 'carp', 'croak';


our $VERSION = '1.2';
our(@EXPORT_OK, %EXPORT_TAGS, $OBJ);

# List::Util provides a uniq() since 1.45, but for some reason my Perl comes
# with an even more ancient version.
sub uniq { my %h = map +($_,1), @_; keys %h }


BEGIN {
  my @htmltags = qw|
    a abbr acronym address area b base bdo big blockquote body br button caption
    cite code col colgroup dd del dfn div dl dt em fieldset form h1 h2 h3 h4 h5 h6
    head i img input ins kbd label legend li Link Map meta noscript object ol
    optgroup option p param pre Q samp script Select small span strong style Sub
    sup table tbody td textarea tfoot th thead title Tr tt ul var
  |;
  my @html5tags = qw|
    a abbr address area article aside audio b base bb bdo blockquote body br
    button canvas caption cite code col colgroup command datagrid datalist dd
    del details dfn dialog div dl dt em embed fieldset figure footer form h1 h2
    h3 h4 h5 h6 head header hr i iframe img input ins kbd label legend li Link
    main Map mark meta meter nav noscript object ol optgroup option output p
    param pre progress Q rp rt ruby samp script section Select small source
    span strong style Sub sup table tbody td textarea tfoot th thead Time title
    Tr ul var video
  |;
  my @Htmltags   = map ucfirst, @htmltags;
  my @Html5tags  = map ucfirst, @html5tags;
  my @html_tags  = map lc($_).'_', @htmltags;
  my @html5_tags = map lc($_).'_', @html5tags;
  my @all = uniq @htmltags, @html5tags, @Htmltags, @Html5tags, @html_tags, @html5_tags;

  # boolean/empty/self-closing tags
  my %htmlbool = map +($_,1), qw{
    area base br col command embed hr img input link meta param source
  };

  # create the subroutines to map to the html tags
  no strict 'refs';
  for my $e (@all) {
    (my $le = lc $e) =~ s/_$//;
    *{__PACKAGE__."::$e"} = sub {
      my $s = ref($_[0]) eq __PACKAGE__ ? shift : $OBJ;
      $s->tag($le, @_, $htmlbool{$le} && $#_%2 ? undef : ());
    }
  }

  # functions to export
  @EXPORT_OK = (@all, qw(
    xml mkclass xml_escape html_escape
    tag  html  lit  txt  end
    Tag  Html  Lit  Txt  End
    tag_ html_ lit_ txt_ end_
  ));
  %EXPORT_TAGS = (
    html  => [ @htmltags,   qw(tag  html  lit  txt  end ) ],
    html5 => [ @html5tags,  qw(tag  html  lit  txt  end ) ],
    Html  => [ @Htmltags,   qw(Tag  Html  Lit  Txt  End ) ],
    Html5 => [ @Html5tags,  qw(Tag  Html  Lit  Txt  End ) ],
    html_ => [ @html_tags,  qw(tag_ html_ lit_ txt_ end_) ],
    html5_=> [ @html5_tags, qw(tag_ html_ lit_ txt_ end_) ],
    xml   => [ qw(xml tag lit txt end) ],
  );
};


# the common (X)HTML doctypes, from http://www.w3.org/QA/2002/04/valid-dtd-list.html
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
html5
<!DOCTYPE html>
__


sub new {
  my($pack, %o) = @_;
  $o{write} ||= sub { print @_ };
  my $self = bless {
    %o,
    nesting => 0,
    stack => [],
  }, $pack;
  $OBJ = $self if $o{default};
  return $self;
};


# Convenient function to generate a dynamic class attribute.
sub mkclass {
  my %c = @_;
  my $c = join ' ', grep $c{$_}, keys %c;
  return $c ? (class => $c) : ();
}


# XML escape (not a method)
my %XML = qw/& &amp; < &lt; " &quot;/;
sub xml_escape {
  local $_ = $_[0];
  if(!defined $_) {
    carp "Attempting to XML-escape an undefined value";
    return '';
  }
  s/([&<"])/$XML{$1}/g;
  $_;
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

*Lit = \&lit;
*lit_ = \&lit;


# output text (HTML escaped)
sub txt {
  my $s = ref($_[0]) eq __PACKAGE__ ? shift : $OBJ;
  $s->lit(xml_escape $_) for @_;
}

*Txt = \&txt;
*txt_ = \&txt;


# Output any XML or HTML tag.
# Arguments                           Output
#  'tagname'                           <tagname>
#  'tagname', id => "main"             <tagname id="main">
#  'tagname', '<bar>'                  <tagname>&lt;bar&gt;</tagname>
#  'tagname', sub { .. }               <tagname>..</tagname>
#  'tagname', id => 'main', '<bar>'    <tagname id="main">&lt;bar&gt;</tagname>
#  'tagname', id => 'main', sub { .. } <tagname id="main">..</tagname>
#  'tagname', id => 'main', undef      <tagname id="main" />
#  'tagname', undef                    <tagname />
sub tag {
  my $s = ref($_[0]) eq __PACKAGE__ ? shift : $OBJ;
  my $name = shift;
  croak "Invalid XML tag name" if !$name || $name =~ /^[^a-z]/i || $name =~ / /;

  my $indent = $s->{pretty} ? "\n".(' 'x($s->{nesting}*$s->{pretty})) : '';
  my $t = $indent.'<'.$name;
  while(@_ > 1) {
    my $attr = shift;
    croak "Invalid XML attribute name" if !$attr || $attr =~ /^[^a-z]/i || $attr =~ / /;
    $t .= qq{ $attr="}.xml_escape(shift).'"';
  }

  if(!@_) {
    $s->lit($t.'>');
    push @{$s->{stack}}, $name;
    $s->{nesting}++;
  } elsif(!defined $_[0]) {
    $s->lit($t.' />');
  } elsif(ref $_[0] eq 'CODE') {
    $s->lit($t.'>');
    local $s->{nesting} = $s->{nesting}+1;
    local $s->{stack} = []; # Call the sub with an empty stack, there's nothing to end() now.
    $_[0]->();
    $s->lit($indent.'</'.$name.'>');
  } else {
    $s->lit($t.'>'.xml_escape(shift).'</'.$name.'>');
  } 
}

*Tag = \&tag;
*tag_ = \&tag;


# Ends the last opened tag
sub end {
  my $s = ref($_[0]) eq __PACKAGE__ ? shift : $OBJ;
  my $w = shift;
  my $l = pop @{$s->{stack}};
  $s->{nesting}--;
  croak "No more tags to close" if !$l;
  croak "Specified tag to end ($w) is not equal to the last opened tag ($l)" if $w && $w ne $l;
  $s->lit("\n".(' 'x($s->{nesting}*$s->{pretty}))) if $s->{pretty};
  $s->lit('</'.$l.'>');
}

*End = \&end;
*end_ = \&end;


sub html {
  my $s = ref($_[0]) eq __PACKAGE__ ? shift : $OBJ;
  my $hascontent = @_ % 2 == 1;
  my $c = $hascontent && pop;
  my %o = @_;

  my $doctype = delete $o{doctype} || 'html5';

  $s->lit($doctypes{$doctype}."\n");
  my $lang = delete $o{lang};
  $s->tag('html',
    # html5 has no 'xmlns' or 'xml:lang'
    $doctype eq 'html5' ? (
      $lang ? (lang => $lang) : (),
    ) : (
      xmlns => 'http://www.w3.org/1999/xhtml',
      $lang ? ('xml:lang' => $lang, lang => $lang) : (),
    ),
    %o,
    $hascontent ? ($c) : ()
  );
}

*Html = \&html;
*html_ = \&html;


# Writes an xml header, doesn't open an <xml> tag, and doesn't need an
# end() either.
sub xml() {
  my $s = ref($_[0]) eq __PACKAGE__ ? shift : $OBJ;
  $s->lit(qq|<?xml version="1.0" encoding="UTF-8"?>|);
}


1;

