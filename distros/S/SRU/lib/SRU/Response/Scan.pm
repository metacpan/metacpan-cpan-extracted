package SRU::Response::Scan;
{
  $SRU::Response::Scan::VERSION = '1.01';
}
#ABSTRACT: A class for representing SRU scan responses

use strict;
use warnings;
use base qw( Class::Accessor SRU::Response );
use SRU::Utils::XML qw( element elementNoEscape );


sub new {
    my ($class,$request) = @_;
    return error( "must pass in SRU::Request::Scan object to new()" )
        if ! ref($request) or ! $request->isa( 'SRU::Request::Scan' );

    my $self = $class->SUPER::new( {
        version             => $request->version(),
        terms               => [],
        diagnostics         => [],
        extraResponseData   => '',
        echoedScanRequest   => $request->asXML(),
        stylesheet          => $request->stylesheet()
    } );

    $self->addDiagnostic( SRU::Response::Diagnostic->newFromCode(7,'version') )
        if ! $self->version();

    return $self;
}


sub addTerm {
    my ($self,$term) = @_;
    return error( "must pass in SRU::Response::Term object to addTerm()" )
        if ! $term->isa( "SRU::Response::Term" );
    push( @{ $self->{terms} }, $term );
}


SRU::Response::Scan->mk_accessors( qw(
    version
    terms
    diagnostics
    extraResponseData
    echoedScanRequest
    stylesheet
) );


sub asXML {
    my $self = shift;
    my $xml = 
        "<?xml version='1.0' ?>\n" . 
        $self->stylesheetXML() . "\n" . 
        "<scanResponse xmlns=\"http://www.loc.gov/zing/srw/\">\n" . 
        element( 'version', $self->version() );

    ## add all the terms if there are some
    if ( @{ $self->terms() } ) {
        $xml .= "<terms>\n";
        foreach my $term ( @{ $self->terms() } ) { 
            $xml .= $term->asXML(); 
        }
        $xml .= "</terms>\n";
    }

    $xml .= $self->diagnosticsXML();
    $xml .= elementNoEscape( 'extraResponseData', $self->extraResponseData() );
    $xml .= $self->echoedScanRequest();
    $xml .= "</scanResponse>";

    return( $xml );
}

1;

__END__

=pod

=head1 NAME

SRU::Response::Scan - A class for representing SRU scan responses

=head1 SYNOPSIS

SRU::Response::Scan is a class for representing SRU scan response
A scan request allows SRU clients to browse the indexes of an SRU
server, much like you would scan the back of a book index to look
up particular terms in the body of the book. The scan response
bundles up the terms that were looked up.

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

The constructor which you must pass a valid SRU::Request::Scan
object. 

=cut

=head2 version()

=head2 addTerm()

Allows you to add terms to the response object. Terms that are passed in
must be valid SRU::Response::Term objects.

    $response->addTerm( SRU::Response::Term->new( value => 'Foo Fighter' ) );

=cut

=head2 terms()

Get/set the terms associated with the response. Be carefult you must pass
in an array ref of SRU::Response::Term objects, or expect an array ref
back when getting the values. If you don't bad things will happen.

=head2 diagnostics()

=head2 extraResponseData()

=head2 echoedScanRequest()

=cut

=head2 asXML()

=cut
=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ed Summers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
