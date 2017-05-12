package Catalyst::Controller::SRU;
{
  $Catalyst::Controller::SRU::VERSION = '1.01';
}
#ABSTRACT: Dispatch SRU methods with Catalyst

use strict;
use warnings;


use base qw( Catalyst::Controller );

use SRU::Request;
use SRU::Response;
use SRU::Response::Diagnostic;
use CQL::Parser 1.12;

sub index : Private {
    my( $self, $c ) = @_;

    my $sru_request  = SRU::Request->newFromURI( $c->req->uri );
    my $sru_response = SRU::Response->newFromRequest( $sru_request );
    my @args         = ( $sru_request, $sru_response );

    my $cql;
    my $mode = $sru_request->type;
    if ( $mode eq 'scan' ) {
        $cql = $sru_request->scanClause;
    }
    elsif ( $mode eq 'searchRetrieve' ) {
        $cql = $sru_request->query;
    }

    if( defined $cql ) {
        $cql = CQL::Parser->new->parseSafe( $cql );
        push @args, $cql;
        unless ( ref $cql ) {
            $sru_response->addDiagnostic( SRU::Response::Diagnostic->newFromCode( $cql ) );
        }
    }

    if ( my $action = $self->can( $mode ) ) {
        $action->( $self, $c, @args );
    }
    else {
        $sru_response->addDiagnostic( SRU::Response::Diagnostic->newFromCode( 4 ) );
        $c->log->debug( qq(Couldn't find sru method "$mode") ) if $c->debug;
    }

    $c->res->content_type( 'text/xml' );
    $c->res->body( $sru_response->asXML );
};


1;

__END__

=pod

=head1 NAME

Catalyst::Controller::SRU - Dispatch SRU methods with Catalyst

=head1 SYNOPSIS

    package MyApp::Controller::SRU;

    # use it as a base controller
    use base qw( Catalyst::Controller::SRU );
        
    # explain, scan and searchretrieve methods
    sub explain {
        my ( $self, $c,
            $sru_request,  # ISA SRU::Request::Explain
            $sru_response, # ISA SRU::Response::Explain 
        ) = @_;
    }
    
    sub scan {
        my ( $self, $c,
            $sru_request,  # ISA SRU::Request::Scan
            $sru_response, # ISA SRU::Response::Scan
            $cql,          # ISA CQL::Parser root node
        ) = @_;

    }
    
    sub searchRetrieve {
        my ( $self, $c,
            $sru_request,  # ISA SRU::Request::SearchRetrieve
            $sru_response, # ISA SRU::Response::SearchRetrieve
            $cql,          # ISA CQL::Parser root node
        ) = @_;
    }

=head1 DESCRIPTION

This module allows your controller class to dispatch SRU actions
(C<explain>, C<scan>, and C<searchRetrieve>) from its own class.

=head1 METHODS

=head2 index : Private

This method will create an SRU request, response and possibly a CQL object based on the
type of SRU request it finds. It will then pass the data over to your customized method.

=cut

=head1 SEE ALSO

=over 4

=item * L<Catalyst>

=item * L<SRU>

=back

=head1 AUTHORS

Brian Cassidy <bricas@cpan.org>

=cut
=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ed Summers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
