{

=head1 NAME

Net::Google::Search - simple OOP-ish interface to the Google SOAP API for searching

=head1 SYNOPSIS

 use Net::Google::Search;
 my $search = Net::Google::Search->new(\%args);

 $search->query(qw(aaron cope));
 map { print $_->title()."\n"; } @{$search->results()};

 # or

 foreach my $r (@{$search->response()}) {
   print "Search time :".$r->searchTime()."\n";

   # returns an array ref of Result objects
   # the same as the $search->results() method
   map { print $_->URL()."\n"; } @{$r->resultElement()}
 }

=head1 DESCRIPTION

Provides a simple OOP-ish interface to the Google SOAP API 
for searching.

This package is used by I<Net::Google>.

=head1 ENCODING

According to the Google API docs :

 "In order to support searching documents in multiple languages 
 and character encodings the Google Web APIs perform all requests 
 and responses in the UTF-8 encoding. The parameters <ie> and 
 <oe> are required in client requests but their values are ignored.
 Clients should encode all request data in UTF-8 and should expect
 results to be in UTF-8."

(This package takes care of setting both parameters in requests.)

=cut

use strict;

package Net::Google::Search;
use base qw (Net::Google::tool);

use Carp;
use Net::Google::Response;

$Net::Google::Search::VERSION   = '1.0';

use constant RESTRICT_ENCODING => qw [ arabic gb big5 latin1 latin2 latin3 latin4 latin5 latin6 greek hebrew sjis euc-jp euc-kr cyrillic utf8 ];

use constant RESTRICT_LANGUAGES => qw [ ar zh-CN zh-TW cs da nl en et fi fr de el iw hu is it ja ko lv lt no pt pl ro ru es sv tr ];

use constant RESTRICT_COUNTRIES => qw [ AD AE AF AG AI AL AM AN AO AQ AR AS AT AU AW AZ BA BB BD BE BF BG BH BI BJ BM BN BO BR BS BT BV BW BY BZ CA CC CD CF CG CH CI CK CL CN CO CR CU CV CX CY CZ DE DJ DK DM DO DZ EC EE EG EH ER ES ET EU FI FJ FK FM FO FR FX GA GD GE GF GH GI GL GM GN GP GQ GR GS GT GU GW GY HK HM HN HR HT HU ID IE IL IO IQ IR IS IT JM JO JP KE KG KH KI KM KN KP KR KW KY KZ LA LB LC LI LK LR LS LT LU LV LY MA MC MD MG MH MK ML MM MN MO MP MQ MR MS MT MU MV MW MX MY MZ NA NC NE NF NG NI ML NO NP NR NU NZ OM PA PE PF PG PH PK PL PM PN PR PS PT PW PY QA RE RO RU RW SA SB SC SD SE SG SH SI SJ SK SL SM SN SO SR ST SV SY SZ TC TD TF TG TH TJ TK TM TN TO TP TR TT TV TW TZ UA UG UK UM US UY UZ VA VC VE VG VI VN VU WF WS YE YT YU ZA ZM ZR ];

use constant RESTRICT_TOPICS => qw [ unclesam linux mac bsd ];

use constant WATCH => "__estimatedTotalResultsCount";

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new(\%args)

Valid arguments are :

=over 4

=item *

B<key>

I<string>. A Google API key. 

If none is provided then the key passed to the parent I<Net::Google>
object will be used.

=item *

B<starts_at>

I<int>. First result number to display. 

Default is 0.

=item *

B<max_results>

I<int>. Number of results to return. 

Default is 10.

=item *

B<lr>

I<string> or I<array reference>. Language restrictions.

=item *

B<safe>

I<boolean>.

=item *

B<filter>

I<boolean>.

=item *

B<http_proxy>

I<url>. A URL for proxy-ing HTTP requests.

=item *

B<debug>

Valid options are:

=over 4

=item *

I<boolean>

If true prints debugging information returned by SOAP::Lite
to STDERR

=item *

I<coderef>.

Your own subroutine for munging the debugging information
returned by SOAP::Lite.

=back

=back

The object constructor in Net::Google 0.53, and earlier, expected
a I<GoogleSearchService> object as its first argument followed by
 a hash reference of argument. Versions 0.6 and higher are backwards 
compatible.

Returns an object. Woot!

=cut

sub new {
  my $pkg = shift;
  
  my $self = {};
  bless $self,$pkg;

  if (! $self->init("search",@_)) {
    return undef;
  }

  return $self;
}

sub init {
  my $self = shift;

  my $args = $self->SUPER::init(@_)
    || return 0;

  #

  $self->{'_query'}       = [];
  $self->{'_lr'}          = [];
  $self->{'_restrict'}    = [];
  $self->{'_safe'}        = 0;
  $self->{'_filter'}      = 0;
  $self->{'_starts_at'}   = 0;
  $self->{'_max_results'} = 10;

  $self->starts_at(($args->{'starts_at'} || 0));
  $self->max_results(($args->{'max_results'}) || 10);

  if ($args->{lr}) {
    defined($self->lr( ((ref($args->{'lr'}) eq "ARRAY") ? @{$args->{'lr'}} : $args->{'lr'}) )) || return 0;
  }

  if ($args->{restrict}) {
    defined($self->restrict( ((ref($args->{'restrict'}) eq "ARRAY") ? @{$args->{'restrict'}} : $args->{'restrict'}) )) || return 0;
  }

  if (defined($args->{'filter'})) {
    defined($self->filter($args->{'filter'})) || return 0;
  }

  if (defined($args->{'safe'})) {
    defined($self->safe($args->{'safe'})) || return 0;
  }

  if (defined($args->{'starts_at'})) {
    defined($self->starts_at($args->{'starts_at'})) || return 0;
  }

  if (defined($args->{'max_results'})) {
    defined($self->max_results($args->{'max_results'})) || return 0;
  }

  return 1;
}

=head1 OBJECT METHODS

=cut

sub ie {
    carp "The 'ie' method has been deprecated";
}

sub oe {
    carp "The 'oe' method has been deprecated";
}

=head2 $obj->key($string)

Get/set the Google API key for this object.

=cut

# Defined in Net::Google::tool

=head2 $obj->http_proxy($url)

Get/set the HTTP proxy for this object.

Returns a string.

=cut

# Defined in Net::Google::tool

=head2 $obj->query(@data)

If the first item in I<@data> is empty, then any existing 
I<query> data will be removed before the new data is added.

Returns a string of words separated by white space. Returns 
undef if there was an error.

=cut

sub query {
  my $self = shift;
  my @data = @_;

  if ((scalar(@data) > 1) && ($data[0] eq "")) {
    $self->{'_query'} = [];
  }

  if (@data) {
    push @{$self->{'_query'}}, @data;
  }

  return join(" ",@{$self->{'_query'}});
}

=head2 $obj->starts_at($at)

Returns an int. Default is 0.

Returns undef if there was an error.

=cut

sub starts_at {
  my $self = shift;
  my $at   = shift;

  if (defined($at)) {
    $self->{'_starts_at'} = $at;
  }

  return $self->{'_starts_at'};
}

=head2 $obj->max_results($max)

The default set by Google is 10 results. However, if 
you pass a number greater than 10 the I<results> method 
will make multiple calls to Google API.

Returns an int.

Returns undef if there was an error.

=cut

sub max_results {
  my $self = shift;
  my $max  = shift;

  if (defined($max)) {

    if (int($max) < 1) {
      carp "'$max' must be a int greater than 0";
      $max = 1;
    }

    $self->{'_max_results'} = $max;
  }

  return $self->{'_max_results'};
}

=head2 $obj->restrict(@types)

If the first item in I<@types> is empty, then any existing 
I<restrict> data will be removed before the new data is 
added.

Returns a string. Returns undef if there was an error.

=cut

sub restrict {
  my $self  = shift;
  my @types = @_;

  if ((scalar(@types) > 1) && ($types[0] eq "")) {
    $self->{'_restrict'} = [];
    shift @types;
  }

  if (@types) {
    push @{$self->{'_restrict'}},@types;
  }
  
  return join("",@{$self->{'_restrict'}});
}

=head2 $obj->filter($bool)

Returns true or false. Returns undef if there was an error.

=cut

sub filter {
  my $self = shift;
  my $bool = shift;

 
  if (defined($bool)) {
    $self->{'_filter'} = ($bool) ? 1 : 0;
  }

  return $self->{'_filter'};
}

=head2 $obj->safe($bool)

Returns true or false. Returns undef if there was an error.

=cut

sub safe {
  my $self = shift;
  my $bool = shift;

  if (defined($bool)) {
    $self->{'_safe'} = ($bool) ? 1 : 0;
  }

  return $self->{'_safe'};
}

=head2 $obj->lr(@lang)

Language restriction.

If the first item in I<@lang> is empty, then any existing 
I<lr> data will be removed before the new data is added.

Returns a string. Returns undef if there was an error.

=cut

sub lr {
  my $self = shift;
  my @lang = @_;

  if ((scalar(@lang) > 1) && ($lang[0] eq "")) {
    $self->{'_lr'} = [];
    shift @lang;
  } 

  if (@lang) {
    push @{$self->{'_lr'}},@lang;
  }
  
  return join("",@{$self->{'_lr'}});
}

=head2 $obj->return_estimatedTotal($bool)

Toggle whether or not to return all the results defined by the
'__estimatedTotalResultsCount' key.

Default is false.

=cut

sub return_estimatedTotal {
  my $self = shift;
  my $bool = shift;

  if (defined($bool)) {
    $self->{'__estimatedTotal'} = ($bool) ? 1 : 0;
  }

  return $self->{'__estimatedTotal'};
}

=head2 $obj->response()

Returns an array ref of I<Net::Google::Response> objects, 
from which the search response metadata as well as the 
search results may be obtained.

Use this method if you would like to receive a full response
 as documented in the Google Web APIs Reference (the whole 
of section 3).

=cut

sub response {
  my $self = shift;

  if (defined($self->{'__state'}) &&
      ($self->{'__state'} eq $self->_state())) {

    return $self->{'__response'};
  }

  $self->{'__response'} = [];

  my $start_at  = $self->starts_at();
  my $to_fetch  = $self->max_results();

  while ($to_fetch > 0) {
    my $count = ($to_fetch > 10) ? 10 : $to_fetch;

    # Net::Google::Response will carp
    # if there's a problem so we just
    # move on if there's a problem.

    my $res = $self->_response($start_at,$count);

    if (! defined($res)) {
	last;
    }

    #

    if ((! $self->return_estimatedTotal()) &&
	($start_at >= $res->{__endIndex})) {

      last;
    }

    #

    if ($self->return_estimatedTotal()) {

      if (($self->{'__possible'} + scalar(@{$res->resultElements()})) >  $res->{'__estimatedTotalResultsCount'}) {

	my $justright = int($res->{'__estimatedTotalResultsCount'} - $self->{'__possible'});
	@{$res->resultElements()} = @{$res->resultElements()}[0..($justright -1)];

	push @{$self->{'__response'}} , $res;
	last;
      }

      $self->{'__possible'} += scalar(@{$res->resultElements()});

      if (($self->{'__possible'} + scalar(@{$res->resultElements()})) ==  $res->{'__estimatedTotalResultsCount'}) {
	last;
      }
    }

    #

    push @{$self->{'__response'}}, $res;

    $start_at += 10;
    $to_fetch -= 10;
  }

  return $self->{'__response'};
}

=head2 $obj->results()

Returns an array ref of I<Result> objects (see docs for 
I<Net::Google::Response>), each of which represents one 
result from the search.

Use this method if you don't care about the search response 
metadata, and only care about the resources that are found 
by the search, as described in section 3.2 of the Google Web 
APIs Reference.

=cut

sub results {
  my $self = shift;
  return [ map { @{ $_->resultElements() } } @{$self->response()} ];
}

=head2 $obj->queries_exhausted() 

Returns true or false depending on whether or not the current in-memory
B<session> has exhausted the Google API 1000 query limit.

=cut

# Defined in ::tool

sub _response {
  my $self  = shift;
  my $first = shift;
  my $count = shift;

  $self->_queries(1);

  my $response = 
    $self->{'_service'}
      ->doGoogleSearch(
		       $self->key(),
		       $self->query(),
		       $first,
		       $count,
		       SOAP::Data->type(boolean=>($self->filter() 
						  ? "true" : "false")),
		                                  # I don't think I should need to
		                                  # do this but SOAP::Lite doesn't
		                                  # appear to be doing to right thing
		                                  # see also : RT bug #6167
		                                  # ? 1 : 0)),
		       $self->restrict(),
		       SOAP::Data->type(boolean=>($self->safe() 
						  ? "true" : "false")),
		                                  # see above
		                                  # ? 1 : 0)),
		       $self->lr(),
		       # input encoding
		       undef,
		       # output encoding
		       undef,
		      );

  if (! $response) {
    return undef;
  }

  $self->{'__state'} = $self->_state();
  return Net::Google::Response->new($response);
}

sub _state {
  my $self  = shift;
  my $state = undef;
  map {$state .= $self->$_()} qw (query lr restrict safe filter starts_at max_results);
  return $state;
}

=head1 VERSION

1.0

=head1 DATE

$Date: 2005/03/26 20:49:03 $

=head1 AUTHOR

Aaron Straup Cope

=head1 CONTRIBUTORS

Marc Hedlund <marc@precipice.org>

=head1 TO DO

=over 4

=item *

Add hooks to manage boolean searches and speacial query strings.

=back

=head1 SEE ALSO

L<Net::Google>

=head1 LICENSE

Copyright (c) 2002-2005, Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under 
the same terms as Perl itself.

=cut

return 1;

}
