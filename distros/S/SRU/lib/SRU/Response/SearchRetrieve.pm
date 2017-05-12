package SRU::Response::SearchRetrieve;
{
  $SRU::Response::SearchRetrieve::VERSION = '1.01';
}
#ABSTRACT: A class for representing SRU searchRetrieve responses

use strict;
use warnings;
use base qw( Class::Accessor SRU::Response );
use SRU::Utils::XML qw( element );
use SRU::Utils qw( error );
use SRU::Response::Record;


sub new {
    my ($class,$request) = @_;
    return error( 'must pass in a SRU::Request::SearchRetrieve object' )
        if ! ref($request) or ! $request->isa( 'SRU::Request::SearchRetrieve' );

    my $self =  $class->SUPER::new( {
        version                         => '1.1',
        numberOfRecords                 => 0,
        records                         => [],
        resultSetId                     => undef,
        resultSetIdleTime               => undef,
        nextRecordPosition              => undef,
        diagnostics                     => [],
        extraResponseData               => '',
        echoedSearchRetrieveRequest     => $request->asXML(),
        stylesheet                      => $request->stylesheet(),
    } );

    $self->addDiagnostic( SRU::Response::Diagnostic->newFromCode(7,'version') )
        if ! $self->version();

    $self->addDiagnostic( SRU::Response::Diagnostic->newFromCode(7, 'query') )
        if ! $request->query();

    return $self;
}


sub numberOfRecords {
    my ($self,$num) = @_;
    if ( $num ) { $self->{numberOfRecords} = $num; }
    return $self->{numberOfRecords};
}


sub addRecord {
    my ($self,$r) = @_;
    return if ! $r->isa( 'SRU::Response::Record' );
    ## set recordPosition if necessary
    if ( ! $r->recordPosition() ) { 
        $r->recordPosition( $self->numberOfRecords() + 1 );
    }
    $self->{numberOfRecords}++;
    push( @{ $self->{records} }, $r );
}



SRU::Response::SearchRetrieve->mk_accessors( qw(
    version 
    records                     
    resultSetId                 
    resultSetIdleTime           
    nextRecordPosition          
    diagnostics                 
    extraResponseData           
    echoedSearchRetrieveRequest 
    stylesheet
) );


sub asXML {
    my $self     = shift;
    my %args     = @_;
    my $encoding = $args{ encoding };

    my $numberOfRecords = $self->numberOfRecords();
    my $stylesheet = $self->stylesheetXML();
    my $version = element( 'version', $self->version() );
    my $diagnostics = $self->diagnosticsXML();
    my $echoedSearchRetrieveRequest = $self->echoedSearchRetrieveRequest();
    my $resultSetIdleTime = $self->resultSetIdleTime();
    my $resultSetId = $self->resultSetId();

    my $extraResponseData = '<extraResponseData>' . $self->extraResponseData() . '</extraResponseData>';
    my $xmltitle;
    if( $encoding ) {
        $xmltitle = "<?xml version='1.0' encoding='$encoding'?>";
    }
    else {
        $xmltitle = "<?xml version='1.0'?>";
    }

    my $xml = 
<<SEARCHRETRIEVE_XML;
$xmltitle
$stylesheet
<searchRetrieveResponse xmlns="http://www.loc.gov/zing/srw/">
$version
<numberOfRecords>$numberOfRecords</numberOfRecords>
SEARCHRETRIEVE_XML

    $xml .= "<resultSetId>$resultSetId</resultSetId>" 
        if defined($resultSetId);
    $xml .= "<resultSetIdleTime>$resultSetIdleTime</resultSetIdleTime>\n"
        if defined($resultSetIdleTime);

    if( $numberOfRecords ) {
        $xml .= "<records>\n";

        ## now add each record
        foreach my $r ( @{ $self->{records} } ) {
            $xml .= $r->asXML()."\n";
        }

        $xml .= "</records>\n";
    }

    $xml .=
<<SEARCHRETRIEVE_XML;
$diagnostics
$extraResponseData 
$echoedSearchRetrieveRequest
</searchRetrieveResponse>
SEARCHRETRIEVE_XML

    return $xml;
}

1;

__END__

=pod

=head1 NAME

SRU::Response::SearchRetrieve - A class for representing SRU searchRetrieve responses

=head1 SYNOPSIS

    ## create response from the request object
    my $response = SRU::Response::SearchRetrieve->new( $request );

    ## add records to the response 
    foreach my $record ( @records ) { $response->addRecord( $record ); }

    ## print out the response as XML
    print $response->asXML();

=head1 DESCRIPTION

SRU::Response::SearchRetrieve provides a framework for bundling up 
the response to a searchRetrieve request. You are responsible for
generating the XML representation of the records, and the rest
should be taken care of.

=head1 METHODS

=head2 new()

=cut

=head2 numberOfRecords()

Returns the number of results associated with the object.

=cut

=head2 addRecord()

Add a SRU::Response::Record object to the response.

    $response->addRecord( $r );

If you don't pass in the right sort of object you'll get back
undef and $SRU::Error will be populated appropriately.

=cut

=head2 records()

Gets or sets all the records associated with the object. Be careful
with this one :) You must pass in an array ref, and expect an 
array ref back.

=cut

=head2 resultSetId()

=head2 resultSetIdleTime()

=head2 nextRecordPosition()

=head2 diagnostics()

=head2 extraResponseData()

=head2 echoedSearchRetrieveRequest()

=cut

=head2 asXML()

    asXML(encoding=>"ISO-8859-1")

Returns the object serialized as XML. UTF-8 and UTF-16 are default encodings if you don't pass the encoding parameter. You can define different encoding in order to parse you XML document correctly.

=cut
=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ed Summers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
