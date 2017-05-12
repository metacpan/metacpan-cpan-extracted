package SVG::Parser::SAX;
use strict;
use Carp;

require 5.004;

use XML::SAX;
use SVG::Parser::Base;
use SVG::Parser::SAX::Handler;

use vars qw(@ISA $VERSION);
@ISA=qw(SVG::Parser::Base); # this changes once the parser type is known

$VERSION="1.03";

#-------------------------------------------------------------------------------

=head1 NAME

SVG::Parser::SAX - XML SAX Parser for SVG documents

=head1 SYNOPSIS

  #!/usr/bin/perl -w
  use strict;
  use SVG::Parser::SAX;

  die "Usage: $0 <file>\n" unless @ARGV;

  my $xml;
  {
      local $/=undef;
      $xml=<>;
  }

  my $parser=new SVG::Parser::SAX(-debug => 1);

  my $svg=$parser->parse($xml);

  print $svg->xmlify;

=head1 DESCRIPTION

SVG::Parser::SAX is the SAX-based parser module used by SVG::Parser when an
underlying XML::SAX-based parser is selected. It may also be used directly, as shown
in the synopsis above.

Use SVG::Parser to retain maximum flexibility as to which underlying parser is chosen.
Use SVG::Parser::SAX to supply SAX-specific parser options or where the presence
of a functional XML::SAX parser is known and/or preferred.

=head2 EXPORTS

None. However, a preferred SAX parser implementations can be specified by
passing the package name to SVG::Parser::SAX in the import list. For example:

    use SVG::Parser::SAX qw(XML::LibXML::SAX::Parser);

A minimum version number may be additionally suppied as a second import item:

    use SVG::Parser::SAX (XML::LibXML::SAX::Parser => 1.40);

This overrides the automatic selection of a suitable SAX parser. To try several
different parsers in turn, use the SVG::Parser module instead and restrict it
to only try SAX-based parsers. To make use of the automatic selection mechanism,
omit the import list.

When loaded via SVG::Parser, this parent class may be specified by placing it
after the '=' in a parser specification:

See L<SVG::Parser> for more details.

=head2 EXAMPLES

See C<svgsaxparse> in the examples directory of the distribution.

=head1 AUTHOR

Peter Wainwright, peter.wainwright@cybrid.net

=head1 SEE ALSO

L<SVG>, L<SVG::Parser>, L<SVG::Parser::Expat>, L<XML::SAX>

=cut

#-------------------------------------------------------------------------------

sub new {
    my $proto=shift;
    my $class=ref($proto) || $proto;
    my %attrs=@_;

    my $handler=SVG::Parser::SAX::Handler->new(%attrs);
    my $self=XML::SAX::ParserFactory->parser(
        Handler => $handler,
    );

    # first time through set up the @ISA for the package
    @ISA=(ref($self),"SVG::Parser::Base") if @ISA==1;

    return bless $self,$class;
}

#-------------------------------------------------------------------------------
# Import method to change default inheritance, if required

sub import {
    my $package=shift;

    # permit an alternative XML::SAX parser to be our parser
    if (@_) {
        my ($superclass,$version)=@_;

        # select specific XML::SAX parser: 'pkg' or 'pkg => version'
        if ($version) {
            $XML::SAX::ParserPackage="$superclass ($version)" if eval qq[
                use $superclass $version;
                1;
            ];
        } else {
            $XML::SAX::ParserPackage=$superclass if eval qq[
                use $superclass;
                1;
            ];
        }
    }
}

#-------------------------------------------------------------------------------
# Expat -> SAX compatability

# parsefile take a filename or a file handle, parse_file takes a file handle
sub parsefile {
    my ($self,$source,@args)=@_;

    my $type=$self->identify($source);
    return "" if $type eq $self->ARG_IS_INVALID;

    if ($type eq $self->ARG_IS_STRING) {
        local(*FH);
        open FH,$source or croak "Couldn't open $: $!";
        return $self->SUPER::parse_file(*FH,@_);
    } elsif ($type eq $self->ARG_IS_HASHRF) {
        return $self->SUPER::parse({ %$source,@args });
    } else {
        return $self->SUPER::parse_file($source,@_);
    }
}

*parse_file=\&parsefile;

#-------------------------------------------------------------------------------

1;
