## @file
# (Enter your file info here)
# 
# $Id: S3.pm 432 2008-05-02 19:17:09Z damjan $

# sample usage:
# my $response;
# my $s3 = RWDE::DB::S3->new($AWS_ACCESS_KEY_ID, $AWS_SECRET_ACCESS_KEY);
# $response = $s3->createBucket($BUCKET_NAME);
# $response = $s3->putObject($BUCKET_NAME, $KEY_NAME, 'text/plain', 'file data string');
# $response = $s3->getObject($BUCKET_NAME, $KEY_NAME);
# print "response: -".$response->content."-\n";
# $response = $s3->deleteObject($BUCKET_NAME, $KEY_NAME);
# $response = $s3->deleteBucket($BUCKET_NAME);

## @class RWDE::DB::S3
# (Enter RWDE::DB::S3 info here)
package RWDE::DB::S3;

use strict;
use warnings;

use Error qw(:try);
use RWDE::Exceptions;

use Data::Dumper;
use LWP::UserAgent;
use Digest::HMAC_SHA1;
use HTTP::Date;
use MIME::Base64 qw(encode_base64);

use RWDE::Configuration; 

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 508 $ =~ /(\d+)/;

## @cmethod object new()
# (Enter new info here)
# @return (Enter explanation for return value here)
sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = {};
  $self->{AWS_ACCESS_KEY_ID}     = RWDE::Configuration->AccessKeyID;
  $self->{AWS_SECRET_ACCESS_KEY} = RWDE::Configuration->SecretAccessKey;
  $self->{AGENT} = LWP::UserAgent->new();
  bless($self, $class);
  return $self;
}

## @method object setACL()
# (Enter setACL info here)
# @return (Enter explanation for return value here)
sub setACL {
  my ($self, $bucketName, $keyName, $acl) = @_;
	my $xml_acl = ''; #replace with xml data string
  return $self->_create_message('PUT', "$bucketName/$keyName?acl", {}, $xml_acl);
}

## @method object listBucket()
# (Enter listBucket info here)
# @return (Enter explanation for return value here)
sub listBucket {
  my ($self, $bucketName) = @_;
	#options can be added to the path here, $bucketName?...
  return $self->_create_message('GET', $bucketName);
}

## @method object createBucket()
# (Enter createBucket info here)
# @return (Enter explanation for return value here)
sub createBucket {
  my ($self, $bucketName) = @_;
  return $self->_create_message('PUT', $bucketName);
}

## @method object deleteBucket()
# (Enter deleteBucket info here)
# @return (Enter explanation for return value here)
sub deleteBucket {
  my ($self, $bucketName) = @_;
  return $self->_create_message('DELETE', $bucketName);
}

## @method object putObject()
# (Enter putObject info here)
# @return (Enter explanation for return value here)
sub putObject {
  my ($self, $bucketName, $keyName, $contentType, $data, $acl) = @_;
	$acl ||= 'public-read';
  return $self->_create_message('PUT', "$bucketName/$keyName", { "Content-Type" => $contentType }, $data, $acl);
}

## @method object getObject()
# (Enter getObject info here)
# @return (Enter explanation for return value here)
sub getObject {
  my ($self, $bucketName, $keyName) = @_;
  return $self->_create_message('GET', "$bucketName/$keyName");
}

## @method object deleteObject()
# (Enter deleteObject info here)
# @return (Enter explanation for return value here)
sub deleteObject {
  my ($self, $bucketName, $keyName) = @_;
  return $self->_create_message('DELETE', "$bucketName/$keyName");
}


## @method protected object _create_message()
# (Enter _create_message info here)
# @return (Enter explanation for return value here)
sub _create_message {
  my ($self, $method, $path, $headers, $data, $acl) = @_;
  $headers	||= {};
  $data			||= '';
	# $acl			||= 'public-read';

  # add any headers we were given to our header object
  my $http_header = HTTP::Headers->new;
  while (my ($k, $v) = each %$headers) {
    $http_header->header($k => $v);
  }

  # header must have a date, add if it we don't have one yet
  if (not $http_header->header('Date')) {
    $http_header->header(Date => time2str(time));
  }

  #Make the objects readable
	if(defined($acl)) {
  	$http_header->header('x-amz-acl' => $acl);
	}

  # add content length header
  if (length($data) > 0) {
    $http_header->header('content-length' => length($data));
  }

  # hash our request with our secret access key so amazon knows we're legit
  my $canonical_string = canonical_string($method, $path, $http_header);
  my $hmac = Digest::HMAC_SHA1->new($self->{AWS_SECRET_ACCESS_KEY});
  $hmac->add($canonical_string);
  my $signature = encode_base64($hmac->digest, '');
  $http_header->header(Authorization => "AWS $self->{AWS_ACCESS_KEY_ID}:$signature");

  # create the actual request
  my $url = "https://s3.amazonaws.com:443/$path";
  my $request = HTTP::Request->new($method, $url, $http_header);
  $request->content($data);

  # adios, bon voyage
  my $response = $self->{AGENT}->request($request);
  throw RWDE::DataBadException({ info => $response->content }) unless $response->is_success;

  return $response;
}

## @method object trim()
# (Enter trim info here)
# @return (Enter explanation for return value here)
sub trim {
  my ($value) = @_;

  $value =~ s/^\s+//;
  $value =~ s/\s+$//;
  return $value;
}

## @method object canonical_string()
# (Enter canonical_string info here)
# @return (Enter explanation for return value here)
sub canonical_string {
  my ($method, $path, $headers, $expires) = @_;
  my %interesting_headers = ();
  while (my ($key, $value) = each %$headers) {
    my $lk = lc $key;
    if ( $lk eq 'content-md5'
      or $lk eq 'content-type'
      or $lk eq 'date'
      or $lk =~ /^x-amz-/) {
      $interesting_headers{$lk} = trim($value);
    }
  }

  # these keys get empty strings if they don't exist
  $interesting_headers{'content-type'} ||= '';
  $interesting_headers{'content-md5'}  ||= '';

  # just in case someone used this.  it's not necessary in this lib.
  $interesting_headers{'date'} = '' if $interesting_headers{'x-amz-date'};

  # if you're using expires for query string auth, then it trumps date
  # (and x-amz-date)
  $interesting_headers{'date'} = $expires if $expires;

  my $buf = "$method\n";
  foreach my $key (sort keys %interesting_headers) {
    if ($key =~ /^x-amz-/) {
      $buf .= "$key:$interesting_headers{$key}\n";
    }
    else {
      $buf .= "$interesting_headers{$key}\n";
    }
  }

  # don't include anything after the first ? in the resource...
  $path =~ /^([^?]*)/;
  $buf .= "/$1";

  # ...unless there is an acl or torrent parameter
  if ($path =~ /[&?]acl($|=|&)/) {
    $buf .= '?acl';
  }
  elsif ($path =~ /[&?]torrent($|=|&)/) {
    $buf .= '?torrent';
  }
  elsif ($path =~ /[&?]logging($|=|&)/) {
    $buf .= '?logging';
  }

  return $buf;
}

1;

