#!/usr/bin/perl
package Pod::AxPoint;

$Pod::AxPoint::VERSION = 0.04;

use Pod::Tree;
use Carp;

# map pod => ax XML
# scheme: http://search.cpan.org/dist/XML-Handler-AxPoint/lib/XML/Handler/AxPoint.pm

use vars qw(%syntax $ax);

my %syntax = (
	      head1       => "title",
	      head2       => "title",
	      text        => "plain",
	      verbatim    => "source-code",
	      b           => "b",
	      i           => "i",
	      c           => "source-code",
	      f           => "i",
	      g           => "image",
	      list_number => "list",
	      list_bullet => "list",
	      list_text   => "list",
	      item_number => "point",
	      item_bullet => "point",
	      item_text   => "point",
	      table       => "table",
	      row         => "row",
	      cell        => "col",
	      );

sub new {
  my ($class, %param) = @_;
  my $type = ref( $class ) || $class;
  my $self = \%param;
  bless $self, $type;
}

sub syntax {
  my($this, %syn) = @_;
  %syntax = %syn;
}

sub process {
  my($this, $pod) = @_;
  if (! $pod) {
    croak qq(Required parameter '$pod' missing!\n);
  }

  $ax = qq(<?xml version="1.0"?>\n<slideshow>\n);

  #####  start the rendering process
  my $tree = new Pod::Tree;
  my $in_slide   = 0;  # to find end of slice

  $tree->load_string($pod, in_pod => 0) or croak "Could not load POD: $!\n";

  $tree->walk(\&walker);

  $ax .= qq(</slide></slideshow>\n);

  return $ax;
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
  $ax .=  &tag_open($syntax{verbatim});

  $text =~ s/\s\s*$/ /gs;  # remove trailing spaces
  #$text =~ s/</&lt;/gs;    # replace <

  $ax .=  $text;
  $ax .=  &tag_close($syntax{verbatim});
}

sub walk_ordinary {
  my $node = shift;
  my $text = $node->get_raw;
  # normal paragraph
  $ax .=  &tag_open($syntax{text});
  &walk_children($node);
  $ax .=  &tag_close($syntax{text});
}

sub walk_command {
  my $node    = shift;
  my $command = lc($node->get_command);
  if ($command =~ /head([1-2])/) {
    my $level = $1;
    # start of a new section
    if ($in_slide) {
      # finish previous section
      $ax .=  qq(</slide>\n);
    }
    else {
      # first section
      $in_slide = 1;
    }
    $ax .=  qq(<slide>\n);

    $ax .=  &tag_open($syntax{$command});
    &walk_children($node);
    $ax .=  &tag_close($syntax{$command});
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

  if ($letter =~ /i|b|c|f/) {
    # format element
    $ax .=  &tag_open($syntax{$letter});
    &walk_children($node);
    $ax .=  &tag_close($syntax{$letter});
  }
  elsif ($letter =~ /g/) {
    # graphic element
    my ($image, $parameter) = split/\|/, $node->get_deep_text;
    # for now we ignore $parameter but might use it for scaling in the future
    $ax .=  qq(<image>$image</image>\n);
  }
  # currently unsupported - convert to unicode xml entities?
  # eg &#213; - FIXME
  #elsif ($letter =~ /e/) {
  #  # character entity, html unicode and pod entities are supported
  #  my $entity = $node->get_deep_text;
  #  print "&" .$entity . ";";
  #}
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
    $section = $target->get_section;
    # $name unsupported
    $ax .=  qq(<color name="blue"><u>$uri</u></color>);
  }
}


sub walk_text {
  my $node  = shift;
  my $text  = $node->get_text;
  $ax .=  $text;
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
  $ax .=  &tag_open($syntax{table} . $options);
  &walk_children($node);
  $ax .=  &tag_close($syntax{table});
}

sub walk_row {
  my $node = shift;
  my $options = &table_opt($node->get_arg);
  $ax .=  &tag_open($syntax{row} . $options);
  &walk_children($node);
  $ax .=  &tag_close($syntax{row});
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
  $ax .=  &tag_open($syntax{$tag} . $options);
  $ax .=  $node->get_deep_text;
  &walk_siblings($node);
  $ax .=  &tag_close($syntax{$tag});
}


sub walk_list {
  my $node      = shift;
  my $indent    = $node->get_arg;
  my $list_type = $node->get_list_type;

  $ax .=  &tag_open($syntax{"list_" . $list_type});

  &walk_children($node);	# text of the =over paragraph

  $ax .=  &tag_close($syntax{"list_" . $list_type});
}


sub walk_item {
  my $node      = shift;
  my $item_type = $node->get_item_type;

  # we must add the level here
  # http://axkit.org/archive/message/48/42
  $ax .=  &tag_open($syntax{"item_" . $item_type}, q(level="1"));
  if ($item_type ne "bullet" && $item_type ne "number") {
    # bullet types do not have content on the =item line beside the bullet
    &walk_children($node);	# text of the =item paragraph
  }
  &walk_siblings($node);
  $ax .=  &tag_close($syntax{"item_" . $item_type});
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

sub formatter_text {
  my($text) = @_;
  local $_ = $text;

  s/\s\s*$/ /gs;         	           # remove trailing spaces
  s/</&lt;/gs;           	           # replace <
  $ax .=  qq(<source-code>$_</source-code>); # 1:1 txt content
}

sub formatter_xml {
  my($text) = @_;
  # keep the input as is
  $ax .=  $text;
}

__END__

=head1 NAME

Pod::AxPoint - Generate AxPoint XML slideshow from POD source.

=head1 SYNOPSIS

 use Pod::AxPoint;
 my $ax = new Pod::AxPoint;
 print $ax->process($pod);

=head1 DESCRIPTION

B<Pod::AxPoint> converts POD input to AxPoint XML, which
can be used to generate HTML Slideshows.

The script L<pod2axpoint> delivered with Pod::AxPoint
provides a commandline frontend for the module.

There is another script for this purpose on cpan,
L<podslides-ax-magicpoint-0.01>, but this creates a xslt
transformation and doesn't support everything of AxPoint.
That's why I wrote my own.

=head1 METHODS

=head2 new()

This creates a new Pod::AxPoint object.

=head2 process($pod)

This actually generates the AxPoint slideshow from the supplied
POD string. Look at the B<POD> section for details about the
POD format.

Returns the slideshow as single string containing the AxPoint XML code.

=head2 syntax(%syntax)

You may call this before calling B<process()> to overwrite the
internal syntax map for mapping from POD to XHTML.

This is the default:

 %syntax = (
	      head1       => "title",
	      head2       => "title",
	      text        => "plain",
	      verbatim    => "source-code",
	      b           => "b",
	      i           => "i",
	      c           => "source-code",
	      f           => "i",
	      g           => "image",
	      list_number => "list",
	      list_bullet => "list",
	      list_text   => "list",
	      item_number => "point",
	      item_bullet => "point",
	      item_text   => "point",
	      table       => "table",
	      row         => "row",
	      cell        => "col",
	      );

You are encouraged to keep this mapping as is.

=head1 POD

Beside the known L<perlpod> markup some exceptions has been made:

=over

=item

Only the title B<=head1> is supported currently.

=item

Images can be included using the tag B<GE<lt>>image.pngB<E<gt>>.

=item

Plain XML code can be included using the B<xml> formatter, eg:

 =begin xml
 
 <title>Blah</title>
 
 =end xml

This way you add the required B<metadata> block to your slide.

=back


=head1 DEPENDENCIES

L<Pod::Tree> perl module is required.

B<AxPoint> is required. I used the FreeBSD port:

 /usr/ports/print/axpoint (axpoint-1.50)

Beside axpoint you need L<Pod::Tree> for parsing POD.

B<AxPoint> itself has a lot of dependencies, here are all the
(FreeBSD) packages were installed:

 axpoint-1.50                   XML Based Presentations
 docbook-xml-4.2_1              XML version of the DocBook DTD
 expat-2.0.0_1                  XML 1.0 parser written in C
 fontconfig-2.3.2_6,1           An XML-based font configuration API for X Windows
 libxml2-2.6.27                 XML parser library for GNOME
 p5-XML-Filter-BufferText-1.01  Filter to put all characters() in one event
 p5-XML-Filter-XSLT-0.03        XSLT as a SAX Filter
 p5-XML-LibXML-1.62001          Interface to Gnome libxml2 library
 p5-XML-LibXML-Common-0.13      Routines and Constants common for XML::LibXML and XML::GDOM
 p5-XML-LibXSLT-1.59            Perl interface to the GNOME XSLT library
 p5-XML-NamespaceSupport-1.09_1 A simple generic namespace support class
 p5-XML-Parser-2.34_2           Perl extension interface to James Clark's XML parser, expat
 p5-XML-SAX-0.15                Simple API for XML
 p5-XML-SAX-Expat-0.38          Simple API for XML
 p5-XML-SAX-Writer-0.50         SAX2 XML Writer
 sdocbook-xml-1.1,1             "Simplified" DocBook XML DTD
 xmlcatmgr-2.2                  SGML and XML catalog manager

If you're not on FreeBSD try cpan or install all the
stuff manually - which is annoying.

Last but not least: try FreeBSD.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007 Thomas Linden

This tool is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 BUGS AND LIMITATIONS

See rt.cpan.org for current bugs, if any.

=head1 INCOMPATIBILITIES

None known.

=head1 DIAGNOSTICS

To debug pod2axpoint use B<debug()> or the perl debugger, see L<perldebug>.

=head1 AUTHOR

Thomas Linden <tlinden |AT| cpan.org>

=head1 VERSION

0.04

=cut
