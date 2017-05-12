package SRU::Response;
{
  $SRU::Response::VERSION = '1.01';
}
#ABSTRACT: A factory for creating SRU response objects

use strict;
use warnings;
use SRU::Response::Explain;
use SRU::Response::Scan;
use SRU::Response::SearchRetrieve;
use SRU::Utils qw( error );
use SRU::Utils::XML qw( stylesheet );


sub newFromRequest {
    my ($class,$request) = @_;

    ## make sure we've got a SRU::Request object
    my $requestType = ref($request);
    return error( "must pass in valid SRU::Request object" )
        if ! $requestType or ! $request->isa( 'SRU::Request' );

    ## return the appropriate response object
    my $response;
    if ( $requestType eq 'SRU::Request::Explain' ) {
        $response = SRU::Response::Explain->new( $request );
    } elsif ( $requestType eq 'SRU::Request::Scan' ) {
        $response = SRU::Response::Scan->new( $request );
    } elsif ( $requestType eq 'SRU::Request::SearchRetrieve' ) {
        $response = SRU::Response::SearchRetrieve->new( $request );
    }
    return $response;
}


sub type {
    my $self  = shift;
    my $class = ref $self || $self;
    return lcfirst( ( split( '::', $class ) )[ -1 ] );
}


sub addDiagnostic {
    my ($self,$d) = @_;
    push(@{ $self->{diagnostics} }, $d);
}


sub diagnosticsXML {
    my $self = shift;
    my $xml = '';
    foreach my $d ( @{ $self->diagnostics() } ) {
        $xml .= $d->asXML();
    }
    return $xml;
}


sub stylesheetXML {
    my $self = shift;
    if ( $self->stylesheet() ) {
        return stylesheet( $self->stylesheet() );
    }
    return '';
}

1;

__END__

=pod

=head1 NAME

SRU::Response - A factory for creating SRU response objects

=head1 SYNOPSIS

    my $request = SRU::Request->newFromURI( $uri );
    my $response = SRU::Response->newFromRequest( $request );

=head1 DESCRIPTION

SRU::Response provides a mechanism for creating the appropriate
response object based on a request that is passed in. For example,
if you pass in a SRU::Request::Scan object you'll get back
a SRU::Response::Scan object with some of the particulars filled in.

=head1 METHODS 

=head2 newFromRequest()

The factory method which you must pass in a valid request object:
SRU::Request::Explain, SRU::Request::Scan or SRU::Request::SearchRetrieve.
If you fail to pass in the correct object you will be returned undef, 
with an appropriate error stored in $SRU::Error.

=cut

=head1 INHERITED METHODS

SRU::Resonse also serves as the base class for the three response types, and
thus provides some general functionality to the child classes. 

=head2 type()

Returns 'searchRetrieve', 'scan' or 'explain' depending on what type of
object it is.

=cut

=head2 addDiagnostic()

=cut

=head2 diagnosticsXML()

=cut

=head2 stylesheetXML()

=cut
=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ed Summers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
