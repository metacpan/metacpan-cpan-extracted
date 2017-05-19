package Mojo::CloudCheckr;
use Mojo::Base -base;

our $VERSION = '0.01';

use Mojo::UserAgent;

has access_key => sub { die 'missing access_key' };
has base_url   => 'https://api.cloudcheckr.com/api';
has format     => 'json';
has _ua        => sub { Mojo::UserAgent->new };

sub get {
  my ($self, $cb) = (shift, ref $_[-1] eq 'CODE' ? pop @_ : ());
  my ($controller, $action) = (shift, shift);
  my $args = @_ % 2 == 0 ? {@_} : shift;
  if ( $cb ) {
    $self->_ua->get($self->_url($controller, $action) => form => $args => sub {
      my ($ua, $tx) = @_;
      $tx->req->params->remove('access_key');
      $cb->($ua, $tx);
    });
  } else {
    my $tx = $self->_ua->get($self->_url($controller, $action) => form => $args);
    $tx->req->params->remove('access_key');
    return $tx;
  }
}

sub _url {
  my ($self, $controller, $action) = @_;
  my $format = $self->format;
  my $url = Mojo::URL->new($self->base_url);
  push @{$url->path->parts}, "$controller.$format", $action;
  $url->query(access_key => $self->access_key);
  return $url;
}

1;

=encoding utf8

=head1 NAME

Mojo::CloudCheckr - A simple interface to the CloudCheckr API

=head1 SYNOPSIS

  use Mojo::CloudCheckr;

  my $cc = Mojo::CloudCheckr->new(access_key => '...');
  say $cc->get(account => 'get_accounts_v2')->result->json('/accounts_and_users/0/account_name');
  
=head1 DESCRIPTION

A simple interface to the CloudCheckr API.

Currently only a single L<get> method is available, and it offers no data
validation or error handling. No built-in support for paging. No support for
POST queries (GET only).  Pull requests welcome!

The API user guide is available at L<http://support.cloudcheckr.com/cloudcheckr-api-userguide/>
The API reference guide is available at L<http://support.cloudcheckr.com/cloudcheckr-api-userguide/cloudcheckr-api-reference-guide/>
The API admin reference guide is available at L<http://support.cloudcheckr.com/cloudcheckr-api-userguide/cloudcheckr-admin-api-reference-guide/>
The API inventory guide is available at L<http://support.cloudcheckr.com/api-reference-guide-inventory/>

So what does this module do? It makes building the API URL easier and includes
the access key on all requests. It then removes the access key from the request
message of the returned transaction. So, not much. But it does offer a little
bit of sugar, and, hopefully eventually, some data validation, error handling,
built-in support for paging, and POST queries.

=head1 ATTRIBUTES

L<Mojo::CloudCheckr> implements the following attributes.

=head2 access_key

  my $access_key = $cc->access_key;
  $cc            = $cc->access_key($key);

The access_key for your CloudCheckr API.  Learn more at L<http://support.cloudcheckr.com/cloudcheckr-api-userguide/>

=head2 base_url

  my $base_url = $cc->base_url;
  $cc          = $cc->base_url($url);

The base URL for the CloudCheckr API, defaults to https://api.cloudcheckr.com/api.

=head2 format

  my $format = $cc->format;
  $cc        = $cc->format($format);

The response format from the CloudCheckr API, defaults to json.

  # Set the format to XML
  $cc->format('xml');

=head1 METHODS

L<Mojo::CloudCheckr> inherits all methods from L<Mojo::Base> and implements the
following new ones.

=head2 get

  # Blocking
  my $tx = $cc->get(controller => 'action', %args);
  say $tx->result->body;
  
  # Non-blocking
  $cc->get(controller => 'action', %args => sub {
    my ($ua, $tx) = @_;
    say $tx->result->body;
  });

All CloudCheckr API calls have a controller (or category) and an action (or
task). Each of these is required for L<get> and is defined in the API
reference docs. If a callback is provided, it will process the request non-
blocking. The access_key parameter will be removed from the request in the
returned transaction (so that the arguments that were used to generate the
response can be dumped without the need to hide this private key.)

=head1 SEE ALSO

L<http://cloudcheckr.com>

=cut
