package SRU::Request;
{
  $SRU::Request::VERSION = '1.01';
}
#ABSTRACT: Factories for creating SRU request objects. 

use strict;
use warnings;
use URI;
use SRU::Request::Explain;
use SRU::Request::SearchRetrieve;
use SRU::Request::Scan;
use SRU::Utils qw( error );
use SRU::Utils::XML qw( escape );
use Scalar::Util qw(reftype);

our %PARAMETERS = (
    'explain' => 
        [qw(version recordPacking stylesheet extraRequestData)],
    'scan' => 
        [qw(version scanClause responsePosition maximumTerms stylesheet 
           extraRequestData)],
    'searchRetrieve' => 
        [qw(version query startRecord maximumRecords recordPacking recordSchema
           recordXPath resultSetTTL sortKeys stylesheet extraRequestData)]
);


sub new {
    my $class = shift;

    my %query;

    if ( @_ % 2 ) {
        my $q = shift;

        if ( UNIVERSAL::isa( $q, 'CGI' ) ) {
            ## we must have ampersands between query string params, but lets
            ## make sure we don't screw anybody else up
            my $saved = $CGI::USE_PARAM_SEMICOLONS; 
            $CGI::USE_PARAM_SEMICOLONS = 0;
            $q = $q->self_url;
            $CGI::USE_PARAM_SEMICOLONS = $saved;
        } elsif ( (reftype $q // '') eq 'HASH' ) {
            $q = "http://example.org/?" . $q->{QUERY_STRING};
        }
            
        if ( ! UNIVERSAL::isa( $q, 'URI' ) ) { 
            $q = URI->new($q);
        }
        if ( UNIVERSAL::isa( $q, 'URI' ) ) {
            %query = $q->query_form;
        } else {
            return error( "invalid uri: $q" ) 
        }
    } else {
        %query = @_;
    }

    my $operation = $query{operation} || 'explain';

    my $request;
    if ( $operation eq 'scan' ) { 
        $request = SRU::Request::Scan->new( %query );
    } elsif ( $operation eq 'searchRetrieve' ) {
        $request = SRU::Request::SearchRetrieve->new( %query );
    } elsif ( $operation eq 'explain' ) {
        $request = SRU::Request::Explain->new( %query );
    } else {
        $request = SRU::Request::Explain->new( %query );
        $request->missingOperator(1);
    }

    return $request;

}


*newFromURI = *new;
*newFromCGI = *new;


sub asXML {
    my $self = shift;

    ## extract the type of request from the type of object
    my ($type) = ref($self) =~ /^SRU::Request::(.*)$/;
    $type = "echoed${type}Request";

    ## build the xml
    my $xml = "<$type>";

    ## add xml for each param if it is available
    foreach my $param ( $self->validParams() ) {
        $xml .= "<$param>" . escape($self->$param) . "</$param>" 
            if $self->$param;
    }
    ## add XCQL if appropriate
    if ( $self->can( 'cql' ) ) {
        my $cql = $self->cql();
        if ( $cql ) {
            my $xcql = $cql->toXCQL(0);
            chomp( $xcql );
            $xcql =~ s/>\n *</></g; # collapse whitespace
            $xml .= "<xQuery>$xcql</xQuery>";
        }
    }

    $xml .= "</$type>";
    return $xml;
}


sub asURI {
    my ($self, $base) = @_;

    my $uri = URI->new($base // "http://localhost/");
    my %query = $uri->query_form;

    $query{operation} = $self->type;
    
    no strict 'refs';
    foreach (@{ $PARAMETERS{ $self->type } }) {
        $query{$_} = $self->$_ if defined $self->$_;
    }

    $uri->query_form( \%query );
    return $uri;
}



sub type {
    my $self  = shift;
    my $class = ref $self || $self;
    return lcfirst( ( split( '::', $class ) )[ -1 ] );
}

1;

__END__

=pod

=head1 NAME

SRU::Request - Factories for creating SRU request objects. 

=head1 SYNOPSIS

    use SRU::Request;
    my $request = SRU::Request->newFromURI( $uri );

=head1 DESCRIPTION

SRU::Request allows you to create the appropriate SRU request object
from a URI object. This allows you to pass in a URI and get back 
one of SRU::Request::Explain, SRU::Request::Scan or 
SRU::Request::SearchRetrieve depending on the type of URI that is passed 
in. See the docs for those classes for more information about what
they contain.

=head1 METHODS

=head2 new( %query | $uri | $cgi | $env )

Create a new request object which is one of:

=over 4

=item * SRU::Request::Explain

=item * SRU::Request::Scan

=item * SRU::Request::SearchRetrieve

=back

One can pass query parameters as hash, as URL, as L<URI>, as L<CGI> object or
as L<PSGI> request.

If the request is not formatted properly the call will return undef. 
The error encountered should be available in $SRU::Error.

=cut

=head2 newFromURI

=head2 newFromCGI

Deprecated aliases for C<new>.

=cut

=head2 asXML()

Used to generate <echoedExplainRequest>, <echoedSearchRetrieveRequest> and
<echoedScanRequest> elements in the response.

=cut

=head2 asURI( [ $base ] )

Creates a L<URI> of this request. The optional C<base> URL, provided as
string or as L<URI>, is set to C<http://localhost/> by default.

=cut

=head2 type()

Returns 'searchRetrieve', 'scan' or 'explain' depending on what type of
object it is.

=cut
=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ed Summers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
