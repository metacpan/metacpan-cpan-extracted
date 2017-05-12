package SVG::Parser;
use strict;

require 5.004;

use vars qw(@ISA $VERSION);

$VERSION="1.03";

#-------------------------------------------------------------------------------
# Pick a parser, any parser...

# Override this list in import to force a different choosing order
@ISA=qw(SVG::Parser::SAX SVG::Parser::Expat) unless @ISA;
#@ISA=qw(SVG::Parser::Expat SVG::Parser::SAX) unless @ISA;

#-------------------------------------------------------------------------------
# Import method to change default inheritance, if required

sub import {
    my $package=shift;

    @ISA=@_ if @_;
    my @classes;

    foreach my $superclassspec (@ISA) {
        # extract parameters to pass to superclass import method if present
        my ($superclass,$importlist)=split /=/,$superclassspec,2;
        my @importlist=$importlist ? (split '=',$importlist) : ();

        # shorthand shortcuts
        $superclass="SVG::Parser::SAX" if $superclass eq 'SAX';
        $superclass="SVG::Parser::Expat" if $superclass eq 'Expat';

        # test each superclass specifier in turn
        if (eval qq[use $superclass qw(@importlist); 1;]) {
            @ISA = ($superclass);
            return;
	}

        push @classes,"$superclass qw(",(join " ",@importlist),")";
    }

    die "No XML parser found (searched for ",(join ",",@classes),")\n";
}

#-------------------------------------------------------------------------------
# Allow basic calls to 'parse' to handle strings and handles equally well for
# either parser. More complex API usage will not work.

sub parse {
    my ($self,$source,%args)=@_;

    my $type=$self->identify($source) or return "";

    if ($type eq $self->ARG_IS_HANDLE) {
	# both parse()rs will accept a handle
        return $self->SUPER::parse($source,%args);
    } elsif ($type eq $self->ARG_IS_STRING) {
        # the API for strings, however, differs
        if ($self->isa("SVG::Parser::SAX")) {
            my %parser_options=( Source => {String => $source} );
            return $self->SUPER::parse(%parser_options,%args);
        } else {
            return $self->SUPER::parse($source,%args);
        }
    } else {
        # a hash reference only makes sense to the SAX parser

        if ($self->isa("SVG::Parser::SAX")) {
            # combine extra hash values if present
            $source={ %$source, %args };
            return $self->SUPER::parse($source);
        } else {
            # the source is unknown
            die "Invalid argument $source to SVG::Parser in Expat mode";
        }
    }
}

#-------------------------------------------------------------------------------

=head1 NAME

SVG::Parser - XML Parser for SVG documents

=head1 SYNOPSIS

  #!/usr/bin/perl -w
  use strict;
  use SVG::Parser;

  die "Usage: $0 <file>\n" unless @ARGV;

  my $xml;
  {
      local $/=undef;
      $xml=<>;
  }

  my $parser=new SVG::Parser(-debug => 1);
  my $svg=$parser->parse($xml);
  print $svg->xmlify;

  and:

  #!/usr/bin/perl -w
  use strict; 
  use SVG::Parser qw(SAX=XML::LibXML::Parser::SAX Expat SAX);

  die "Usage: $0 <file>\n" unless @ARGV;
  my $svg=SVG::Parser->new()->parsefile($ARGV[0]);
  print $svg->xmlify;



=head1 DESCRIPTION

SVG::Parser is an XML parser for SVG Documents. It takes XML as input and
produces an SVG object as its output.

SVG::Parser supports both XML::SAX and XML::Parser (Expat) parsers, with SAX
preferred by default. Only one of these needs to be installed for SVG::Parser
to function.

A list of preferred parsers may be specified in the import list - SVG::Parser
will use the first parser that successfully loads. Some basic measures are taken
to provide cross-compatability. Applications requiring more advanced parser
features should use the relevant parser module directly; see
L<SVG::Parser::Expat> and L<SVG::Parser::SAX>.

=head2 METHODS

SVG::Parser provides all methods supported by its parent parser class. In
addition it provides the following:

=over 4

=item * new([%attrs])

Create a new SVG::Parser object. Optional attributes may be passed as arguments;
all attributes without a leading '-' prefix are passed to the parent
constructor. For example:

   my $parser=new SVG::Parser(%parser_options);

Note that parser options are dependant on which parser type is selected.

Attributes with a leading '-' are processed by SVG::Parser. Currently the only 
recognised attribute is '-debug', which generates a simple but possibly useful
debug trace of the parsing process to standard error. For example:

   my $parser=new SVG::Parser(-debug => 1);

or:

   my $parser=SVG::Parser->new(-debug => 1);

Attributes with a leading '--' are passed to the SVG constructor when creating
the SVG object returned as the result of the parse:

   my $parser=new SVG::Parser(
	-debug => 1,
	"--indent" => "\t",
        "--raiseerror" => 1
   );

The leading '-' is stripped from attribute names passed this way, so this sets
the '-indent' and '-raiseerror' attributes in the SVG module. See L<SVG> for a
list of valid SVG options.

(The C<new> constructor is provided by XML::SAX::Expat or SVG::Parser::SAX,
but operates identically in either case.)

=item * parse($xml)

Parse an XML document and return an SVG object which may then be used to
manipulate the SVG content before regenerating the output XML. For example:

    my $svg=$parser->parse($svgxml);

Because the parse() method differs in use beteen XML::Parser and XML::SAX,
SVG::Parser provides its own parse() method. This calls the parent parser with
the correct first argument when given either a filehandle or a string as input.

Additional arguments are passed to the parent parser class, but since
XML::Parser and XML::SAX parsers take options in different formats this is
of limited use. SVG::Parser does not currently provide any translation of
parser options.

See L<XML::Parser>, L<XML::SAX>, and L<XML::Parser::PerlSAX> for other ways to
parse input XML.

=item * parse_file($filehandle|$filename)

=item * parsefile($filehandle|$filename)

Since the parse_file() method (XML::SAX) and parsefile() method (XML::Parser)
differ in both name and usage, SVG::Parser provides its own version of both
methods that determines whether the passed argument is a filehandle or
a file name and directs the call to the appropriate parent parser method.

Both methods will work equally well whichever parent parser class is in use:

    my $svg=$parser->parse_file($svgxml);
    my $svg=$parser->parsefile($svgxml);
    my $svg=$parser->parse_file(*SVGIN);
    my $svg=$parser->parsefile(*SVGIN);
    ...etc...

(These methods will also work when using SVG::Parser::Expat or SVG::Parser::SAX
directly.)

=back

=head2 EXPORTS

None. However, a list of preferred parsers can be specified by passing the
package name to SVG::Parser in the import list. This allows an SVG parser
application to use the best parser available without knowing what XML parsers
might be available on the target platform. SAX is generally preferred to Expat,
but an Expat-based parser may be preferable to the slow Perl-based SAX
parser XML::SAX::PurePerl. (See L<XML::SAX::PurePerl>.) 

Each parser specification consists of one of the two supported SVG parsers,
SVG::Parser::Expat or SVG::Parser::SAX, optionally followed by an '=' and an
explicit parser package. For example:

    use SVG::Parser qw(SVG::Parser::SAX SVG::Parser::Expat);

Instead of specifying the full SVG parser name, 'Expat' and 'SAX' may be used as
shorthand. For example:

    use SVG::Parser qw(SAX Expat);

Both the above examples produce the default behaviour. To prefer Expat over SAX
use either of:

    use SVG::Parser qw(SVG::Parser::Expat SVG::Parser::SAX);
    use SVG::Parser qw(Expat SAX);

To use Expat with a specific XML::Parser subclass:

    use SVG::Parser qw(SVG::Parser::Expat=My::XML::Parser::Subclass);

To use SAX with the XML::LibXML SAX parser:

    use SVG::Parser qw(SVG::Parser::SAX=XML::LibXML::SAX::Parser);

A number of specifications can be listed to have SVG::Parse try a number of
possible parser alternatives in decreasing order of preference:

    use SVG::Parser qw(
        SAX=My::SAXParser
        Expat=My::Best::ExpatParser
        SAX=XML::LibXML::SAX::Parser
        Expat=My::Other::ExpatParser
        Expat
        SAX
    )

You can test different scenarios from the command line. For example:

    perl -MSVG::Parser=SAX mysvgapp.pl
    perl -MSVG::Parser=Expat,SAX mysvgapp.pl
    perl -MSVG::Parser=SAX=XML::LibXML::SAX::Parser,Expat mysvgapp.pl

To pass additional items in the import list to the parent Expat or SAX parser
class, use additional '=' separators in the parser specification. In the case
of XML::SAX a minimum version number may be required this way:

    # require version 1.40+ of the LibXML SAX parser, otherwise use Perl
    use SVG::Parser qw(
        SAX=XML::LibXML::SAX::Parser=1.40
        SAX=XML::SAX::PurePerl
    );

Similarly, from the command line:

    perl -MSVG::Parser=SAX=XML::LibXML::SAX::Parser=1.40,SAX=XML::SAX::PurePerl mysvgapp.pl

=head2 EXAMPLES

See C<svgparse>, C<svgparse2>, and C<svgparse3> in the examples directory of the
distribution, along with C<svgexpatparse> and C<svgsaxparse> for examples of using
the SVG::Parser::Expat and SVG::Parser::SAX modules directly.

=head1 AUTHOR

Peter Wainwright, peter.wainwright@cybrid.net

=head1 SEE ALSO

L<SVG>, L<SVG::Parser::Expat>, L<SVG::Parser::SAX>, L<XML::Parser>, L<XML::SAX>

=cut

1;
