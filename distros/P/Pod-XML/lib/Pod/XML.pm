package Pod::XML;

# $Id: XML.pm 30 2007-02-03 16:50:07Z matt $

use strict;
use warnings;
use vars qw(@ISA $VERSION);

use Pod::Parser;

@ISA = ( 'Pod::Parser' );

$VERSION = '0.99';

# I'm not sure why Matt Sergeant did this in this way but I'll leave it for
# the time being
my %head2sect = (
  1 => "sect1",
  2 => "sect2",
  3 => "sect3",
  4 => "sect4",
);

# a hash array of HTML escape codes
my %HTML_Escapes = (
  "apos"      => "#x27",  # apostrophe
  "Aacute"    => "#xC1",  # capital A, acute accent
  "aacute"    => "#xE1",  # small a, acute accent
  "Acirc"     => "#xC2",  # capital A, circumflex accent
  "acirc"     => "#xE2",  # small a, circumflex accent
  "AElig"     => "#xC6",  # capital AE diphthong (ligature)
  "aelig"     => "#xE6",  # small ae diphthong (ligature)
  "Agrave"    => "#xC0",  # capital A, grave accent
  "agrave"    => "#xE0",  # small a, grave accent
  "Aring"     => "#xC5",  # capital A, ring
  "aring"     => "#xE5",  # small a, ring
  "Atilde"    => "#xC3",  # capital A, tilde
  "atilde"    => "#xE3",  # small a, tilde
  "Auml"      => "#xC4",  # capital A, dieresis or umlaut mark
  "auml"      => "#xE4",  # small a, dieresis or umlaut mark
  "Ccedil"    => "#xC7",  # capital C, cedilla
  "ccedil"    => "#xE7",  # small c, cedilla
  "Eacute"    => "#xC9",  # capital E, acute accent
  "eacute"    => "#xE9",  # small e, acute accent
  "Ecirc"     => "#xCA",  # capital E, circumflex accent
  "ecirc"     => "#xEA",  # small e, circumflex accent
  "Egrave"    => "#xC8",  # capital E, grave accent
  "egrave"    => "#xE8",  # small e, grave accent
  "ETH"       => "#xD0",  # capital Eth, Icelandic
  "eth"       => "#xF0",  # small eth, Icelandic
  "Euml"      => "#xCB",  # capital E, dieresis or umlaut mark
  "euml"      => "#xEB",  # small e, dieresis or umlaut mark
  "Iacute"    => "#xCD",  # capital I, acute accent
  "iacute"    => "#xED",  # small i, acute accent
  "Icirc"     => "#xCE",  # capital I, circumflex accent
  "icirc"     => "#xEE",  # small i, circumflex accent
  "Igrave"    => "#xCD",  # capital I, grave accent
  "igrave"    => "#xED",  # small i, grave accent
  "Iuml"      => "#xCF",  # capital I, dieresis or umlaut mark
  "iuml"      => "#xEF",  # small i, dieresis or umlaut mark
  "Ntilde"    => "#xD1",  # capital N, tilde
  "ntilde"    => "#xF1",  # small n, tilde
  "Oacute"    => "#xD3",  # capital O, acute accent
  "oacute"    => "#xF3",  # small o, acute accent
  "Ocirc"     => "#xD4",  # capital O, circumflex accent
  "ocirc"     => "#xF4",  # small o, circumflex accent
  "Ograve"    => "#xD2",  # capital O, grave accent
  "ograve"    => "#xF2",  # small o, grave accent
  "Oslash"    => "#xD8",  # capital O, slash
  "oslash"    => "#xF8",  # small o, slash
  "Otilde"    => "#xD5",  # capital O, tilde
  "otilde"    => "#xF5",  # small o, tilde
  "Ouml"      => "#xD6",  # capital O, dieresis or umlaut mark
  "ouml"      => "#xF6",  # small o, dieresis or umlaut mark
  "szlig"     => "#xDF",  # small sharp s, German (sz ligature)
  "THORN"     => "#xDE",  # capital THORN, Icelandic
  "thorn"     => "#xFE",  # small thorn, Icelandic
  "Uacute"    => "#xDA",  # capital U, acute accent
  "uacute"    => "#xFA",  # small u, acute accent
  "Ucirc"     => "#xDB",  # capital U, circumflex accent
  "ucirc"     => "#xFB",  # small u, circumflex accent
  "Ugrave"    => "#xD9",  # capital U, grave accent
  "ugrave"    => "#xF9",  # small u, grave accent
  "Uuml"      => "#xDC",  # capital U, dieresis or umlaut mark
  "uuml"      => "#xFC",  # small u, dieresis or umlaut mark
  "Yacute"    => "#xDD",  # capital Y, acute accent
  "yacute"    => "#xFD",  # small y, acute accent
  "yuml"      => "#xFF",  # small y, dieresis or umlaut mark
  "lchevron"  => "#xAB",  # left chevron (double less than)
  "rchevron"  => "#xBB",  # right chevron (double greater than)
);

sub html_escape
{
  my $text = shift || '';

  # ampersand MUST be done first!
  $text =~ s/&/\&amp;/g;

  # handle < and > too
  $text =~ s/</\&lt;/g;
  $text =~ s/>/\&gt;/g;

  # convert other {tag:...} markers
  $text =~ s/{tag:escape ref='([^']*)'}/\&$1;/g;

  return $text;
}

sub finalise_output
{
  my $parser = shift;

  # put something pretty together
  $parser->{xml_string} =
      "<?xml version='1.0' encoding='" .
      ( $parser->{Encoding} || "iso-8859-1" ) . "'?>\n" .
      "<pod xmlns=\"http://axkit.org/ns/2000/pod2xml\">\n" .
      "<head>\n" .
      "<title>" . html_escape ( $parser->{title} ) . "</title>\n" .
      "</head>\n" .
      $parser->{xml_string} .
      "</pod>\n";

  if ( $parser->{Encoding} )
  {
    my $tmp = Encode::encode ( $parser->{Encoding}, $parser->{xml_string} );
    $parser->{xml_string} = $tmp;
  }

  if ( ! $parser->{send_to_string} )
  {
    my $fh = $parser->output_handle ();

    print $fh $parser->{xml_string};
  }
}

sub xml_output
{
  my ( $parser, @strings ) = @_;
  
  $parser->{xml_string} .= join ( '', @strings );
}

sub begin_pod
{
  my ( $parser ) = @_;

  if ( $parser->{Encoding} )
  {
    # can we use the Encode module?
    eval
    {
      require Encode;
    };

    die ( "Need Encode module to specify specific output encoding - " . $@ )
      if ( $@ );

    # make sure we can encode to the specific encoding
    eval
    {
      Encode::encode ( $parser->{Encoding}, "" );
    };

    die ( "Encoding issue - " . $@ ) if ( $@ );
  }

  $parser->{headlevel} = 0;
  $parser->{seentitle} = 0;
  $parser->{closeitem} = 0;
  $parser->{in_begin_block} = 0;
  $parser->{this_is_name} = 0;
  $parser->{title} = '';
  $parser->{xml_string} = '';
}

sub end_pod
{
  my ( $parser ) = @_;

  while ( $parser->{headlevel} )
  {
    $parser->xml_output ( "</" . $head2sect { $parser->{headlevel}-- } .
        ">\n" );
  }

  $parser->finalise_output;
}

sub command
{
  my ( $parser, $command, $paragraph ) = @_;

  $paragraph =~ s/\s*$//;
  $paragraph =~ s/^\s*//;

  $paragraph = $parser->interpolate ( $paragraph );
  $paragraph = uri_find ( $paragraph );
  $paragraph = html_escape ( $paragraph );
  $paragraph =~ s/\{(\/?)tag:(.*?)\}/<$1$2>/g;
  $paragraph =~ s/\{code:(\d+)\}/&#$1/g;

  if ( $parser->{in_begin_block} == 0 )
  {
    if ( $command =~ /^head(\d+)/ )
    {
      my $headlevel = $1;

      # we should use "NAME" as the title
      $parser->{this_is_name}++
        if ( $paragraph =~ m/^name$/i && $parser->{this_is_name} == 0 );

      if ( $headlevel <= $parser->{headlevel} )
      {
        while ( $headlevel <= $parser->{headlevel} )
        {
          $parser->xml_output ( "</", $head2sect { $parser->{headlevel}-- },
              ">\n" );
        }
      }

      while ( $headlevel > ( $parser->{headlevel} + 1 ) )
      {
        $parser->xml_output ( "<", $head2sect { ++$parser->{headlevel} },
            ">\n" );
      }

      $parser->{headlevel} = $headlevel;
      $parser->xml_output ( "<", $head2sect { $headlevel }, ">\n",
          "<title>", $paragraph, "</title>\n" );
    }
    elsif ( $command eq "over" )
    {
      if ( $parser->{closeitem} )
      {
        $parser->xml_output ( "</item>\n" );
        $parser->{closeitem} = 0;
      }

      $parser->xml_output ( "<list>\n" );
    }
    elsif ( $command eq "back" )
    {
      if ( $parser->{closeitem} )
      {
        $parser->xml_output ( "</item>\n" );
        $parser->{closeitem} = 0;
      }

      $parser->xml_output ( "</list>\n" );
    }
    elsif ( $command eq "item" )
    {
      if ( $parser->{closeitem} )
      {
        $parser->xml_output ( "</item>\n" );
        $parser->{closeitem} = 0;
      }

      $parser->xml_output ( "<item>" );

      if ( $paragraph ne '*' )
      {
        $paragraph =~ s/^\*\s+//;
        $parser->xml_output ( "<itemtext>", $paragraph, "</itemtext>\n" );
      }

      $parser->{closeitem}++;
    }
    elsif ( $command eq 'begin' )
    {
      # this is to strip out =begin ... =end blocks, which aren't generally POD
      $parser->{in_begin_block} = 1;
    }
  }
  elsif ( $command eq 'end' )
  {
    $parser->{in_begin_block} = 0;
  }
}

sub verbatim
{
  my ( $parser, $paragraph ) = @_;

  return if $parser->{in_begin_block};

  if ( $paragraph =~ s/^(\s*)// )
  {
    my $indent = $1;

    $paragraph =~ s/\s*$//;

    return unless length $paragraph;
  
    $paragraph =~ s/^$indent//mg; # un-indent
    $paragraph =~ s/\]\]>/\]\]>\]\]&gt;<!\[CDATA\[/g;

    # is this the title block?
    if ( $parser->{this_is_name} == 1 )
    {
    # increment, rather than setting back to zero; this way we can ensure
    # the first NAME is used, but not proceeding ones
      $parser->{this_is_name}++;
      $parser->{title} = "<![CDATA[\n" . $paragraph . "\n]]>";
    }

    $parser->xml_output ( "<verbatim><![CDATA[\n", $paragraph,
        "\n]]></verbatim>\n" );
  }
}

sub textblock
{
  my ( $parser, $paragraph, $line_num ) = @_;

  return if $parser->{in_begin_block};

  $paragraph =~ s/^\s*//;
  $paragraph =~ s/\s*$//;

  my $text = $parser->interpolate ( $paragraph );

  $text = uri_find ( $text );
  $text = html_escape ( $text );
  $text =~ s/\{(\/?)tag:(.*?)\}/<$1$2>/g;
  $text =~ s/\{code:(\d+)\}/&#$1/g;

  if ( $parser->{this_is_name} == 1 )
  {
    # increment, rather than setting back to zero; this way we can ensure the
    # first NAME is used, but not proceeding ones
    $parser->{this_is_name}++;
    $parser->{title} = $paragraph;
  }

  if ( $parser->{headlevel} == 0 )
  {
    $parser->xml_output ( "<sect1>\n<title>", $parser->{title},
        "</title>\n" );
    $parser->{headlevel}++;
  }

  $parser->xml_output ( "<para>\n", $text, "\n</para>\n" );
}

sub uri_find
{
  my $text = shift || '';

  # Code from the Perl Cookbook
  my $urls = '(https|http|telnet|gopher|file|wais|ftp|mailto)';
  my $ltrs = '\w';
  my $gunk = '/#~:.?+=&%@!\-';
  my $punc = '.:?\-!,';
  my $any  = $ltrs . $gunk . $punc;

  my $new;

  while (
      $text =~ m{
        \G          # anchor to last match place
        (.*?)       # catch stuff before match in $1
        \b          # start at word boundary
        (           # BEGIN $2
          $urls :   # http:
          (?![:/])  # negative lookahead for : or /
          [$any]+?  # followed by 1 or more allowed charact
        )           # END $2
        (?=         # look ahead after $2
          [$punc]*  #  for 0 or more punctuation characters
          (
            [^$any] #  followed by a non-URL character
            | \Z    #  or alternatively the end of the html
          )
        )           # end of look ahead
        }igcsox )
  {
    my ( $pre, $url ) = ( $1, $2 );
    $new .= $pre;
    $new .= "\{tag:xlink uri='" . $url . "'\}" . $url . "\{/tag:xlink\}";
  }

  $text =~ /\G(.*)/gcs;
  $new .= $1 if defined $1;

  return $new;
}

sub interior_sequence
{
  my ( $parser, $seq_command, $seq_argument ) = @_;
  my $fh = $parser->output_handle ();

  if ( $seq_command eq 'C' )
  {
    return "\{tag:code\}" . $seq_argument . "\{\/tag:code\}";
  }
  elsif ( $seq_command eq 'I' )
  {
    return "\{tag:emphasis\}" . $seq_argument . "\{\/tag:emphasis\}";
  }
  elsif ( $seq_command eq 'B' )
  {
    return "\{tag:strong\}" . $seq_argument . "\{\/tag:strong\}";
  }
  elsif ( $seq_command eq 'S' )
  {
    $seq_argument =~ s/ /\{char:160\}/g;

    return $seq_argument;
  }
  elsif ( $seq_command eq 'F' )
  {
    return "\{tag:filename\}" . $seq_argument . "\{\/tag:filename\}";
  }
  elsif ( $seq_command eq 'X' )
  {
    return "\{tag:index\}" . $seq_argument . "\{\/tag:index\}";
  }
  elsif ( $seq_command eq 'L' )
  {
    # parse L<>, can be any of:
    #  L<name> or L<sect> (other page or section in this page)
    #  L<name/ident> (item in a other page)
    #  L<name/"sect"> (section in other page)
    #  L<"sect"> (same as L<sect>)
    #  L</"sect"> (same as L<sect>)
    #  L</sect> (same as L<sect>)
    # plus any of the above can be prefixed with text| to use
    # that text as the link text.

    # Additionally, there can also be;
    #  L<scheme:...>
    # which SHOULD NOT be prepended label|
    $seq_argument =~ s/[\r\n]/ /g;
    my $text = $seq_argument;

    if ( $seq_argument =~ /^([^|]+)\|(.*)$/ )
    {
      $text = $1;
      $seq_argument = $2;
    }

    if ( $seq_argument =~ /^[a-z]+:\//i )
    {
      $text ||= $seq_argument;
    }
    elsif ( $seq_argument =~ /^(.*?)\/(.*)$/ )
    {
      # name/ident or name/"sect"
      my $ident_or_sect = $2;
      $seq_argument = $1;

      if ( $ident_or_sect =~ /^\"(.*)\"$/ )
      {
        my $sect = $1;
        $sect = substr ( $sect, 0, 30 );
        $sect =~ s/\s/_/g;
        $seq_argument .= '#' . $sect;
      }
      else 
      {
        $seq_argument .= '#' . $ident_or_sect;
      }
    }
    elsif ( $seq_argument =~ /^\\?\"(.*)\"$/ )
    {
      my $sect = $1;
      $sect = substr ( $sect, 0, 30 );
      $sect =~ s/\s/_/g;
      $seq_argument = '#' . $sect;
    }

    return "\{tag:link xref='" . $seq_argument . "'\}" . $text .
        "\{\/tag:link\}";
  }
  elsif ( $seq_command eq 'E' )
  {
    # E<> codes can be numerical!
    if ( $seq_argument =~ m/^(0[0-7]+|[0-9]+)$/ )
    {
      # it's octal, convert to decimal!
      $seq_argument = oct ( $seq_argument ) if $seq_argument =~ m/^0/;

      # convert to hex
      $seq_argument = sprintf ( '0x%x', $seq_argument ); 
    }

    if ( $seq_argument =~ m/^0x([0-9A-Fa-f]{2,4})$/ )
    {
      # E<> is hex!
      $seq_argument = "#x" . $1;
    }
    else
    {
      # if we know about this code then translate it into hex
      if ( exists $HTML_Escapes { $seq_argument } )
      {
        $seq_argument = $HTML_Escapes { $seq_argument };
      }
    }

    # probably a HTML escape code
    $seq_argument = "{tag:escape ref='" . $seq_argument . "'}";

    return $seq_argument;
  }
}

1;

__END__

=head1 NAME

Pod::XML - Module to convert POD to XML

=head1 SYNOPSIS

  use Pod::XML;
  my $parser = Pod::XML->new();
  $parser->parse_from_file("foo.pod");

=head1 DESCRIPTION

This module uses Pod::Parser to parse POD and generates XML from the
resulting parse stream. It uses its own format, described below.

=head1 OPTIONS

=over 2

=item Encoding

Specify the output encoding of the XML file. Requires Encode Perl module.

=back

=head1 XML FORMAT

The XML format is not a standardised format - if you wish to generate
some standard XML format such as docbook, please use a tool such as XSLT
to convert between this and that format.

The format uses the namespace "http://axkit.org/ns/2000/pod2xml". Do not
try and request this URI - it is virtual. You will get a 404.

The best way to describe the format is to show you:

  <pod xmlns="http://axkit.org/ns/2000/pod2xml">
    <head>
      <title>The first =head1 goes in here</title>
    </head>
    <sect1>
    <title>Subsequent =head1's create a sect1</title>
      <para>
      Ordinary paragraphs of text create a para tag.
      </para>
      <verbatim><![CDATA[
      Indented verbatim sections go in verbatim tags using a CDATA
      section rather than XML escaping.
      ]]></verbatim>
      <sect2>
      <title>=head2's go in sect2</title>
        <para>
        Up to =head4 is supported (despite not really being 
        supported by pod), producing sect3 and 
        sect4 respectively for =head3 and =head4.
        </para>
        <para>
        Bold text goes in a <strong>strong</strong> tag.
        </para>
        <para>
        Italic text goes in a <emphasis>emphasis</emphasis> tag.
        </para>
        <para>
        Code goes in a <code>code</code> tag.
        </para>
        <para>
        Lists (=over, =item, =back) go in list/item/itemtext 
        tags. The itemtext element is only present if the 
        =item text is <strong>not</strong> the "*" character.
        </para>
      </sect2>
    </sect1>
  </pod>

If the first =head1 is "NAME" (like standard perl modules are supposed
to be) it takes the next paragraph as the document title. Other standard
head elements of POD are left unchanged (particularly, the SYNOPSIS and
DESCRIPTION elements of standard POD).

Pod::XML tries to be careful about nesting sects based on the head
level in the original POD. Let me know if this doesn't work for you.

=head1 AUTHOR

Original version by Matt Sergeant, matt@sergeant.org

Version 0.95+ by Matt Wilson E<lt>matt@mattsscripts.co.ukE<gt>

=head1 MAINTAINER

Matt Wilson E<lt>matt@mattsscripts.co.ukE<gt>

=head1 SEE ALSO

L<Pod::Parser>

=head1 LICENSE

This is free software, you may use it and distribute it under the
same terms as Perl itself.

=cut

# vim:ts=2:sw=2:et
