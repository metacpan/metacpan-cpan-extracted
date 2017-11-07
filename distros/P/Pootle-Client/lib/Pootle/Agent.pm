# Copyright (C) 2017 Koha-Suomi
#
# This file is part of Pootle-Client.

package Pootle::Agent;

use Modern::Perl '2015';
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
use feature 'signatures'; no warnings "experimental::signatures";
use Carp::Always;
use Try::Tiny;
use Scalar::Util qw(blessed);

=head2 Pootle::Agent

LWP::Curl wrapper to deal with various types of exceptions transparently

=cut

use Params::Validate qw(:all);
use LWP::UserAgent;
use Encode;
use MIME::Base64;
use JSON::XS;
use File::Slurp;

use Pootle::Logger;
my $l = bless({}, 'Pootle::Logger'); #Lazy load package logger this way to avoid circular dependency issues with logger includes from many packages

use Pootle::Exception;
use Pootle::Exception::HTTP::MethodNotAllowed;
use Pootle::Exception::HTTP::NotFound;
use Pootle::Exception::Credentials;

sub new($class, @params) {
  $l->debug("Initializing '$class' with parameters: ".$l->flatten(@params)) if $l->is_debug();
  my %self = validate(@params, {
    baseUrl => 1,
    credentials => 1,
  });
  my $s = bless(\%self, $class);

  $s->{credentials} = $s->_loadCredentials();

  $s->{ua} = LWP::UserAgent->new(
    default_headers => HTTP::Headers->new(Authorization => $s->_authorization()),
  );

  return $s;
}

=head2 _authorization

 @RETURNS HTTP Basic authorization header content, eg. 'Basic QWxhZGRpbjpPcGVuU2VzYW1l'

=cut

sub _authorization($s) {
  return 'Basic '.MIME::Base64::encode(Encode::encode('UTF-8', $s->credentials()), ''); #Turn $credentials into a byte/octet stream, and encode that as base64, with no eol
}

=head2 request

Make requests and deal with logging and error handling

 @RETURNS List of 0 - HTTP::Response
                  1 - HASHRef of response JSON payload
 @THROWS Pootle::Exception::HTTP::MethodNotAllowed endpoint doesn't support the given method
 @THROWS Pootle::Exception::HTTP::NotFound endpoint not found?

=cut

sub request($s, $verb, $apiUrl, $params) {
  my $response = $s->ua->$verb($s->baseUrl.'/'.$apiUrl);
  my $contentHash;
  try {
    $contentHash = $s->_getContent($response);
    $l->trace("\$response: ".$s->_httpResponseToLoggableFromSuccess($response, $contentHash)) if $l->is_trace();
  } catch {
    if ($_ =~ /^malformed JSON string/) { #Presumably this is a JSON::XS issue
      my $errorStr = $s->_httpResponseToLoggableFromFail($response);
      $l->trace("\$response: ".$errorStr) if $l->is_trace();
      Pootle::Exception::HTTP::MethodNotAllowed->throw(error => $errorStr) if $errorStr =~ /405 METHOD NOT ALLOWED$/sm;
      Pootle::Exception::HTTP::NotFound->throw(error => $errorStr) if $errorStr =~ /404 Not Found$/sm;
      Pootle::Exception::rethrowDefaults($errorStr);
    }
    Pootle::Exception::rethrowDefaults($_);
  };
  return ($response, $contentHash);
}

=head2 _getContent

 @RETURNS HASHRef, Content's JSON payload decoded to Perl's internal UTF-8 representation

=cut

sub _getContent($s, $response) {
  my $content = $response->content();
  return JSON::XS->new->utf8->decode($content);
}

sub _httpResponseToLoggableFromSuccess($s, $response, $contentHash) {
  return join("\n",
              $s->_httpResponseToLoggableHeader($response),
              scalar(Data::Dumper->new([$contentHash],[])->Terse(1)->Indent(1)->Varname('')->Maxdepth(0)->Sortkeys(1)->Quotekeys(1)->Dump()),
  );
}

sub _httpResponseToLoggableFromFail($s, $response) {
  return join("\n",
              $s->_httpResponseToLoggableHeader($response),
              $response->content(),
  );
}

sub _httpResponseToLoggableHeader($s, $response) {
  my $status_line = $response->status_line;
  my $proto = $response->protocol;
  $status_line = "$proto $status_line" if $proto;
  return join("\n", $status_line, $response->headers_as_string("\n"),''); #Includes empty line to signal the start of HTTP payload
}

sub _loadCredentials($s) {
  my $c = $s->credentials();
  my $credentialsConfirmed;
  my $file;
  if (-e $c) { #This is a file
    $file = $c;
    $l->info("Loading credentials from file '$c'");
    my @rows = File::Slurp::read_file( $c => { binmode => ':encoding(UTF-8)' } );
    foreach my $row (@rows) {
      if ($row =~ /^(.+):(.+)$/) {
        $credentialsConfirmed = "$1:$2";
      }
      last;
    }
  }
  else {
    $credentialsConfirmed = $c;
  }

  unless ($credentialsConfirmed && $credentialsConfirmed =~ /^(.+):(.+)$/) {
    Pootle::Exception::Credentials->throw(error => "_loadCredentials():> Given credentials ".($file ? "from file '$file' " : "")."are malformed. Credentials must look like username:password, or point to a file with properly formatted credentials.");
  }
  return $credentialsConfirmed;
}

##########    ###   ###
 ## ACCESSORS  ###   ###
##########    ###   ###

=head2 baseUrl

 @RETURNS String, the full url of the Pootle server we are interfacing with, eg. https://translate.koha-community.org

=cut

sub baseUrl($s) {
  return $s->{baseUrl};
}

=head2 credentials

 @RETURNS String, username:password

=cut

sub credentials($s) {
  return $s->{credentials};
}

=head2 ua

 @RETURNS L<LWP::UserAgent>

=cut

sub ua($s) { return $s->{ua} }

1;
