package Plack::App::Prerender;

# ABSTRACT: a simple prerendering proxy for Plack

use v5.10.1;
use strict;
use warnings;

our $VERSION = 'v0.1.2';

use parent qw/ Plack::Component /;

use Encode qw/ encode /;
use HTTP::Headers;
use HTTP::Request;
use HTTP::Status qw/ :constants /;
use Plack::Request;
use Plack::Util;
use Plack::Util::Accessor qw/ mech rewrite cache max_age request response wait /;
use Ref::Util qw/ is_coderef is_plain_arrayref /;
use Time::Seconds qw/ ONE_HOUR /;
use WWW::Mechanize::Chrome;

# RECOMMEND PREREQ: CHI
# RECOMMEND PREREQ: Log::Log4perl
# RECOMMEND PREREQ: Ref::Util::XS


sub prepare_app {
    my ($self) = @_;

    unless ($self->mech) {

        my $mech = WWW::Mechanize::Chrome->new(
            headless         => 1,
            separate_session => 1,
        );

        $self->mech($mech);

    }

    unless ($self->request) {
        $self->request(
            [
             qw/
             X-Forwarded-For
             X-Forwarded-Host
             X-Forwarded-Port
             X-Forwarded-Proto
             /
            ]
        );
    }

    unless ($self->response) {
        $self->response(
            [
             qw/
             Content-Type
             Expires
             Last-Modified
             /
            ]
        );
    }

    unless ($self->max_age) {
        $self->max_age( ONE_HOUR );
    }
}

sub call {
    my ($self, $env) = @_;

    my $req = Plack::Request->new($env);

    my $method = $req->method // '';
    unless ($method eq "GET") {
        return [ HTTP_METHOD_NOT_ALLOWED, [], [] ];
    }

    my $path_query = $env->{REQUEST_URI};

    my $base = $self->rewrite;
    my $url  = is_coderef($base)
        ? $base->($path_query, $env)
        : $base . $path_query;

    $url //= [ HTTP_BAD_REQUEST, [], [] ];
    return $url if (is_plain_arrayref($url));

    my $cache = $self->cache;
    my $data  = $cache->get($path_query);
    if (defined $data) {

        return $data;

    }
    else {

        my $mech = $self->mech;
        $mech->reset_headers;

        my $req_head = $req->headers;
        for my $field (@{ $self->request }) {
            my $value = $req_head->header($field) // next;
            $mech->add_header( $field => $value );
        }
        if (my $ua = $req_head->header('User-Agent')) {
            $mech->add_header( 'X-Forwarded-User-Agent' => $ua );
        }

        my $res  = $mech->get( $url );

        if (my $count = $self->wait) {
            while ($mech->infinite_scroll(1)) {
                last if $count-- < 0;
            }
        }

        my $body = encode("UTF-8", $mech->content);

        my $head = $res->headers;
        my $h = Plack::Util::headers([ 'X-Renderer' => __PACKAGE__ ]);
        for my $field (@{ $self->response }) {
            my $value = $head->header($field) // next;
            $value =~ tr/\n/ /;
            $h->set( $field => $value );
        }

        if ($res->code == HTTP_OK) {

            my $age;
            if (my $value = $head->header("Cache-Control")) {
                ($age) = $value =~ /(?:s\-)?max-age=([0-9]+)\b/;
                if ($age && $age > $self->max_age) {
                    $age = $self->max_age;
                }
            }

            $data = [ HTTP_OK, $h->headers, [$body] ];

            $cache->set( $path_query, $data, $age // $self->max_age );

            return $data;

        }
        else {

            return [ $res->code, $h->headers, [$body] ];

        }
    }

}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::App::Prerender - a simple prerendering proxy for Plack

=head1 VERSION

version v0.1.2

=head1 SYNOPSIS

  use CHI;
  use Log::Log4perl qw/ :easy /;
  use Plack::App::Prerender;

  my $cache = CHI->new(
      driver   => 'File',
      root_dir => '/tmp/test-chi',
  );

  Log::Log4perl->easy_init($ERROR);

  my $app = Plack::App::Prerender->new(
      rewrite => "http://www.example.com",
      cache   => $cache,
      wait    => 10,
  )->to_app;

=head1 DESCRIPTION

This is a PSGI application that acts as a simple prerendering proxy
for websites using Chrone.

This only supports GET requests, as this is intended as a proxy for
search engines that do not support AJAX-generated content.

=head1 ATTRIBUTES

=head2 mech

A L<WWW::Mechanize::Chrome> object. If omitted, a headless instance of
Chrome will be launched.

If you want to specify alternative options, you chould create your own
instance of WWW::Mechanize::Chrome and pass it to the constructor.

=head2 rewrite

This can either be a base URL prefix string, or a code reference that
takes the PSGI C<REQUEST_URI> and environment hash as arguments, and
returns a full URL to pass to L</mech>.

If the code reference returns C<undef>, then the request will abort
with an HTTP 400.

If the code reference returns an array reference, then it assumes the
request is a Plack response and simply returns it.

This can be used for simple request validation.  For example,

  use Robots::Validate v0.2.0;

  sub validator {
    my ($path, $env) = @_;

    state $rv = Robots::Validate->new();

    unless ( $rv->validate( $env ) ) {
        if (my $logger = $env->{'psgix.logger'}) {
           $logger->( { level => 'warn', message => 'not a bot!' } );
        }
        return [ 403, [], [] ];
    }

    ...
  }

=head2 cache

This is the cache handling interface. See L<CHI>.

=head2 max_age

This is the maximum time (in seconds) to cache content.  If the page
returns a C<Cache-Control> header with a C<max-age>, then that will be
used instead.

=head2 request

This is an array reference of request headers to pass through the
proxy.  These default to the reverse proxy forwarding headers:

=over

=item C<X-Forwarded-For>

=item C<X-Forwarded-Host>

=item C<X-Forwarded-Port>

=item C<X-Forwarded-Proto>

=back

The C<User-Agent> is forwarded as C<X-Forwarded-User-Agent>.

=head2 response

This is an array reference of response headers to pass from the
result.  It defaults to the following headers:

=over

=item C<Content-Type>

=item C<Expires>

=item C<Last-Modified>

=back

=head2 wait

The number of seconds to wait for new content to be loaded.

=head1 LIMITATIONS

This does not support cache invalidation or screenshot rendering.

This only does the bare minimum necessary for proxying requests. You
may need additional middleware for reverse proxies, logging, or
security filtering.

=head1 SEE ALSO

L<Plack>

L<WWW::Mechanize::Chrome>

Rendertron L<https://github.com/GoogleChrome/rendertron>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/perl-Plack-App-Prerender>
and may be cloned from L<git://github.com/robrwo/perl-Plack-App-Prerender.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/perl-Plack-App-Prerender/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
