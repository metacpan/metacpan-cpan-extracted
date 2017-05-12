{

=head1 NAME

Net::Google::Response - simple OOP-ish interface to the Google SOAP
API search responses

=head1 SYNOPSIS

 my $service = Net::Google->new(key=>LOCAL_GOOGLE_KEY);
 my $session = $service->search();

 $session->query(qw(Perl modules));

 # You are probably better off calling
 # $session->results() but if you want
 # the raw response object(s) here ya go :

 my $responses = $session->response();
 my $count     = scalar(@$responses);

 # $r is a Net::Google::Response object

 foreach my $r (@$responses) {
     print sprintf("%s : %s\n",$r->searchQuery(),$r->estimatedTotalResults());
 }

=head1 DESCRIPTION

Provides a simple OOP-ish interface to the Google SOAP API for
searching.  This package is used by I<Net::Google>.

The Net::Google::Response object is used to contain response
information provided by the Google search service in response to a
search query.  The Response object allows the client program to easily
access the data returned from a search.

Response data is accessed using methods with identical names to the
elements of a search response (as documented in the Google Web APIs
Reference, section 3).  For instance, the first example in the SYNOPSIS
section, above, would return the estimated number of total results for
the query.

Response objects may contain other response objects, where an element
would return an array of other elements.  For instance, calling
C<$response-E<gt>resultElements()> will return a reference to an array
of Net::Google::Response objects, each one representing one result
from the search.

The Response module will automatically provide methods for the search
response, as described by the service WSDL file.  The results format
is described by the Google APIs documentation, to which you should
refer for the most up-to-date information.  As of the April 8th, 2002
release of the Google APIs, the methods below are provided for each
search result.

=cut

use strict;

package Net::Google::Response;

use vars qw ($AUTOLOAD);

use Carp;

$Net::Google::Response::VERSION   = '1.0';

# Note that we handle 'resultElements' separately
# Maybe we should doing the same w/ directoryCategories...

use constant RESPONSE_FIELDS => qw [ directoryCategories estimateIsExact startIndex searchTime estimatedTotalResultsCount searchTips searchComments searchQuery endIndex documentFiltering ];

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new(\%args)

=cut

sub new {
  my $pkg    = shift;

  my $self = {};
  bless $self,$pkg;

  if (! $self->init(@_)) {
    return undef;
  }

  return $self;
}

sub init {
  my $self     = shift;
  my $response = shift;

  if (ref($response) ne "GoogleSearchResult") {
    carp "Unknown response object.";
    return 0;
  }

  foreach my $el (@{$response->{'resultElements'}}) {
    if (my $res = Result->new($el)) {
      push @{$self->{'__resultElements'}},$res;
    }
  }

  map { $self->{'__'.$_} = $response->{$_}; } &RESPONSE_FIELDS;
  return 1;
}

=head1 I<Net::Google::Response> OBJECT METHODS

=cut

=head2 $response->documentFiltering()

Returns 0 if false, 1 if true.

=head2 $response->searchComments()

Returns a string.

=head2 $response->estimatedTotalResultsCount()

Returns an integer.

=head2 $response->estimateIsExact()

Returns 0 if false, 1 if true.

=head2 $response->resultElements()

Returns a reference to an array of I<Response> objects.

=cut

sub resultElements {
  my $self    = shift;

  if(ref($self->{'__resultElements'}) eq "ARRAY") {
    return $self->{'__resultElements'};
  } 

  return [];
}

=head2 $response->searchQuery()

Returns a string.

=head2 $response->startIndex()

Returns an integer.

=head2 $response->endIndex()

Returns an integer.

=head2 $response->searchTips()

Returns a string.

=head2 $response->directoryCategories() 

Returns a reference to an array of Response objects (one per directory
category -- see below).

=head2 $response->searchTime()

Returns a float.

=head2 $pkg->to_string()

=cut

sub to_string {
  my $self = shift;
  my $string = '';

  foreach my $key (keys %$self) {
    $string .= "$key: $$self{$key}\n";
  }

  return $string;
}

sub DESTROY {
  return 1;
}

sub AUTOLOAD {
  my $self = shift;

  $AUTOLOAD =~ s/.*:://;
  
  unless (grep/^($AUTOLOAD)$/,&RESPONSE_FIELDS) {
    carp "Unknown attribute : ".$AUTOLOAD;
    return undef;
  }

  return $self->{'__'.$AUTOLOAD};
}

package Result;
use Carp;

use vars qw ($AUTOLOAD);

use constant RESULT_FIELDS => qw [ title URL snippet cachedSize directoryTitle summary hostName directoryCategory relatedInformationPresent ];

sub new {
  my $pkg = shift;

  my $self = {};
  bless $self,$pkg;

  if (! $self->init(@_)) {
    return undef;
  }

  return $self;
}

sub init {
  my $self = shift;
  my $res  = shift;

  unless (ref($res) eq "ResultElement") {
    carp "Unknown result object";
    return 0;
  }

  map { $self->{'__'.$_} = $res->{$_}; } &RESULT_FIELDS;
  return 1;
}

=head1 I<Result> OBJECT METHODS

=cut

=head2 $result->title()

Returns a string.

=head2 $result->URL()

Returns a string.

=head2 $result->snippet()

Returns a string, formatted in HTML.

=head2 $result->cachedSize()

Returns a string.

=head2 $result->directoryTitle()

Returns a string.

=head2 $result->summary()

Returns a string.

=head2 $result->hostName()

Returns a string.

=head2 $result->directoryCategory()

Returns a hash reference.

=cut

sub AUTOLOAD {
  my $self = shift;
  $AUTOLOAD =~ s/.*:://;

  unless (grep/^($AUTOLOAD)$/,&RESULT_FIELDS) {
    carp "Unknown attribute :".$AUTOLOAD;
    return undef;
  }

  return $self->{'__'.$AUTOLOAD};
}

sub DESTROY {
  return 1;
}

=head1 VERSION

1.0

=head1 DATE

$Date: 2005/04/02 21:51:16 $

=head1 AUTHOR

Aaron Straup Cope

=head1 CONTRIBUTORS

Marc Hedlund <marc@precipice.org>

=head1 SEE ALSO

L<Net::Google>

=head1 LICENSE

Copyright (c) 2002-2005, Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the
same terms as Perl itself.

=cut

return 1;

}
