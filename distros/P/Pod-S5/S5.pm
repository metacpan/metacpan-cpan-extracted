#!/usr/bin/perl

 #   map perl POD to S5
 #
 #
 #   This  file  is  part of the  Pod2S5.
 #
 #   By  accessing  this software,  Pod2S5,  you are  duly informed
 #   of and  agree to be  bound  by the  conditions  described below
 #   in this notice:
 #
 #   This software product, Pod2S5,  is developed by  Thomas Linden
 #   and     copyrighted  (C) 2007-2013 by  Thomas Linden,  with all
 #   rights reserved.
 #
 #   There is  no charge for  Pod2S5 software. You can redistribute
 #   it and/or modify it under  the terms of the  GNU General Public
 #   License, which is incorporated by reference herein.
 #
 #   Pod2S5 is distributed WITHOUT ANY WARRANTY,IMPLIED OR EXPRESS,
 #   OF  MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE or that
 #   the  use of it will not infringe on any third party's intellec-
 #   tual property rights.
 #
 #   You  should  have  received a  copy  of  the GNU General Public
 #   License along with Pod2S5.  Copies  can also be obtained from:
 #
 #     http://www.gnu.org/copyleft/gpl.html
 #
 #   or by writing to:
 #
 #     Free Software Foundation, Inc.
 #     59 Temple Place, Suite 330
 #     Boston, MA 02111-1307
 #     USA
 #
 #   Or contact:
 #
 #    "Thomas Linden" <tom |AT| cpan.org>
 #
 #   Additional Copyrights:
 #
 #    Eric Meyer (D/pod2s5/Pod-S5-0.01/demo/example/index.html)
 #     S5 Version 1.2a (Attribution-ShareAlike 2.0 License)
 #
 #


package Pod::S5;

$Pod::S5::VERSION = 0.09;

use Pod::Tree;
use Carp;

use vars qw(%syntax %highlite $substitutions $head $foot $s5);


%syntax = (
	      head1       => "h1",
	      head2       => "h2",
	      head3       => "h3",
	      head4       => "h4",
	      text        => "p",
	      verbatim    => "code",
	      b           => "b",
	      i           => "i",
	      u           => "u",
	      c           => "code",
	      f           => "i",
	      g           => "img",
	      list_number => "ol",
	      list_bullet => q(ul class="incremental"),
	      list_text   => "ul",
	      item_number => "li",
	      item_bullet => "li",
	      item_text   => "li",
	      table       => "table",
	      row         => "tr",
	      cell        => "td",
	      );


# used for syntax highlighting, if Syntax::Highlight::Engine::Kate
# is installed and the Code in question is supported
%highlite = {
                Alert => ['<font color="#0000ff">', '</font>'],
                BaseN => ['<font color="#007f00">', '</font>'],
                BString => ['<font color="#c9a7ff">', '</font>'],
                Char => ['<font color="#ff00ff">', '</font>'],
                Comment => ['<font color="#7f7f7f"><i>', '</i></font>'],
                DataType => ['<font color="#0000ff">', '</font>'],
                DecVal => ['<font color="#00007f">', '</font>'],
                Error => ['<font color="#ff0000"><b><i>', '</i></b></font>'],
                Float => ['<font color="#00007f">', '</font>'],
                Function => ['<font color="#007f00">', '</font>'],
                IString => ['<font color="#ff0000">', ''],
                Keyword => ['<b>', '</b>'],
                Normal => ['', ''],
                Operator => ['<font color="#ffa500">', '</font>'],
                Others => ['<font color="#b03060">', '</font>'],
                RegionMarker => ['<font color="#96b9ff"><i>', '</i></font>'],
                Reserved => ['<font color="#9b30ff"><b>', '</b></font>'],
                String => ['<font color="#ff0000">', '</font>'],
                Variable => ['<font color="#0000ff"><b>', '</b></font>'],
                Warning => ['<font color="#0000ff"><b><i>', '</font>'],
	       };

$substitutions = {
		     '<' => '&lt;',
		     '>' => '&gt;',
		     '&' => '&amp;',
		     ' ' => '&nbsp;',
		     "\t" => '&nbsp;&nbsp;&nbsp;',
		     "\n" => "<BR>\n",
        };



# well, this looks ugly but I dont want to have html
# files to lay around on the disk because pod2s5 is
# a self-contained tool, including all the required
# stuff. templates and the s5 engine itself are contained
# too, after the __DATA__ internal filehandle.
$head = qq(<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">

<head>
<title>#name#</title>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
<meta name="generator" content="pod2s5 #version#" />
<meta name="generator" content="S5" />
<meta name="version" content="S5 1.1" />
<meta name="presdate" content="#creation#" />
<meta name="author" content="#author#" />
<meta name="company" content="#company#" />
<!-- configuration parameters -->
<meta name="defaultView" content="slideshow" />
<meta name="controlVis" content="hidden" />
<!-- style sheet links -->
<link rel="stylesheet" href="ui/#theme#/slides.css" type="text/css" media="projection" id="slideProj" />
<link rel="stylesheet" href="ui/default/outline.css" type="text/css" media="screen" id="outlineStyle" />
<link rel="stylesheet" href="ui/default/print.css" type="text/css" media="print" id="slidePrint" />
<link rel="stylesheet" href="ui/default/opera.css" type="text/css" media="projection" id="operaFix" />

<!-- embedded styles -->
<style type="text/css" media="all">
.imgcon {width: 525px; margin: 0 auto; padding: 0; text-align: center;}
#anim {width: 270px; height: 320px; position: relative; margin-top: 0.5em;}
#anim img {position: absolute; top: 42px; left: 24px;}
img#me01 {top: 0; left: 0;}
img#me02 {left: 23px;}
img#me04 {top: 44px;}
img#me05 {top: 43px;left: 36px;}
</style>
<!-- S5 JS -->
<script src="ui/default/slides.js" type="text/javascript"></script>
<!--
   tom AT cpan.org:
   this will not work, it's not contained
   in the downloadable S5
   <script src="/mint/?js" type="text/javascript"></script></head>
-->
<body>

<div class="layout">

<div id="controls"></div>
<div id="currentSlide"></div>
<div id="header"></div>
<div id="footer">
<h1>#where# &#8226; #creation#</h1>
<h2>#name#</h2></div>
</div>);

$foot = qq(</div></body></html>);


sub new {
  my ($class, %param) = @_;
  my $type = ref( $class ) || $class;

  my @names = qw(theme author creation where company name);
  foreach my $name (@names) {
    if (! exists $param{$name}) {
      croak qq(Required parameter "$name" is not defined!\n);
    }
  }
  $param{version} = $Pod::S5::VERSION;

  my $self = \%param;

  bless $self, $type;
}

sub highlite {
  my ($this, %high) = @_;
  %highlite = %high;
}

sub syntax {
  my($this, %syn) = @_;
  %syntax = %syn;
}

sub head {
  my($this, $h) = @_;
  $head = $h;
}

sub foot {
  my($this, $f) = @_;
  $foot = $f;
}

sub process {
  my($this, $pod) = @_;
  if (! $pod) {
    croak qq(Required parameter '$pod' missing!\n);
  }

  # insert variables into header
  $head =~ s/#([a-z]+)#/$this->{$1}/ges;

  $s5 = $head;

  #####  start the rendering process
  my $tree = new Pod::Tree;
  my $in_slide   = 0;  # to find end of slice

  $tree->load_string($pod, in_pod => 0) or croak "Could not load POD: $!\n";

  $tree->walk(\&walker);

  $s5 .= $foot;

  return $s5;
}


sub tag_open {
  my ($name, $param) = @_;
  if ($param) {
    return qq(<$name $param>);
  }
  else {
    return qq(<$name>);
  }
}

sub tag_close {
  my $name = shift;
  return "</" . $name . ">";
}

sub walker {
  my $node = shift;
  my $type = $node->get_type;
  my $sub = "walk_" . $type;
  &$sub($node);
}


sub walk_root {
  my $node = shift;
  &walk_children($node);
}


sub walk_children {
  my $node     = shift;
  my $children = $node->get_children;

  foreach my $child (@$children) {
      &walker($child);
  }
}

sub walk_verbatim {
  my $node = shift;
  my $text = $node->get_text;
  $s5 .= &tag_open($syntax{verbatim});

  $text =~ s/\s\s*$/ /gs;  # remove trailing spaces
  #$text =~ s/</&lt;/gs;    # replace <

  $s5 .= $text;
  $s5 .= &tag_close($syntax{verbatim});
}

sub walk_ordinary {
  my $node = shift;
  my $text = $node->get_raw;
  # normal paragraph
  $s5 .= &tag_open($syntax{text});
  &walk_children($node);
  $s5 .= &tag_close($syntax{text});
}

sub walk_command {
  my $node    = shift;
  my $command = lc($node->get_command);
  if ($command =~ /head([1-4])/) {
    my $level = $1;
    if ($level == 1) {
      # start of a new slide
      if ($in_slide) {
	# finish previous section
	$s5 .= qq(</div>\n);
      }
      else {
	# first section
	$in_slide = 1;
      }
      $s5 .= qq(<div class="slide">\n);
    }

    $s5 .= &tag_open($syntax{$command});
    &walk_children($node);
    $s5 .= &tag_close($syntax{$command});
  }
  elsif ($command =~ /over/) {
    &walk_list($node);
  }
}

sub walk_letter {
  # workaround for node-type 'letter', which
  # is handled in walk_sequence()
  &walk_sequence(@_);
}

sub walk_sequence {
  my $node   = shift;
  my $letter = lc($node->get_letter);

  if ($letter =~ /i|b|c|f|u/) {
    # format element
    $s5 .= &tag_open($syntax{$letter});
    &walk_children($node);
    $s5 .= &tag_close($syntax{$letter});
  }
  elsif ($letter =~ /g/) {
    # graphic element
    my ($image, $parameter) = split/\|/, $node->get_deep_text;
    # for now we ignore $parameter but might use it for scaling in the future
    $s5 .= qq(<img src="$image" $parameter/>\n);
  }
  elsif ($letter =~ /e/) {
    # character entity, html unicode and pod entities are supported
    my $entity = $node->get_deep_text;
    $s5 .= "&" .$entity . ";";
  }
  elsif ($letter =~ /l/) {
    my ($uri, $name);
    my $target   = $node->get_target;
    my $linkpage = $target->get_page;
    if($linkpage =~ /\s/) {
      ($uri, $name) = split /\s\s*/, $linkpage, 2;
    }
    else {
      $uri = $linkpage;
    }
    my $section = $target->get_section;

    if ($section) {
      $section = qq(#$section);
    }
    $s5 .= qq(<a href="$uri$section">);
    if (! $name) {
      &walk_children($node);
    }
    $s5 .= qq(</a>);
  }
}





sub walk_text {
  my $node  = shift;
  my $text  = $node->get_text;
  $s5 .= $text;
}

sub table_opt {
  my $opt = shift;
  if (! $opt) {
    return "";
  }
  else {
    $opt =~ s/^\s*//gs;
    $opt =~ s/\s*$//gs;
    $opt =~ s/,/ /g;
    $opt = " $opt";
    return $opt;
  }
}

sub walk_table {
  my $node = shift;
  my $options = &table_opt($node->get_arg);
  $s5 .= &tag_open($syntax{table} . $options);
  &walk_children($node);
  $s5 .= &tag_close($syntax{table});
}

sub walk_row {
  my $node = shift;
  my $options = &table_opt($node->get_arg);
  $s5 .= &tag_open($syntax{row} . $options);
  &walk_children($node);
  $s5 .= &tag_close($syntax{row});
  &walk_siblings($node);
}

sub walk_cell {
  my $node = shift;
  my $tag = "cell";
  my $options = &table_opt($node->get_arg);
  if ($options) {
    # removed + match
    $options =~ s/type=head//;
    $tag = "headcell";
  }
  $s5 .= &tag_open($syntax{$tag} . $options);
  $s5 .= $node->get_deep_text;
  &walk_siblings($node);
  $s5 .= &tag_close($syntax{$tag});
}


sub walk_list {
  my $node      = shift;
  my $indent    = $node->get_arg;
  my $list_type = $node->get_list_type;

  $s5 .= &tag_open($syntax{"list_" . $list_type});

  &walk_children($node);	# text of the =over paragraph

  $s5 .= &tag_close($syntax{"list_" . $list_type});
}


sub walk_item {
  my $node      = shift;
  my $item_type = $node->get_item_type;

  # we must add the level here
  # http://axkit.org/archive/message/48/42
  $s5 .= &tag_open($syntax{"item_" . $item_type}, q(level="1"));
  if ($item_type ne "bullet" && $item_type ne "number") {
    # bullet types do not have content on the =item line beside the bullet
    &walk_children($node);	# text of the =item paragraph
  }
  &walk_siblings($node);
  $s5 .= &tag_close($syntax{"item_" . $item_type});
}

sub walk_siblings {
  my $node     = shift;
  my $siblings = $node->get_siblings;

  for my $sibling (@$siblings) {
    &walker($sibling);
  }
}

sub walk_for {
  my $node      = shift;
  my $formatter = $node->get_arg;
  my $text      = $node->get_text;
  $formatter =~ s/\s//g;

  # call the generalized formatter
  my $sub = "formatter_" . $formatter;
  &$sub($text);
}


sub walk_code {
  # perl code and comments - ignore
  return;
}

sub AUTOLOAD {
  # here comes the magic, we catch the formatter sub
  # called by walker() containing the highlite syntax
  # in question, if any. Otherwise just to text output
  my($text) = @_;
  my $lang = $Pod::S5::AUTOLOAD;
  $lang =~ s/.*::formatter_(.)/uc($1)/e;
  &formatter_highlight($text, $lang);
}

sub formatter_highlight {
  my ($text, $lang) = @_;
  if ($lang) {
    # try to load Syntax::Highlight::Engine::Kate
    eval {
      require Syntax::Highlight::Engine::Kate;
    };
    if ($@) {
      warn qq(WARNING: Syntax::Highlight::Engine::Kate could not be loaded, using TEXT mode.\n);
      &formatter_text($text);
    }
    else {
      eval {
	# this might fail if the language provided is not supported
	my $hl = new Syntax::Highlight::Engine::Kate(
						     language => $lang,
						     substitutions => $substitutions,
						     format_table => \%highlite
						     );
	$s5 .= $hl->highlightText($text);
      };
      if ($@) {
	warn qq(WARNING: Could not render text input for syntax $lang: $@, using TEXT mode.\n);
	&formatter_text($text);
      }
    }
  }
  else {
    &formatter_text($text);
  }
}

sub formatter_text {
  my($text) = @_;
  local $_ = $text;

  s/\s\s*$/ /gs;             # remove trailing spaces
  s/</&lt;/gs;               # replace <
  $s5 .= qq(<pre>$_</pre>); # 1:1 txt content
}

sub formatter_note {
  my($text) = @_;
  local $_ = $text;

  s/\s\s*$/ /gs;             # remove trailing spaces
  s/</&lt;/gs;               # replace <
  $s5 .= qq(<div class="notes">$_</div>); # notes
}


sub formatter_html {
  my($text) = @_;
  # keep the input as is
  $s5 .= $text;
}


sub prepare {
  my($text) = @_;
  local $_ = $text;
  s/\s\s*$/ /gs;
  s/</&lt;/gs;
  s/&/&amp;/gs;
  return $_;
}


1;

=head1 NAME

Pod::S5 - Generate S5 slideshow from POD source.

=head1 SYNOPSIS

 use Pod::S5;
 my $s5 = new Pod::S5(
              theme    => 'default',
              author   => 'root',
              creation => '1.1.1979',
              where    => 'Perl Republic',
              company  => 'Perl Inc.',
              name     => 'A slide about perl');
 print $s5->process($pod);

=head1 DESCRIPTION

B<Pod::S5> converts POD input to a S5 HTML slideshow. No
additional software is required. Just write a POD file, run
B<Pod::S5> on it - and you're done.

This is the perl module which actually generates the S5
markup output. It doesn't output nor create the S5 stuff
such as stylesheets, images or the like. You are responsible
to make those files available in the proper location.

=head1 METHODS

=head2 new(%param)

This creates a new Pod::S5 object. The variables required
for slideshow generation must be supplied as a hash. Example:

 my $s5 = new Pod::S5(
              theme    => 'default',
              author   => 'root',
              creation => '1.1.1979',
              where    => 'Perl Republic',
              company  => 'Perl Inc.',
              name     => 'A slide about perl');

All parameters are required.

=head2 process($pod)

This actually generates the S5 slideshow from the supplied
POD string. Look at the B<POD> section for details about the
POD format.

Returns the slideshow as single string. No stylesheet or images
are contained, the string is just the XHTML code for the slideshow.

=head2 highlite(%hash)

You may call this before calling B<process()> to overwrite the
internal %highlite hash which is used for syntax highlighting.

See L<Syntax::Highlight::Engine::Kate> how it must be formatted.

=head2 syntax(%syntax)

You may call this before calling B<process()> to overwrite the
internal syntax map for mapping from POD to XHTML.

This is the default:

 %syntax = (
              head1       => "h1",
              head2       => "h2",
              head3       => "h3",
              head4       => "h4",
              text        => "p",
              verbatim    => "code",
              b           => "b",
              i           => "i",
              u           => "u",
              c           => "code",
              f           => "i",
              g           => "img",
              list_number => "ol",
              list_bullet => q(ul class="incremental"),
              list_text   => "ul",
              item_number => "li",
              item_bullet => "li",
              item_text   => "li",
              table       => "table",
              row         => "tr",
              cell        => "td",
              );

You are encouraged to keep this mapping as is.

=head2 head($template)

You may call this before calling B<process()> to overwrite the
internal XHTML header template. Look at the Pod::S5 source how
it currently looks. This is the original S5 header with template
variables for replacement with the supplied parameters to B<new()>.

=head2 foot($string)

You may call this before calling B<process()> to overwrite the
internal XHTML footer.

=head1 POD

Beside the known L<perlpod> markup some additions have been made:

Since we are generating a slideshow, the POD must be devided into
pieces which can be used as slides. Slides will be separated by the
B<=head1> title tag (which itself becomes the title of the slide.

 =head1 Intro --+
                |
 [..]           +------- Slide 1
 [..]           |
            ----+
 
 =head1 Intro --+
                |
 [..]           +------- Slide 2
 [..]           |
            ----+
 
 =head1 End   --+
                |
 [..]           +------- Slide 3
 [..]           |
            ----+

Each slide may contain any valid POD.

=over

=item

Images can be included using the tag B<GE<lt>>image.pngB<E<gt>>.
You must manually copy images to the target directory.

=item

Plain HTML code can be included using the B<html> formatter, eg:

 =begin html
 
 <title>Blah</title>
 
 =end html

=item

You can create incremental slides using bullet lists, that is
each list item will appear separately, as if it were on an extra
slide.

Example:

 =over
 
 =item *
 
 1st item
 
 =item *
 
 2nd item
 
 =back

=item

You can add special formatters for code, which will be syntax
highlighted if the module L<Syntax::Highlight::Engine::Kate>
is installed. Use the name of the programming language as the
formatter name.

Example:

 =begin perl
 
 if ($var) {
  exit;
 }
 
 =end perl

To get a list of the available languages, refer to the
L<Syntax::Highlight::Engine::Kate> manpage.

=item

Notes can be added to a slide by inserting a B<note> formatter, eg:

 =begin note

 some additional stuff

 =end note

It will be rendered as plain text.

=back


=head1 DEPENDENCIES

L<Syntax::Highlight::Engine::Kate> is optional.

The S5 slideshow files.

=head1 SEE ALSO

S5 is already included in the script B<pod2s5> which is
delivered together with B<Pod::S5>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007-2011 Thomas Linden

This tool is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

S5 Copyright (c) 2007 Eric Meyer
S5 Version 1.2a (Attribution-ShareAlike 2.0 License)

=head1 BUGS AND LIMITATIONS

See rt.cpan.org for current bugs, if any.

=head1 INCOMPATIBILITIES

None known.

=head1 DIAGNOSTICS

To debug Pod::S5 use B<debug()> or the perl debugger, see L<perldebug>.

=head1 AUTHOR

Thomas Linden <tlinden |AT| cpan.org>

=head1 VERSION

0.09

=cut

__DATA__
