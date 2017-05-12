use strict;
use warnings;
package RDF::Flow;
{
  $RDF::Flow::VERSION = '0.178';
}
#ABSTRACT: RDF data flow pipeline

use RDF::Flow::Source qw(rdflow_uri);
use RDF::Flow::Union;
use RDF::Flow::Cascade;
use RDF::Flow::Pipeline;
use RDF::Flow::Cached;

use base 'Exporter';
our @EXPORT = qw(rdflow);
our @EXPORT_OK = qw(rdflow cached union cascade pipeline previous rdflow_uri);
our %EXPORT_TAGS = (
    all => [qw(rdflow cached union cascade pipeline previous)] );

our $PREVIOUS = RDF::Flow::Source->new( sub { shift->{'rdflow.data'} } );

sub rdflow   { RDF::Flow::Source->new(@_) }
sub union    { RDF::Flow::Union->new( @_ ) }
sub cascade  { RDF::Flow::Cascade->new( @_ ) }
sub pipeline { RDF::Flow::Pipeline->new( @_ ) }
sub cached   { RDF::Flow::Cached->new( @_ ); }

sub previous { $RDF::Flow::PREVIOUS; }

1;


__END__
=pod

=head1 NAME

RDF::Flow - RDF data flow pipeline

=head1 VERSION

version 0.178

=head1 SYNOPSIS

    # define RDF sources (see RDF::Flow::Source)
    $src = rdflow( "mydata.ttl", name => "RDF file as source" );
    $src = rdflow( "mydirectory", name => "directory with RDF files as source" );
    $src = rdflow( \&mysub, name => "code reference as source" );
    $src = rdflow( $model,  name => "RDF::Trine::Model as source" );

    # using a RDF::Trine::Model as source is equivalent to:
    $src = RDF::Flow->new( sub {
        my $env = shift;
        my $uri = RDF::Flow::uri( $env );
        return $model->bounded_description( RDF::Trine::iri( $uri ) );
    } );

    # retrieve RDF data
    $rdf = $src->retrieve( $uri );
    $rdf = $src->retrieve( $env ); # uri constructed from $env

    # code reference as source (more detailed example)
    $src = rdflow( sub {
        my $uri = RDF::Flow::uri( $env );
        my $model = RDF::Trine::Model->temporary_model;
        add_some_statements( $uri, $model );
        return $model;
    });

=head1 DESCRIPTION

RDF::Flow provides a simple framework on top of L<RDF::Trine> to define and
connect RDF sources in data flow pipes. In a nutshell, a source is connected
to some data (possibly RDF but it could also wrap any other forms) and you
can retrieve RDF data from it, based on a request URI:

                     +--------+
    Request (URI)--->+ Source +-->Response (RDF)
                     +---+----+
                         ^
                Data (possibly RDF)

The base class to define RDF sources is L<RDF::Flow::Source>, so please have a
look at the documentation of this class. Multiple sources can be connected to
data flow networks: Predefined sources exist to combine sources
(L<RDF::Flow::Union>, L<RDF::Flow::Pipeline>, L<RDF::Flow::Cascade>), to access
LinkedData (L<RDF::Flow::LinkedData>), to cache requests
(L<RDF::Flow::Cached>), and for testing (L<RDF::Flow::Dummy>).

=head1 EXPORTED FUNCTIONS

By default this module only exports C<rdflow> as constructor shortcut.
Additional shortcut functions can be exported on request. The C<:all>
tag exports all functions.

=over 4

=item C<rdflow>

Shortcut to create a new source with L<RDF::Flow::Source>.

=item C<cached>

Shortcut to create a new cached source with L<RDF::Flow::Cached>.

=item C<cascade>

Shortcut to create a new source cascade with L<RDF::Flow::Cascade>.

=item C<pipeline>

Shortcut to create a new source pipeline with L<RDF::Flow::Pipeline>.

=item C<previous>

A source that always returns C<rdflow.data> without modification.

=item C<union>

Shortcut to create a new union of sources with L<RDF::Flow::Union>.

=back

=head2 LOGGING

RDF::Flow uses L<Log::Contextual> for logging. By default no logging messages
are created, unless you enable a logger.  To simply see what's going on in
detail, enable a simple logger:

    use Log::Contextual::SimpleLogger;
    use Log::Contextual qw( :log ),
       -logger => Log::Contextual::SimpleLogger->new({ levels => [qw(trace)]});

=head1 DEFINING NEW SOURCE TYPES

Basically you must only derive from L<RDF::Flow::Source> and create the method
C<retrieve_rdf>:

    package MySource;
    use parent 'RDF::Flow::Source';
    use RDF::Flow::Source qw(:util); # if you need utilty functions

    sub retrieve_rdf {
        my ($self, $env) = @_;
        my $uri = $env->{'rdflow.uri'};

        # ... your logic here ...

        return $model;
    }

=head1 LIMITATIONS

The current version of this module does not check for circular references if
you connect multiple sources.  Maybe environment variable such as C<rdflow.depth>
or C<rdflow.stack> will be introduced. Surely performance can also be increased.

=head1 SEE ALSO

You can use this module together with L<Plack::Middleware::RDF::Flow> (available
at L<at github|https://github.com/nichtich/Plack-Middleware-RDF-Flow>) to create
Linked Data applications.

There are some CPAN modules for general data flow processing, such as L<Flow>
and L<DataFlow>. As RDF::Flow is inspired by L<PSGI>, you should also have a
look at the PSGI toolkit L<Plack>. Some RDF sources can also be connected
with L<RDF::Trine::Model::Union> and L<RDF::Trine::Model::StatementFilter>.
More RDF-related Perl modules are collected at L<http://www.perlrdf.org/>.

Research references on RDF pipelining can be found in the presentation "RDF
Data Pipelines for Semantic Data Federation", more elaborated and not connected
to this module: L<http://dbooth.org/2011/pipeline/>. Another framework for
RDF integration based on a pipe model is RDF Gears:
L<https://bitbucket.org/feliksik/rdfgears/>.

=head1 AUTHOR

Jakob Voß <voss@gbv.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

