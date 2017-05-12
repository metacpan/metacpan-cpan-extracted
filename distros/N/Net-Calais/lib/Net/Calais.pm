# ===========================================================================
# Net::Calais
# 
# Interface to OpenCalais web service
# 
# Alessandro Ranellucci <aar@cpan.org>
# 
package Net::Calais;
use strict;
use warnings;

use HTTP::Request::Common;
use LWP::UserAgent;
use XML::Writer;

our $VERSION = '1.02';

our $CALAIS_URL = 'http://api.opencalais.com/enlighten/rest/';
our $SEMANTICPROXY_URL = 'http://service.semanticproxy.com/processurl/';

#--
sub new {
    my ($class, %params) = @_;
    die "Calais apikey required\n" unless $params{apikey};
    my $self = { apikey => $params{apikey} };
    $self->{ua} = LWP::UserAgent->new() or return undef;
    bless $self, $class;
    return $self;
}
#--
sub enlighten {
    my __PACKAGE__ $self = shift;
    my ($content, %params) = @_;
    
    # process user params and set some defaults
    my %request_params = (licenseID => $self->{apikey}, content => $content);
    my (%processingDirectives, %userDirectives) = ();
    $processingDirectives{'c:contentType'} = $params{contentType} || 'text/txt';
    $processingDirectives{'c:outputFormat'} = $params{outputFormat} || 'XML/RDF';
    for (qw(reltagBaseURL calculateRelevanceScore enableMetadataType discardMetadata)) {
        $processingDirectives{"c:$_"} = $params{$_} if $params{$_};
    }
    for (qw(allowDistribution allowSearch externalID submitter)) {
        $userDirectives{"c:$_"} = $params{$_} if $params{$_};
    }
    
    # build the paramxXML parameter
    my $xmlWriter = XML::Writer->new(
        OUTPUT => \$request_params{paramsXML},
        DATA_MODE => 1,
        DATA_INDENT => 0,
        ENCODING => 'UTF-8'
    );
    $xmlWriter->startTag('c:params',
        'xmlns:c' => 'http://s.opencalais.com/1/pred/',
        'xmlns:rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#');
    $xmlWriter->startTag('c:processingDirectives', %processingDirectives);
    $xmlWriter->endTag('c:processingDirectives');
    $xmlWriter->startTag('c:userDirectives', %userDirectives);
    $xmlWriter->endTag('c:userDirectives');    
    $xmlWriter->startTag('c:externalMetadata');
    $xmlWriter->raw($params{externalMetadata}) if $params{externalMetadata};
    $xmlWriter->endTag('c:externalMetadata');
    $xmlWriter->endTag('c:params');
    $xmlWriter->end;
    
    # do REST request and return response
    my $response = $self->{ua}->request(POST $CALAIS_URL, \%request_params);
    if (!$response->is_success) {
        $self->{error} = $response->status_line;
        return undef;
    }
    return $response->content;
}
#--
sub semanticproxy {
    my __PACKAGE__ $self = shift;
    my ($url, %params) = @_;
    
    die "URL is required\n" unless $url;
    $params{output} ||= 'html';
    
    my $reqUrl = sprintf("%s%s/%s/%s", $SEMANTICPROXY_URL, $self->{apikey}, $params{output}, $url);
    my $response = $self->{ua}->request(GET $reqUrl);
    if (!$response->is_success) {
        $self->{error} = $response->status_line;
        return undef;
    }
    return $response->content;
}
#--
1;
__END__

=head1 NAME

Net::Calais - Interface to OpenCalais web service

=head1 SYNOPSIS

    use Net::Calais;
    
    my $calais = Net::Calais->new(apikey => 'akljelkjde3jlkj2i2l2');
    print $calais->enlighten($html, contentType => 'text/html');

=head1 METHODS

=over 8

=item B<new()>

	Net::Calais->new(PARAM => ...);

Acceptable parameters:

=over 4

=item  apikey

The API key used for authentication with the service.

=back

=item B<enlighten()>

	$calais->enlighten($data, PARAM => ...);

Submits text to the OpenCalais web service.

Optional parameters:

=over 4

=item  contentType

Format of the input content (may be text/raw, text/txt/, text/html, text/xml).
Unless specified, text/txt is assumed.

=item  outputFormat

Format of the server response. Unless specified, XML/RDF is assumed.

=item  reltagBaseURL

=item  calculateRelevanceScore

=item  enableMetadataType

=item  discardMetadata

=item  allowDistribution

=item  allowSearch

=item  externalID

=item  submitter

=item  externalMetadata

This should be a RDF representation of your additional metadata (see OpenCalais docs).

=back

See L<http://opencalais.com/APIcalls#inputparameters> for description of such
parameters.

=item B<semanticproxy()>

	$calais->semanticproxy($url, PARAM => ...);

Submits text to the SemanticProxy web service.

Optional parameters:

=over 4

=item  output

Format of the requested output (may be html, rdf or microformat).

=back

=back

=head1 PACKAGE VARIABLES

=over 8

=item B<$CALAIS_URL>

By modifying the I<$Net::Calais::CALAIS_URL> variable you can set a custom URL
for REST requests.  The default value is I<http://api.opencalais.com/enlighten/rest/>.
This may be useful to use the beta service which is usually located at I<beta.opencalais.com>.

=item B<$SEMANTICPROXY_URL>

By modifying the I<$Net::Calais::SEMANTICPROXY_URL> variable you can set a custom base URL
for SemanticProxy REST requests.  The default value is I<http://service.semanticproxy.com/processurl/>.


=back

=head1 SEE ALSO

L<http://opencalais.com/>

=head1 BUGS AND FEEDBACK

You are very welcome to write mail to the maintainer (aar@cpan.org) with 
your contributions, comments, suggestions, bug reports or complaints.

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Alessandro Ranellucci E<lt>aar@cpan.orgE<gt>

=cut
