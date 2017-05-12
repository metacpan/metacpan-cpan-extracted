use strict;
use warnings;
package RDF::Flow::LinkedData;
{
  $RDF::Flow::LinkedData::VERSION = '0.178';
}
#ABSTRACT: Retrieve RDF from a HTTP-URI

use Log::Contextual::WarnLogger;
use Log::Contextual qw(:log), -default_logger
    => Log::Contextual::WarnLogger->new({ env_prefix => __PACKAGE__ });

use parent 'RDF::Flow::Source';
use RDF::Flow::Source qw(:util);

use Try::Tiny;
use RDF::Trine::Model;
use RDF::Trine::Parser;

sub name {
    shift->{name} || 'anonymous LinkedData source';
}

sub retrieve_rdf {
    my ($self, $env) = @_;
    my $url = rdflow_uri( $env );

    my $model = RDF::Trine::Model->new;

    try {
        die 'not an URL' unless $url =~ /^http[s]?:\/\//;
        RDF::Trine::Parser->parse_url_into_model( $url, $model );
        log_debug { "retrieved data from $url" };
    } catch {
        $self->trigger_error("failed to retrieve RDF from $url: $_", $env);
    };

    return $model;
}

1;


__END__
=pod

=head1 NAME

RDF::Flow::LinkedData - Retrieve RDF from a HTTP-URI

=head1 VERSION

version 0.178

=head1 DESCRIPTION

This L<RDF::Flow::Source> fetches RDF data via HTTP. The request URI is used
as URL to get data from. For instance the following source retrieves RDF data
from DBPedia, if a DBPedia or English Wikipedia URI is provided:

    my $dbpedia = RDF::Flow::LinkedData->new(
        name => "DBPedia",
        match => sub {
            $_[0] =~ s{^http://en\.wikipedia\.org/wiki/}{http://dbpedia.org/resource/};
            return ($_[0] =~ qr{^http://dbpedia\.org/resource/.+});
        }
    );

=head1 CONFIGURATION

The following configuration options from L<RDF::Flow::Source> are useful in
particular:

=over 4

=item name

Name of the source. Defaults to "anonymous LinkedData source".

=item match

Optional regular expression or code reference to match and/or map request URIs.

=back

=head1 AUTHOR

Jakob Voß <voss@gbv.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

