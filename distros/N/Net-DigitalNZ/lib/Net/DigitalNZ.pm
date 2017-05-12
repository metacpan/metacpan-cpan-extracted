
package Net::DigitalNZ;
#Based heavily on Net::Twitter

$VERSION = "0.15";
use 5.005;
use strict;

use URI::Escape;
use JSON::Any 1.19;
use LWP::UserAgent 2.032;
use Carp;

sub new {
my $class = shift;

my %conf;

if ( scalar @_ == 1 ) {
  if ( ref $_[0] ) {
    %conf = %{ $_[0] };
    } else {
      croak "Bad argument \"" . $_[0] . "\" passed, please pass a hashref containing config values.";
    }
  }
  else {
    %conf = @_;
  }
  $conf{apiurl}   = 'http://api.digitalnz.org/' unless defined $conf{apiurl};

  ### Set useragents, HTTP Headers, source codes.
  $conf{useragent} = "Net::DigitalNZ/$Net::DigitalNZ::VERSION (PERL)"
  unless defined $conf{useragent};
  ### Allow specifying a class other than LWP::UA

  $conf{no_fallback} = 0 unless defined $conf{no_fallback};

  ### Create an LWP Object to work with
  $conf{ua} = LWP::UserAgent->new();


  $conf{ua}->env_proxy();

  $conf{response_error}  = undef;
  $conf{response_code}   = undef;
  $conf{response_method} = undef;

  return bless {%conf}, $class;
}
                        
### Return a shallow copy of the object to allow error handling when used in
### Parallel/Async setups like POE. Set response_error to undef to prevent
### spillover, just in case.

sub clone {
  my $self = shift;
  bless { %{$self}, response_error => $self->{error_return_val} };
}
                        

                        
sub get_error {
  my $self = shift;
  my $response = eval { JSON::Any->jsonToObj( $self->{response_error} ) };

  if ( !defined $response ) {
    $response = {
    request => undef,
    error   => "DIGITAL NZ RETURNED ERROR MESSAGE BUT PARSING OF THE JSON RESPONSE FAILED - "
    . $self->{response_error}
    };
  }

  return $response;

}
                          
sub http_code {
  my $self = shift;
  return $self->{response_code};
}

sub http_message {
  my $self = shift;
  return $self->{response_message};
}

sub search {
    my $self = shift;
    my $query = shift;
    my $params = shift;
    
    my $url  = $self->{apiurl} . "records/v1.json/?";
    $url .= 'api_key='. $self->{api_key};
    $url .= '&search_text='. uri_escape($query);

    ### Make a string out of the args to append to the URL.
    
    foreach my $name ( sort keys %{$params} ) {
      # drop arguments with undefined values
      next unless defined $params->{$name};
      $url .= "&" unless substr( $url, -1 ) eq "?";
      $url .= $name . "=" . uri_escape( $params->{$name} );
      
    }
    my $retval;
    ### Make the request, store the results.
    my $req = $self->{ua}->get($url);

    $self->{response_code}    = $req->code;
    $self->{response_message} = $req->message;
    $self->{response_error}   = $req->content;

    undef $retval;
                                                
    ### Trap a case where digitalnz could return a 200 success but give up badly formed JSON
    ### which would cause it to die. This way it simply assigns undef to $retval
    ### If this happens, response_code, response_message and response_error aren't going to
    ### have any indication what's wrong, so we prepend a statement to request_error.
                                                
  if ( $req->is_success ) {
    $retval = eval { JSON::Any->jsonToObj( $req->content ) };

    if ( !defined $retval ) {
      $self->{response_error} =
      "DIGITALNZ RETURNED SUCCESS BUT PARSING OF THE RESPONSE FAILED - " . $req->content;
      return $self->{error_return_val};
      }
  }
  return $retval;
} 

1;
__END__
=head1 NAME

Net::DigitalNZ - Perl interface to digitalnz.org 's open data api.

=head1 DESCRIPTION

The metadata available through DigitalNZ comes from content providers across the New Zealand cultural and heritage, broadcasting, education, and government sectors; as well as local community sources and individuals.

You will need to obtain your own API key from http://digitalnz.org

=head1 SYNOPSIS

     use Net::DigitalNZ;
     my $query = 'Waitangi';
     my $api_key = 'get your own api key';
     my $searcher = Net::DigitalNZ->new(api_key => $api_key);
     my $results = $searcher->search($query);

=head1 METHODS

=head2 search

The search records API call is passed a search query and returns a corresponding result set

     # simple query
     my $results = $searcher->search($query);

     # more complicated query
     my $results = $searcher->search($query, {key => value});

=head3 Parameters

=over 4

=item num_results

the number of results the user wishes returned

=item start

the offset from which the result list should start

=item sort

the field upon which results are sorted. If sort_field isn't specified the results are sorted by relevance. The sort_field must be one of: category, content_provider, date, syndication_date, title

=item direction

the direction in which the results are sorted. Can only be used in conjunction with the sort field and must be either asc or desc. If not specified, sort_direction defaults to asc

=item facets

a list of facet fields to include in the output. See the note on facets below for more information.

=item facet_num_results

the number of facet results to include. Only used if the facets parameter is specified, and defaults to 10.

=item facet_start

the offset from which the facet value list should start. Only used if the facets parameter is specified, and defaults to 0.

=back

=head3 Example

     use Net::DigitalNZ;

     my $query = 'Waitangi';
     my $api_key = 'get your own api key from http://digitalnz.org';

     my $searcher = Net::DigitalNZ->new(api_key => $api_key);
     my $results = $searcher->search($query, {
                          start=>10,
                          num_results => 2}
                   );

     print $results->{result_count} . " items found\n";

     foreach my $r (@{ $results->{results} } ) {
          print $r->{id} . ': '. $r->{title} ."\n";
     }

More info at http://www.digitalnz.org/developer/api-docs/search-records

=head2 Response elements

The search results will return the following elements:

=over 4

=item num_results_requested

the value of the num_results parameter sent to the API method

=item result_count

the total number of results matching this search

=item start

the value of the start parameter sent to the API method

=item results

the search results data. The results element will contain 0 or more result elements, each containing the following elements:

=over 4

=item category

a string containing one or more category names separated by a comma (e.g. Images, Web pages)

=item content_provider

the institution holding the content to which the record refers

=item date

a date associated with the record (e.g. 1996-01-01T00:00:00.000Z). This field may be empty

=item description

text describing the record

=item display_url

the url for the content on the content provider's website

=item id

the internal DigitalNZ identifier (used by the Get Metadata API)

=item metadata-url

the url to the DigitalNZ API method that will return the full metadata for the record

=item source-url

the url that will redirect users directly to the content_url

=item thumbnail-url

the url of for a thumbnail image of the content to which the record refers. This field may be empty.

=back

=item facets

the facet result data (if requested). The facets element will contain one facet-field element corresponding to each facet requested. Each facet-field element contains a sorted list of value elements that are made up of a name and num-results element. See the note below for more information on facets.

=back

=head1 LICENCE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 VERSION CONTROL

http://github.com/Br3nda/perl-net-digitalnz/tree/master

=head1 AUTHOR

Brenda Wallace <brenda@wallace.net.nz> http://br3nda.com

Based heavily on L<Net::Twitter> by Chris Thompson

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
