package SRU::Server;
{
  $SRU::Server::VERSION = '1.01';
}
#ABSTRACT: Respond to SRU requests via CGI::Application



use base qw( CGI::Application Class::Accessor );

use strict;
use warnings;

use SRU::Request;
use SRU::Response;
use SRU::Response::Diagnostic;
use CQL::Parser 1.12;

use constant ERROR   => -1;
use constant DEFAULT => 0;

my @modes     = qw( explain scan searchRetrieve error_mode );
my @accessors = qw( request response cql );

__PACKAGE__->mk_accessors( @accessors );


sub setup {
    my $self = shift;

    $self->run_modes( \@modes );
    $self->start_mode( $modes[ DEFAULT ] );
    $self->mode_param( 'operation' );
}


sub cgiapp_prerun {
    my $self = shift;
    my $mode = shift;

    $CGI::USE_PARAM_SEMICOLONS = 0;

    $self->request( SRU::Request->newFromURI( $self->query->url( -query => 1 ) ) );
    $self->response( SRU::Response->newFromRequest( $self->request ) );

    my $cql;
    if ( $mode eq 'scan' ) {
        $cql = $self->request->scanClause;
    }
    elsif ( $mode eq 'searchRetrieve' ) {
        $cql = $self->request->query;
    }

    if( defined $cql ) {
        $cql = CQL::Parser->new->parseSafe( $cql );
        if (ref $cql) {
            $self->cql( $cql );
        } else {
            $self->prerun_mode( $modes[ ERROR ] );
            $self->response->addDiagnostic( SRU::Response::Diagnostic->newFromCode( $cql ) );
        }
    }

    unless( $self->can( $mode ) ) {
            $self->prerun_mode( $modes[ ERROR ] );
            $self->response->addDiagnostic( SRU::Response::Diagnostic->newFromCode( 4 ) );
    }
}


sub cgiapp_postrun {
    my $self       = shift;
    my $output_ref = shift;

    $self->header_add( -type => 'text/xml' );

    $$output_ref = $self->response->asXML;
}


sub error_mode {
}


1;

__END__

=pod

=head1 NAME

SRU::Server - Respond to SRU requests via CGI::Application

=head1 SYNOPSIS

    package MySRU;

    use base qw( SRU::Server );

    sub explain {
        my $self = shift;

        # $self->request isa SRU::Request::Explain
        # $self->response isa SRU::Response::Explain
    }

    sub scan {
        my $self = shift;

        # $self->request isa SRU::Request::Scan
        # $self->response isa SRU::Response::Scan
        # $self->cql is the root node of a CQL::Parser-parsed query
    }

    sub searchRetrieve {
        my $self = shift;

        # $self->request isa SRU::Request::SearchRetrieve
        # $self->response isa SRU::Response::SearchRetrieve
        # $self->cql is the root node of a CQL::Parser-parsed query
    }

    package main;

    MySRU->new->run;

=head1 DESCRIPTION

This module brings together all of the SRU verbs (explain, scan
and searchRetrieve) under a sub-classable object based on CGI::Application.

=cut

=head1 METHODS

=head2 explain

This method is used to return an explain response. It is the default
method.

=head2 scan

This method returns a scan response.

=head2 searchRetrieve

This method returns a searchRetrieve response.

=cut

=head1 CGI::APPLICATION METHODS

=head2 setup

Sets the C<run_modes>, C<mode_param> and the default runmode (explain).

=cut

=head2 cgiapp_prerun

Parses the incoming SRU request and if needed, checks the CQL query.

=cut

=head2 cgiapp_postrun

Sets the content type (text/xml) and serializes the response.

=cut

=head2 error_mode

Stub error runmode.

=cut

=head1 AUTHORS

=over 4

=item * Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=item * Ed Summers E<lt>ehs@pobox.comE<gt>

=item * Jakob Voss E<lt>voss@gbv.deE<gt>

=back

=cut
=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ed Summers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
