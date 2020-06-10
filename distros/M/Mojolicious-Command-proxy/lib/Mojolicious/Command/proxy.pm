package Mojolicious::Command::proxy;
use Mojo::Base 'Mojolicious::Command';
use Mojo::Util qw(getopt);
use Mojo::URL;
use Mojolicious::Routes;

our $VERSION = '0.001';

has description => 'Proxy web requests elsewhere';
has usage => sub { shift->extract_usage . "\n" };

sub run {
  my ($self, @args) = @_;
  getopt \@args, [qw(no_permute pass_through)],
    'f|from=s' => \my $from;
  $from ||= '';
  my $to = shift @args;
  die $self->usage . "No to" if !$to;
  die $self->usage . "from must be blank or start '/', then something"
    if $from !~ m#^(?:$|/.)#;
  my $app = $self->app;
  $app->routes(Mojolicious::Routes->new) if ref $app eq 'Mojo::HelloWorld';
  $self->proxy($app, $from, $to);
  $app->start(@args);
}

sub proxy {
  my ($self, $app, $from, $to) = @_;
  $from ||= '/';
  $app->routes->any("$from*path" => { path => "" } => sub {
    my ($c) = @_;
    my $req = $c->req;
    my $path = $c->stash('path');
    $path = '/' . $path if $from eq '/'; # weird special behaviour by router
    my $onward_url = $to . $path;
    my $onward_tx = $app->ua->build_tx($req->method => $onward_url);
    $onward_tx->req->content($req->content); # headers and body
    $c->proxy->start_p($onward_tx);
  }, 'proxy');
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Command::proxy - Proxy web requests elsewhere

=begin markdown

# PROJECT STATUS

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.org/mohawk2/Mojolicious-Command-proxy.svg?branch=master)](https://travis-ci.org/mohawk2/Mojolicious-Command-proxy) |

[![CPAN version](https://badge.fury.io/pl/Mojolicious-Command-proxy.svg)](https://metacpan.org/pod/Mojolicious::Command::proxy)

=end markdown

=head1 SYNOPSIS

  Usage: APPLICATION proxy [--from route_prefix] to_url

    mojo proxy http://example.com/subdir daemon -l http://*:3000
    mojo proxy -f /proxy http://example.com/subdir get /proxy/hi

  Options:
    -f, --from                  Proxying route prefix

=head1 DESCRIPTION

L<Mojolicious::Command::proxy> is a command line interface for
making an app that proxies some or all incoming requests elsewhere.
Having done so, it then passes the rest of its arguments to the app's
C<start> method, as illustrated in the synopsis above.

One major reason for this is to be able to point your browser at
e.g. C<localhost:3000> (see first example in synopsis). This relaxes
restrictions on e.g. Service Workers and push notifications, which
normally demand TLS, so you can test functionality even if your real
development server is running elsewhere.

=head1 ATTRIBUTES

=head2 description

  $str = $self->description;

=head2 usage

  $str = $self->usage;

=head1 METHODS

=head2 run

  $get->run(@ARGV);

Run this command. It will add a L</proxy> route as below. If not supplied,
the C<$from> will be empty-string.

Command-line arguments will only be parsed at the start of the
command-line. This allows you to pass option through to e.g. C<daemon>.

As a special case, if the C<app> attribute is exactly a
L<Mojo::HelloWorld> app, it will replace its C<routes> attribute with an
empty one first, since the C<whatever> route clashes with the proxy route,
being also a match-everything wildcard route. This makes the C<mojo proxy>
invocation function as expected.

=head2 proxy

  Mojolicious::Command::proxy->proxy($app, $from_prefix, $to_prefix);

Add a route to the given app, with the given prefix, named C<proxy>. It
will transparently proxy all matching requests to the give C<$to>,
with all the same headers both ways.

It operates by simply appending everything after the C<$from_prefix>,
which I<can> be an empty string (which is treated the same as solitary
C</>, doing what you'd expect), to the C<$to_prefix>. E.g.:

  $cmd->proxy($app, '', '/subdir'); # /2 -> /subdir/2, / -> /subdir/ i.e. all
  $cmd->proxy($app, '/proxy', '/subdir'); # /proxy/2 -> /subdir/2

C<$to> can be a path as well as a full URL, so you can also use this to
route internally. However, the author can see no good reason to do this
outside of testing.

It uses L<Mojolicious::Plugin::DefaultHelpers/proxy-E<gt>start_p> but
adds the full header-proxying behaviour.

=head1 AUTHOR

Ed J

=head1 COPYRIGHT AND LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
