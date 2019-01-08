
# $Id: Parser.pm,v 1.14 2010-12-02 23:41:29 Martin Exp $

use strict;
use warnings;

=head1 NAME

RDF::Simple::Parser - convert RDF string to bucket of triples

=head1 DESCRIPTION

A simple RDF/XML parser -
reads a string containing RDF in XML
returns a 'bucket-o-triples' (array of arrays)

=head1 SYNOPSIS

  my $uri = 'http://www.zooleika.org.uk/bio/foaf.rdf';
  my $rdf = LWP::Simple::get($uri);
  my $parser = RDF::Simple::Parser->new(base => $uri)
  my @triples = $parser->parse_rdf($rdf);
  # Returns an array of array references which are triples

=head1 METHODS

=over

=cut

package RDF::Simple::Parser;

use constant DEBUG => 0;

use File::Slurp;
use LWP::UserAgent;
use RDF::Simple::Parser::Handler;
use XML::SAX qw(Namespaces Validation);

my
$VERSION = 1.15;

# Use a hash to implement objects of this type:
use Class::MethodMaker [
                        new => 'new',
                        scalar => [ qw/ base http_proxy /, ],
                       ];

=item new( [ base => 'http://example.com/foo.rdf' ])

Create a new RDF::Simple::Parser object.

'base' supplies a base URI for relative URIs found in the document

'http_proxy' optionally supplies the address of an http proxy server.
If this is not given, it will try to use the default environment settings.

=cut

=item parse_rdf($rdf)

Accepts a string which is an RDF/XML document
(complete XML, with headers)

Returns an array of array references which are RDF triples.

=cut

sub parse_rdf
  {
  my ($self, $rdf) = @_;
  DEBUG && print STDERR " DDD Parser::parse_rdf()\n";
  my $handler = new RDF::Simple::Parser::Handler(q{deprecated argument},
                                                 qnames => 1,
                                                 base => $self->base,
                                                );
  # Save (a reference to) our handler for future reference:
  $self->{_handler_} = $handler;
  my $factory = new XML::SAX::ParserFactory;
  $factory->require_feature(Namespaces);
  my $parser = $factory->parser(Handler => $handler);
  $parser->parse_string($rdf);
  my $res = $handler->result;
  return $res ? @$res : $res;
  } # parse_rdf


=item parse_file($sFname)

Takes one argument, a string which is a fully qualified filename.
Reads the contents of that file,
parses it as RDF,
and returns the same thing as parse_rdf().

=cut

sub parse_file
  {
  my $self = shift;
  my $sFname = shift || return;
  my $sRDF = read_file($sFname) || return;
  return $self->parse_rdf($sRDF);
  } # parse_file


=item parse_uri($uri)

Accepts a string which is a fully qualified http:// uri
at which some valid RDF lives.
Fetches the remote file and returns the same thing as parse_rdf().

=cut

sub parse_uri
  {
  my $self = shift;
  my $uri = shift || return;
  my $rdf;
  eval
    {
    # TODO: Just use LWP::Simple->get() and tell user if that's not
    # sufficient, do it themselves
    $rdf = $self->ua->get($uri)->content;
    };
  warn ($@) if $@;
  if ($rdf && ($rdf ne q{}))
    {
    # print STDERR " DDD will parse_rdf(===$rdf===)\n";
    $self->base($uri);
    return $self->parse_rdf($rdf);
    } # if
  } # parse_uri

=item getns

Returns a hashref of all namespaces found in the document.

=cut

sub getns
  {
  my $self = shift or return;
  my $handler = $self->{_handler_} or return;
  my $ns = $handler->ns or return;
  return $ns->{_lookup};
  } # getns

# TODO: get rid of this!  Just use LWP

sub ua
  {
  my $self = shift;
  unless ($self->{_ua}) {
    $self->{_ua} = LWP::UserAgent->new(timeout => 30);
    if ($self->http_proxy) {
      $self->{_ua}->proxy('http',$self->http_proxy);
      } else {
        $self->{_ua}->env_proxy;
        }
    }
  return $self->{_ua};
  } # ua

=back

=head1 BUGS

Please report bugs via the RT web site L<http://rt.cpan.org/Ticket/Create.html?Queue=RDF-Simple>

=head1 AUTHOR

Jo Walsh <jo@london.pm.org>
Currently maintained by Martin Thurn <mthurn@cpan.org>

=head1 LICENSE

This module is available under the same terms as perl itself

=cut

1;

__END__
