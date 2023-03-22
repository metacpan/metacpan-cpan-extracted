# ABSTRACT:An interface to ElasticSearch API, version independent
#
# George Bouras, george.mpouras@yandex.com and Joan Ntzougani

package Search::ElasticDirect;
our $VERSION = '2.5.1';

use strict;
use warnings;
use Search::ElasticDirect;
use parent qw(Search::ElasticDirectHttp);
use URI::Escape;
use Cpanel::JSON::XS;

my $json = Cpanel::JSON::XS->new;
$json->allow_bignum(1);
$json->allow_blessed(1);
$json->canonical(0);
$json->pretty(0);
$json->utf8(1);

my $first_doc= 1;
my $more     = 1;
my $HashReply= {};
my $SendData = {};
my $cursor   = undef;
my $response = '';
my $options  = {};
my $url      = '';


    #############
    #  Methods  #
    #############


#   Create new object and provide a connection to the ElasticSearch using varius methods
sub new
{
my $class = shift || __PACKAGE__;
my $self  = {

  host          => '127.0.0.1',
  port          => 9200,
  protocol      => 'https',
  timeout       => 360,
  scroll        => '5m',
  keep_alive    => 1,
  verify_SSL    => 0,
  error         => 0,
  authentication=> 1,
  username      => '',
  password      => '',
  method        => 'GET',
  certca        => undef, # define it if you have self sign certificates
  cert          => undef, # define it if you have Searchguard plugin
  key           => undef, # define it if you have Searchguard plugin
  __this_server => Search::ElasticDirectHttp::HostnameShort(),
  PIT           => 1,
  documents     => 9000,
  index         => '',
  sort          => [],
  path          => '_cat/health',
  param         => '',
  send_data     => '',
  format        => 'data' # json, json_pretty, yaml, txt, data
	};

# Set properties from arguments

  for (my($i,$j)=(0,1); $i < scalar(@_) - (scalar(@_) % 2); $i+=2,$j+=2) {

    if ( exists $self->{$_[$i]} ) {

      if ('_' eq substr $_[$i],0,1) {
      $self->{error} = "Private property \"$_[$i]\" is read only. Valid user properties are : ". join(', ', sort grep ! /^_/, keys %{$self});
      return $self
      }

    $self->{$_[$i]}=$_[$j]
    }
    else {
    $self->{error} = "Invalid property \"$_[$i]\" valid proerties are : ". join(', ', sort grep ! /^_/, keys %{$self});
    return $self
    }
  }

$self->{authentication} = $self->{authentication} =~/(?i)t|y|1/ ? 1:0;
$self->{keep_alive}     = $self->{keep_alive}     =~/(?i)t|y|1/ ? 1:0;
$self->{verify_SSL}     = $self->{verify_SSL}     =~/(?i)t|y|1/ ? 1:0;
$self->{PIT}            = $self->{PIT}            =~/(?i)t|y|1/ ? 1:0;
$self->{protocol}     //= 'https';

if ($self->{timeout} !~/^\d+$/) {$self->{error} = "port ($self->{timeout}) should be an integer\n";      return $self}
if ($self->{port}    !~/^\d+$/) {$self->{error} = "port ($self->{port}) should be an integer\n";         return $self}
if ($self->{port}    > 65535)   {$self->{error} = "port ($self->{port}) should be an less than 65536\n"; return $self}

  if ($self->{authentication}) {
  $self->{username} = URI::Escape::uri_escape( $self->{username} );
  $self->{password} = URI::Escape::uri_escape( $self->{password} );
  }
  else {
  delete $self->{username};
  delete $self->{password}
  }


  if ('https' eq $self->{protocol}) {

    # https searchguard
    if ( (! $self->{authentication}) && (defined $self->{certca}) && (defined $self->{cert}) && (defined $self->{key}) ) {
    unless (-f $self->{certca}) {$self->{error} = "missing ssl certca file $self->{certca}"; return $self}
    unless (-f $self->{cert}  ) {$self->{error} = "missing ssl cart file $self->{cert}";     return $self}
    unless (-f $self->{key}   ) {$self->{error} = "missing ssl key file $self->{key}";       return $self}
    $self->{connect}     = Search::ElasticDirectHttp::HTTP_Tiny_https_certca_cert_key($self->{timeout}, $self->{keep_alive}, $self->{verify_SSL}, $self->{certca}, $self->{cert}, $self->{key});
    $self->{url}         = "https://$self->{host}:$self->{port}";
    $self->{description} = 'SearchGuard, CA certificate, cert admin, key admin'
    }

    # https username, password, certificate. Usually you want this one
    elsif ( ($self->{authentication}) && (defined $self->{certca}) && (defined $self->{username}) && (defined $self->{password}) ) {
    unless (-f $self->{certca}) {$self->{error} = "missing ssl certca file $self->{certca}"; return $self}
    $self->{connect}     = Search::ElasticDirectHttp::HTTP_Tiny_https_certca($self->{timeout}, $self->{keep_alive}, $self->{verify_SSL}, $self->{certca});
    $self->{url}         = "https://$self->{username}:$self->{password}\@$self->{host}:$self->{port}";
    $self->{description} = 'https, CA certificate, username, password';
    $self->{cert}        = undef;
    $self->{key}         = undef
    }

    # https username, password, when you have a signed host certificate
    elsif ( ($self->{authentication}) && (defined $self->{username}) && (defined $self->{password}) ) {
    $self->{connect}     = Search::ElasticDirectHttp::HTTP_Tiny_https($self->{timeout}, $self->{keep_alive}, $self->{verify_SSL});
    $self->{url}         = "https://$self->{username}:$self->{password}\@$self->{host}:$self->{port}";
    $self->{description} = 'https, username, password';
    $self->{certca}      = undef;
    $self->{cert}        = undef;
    $self->{key}         = undef
    }

    else {
    $self->{error} = "uknown $self->{protocol} connection mode";
    return $self
    }
  }
  elsif ('http' eq $self->{protocol}) {

    # http username, password
    if ( ($self->{authentication}) && (defined $self->{username}) && (defined $self->{password}) ) {
    $self->{connect}     = Search::ElasticDirectHttp::HTTP_Tiny_http($self->{timeout}, $self->{keep_alive});
    $self->{url}         = "http://$self->{username}:$self->{password}\@$self->{host}:$self->{port}";
    $self->{description} = 'http, username, password'
    }

    # http
    elsif (! $self->{authentication}) {
    $self->{connect}     = Search::ElasticDirectHttp::HTTP_Tiny_http($self->{timeout}, $self->{keep_alive});
    $self->{url}         = "http://$self->{host}:$self->{port}";
    $self->{description} = 'http';
    }

    else {
    $self->{error} = "unknown $self->{protocol} connection mode";
    return $self
    }
  }

  else {
  $self->{error} = "protocol ( $self->{protocol} ) should be http or https";
  return $self
  }

delete $self->{protocol};
bless $self,$class
}


sub DESTROY {}


#   Auto run when a non existing subroutine is called
sub AUTOLOAD
{
my  $self	= shift;
my  $class	= ref $self || __PACKAGE__;
(my $method	= eval "\$$class\::AUTOLOAD");  # ή πιο απλά $ExampleClass::AUTOLOAD  αλλά θέλουμε να είναι γενικό
my  @Subs;

	foreach ( eval "keys \%$class\::" ) {
	next if ! $class->can($_);
	next if   /^_/;
	next if   $_ eq "\U$_";
	push @Subs, $_
	}

warn "Method $method is missing. Available methods are: ". join(',',@Subs) ."\n";
exit 1
}


sub __NOT_AN_OBJECT
{
my $caller = shift;
print "$caller method did not called as an object. Arguments : ".join(',', @_)."\n";
exit 1
}


#   Returns a copy of an existing object with its properties
sub clone
{
	# clone an existing object
	if ((exists $_[0]) && (__PACKAGE__ eq ref $_[0])) {
	my $obj   = shift;
	my $class = ref $obj;
	my $clone = {};
	foreach (keys %{$obj}) { $clone->{$_} = $obj->{$_} } # Αντιγραφή των ιδιοτήτων
	bless $clone,$class
	}

	# Create new object
	else {
	new(@_)
	}
}


#   TRUE if this server is the Active master otherelse FALSE
sub ActiveMaster
{
my $obj   = ((exists $_[0]) && (__PACKAGE__ eq ref $_[0])) ? shift : __NOT_AN_OBJECT([caller 0]->[3],@_);
$response = $obj->{connect}->request('GET', "$obj->{url}/_cat/nodes?format=json&pretty=false&h=name,master", {headers=> {'Content-Type'=>'application/json'}});
$obj->{error}=0;

  unless ($response->{success}) {
  $obj->{error} = 'method : '. [caller 0]->[3]." , status : $response->{status} , error : $response->{reason} , content : $response->{content}\n";
  return undef
  }

  foreach (grep $_->{master} eq '*', @{ $json->decode($response->{content}) }) {
  return 1 if $_->{name} =~/^$obj->{__this_server}/
  }
0
}


#   pass through the request to elasticsearch
sub direct
{
my $obj = ((exists $_[0]) && (__PACKAGE__ eq ref $_[0])) ? shift : __NOT_AN_OBJECT([caller 0]->[3],@_);
$obj->{error}     = 0;
$obj->{scroll}    = undef;
$obj->{send_data} = '';
$obj->{param}     = '';
$obj->{sort}      = [];

  # Set properties from arguments
  for (my($i,$j)=(0,1); $i < scalar(@_) - (scalar(@_) % 2); $i+=2,$j+=2) {

    if (exists $obj->{$_[$i]}) {
		
      if ('_' eq substr $_[$i],0,1) {
      $obj->{error} = "Private property \"$_[$i]\" is read only. Valid user properties are : ". join(', ', sort grep ! /^(error|_)/, keys %{$obj});
      return undef
      }

    $obj->{$_[$i]}=$_[$j]
    }
    else {
    $obj->{error} = "Invalid property $_[$i] valid properties are : ". join(', ', sort grep ! /^(error|_)/, keys %{$obj});
    return undef
    }
  }

  if ( $obj->{method} !~/(?i)^(GET|DELETE|PUT|POST)$/ ) {
  $obj->{error} = "Unknown request method $obj->{method}";
  return undef
  }

  if ($obj->{send_data}=~/\S/) {
  $options = {content=> $obj->{send_data}, headers=>{charset=>'utf-8', 'Content-Type'=>'application/json'}} 
  }
  else {
  $options = {headers=> {charset=>'utf-8'}};
  }

  if ($obj->{path} eq '') {
  $url = $obj->{url}
  }
  else {
  $obj->{path} =~s/^(?:\/|\\)*(.*?)(?:\/|\\)*$/$1/;
  $url = "$obj->{url}/$obj->{path}";
  $url =~s/[\\\/]*$//
  }

$obj->{param} =~tr/;/&/s;                    # replace old style ; with &
$obj->{param} =~s/format=[^=&]+//g;          # remove format parameter
$obj->{param} =~s/^[\?&]*(.*?)[\?&]*$/$^N/;  # remove ? & from start/end

  if (($obj->{format} eq '')) {
  $obj->{format} = 'data';
  $url .= '?format=json&pretty=false'
  }
  elsif ($obj->{format} =~/json_pretty/i) {
  $url .= '?format=json&pretty=true'
  }
  elsif (($obj->{format} =~/data/i) || ($obj->{format} =~/json/i)) {
  $url .= '?format=json&pretty=false'
  }
  elsif ($obj->{format} eq 'yaml') {$url .= '?format=yaml'}
  elsif ($obj->{format} eq 'csv')  {$url .= '?format=csv'}
  elsif ($obj->{format} eq 'cbor') {$url .= '?format=cbor'}
  elsif ($obj->{format} eq 'smile'){$url .= '?format=smile'}
  else  {$obj->{format} =  'txt';   $url .= '?format=txt'}

$url .= "&$obj->{param}" if $obj->{param} ne '';

#print "path      : $obj->{path}\n";      #exit;
#print "send_data : $obj->{send_data}\n"; #exit;


$response = $obj->{connect}->request("\U$obj->{method}\E", $url, $options);

  unless ($response->{success}) {
  $obj->{error} = 'method : '.[caller 0]->[3]." , status : $response->{status} , error : $response->{reason} , content : $response->{content}";
  return undef
  }

  if (length $response->{content}) {

    if ($obj->{format} eq 'data') {
    $json->decode($response->{content})
    }
    elsif ($obj->{format} eq 'txt') {
    wantarray ? split /\v+/, $response->{content} : $response->{content}
    }
    else {
    $response->{content} # yaml, json, json_prety, 
    }
  }
  else {

    if    ($obj->{format} eq 'data') {{}}
    elsif ($obj->{format}=~/^json/)  {'{}'}
    elsif ($obj->{format} eq 'yaml') {'---'}
    else  {''} # txt
  }
}



#   Deep pagination using the scroll api
#   https://www.elastic.co/guide/en/elasticsearch/reference/current/scroll-api.html
sub DeepPagination_scroll
{
my $obj = ((exists $_[0]) && (__PACKAGE__ eq ref $_[0])) ? shift : __NOT_AN_OBJECT([caller 0]->[3],@_);
$obj->{error}     = 0;
$obj->{format}    = 'data';
$obj->{documents} = 10000;
$obj->{scroll}    = '10m';
$obj->{index}     = undef;
$obj->{send_data} = '{"query":{"match_all":{}}}';
$cursor           = undef;
$first_doc        = 1;
  
  for (my($i,$j)=(0,1); $i < scalar(@_) - (scalar(@_) % 2); $i+=2,$j+=2) {

    if (exists $obj->{$_[$i]}) {
		
      if ('_' eq substr $_[$i],0,1) {
      $obj->{error} = "Private property \"$_[$i]\" is read only. Valid user properties are : ". join(', ', sort grep ! /^(error|_)/, keys %{$obj});
      return undef
      }

    $obj->{$_[$i]}=$_[$j]
    }
    else {
    $obj->{error} = "Invalid property $_[$i] valid properties are : ". join(', ', sort grep ! /^(error|_)/, keys %{$obj});
    return undef
    }
  }

# Change the "size" at send_data by decompile and recompile the send text formatted as json
$HashReply         = $json->decode($obj->{send_data});
$HashReply->{size} = $obj->{documents};
$obj->{send_data}  = $json->encode($HashReply);
$HashReply         = {};
$obj->{scroll}   //= '10m';
$url               = "$obj->{url}/$obj->{index}/_search?scroll=$obj->{scroll}";
$options           = {content=> $obj->{send_data}, headers=> {charset=>'utf-8', 'Content-Type'=>'application/json'}};

  if   (($obj->{format} eq 'data') || ($obj->{format} eq 'json')) {$url .= '&format=json&pretty=false'}
  elsif ($obj->{format} eq 'json_pretty')                         {$url .= '&format=json&pretty=true'}
  elsif ($obj->{format} eq 'yaml')                                {$url .= '&format=yaml'}
  else  {$obj->{error} = "Format $obj->{format} is not one of choose data, yaml, json, json_pretty"; return undef}


  # return the scroll iterator
  sub {
  $response = $obj->{connect}->request('GET', $url, $options);
  CORE::die "method : iterator_scroll , status : $response->{status} , error : $response->{reason} , content : $response->{content}\n" unless $response->{success};

    # If there are more data
    if (($obj->{format} eq 'data') || ($obj->{format} =~/json/)) {
    $HashReply= $json->decode($response->{content});
    $more     = @{$HashReply->{hits}->{hits}} ? 1:0  # go for more if not empty
    }
    elsif ($obj->{format} eq 'yaml') {
    $more = $response->{content} =~/  hits:\s*\[\]/m ? 0:1
    }


    # run once, at the first result, to change the url path
    if ($first_doc) {

      if   (($obj->{format} eq 'data') || ($obj->{format} eq 'json')) {
      $cursor = $HashReply->{_scroll_id};
      $url    = "$obj->{url}/_search/scroll?format=json&pretty=false"
      }
      elsif ($obj->{format} eq 'json_pretty') {
      $cursor = $HashReply->{_scroll_id};
      $url    = "$obj->{url}/_search/scroll?format=json&pretty=true"
      }
      elsif ($obj->{format} eq 'yaml') {
      $url = "$obj->{url}/_search/scroll?format=yaml";

        if ( $response->{content} =~/_scroll_id:\s*"([^"]+)"/m ) {
        $cursor = $^N
        }
        else {
        CORE::die "Could not extract _scroll_id from yaml formatted reply\n$response->{content}\n"
        }
      }

    $options->{content} = "{\"scroll_id\":\"$cursor\",\"scroll\":\"$obj->{scroll}\"}";
    $first_doc=0
    }

    if ($more) {

        if ($obj->{format} eq 'data') {
        $HashReply->{hits}->{hits}
        }
        else {
        $response->{content}
        }
    }
    else {
    # All data retrieved, lets clear the scroll_id
    $response = $obj->{connect}->request('DELETE', "$obj->{url}/_search/scroll", {content=> "{\"scroll_id\":\"$cursor\"}", headers=> {'Content-Type'=>'application/json'}});
    unless ($response->{success}) { $obj->{error} = "method : clear_scroll_id , status : $response->{status} , error : $response->{reason} , content : $response->{content}"; return undef}
    undef
    }
  }
}



#   Deep pagination using the search_after
#   https://www.elastic.co/guide/en/elasticsearch/reference/current/paginate-search-results.html
sub DeepPagination_search_after
{
my $obj = ((exists $_[0]) && (__PACKAGE__ eq ref $_[0])) ? shift : __NOT_AN_OBJECT([caller 0]->[3],@_);
$obj->{error}     = 0;
$obj->{index}     = undef;
$obj->{PIT}       = 0;
$obj->{keep_alive}= '5m';
$obj->{documents} = 10000;
$obj->{sort}      = [ {'@timestamp' => {order => 'asc'}} ];
$obj->{send_data} = '{"query":{"match_all":{}}}';

  for (my($i,$j)=(0,1); $i < scalar(@_) - (scalar(@_) % 2); $i+=2,$j+=2) {

    if (exists $obj->{$_[$i]}) {

      if ('_' eq substr $_[$i],0,1) {
      $obj->{error} = "Private property \"$_[$i]\" is read only. Valid user properties are : ". join(', ', sort grep ! /^(error|_)/, keys %{$obj});
      return undef
      }

    $obj->{$_[$i]}=$_[$j]
    }
    else {
    $obj->{error} = "Invalid property $_[$i] valid properties are : ". join(', ', sort grep ! /^(error|_)/, keys %{$obj});
    return undef
    }
  }

# Define the PIT, sort, size,  and change the "size" by decompiling the send_data 
$obj->{PIT}       = $obj->{PIT} =~/(?i)t|y|1/ ? 1:0;
$SendData         = $json->decode($obj->{send_data});
$SendData->{from} = 0;
$SendData->{size} = $obj->{documents};
$SendData->{sort} = $obj->{sort};

  # if using PIT (Point In Time) we must create it at the index
  if ($obj->{PIT}) {
  $response = $obj->{connect}->request('POST', "$obj->{url}/$obj->{index}/_pit?format=json&pretty=false&keep_alive=$obj->{keep_alive}");
  unless ($response->{success}) {CORE::die 'method : '. [caller 0]->[3]." , status : $response->{status} , error : $response->{reason} , content : $response->{content}\n"; return undef}
  $SendData->{pit} = { keep_alive => $obj->{keep_alive}, id => $json->decode($response->{content})->{id} };
  $url = "$obj->{url}/_search?format=json&pretty=false" # do not use the index
  }
  else {
  $url = "$obj->{url}/$obj->{index}/_search?format=json&pretty=false"
  }

$options = {content=> $json->encode($SendData), headers=> {charset=> 'utf-8', 'Content-Type'=> 'application/json'}};

  # return the search_after iterator
  sub {
  $response = $obj->{connect}->request('GET', $url, $options);
  CORE::die "method : iterator_search_after , status : $response->{status} , error : $response->{reason} , content : $response->{content}\n" unless $response->{success};
  $HashReply = $json->decode($response->{content});

    if (@{$HashReply->{hits}->{hits}}) {
    # use Data::Dumper; $Data::Dumper::Terse=1; $Data::Dumper::Indent=1; print Dumper $HashReply->{hits}->{hits};
    # grab the "sort" from the LAST [-1] document and with that update the search_after
    $SendData->{search_after} = $HashReply->{hits}->{hits}->[-1]->{sort};
    $options->{content}       = $json->encode($SendData); #use Data::Dumper; $Data::Dumper::Terse=1; $Data::Dumper::Indent=1; print Dumper $options;

    $HashReply->{hits}->{hits}
    }
    else {
    # All data retrieved, clear the PIT if used

      if ($obj->{PIT}) {
      $response = $obj->{connect}->request('DELETE', "$obj->{url}/_pit", {content=> "{\"id\":\"$SendData->{pit}->{id}\"}", headers=> {'Content-Type'=>'application/json'}});
      unless ($response->{success}) { $obj->{error} = "method : clear_PIT , status : $response->{status} , error : $response->{reason} , content : $response->{content}" }
      }

    undef
    }
  }
}


#   Deep pagination for SQL syntax using the cusror
#   https://www.elastic.co/guide/en/elasticsearch/reference/current/sql-pagination.html
sub DeepPagination_sql
{
my $obj = ((exists $_[0]) && (__PACKAGE__ eq ref $_[0])) ? shift : __NOT_AN_OBJECT([caller 0]->[3],@_);
$obj->{error}     = 0;
$obj->{documents} = 9000;
$url = "$obj->{url}/_sql";
$first_doc = 1;

  for (my($i,$j)=(0,1); $i < scalar(@_) - (scalar(@_) % 2); $i+=2,$j+=2) {

    if (exists $obj->{$_[$i]}) {

      if ('_' eq substr $_[$i],0,1) {
      $obj->{error} = "Private property \"$_[$i]\" is read only. Valid user properties are : ". join(', ', sort grep ! /^(error|_)/, keys %{$obj});
      return undef
      }

    $obj->{$_[$i]}=$_[$j]
    }
    else {
    $obj->{error} = "Invalid property $_[$i] valid properties are : ". join(', ', sort grep ! /^(error|_)/, keys %{$obj});
    return undef
    }
  }

$SendData = $json->decode($obj->{send_data});
$SendData->{fetch_size} = $obj->{documents} unless exists $SendData->{fetch_size};
if (! exists $SendData->{query}) {$obj->{error} = 'You have not define the query'; return undef}
$options = {content=> $json->encode($SendData), headers=> {charset=> 'utf-8', 'Content-Type'=> 'application/json'}};

$obj->{param} =~s/format=[^=&]+//g;          # remove format parameter
$obj->{param} =~s/^[\?&]*(.*?)[\?&]*$/$^N/;  # remove ? & from start/end

  if (($obj->{format} eq '')) {
  $obj->{format} = 'data';
  $url .= '?format=json&pretty=false'
  }
  elsif ($obj->{format} =~/json_pretty/i) {
  $url .= '?format=json&pretty=true'
  }
  elsif (($obj->{format} =~/data/i) || ($obj->{format} =~/json/i)) {
  $url .= '?format=json&pretty=false'
  }
  elsif ($obj->{format} eq 'yaml') {$url .= '?format=yaml'}
  elsif ($obj->{format} eq 'cbor') {$url .= '?format=cbor'}
  elsif ($obj->{format} eq 'smile'){$url .= '?format=smile'}
  elsif ($obj->{format} eq 'csv')  {$url .= '?format=csv'}
  else  {$obj->{format} =  'txt';   $url .= '?format=txt'}

$url .= "&$obj->{param}" if $obj->{param} ne '';


  # return the cursor iterator
  sub {
  $response = $obj->{connect}->request('POST', $url, $options);
  CORE::die "method : iterator_search_after , status : $response->{status} , error : $response->{reason} , content : $response->{content}\n" unless $response->{success};
  $cursor=undef;

    # read the cursor at every possible fommat, well almost except the cbor,smile
    if (($obj->{format} eq 'csv') || ($obj->{format} eq 'txt')) {

      if (exists $response->{headers}->{cursor}) {
      $cursor = $response->{headers}->{cursor}
      }
    }
    elsif (($obj->{format} eq 'data') || ($obj->{format} =~/json/)) {
    $HashReply = $json->decode($response->{content});

      if (exists $HashReply->{cursor}) {
      $cursor =  $HashReply->{cursor};
      delete     $HashReply->{cursor}
      }
    }
    elsif ($obj->{format} eq 'yaml') {

      if ( $response->{content} =~/cursor: "([^"]+)"/m ) {
      $cursor = $^N
      }
    }

    if ($first_doc) {
    $first_doc=0;

        if (defined $cursor) {
        $options->{content} = "{\"cursor\":\"$cursor\"}" 
        }

    $obj->{format} eq 'data' ? $HashReply : $response->{content}
    }
    else {

      if (defined $cursor) {
      $obj->{format} eq 'data' ? $HashReply : $response->{content}
      }
      else {
      undef
      }
    }
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::ElasticDirect - An interface to ElasticSearch API, version independent

=head1 VERSION

version 2.5.1

=head1 SYNOPSIS

  use Search::ElasticDirect;

  my $elk = Search::ElasticDirect->new( host=> 'SomeServer',  protocol=> 'http', authentication=> 'no' );
  die "Connection error because $elk->{error}\n" if $elk->{error};

  my $reply = $elk->direct( method=>'GET', path=>'_cat/nodes', param=>'h=name,ip,role,version&s=name:asc', format=>'data' );
  die "$elk->{error}\n" if $elk->{error};

  die "Allowed to run only at active master\n" unless $elk->ActiveMaster;
  die $elk->{error} if $elk->{error};

  foreach my $srv (@{$reply}) {
  say join ',', $srv->{name}, $srv->{ip}, $srv->{version}, $srv->{role}
  }

=head1 DESCRIPTION

An interface to ElasticSearch API, version independent

The DeepPagination methods are added to help with complexity of the scroll/cursor/search_after APIs

=head1 ERRORS

Check for errors the property  $obj->{error} . if everything is ok it is B<FALSE>

=head1 METHODS

=head2 new

Create a new ElasticDirect object and define the connection parameters to the elasticsearch cluster. 

=head3 https, username, password, CA certificate

Most of the times you will use this one

  my $elk = Search::ElasticDirect->new(
  
    host           => 'SomeServer',
    port           => 9200,
    protocol       => 'https',
    timeout        => 1800,
    keep_alive     => 'yes',
    authentication => 'yes',
    username       => 'Joe',
    password       => 'JoePass',
    certca         => '/etc/elasticsearch/chain.pem',
    verify_SSL     => 'no' );
  
  die $elk->{error} if $elk->{error};

=head3 https, CA certificate, server key, server certificate

If you are using the B<SearchGuard> security plugin and you need node admin key/cert without username and password to perform admin tasks e.g. to delete an immutable index

  my $elk = Search::ElasticDirect->new(
  
    host           => 'SomeServer',
    port           => 9200,
    protocol       => 'https',
    timeout        => 1800,
    keep_alive     => 'yes',
    authentication => 'no',
    certca         => '/etc/elasticsearch/chain.pem',
    cert           => '/etc/elasticsearch/SomeServer.pem',
    key            => '/etc/elasticsearch/SomeServer.key',  
    verify_SSL     =>'no' );
  
  die $elk->{error} if $elk->{error};

=head3 https, username, password

Without certificate

  my $elk = Search::ElasticDirect->new(
  
    host           => 'SomeServer',
    port           => 9200,
    protocol       => 'https',
    timeout        => 1800,
    keep_alive     => 'yes',
    authentication => 'yes',
    username       => 'Joe',
    password       => 'JoePass' );
  
  die $elk->{error} if $elk->{error};

=head3 http, username, password

Plain text with authentication

  my $elk = Search::ElasticDirect->new(

    host           => 'SomeServer',
    port           => 9200,
    protocol       => 'http',
    timeout        => 1800,
    keep_alive     => 'yes',
    authentication => 'yes',
    username       => 'Joe',
    password       => 'SomePass' );

  die $elk->{error} if $elk->{error};

=head3 http

Plain text without authentication

  my $elk = Search::ElasticDirect->new(

    host           => 'SomeServer',
    port           => 9200,
    protocol       => 'http',
    timeout        => 1800,
    keep_alive     => 'yes',
    authentication => 'no' );

  die $elk->{error} if $elk->{error};

=head2 ActiveMaster

If you have schedule your script at multiple servers for high availability but it must run once at active master server

  my  $obj = Search::ElasticDirect->new(...);
  die $elk->{error} if $elk->{error};

  die "Allowed to run only at active master\n" unless $elk->ActiveMaster;
  die $elk->{error} if $elk->{error};

=head2 direct

Pass through the request to ElasticSeach API transparent without much validation, so you must know the correct syntax and parameters of the API/path you are calling

You can receive the result at the format  B<data>, B<yaml>, B<json>, B<json_pretty>, B<txt>

The data format returns a Perl data structure e.g. hash or array, while the other are text formatted as defined

Examples

=head3 Health as yaml

  my $reply = $elk->direct(method=>'GET', path=>'_cat/health', param=>'filter_path=status', format=>'yaml');
  die $elk->{error} if $elk->{error};
  say $reply

=head3 Health as human readable json

  $elk->direct(method=>'GET', path=>'_cat/health', param=>'filter_path=status', format=>'json_pretty');

=head3 Health as data; no filter_path is required with data

  $reply = $elk->direct(method=>'GET', path=>'_cat/health', format=>'data');
  say $reply->[0]->{status};

=head3 Indicies sorted

  $reply = $elk->direct(method=>'GET', path=>'_cat/indices', param=>'h=index,health,docs.count,store.size&bytes=g&s=index:asc', format=>'data');
  die $elk->{error} if $elk->{error};

  foreach ( @{ $reply } ) {
  say "$_->{index}, $_->{health}, $_->{'docs.count'}, $_->{'store.size'}"
  }

=head3 DSL query

  $reply    = $elk->direct(
  method    => 'GET',
  path      => 'foo/_search',
  format    => 'data',
  send_data => '{"size": 2, "query": {"range": {"@timestamp": {"from": "1970-01-01T00:00:00.000Z", "to": "2036-01-03T23:59:59.999Z"}}}}'
  );

  die $elk->{error} if $elk->{error};

  foreach ( @{ $reply->{hits}->{hits} } ) {
  say say "$_->{_source}->{'@timestamp'} , $_->{_source}->{id}"
  }

=head3 SQL query

format can be here B<data>, B<txt>, B<csv>, B<yaml>, B<json>, B<json_pretty>, B<cbor>, B<smile>

  $reply = $elk->direct(
  method    => 'POST',
  path      => '_sql',
  format    => 'data',
  send_data => "{\"query\": \"SELECT * FROM foo WHERE id >= '01' ORDER BY id DESC LIMIT 100\"}"
  );

  die $elk->{error} if $elk->{error};

  if ($elk->{format} eq 'data') {
  
    foreach ( @{$reply->{rows}} ) {
    say join ' , ', @{$_}
    }
  }
  else {
  say $reply
  }

=head2 DeepPagination_scroll

Retrieve massive amount of results using the B<scroll> API

documents here is how many records to fetch per iteration

format can be B<data>, B<yaml>, B<json> or B<json_pretty>

  my $iterator = $elk->DeepPagination_scroll(
  index     => 'foo',
  documents => 9000,
  format    => 'data',
  send_data => '{"query": {"range": {"@timestamp": {"from": "1970-01-01T00:00:00.000Z", "to": "2036-01-03T23:59:59.999Z"}}}}',
  scroll    => '10m'
  );

  die $elk->{error} if $elk->{error};

  while (my $Documents = $iterator->()) {

    if ($elk->{format} eq 'data') {

      foreach my $doc (@{$Documents}) {
    
        foreach my $key (sort keys %{$doc->{_source}}) {
        say "$key : $doc->{_source}->{$key}";
        }
      }
    }
    else {
    say $Documents
    }
  }

=head2 DeepPagination_search_after

Retrieve massive amount of results using the B<search_after> API

If you choose to use the PIT (point in time) it will created automatic for you

documents here is how many records to fetch per iteration

At sort, define as less fields you can that produce a unique combination. The fields must be sortable reasonable.

  my $iterator = $elk->DeepPagination_search_after(
  index     => 'foo',
  PIT       => 'yes',
  keep_alive=> '10m',
  documents => 9000,
  send_data => '{ "query": {"range": {"@timestamp": {"from": "1970-01-01T00:00:00.000Z", "to": "2036-01-03T23:59:59.999Z"}}} }',
  sort      => [ {'@timestamp'=> {order=> 'asc', format=> "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"}} , {id=>'asc'} ],
  );

  while (my $Documents = $iterator->()) {

    foreach my $doc (@{$Documents}) {
  
      foreach my $key (sort keys %{$doc->{_source}}) {
      say "$key : $doc->{_source}->{$key}"
      }
    }
  }

=head2 DeepPagination_sql

Retrieve massive amount of results using the B<sql> API

documents here is how many records to fetch per iteration

format can be B<data>, B<csv>, B<txt>, B<yaml>, B<json>, B<json_pretty>, B<cbor>, B<smile>

  my $iterator = $elk->DeepPagination_sql(
  documents => 100,
  format    => 'data',
  send_data => '{ "query": "SELECT * FROM foo ORDER BY id DESC" }'
  );

  die $elk->{error} if $elk->{error};

  while (my $Documents = $iterator->()) {

    if ($elk->{format} eq 'data') {
    use Data::Dumper; say Dumper $Documents
    }
    else {
    print $Documents
    }
  }

=head1 SEE OTHER

B<Search::Elasticsearch> The official client for Elasticsearch

B<Dancer2::Plugin::ElasticSearch> ElasticSearch wrapper for Dancer

=head1 SUPPORT

Any ideas or contributors are welcome

=cut

=head1 AUTHOR

George Bouras <george.mpouras@yandex.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by George Bouras.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
