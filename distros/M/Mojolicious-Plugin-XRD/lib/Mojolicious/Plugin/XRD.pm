package Mojolicious::Plugin::XRD;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Util qw/quote deprecated/;

our $VERSION = '0.21';

# Todo: Support
#  $self->reply->xrd( $xrd => {
#    resource => 'acct:akron@sojolicio.us',
#    expires  => (30 * 24 * 60 * 60),
#    cache    => ...,
#    chi      => ...
#  });
#
# - Add Acceptance for XRD and JRD and JSON as a header

# UserAgent name
my $UA_NAME = __PACKAGE__ . ' v' . $VERSION;

# UserAgent maximum redirects
my $UA_MAX_REDIRECTS   = 10;

# UserAgent connect timeout
my $UA_CONNECT_TIMEOUT = 7;


# Register Plugin
sub register {
  my ($plugin, $mojo) = @_;

  # Add types
  for ($mojo->types) {
    $_->type(jrd => 'application/jrd+json');
    $_->type(xrd => 'application/xrd+xml');
  };

  my $reply_xrd = sub {
    my ($c, $xrd, $res) = @_;

    # Define xrd or jrd
    unless ($c->stash('format')) {
      $c->stash('format' => scalar $c->param('format'));
    };

    # Add CORS header
    $c->res->headers->header(
      'Access-Control-Allow-Origin' => '*'
    );

    my $status = 200;

    # Not found
    if (!defined $xrd || !ref($xrd)) {
      $status = 404;
      $xrd = $c->helpers->new_xrd;
      $xrd->subject("$res") if $res;
    }

    # rel parameter
    elsif ($c->param('rel')) {

      # Clone and filter relations
      $xrd = $xrd->filter_rel( $c->every_param('rel') );
    };

    my $head_data = $c->req->method eq 'HEAD' ? '' : undef;

    # content negotiation
    return $c->respond_to(

      # JSON request
      json => sub { $c->render(
        status => $status,
        data   => $head_data // $xrd->to_json,
        format => 'json'
      )},

      # JRD request
      jrd => sub { $c->render(
        status => $status,
        data   => $head_data // $xrd->to_json,
        format => 'jrd'
      )},

      # XML default
      any => sub { $c->render(
        status => $status,
        data   => $head_data // $xrd->to_pretty_xml,
        format => 'xrd'
      )}
    );
  };

  # Add DEPRECATED 'render_xrd' helper
  $mojo->helper(
    render_xrd => sub {
      deprecated 'render_xrd is deprecated in favor of reply->xrd';
      $reply_xrd->(@_)
    }
  );

  # Add 'reply->xrd' helper
  $mojo->helper( 'reply.xrd' => $reply_xrd);

  # Add 'get_xrd' helper
  $mojo->helper( get_xrd => \&_get_xrd );

  # Add 'new_xrd' helper
  unless (exists $mojo->renderer->helpers->{'new_xrd'}) {
    $mojo->plugin('XML::Loy' => {
      new_xrd => [-XRD]
    });
  };
};

# Get XRD document
sub _get_xrd {
  my $c = shift;
  my $resource = Mojo::URL->new( shift );

  # Trim tail
  pop while @_ && !defined $_[-1];

  # No valid resource
  return unless $resource->host;

  my $header = {};
  if ($_[0] && ref $_[0] && ref $_[0] eq 'HASH') {
    $header = shift;
  };

  # Check if security is forced
  my $prot = $resource->protocol;
  my $secure;
  $secure = 1 if $prot && $prot eq 'https';

  # Get callback
  my $cb = pop if ref($_[-1]) && ref($_[-1]) eq 'CODE';

  # Build relations parameter
  my $rel;
  $rel = shift if $_[0] && ref $_[0] eq 'ARRAY';

  # Get secure user agent
  my $ua = Mojo::UserAgent->new(
    name => $UA_NAME,
    max_redirects => ($secure ? 0 : $UA_MAX_REDIRECTS),
    connect_timeout => $UA_CONNECT_TIMEOUT
  );

  my $xrd;

  # Set to secure, if not defined
  $resource->scheme('https') unless $resource->scheme;

  # Get helpers proxy object
  my $h = $c->helpers;

  # Is blocking
  unless ($cb) {

    # Fetch Host-Meta XRD - first try ssl
    my $tx = $ua->get($resource => $header);
    my $xrd_res;

    # Transaction was not successful
    return unless $xrd_res = $tx->success;

    unless ($xrd_res->is_success) {

      # Only support secure retrieval
      return if $secure;

      # Was already insecure
      return if $resource->protocol eq 'http';

      # Make request insecure
      $resource->scheme('http');

      # Update insecure max_redirects;
      $ua->max_redirects($UA_MAX_REDIRECTS);

      # Then try insecure
      $tx = $ua->get($resource => $header);

      # Transaction was not successful
      return unless $xrd_res = $tx->success;

      # Retrieval was successful
      return unless $xrd_res->is_success;
    };

    # Parse xrd document
    $xrd = $h->new_xrd($xrd_res->body) or return;

    # Filter relations
    $xrd = $xrd->filter_rel($rel) if $rel;

    # Return xrd
    return ($xrd, $xrd_res->headers->clone) if wantarray;
    return $xrd;
  };

  # Non-blocking
  # Create delay for https with or without redirection
  my $delay = Mojo::IOLoop->delay(
    sub {
      my $delay = shift;

      # Get with https - possibly without redirects
      $ua->get($resource => $header => $delay->begin);
    },
    sub {
      my ($delay, $tx) = @_;

      # Get response
      if (my $xrd_res = $tx->success) {

        # Fine
        if ($xrd_res->is_success) {

          # Parse xrd document
          $xrd = $h->new_xrd($xrd_res->body) or return $cb->(undef);

          # Filter relations
          $xrd = $xrd->filter_rel($rel) if $rel;

          # Send to callback
          return $cb->($xrd, $xrd_res->headers->clone);
        };

        # Only support secure retrieval
        return $cb->(undef) if $secure;
      }

      # Fail
      else {
        return $cb->(undef);
      };

      # Was already insecure
      return if $resource->protocol eq 'http';

      # Try http with redirects
      $delay->steps(
        sub {
          my $delay = shift;

          $resource->scheme('http');

          # Get with http and redirects
          $ua->max_redirects($UA_MAX_REDIRECTS);
          $ua->get($resource => $header => $delay->begin );
        },
        sub {
          my $delay = shift;

          # Transaction was successful
          if (my $xrd_res = pop->success) {

            # Parse xrd document
            $xrd = $h->new_xrd($xrd_res->body) or return $cb->(undef);

            # Filter relations
            $xrd = $xrd->filter_rel($rel) if $rel;

            # Send to callback
            return $cb->($xrd, $xrd_res->headers->clone);
          };

          # Fail
          return $cb->(undef);
        });
    }
  );

  # Wait if IOLoop is not running
  $delay->wait unless Mojo::IOLoop->is_running;
  return;
};


1;


__END__

=pod

=head1 NAME

Mojolicious::Plugin::XRD - XRD Document Handling with Mojolicious


=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('XRD');

  # In controller
  my $xrd = $c->new_xrd;
  $xrd->subject('acct:akron@sojolicio.us');
  $xrd->link(profile => '/me.html');

  # Render as XRD or JRD, depending on request
  $c->reply->xrd($xrd);

  # Content-Type: application/xrd+xml
  # <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  # <XRD xmlns="http://docs.oasis-open.org/ns/xri/xrd-1.0"
  #      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  #   <Subject>acct:akron@sojolicio.us</Subject>
  #   <Link href="/me.html"
  #         rel="profile" />
  # </XRD>

  # or:
  # Content-Type: application/jrd+json
  # {
  #   "subject":"acct:akron@sojolicio.us",
  #   "links":[{"rel":"profile","href":"\/me.html"}]
  # }

  my $gmail_hm = $c->get_xrd('//gmail.com/.well-known/host-meta');
  print $gmail_hm->link('lrdd')->attrs('template');
  # http://profiles.google.com/_/webfinger/?q={uri}

=head1 DESCRIPTION

L<Mojolicious::Plugin::XRD> is a plugin to support
L<Extensible Resource Descriptor|http://docs.oasis-open.org/xri/xrd/v1.0/xrd-1.0.html> documents through L<XML::Loy::XRD>.

Additionally it supports the C<rel> parameter of the
L<WebFinger|http://tools.ietf.org/html/draft-ietf-appsawg-webfinger>
specification.


=head1 METHODS

=head2 register

  # Mojolicious
  $app->plugin('XRD');

  # Mojolicious::Lite
  plugin 'XRD';

Called when registering the plugin.


=head1 HELPERS

=head2 new_xrd

  # In Controller:
  my $xrd = $self->new_xrd;

Returns a new L<XML::Loy::XRD> object without extensions.


=head2 get_xrd

  # In Controller:
  my $xrd = $self->get_xrd('//gmail.com/.well-known/host-meta');

  # In array context
  my ($xrd, $headers) = $self->get_xrd('//gmail.com/.well-known/host-meta');

  # With relation restrictions and security flag
  $xrd = $self->get_xrd('https://gmail.com/.well-known/host-meta' => ['lrdd']);

  # With additional headers
  $xrd = $self->get_xrd('https://gmail.com/.well-known/host-meta' => {
    'X-My-HTTP-Header' => 'Just for Fun'
  } => ['lrdd']);

  # Non-blocking
  $self->get_xrd('//gmail.com/.well-known/host-meta' => sub {
    my ($xrd, $headers) = @_;
    $xrd->extension(-HostMeta);
    print $xrd->host;
  });

Fetches an XRD document from a given resource and returns it as
L<XML::Loy::XRD> document. In array context it additionally returns the
response headers as a L<Mojo::Headers> object.

Expects a valid URL. In case no scheme is given (e.g., C<//gmail.com>),
the method will first try to fetch the resource with C<https> and
on failure fetches the resource with C<http>, supporting redirections.
If the given scheme is C<https>, the discovery will be secured,
even disallowing redirections.
The second argument may be a hash reference containing HTTP headers.
An additional array reference may limit the relations to be retrieved
(see the L<WebFinger|http://tools.ietf.org/html/draft-ietf-appsawg-webfinger>
specification for further explanation).

This method can be used in a blocking or non-blocking way.
For non-blocking retrieval, pass a callback function as the
last argument. As the first passed response is the L<XML::Loy::XRD>
document, you have to use an offset of C<0> in
L<begin|Mojo::IOLoop::Delay/begin> for parallel requests using
L<Mojo::IOLoop::Delay>.

B<This method is experimental and may change wihout warnings.>


=head2 reply->xrd

  # In Controllers
  $self->reply->xrd( $xrd );
  $self->reply->xrd( undef, 'acct:acron@sojolicio.us' );

The helper C<reply-E<gt>xrd> renders an XRD object either
in C<xml> or in C<json> notation, depending on the request.
If an XRD object is empty, it renders a C<404> error
and accepts a second parameter as the subject of the error
document.


=head1 CAVEATS

There are different versions of XRD and JRD
with different MIME types defined.
In some cases you may have to change the MIME type
manually.


=head1 DEPENDENCIES

L<Mojolicious>,
L<Mojolicious::Plugin::XML::Loy>.


=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-XRD


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2021, L<Nils Diewald|https://www.nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the terms of the Artistic License version 2.0.

=cut
