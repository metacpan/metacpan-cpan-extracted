package SRU::Response::Explain;
{
  $SRU::Response::Explain::VERSION = '1.01';
}
#ABSTRACT: A class for representing SRU explain responses

use strict;
use warnings;
use base qw( Class::Accessor SRU::Response );
use SRU::Response::Diagnostic;
use SRU::Utils qw( error );
use SRU::Utils::XML qw( element );
use Carp qw( croak );


sub new {
    my ($class,$request) = @_;
    return error( 'must pass in a SRU::Request::Explain object' )
        if ! ref($request) or ! $request->isa( 'SRU::Request::Explain' );

   my $self =  $class->SUPER::new( {
        version                 => $request->version(),
        record                  => '',
        diagnostics             => [],
        extraResponseData       => '',
        echoedExplainRequest    => $request->asXML(),
        stylesheet              => $request->stylesheet(),
    } );

    return $self;
}


SRU::Response::Explain->mk_accessors( qw(
    version 
    diagnostics
    extraResponseData
    echoedExplainRequest
    stylesheet
) );

sub record {
    my ( $self, $record ) = @_;
    if ( $record ) {
        croak( "must pass in a SRU::Response::Record object" )
            if ref($record) ne 'SRU::Response::Record';
        $self->{record} = $record;
    }
    return $self->{record};
}


sub asXML {
    my $self = shift;
    my $stylesheet = $self->stylesheetXML();
    my $echoedExplainRequest = $self->echoedExplainRequest();
    my $diagnostics = $self->diagnosticsXML();
    my $record = $self->record() ? $self->record()->asXML() : '';
    my $xml = 
<<"EXPLAIN_XML";
<?xml version="1.0"?>
$stylesheet
<explainResponse xmlns="http://www.loc.gov/zing/srw/">
<version>1.1</version>
$record
$echoedExplainRequest
$diagnostics
</explainResponse>
EXPLAIN_XML
    return $xml;
}

1;

__END__

=pod

=head1 NAME

SRU::Response::Explain - A class for representing SRU explain responses

=head1 SYNOPSIS
    
    use SRU::Response;
    my $response = SRU::Response::Explain->new( $request );

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

The constructor which requires that you pass in a SRU::Request::Explain
object.

=cut

=head2 version()

=head2 record()

=head2 addDiagnostic()

Add a SRU::Response::Diagnostic object to the response.

=head2 diagnostics()

Returns an array ref of SRU::Response::Diagnostic objects relevant 
for the response.

=head2 extraResponseData()

=head2 echoedExplainRequest()

=cut

=head2 asXML()

=cut
=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ed Summers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
