package Plack::Middleware::ReverseProxyPath;

use 5.006;
use strict;
use warnings;
use parent qw(Plack::Middleware);
our $VERSION = '0.04';

sub call {
    my $self = shift;
    my $env = shift;

    if (    $env->{'HTTP_X_FORWARDED_SCRIPT_NAME'}
         || $env->{'HTTP_X_TRAVERSAL_PATH'} ) {

        my $x_script_name    = $env->{'HTTP_X_FORWARDED_SCRIPT_NAME'}   || '';
        my $x_traversal_path = $env->{'HTTP_X_TRAVERSAL_PATH'}          || '';
        my $script_name      = $env->{SCRIPT_NAME};

        # replace $script_name . $path_info
        # prefix of $x_traversal_path with $x_script_name
        if ( length $script_name >= length $x_traversal_path ) {
            $script_name =~ s/^\Q$x_traversal_path\E/$x_script_name/
                or _throw_error(
                    "HTTP_X_TRAVERSAL_PATH: $x_traversal_path\n" .
                    "is not a prefix of \n" .
                    "SCRIPT_NAME: $script_name\n" );
        } else {
            # $x_traversal_path is longer, borrow from path_info
            $x_traversal_path =~ s/^\Q$script_name\E//
                or _throw_error(
                    "SCRIPT_NAME $script_name\n" .
                    "is not a prefix of \n" .
                    "HTTP_X_TRAVERSAL_PATH: $x_traversal_path\n" );
            $script_name = $x_script_name;

            $env->{PATH_INFO} =~ s/^\Q$x_traversal_path\E//
                or _throw_error(
                    "Fragment: $x_traversal_path\n" .
                    "is not a prefix of \n" .
                    "PATH_INFO: $env->{PATH_INFO}\n" .
                    " SCRIPT_NAME: $script_name\n" .
                    " HTTP_X_TRAVERSAL_PATH: $env->{HTTP_X_TRAVERSAL_PATH}\n" );

            # add PSGI required '/' (bad headers w/ trailing / could do it)
            $env->{PATH_INFO} =~ s!^([^/])!/$1!;
        }

        if ( $script_name eq '/' ) { # PSGI doesn't allow '/' only
            $script_name = '';
        }
        $env->{SCRIPT_NAME} = $script_name;

        # don't touch REQUEST_URI, it will continue to refer to the original
    }

    return $self->app->($env);
}

sub _throw_error {
    my ($message) = @_;
    die Plack::Middleware::ReverseProxyPath::Exception->new($message);
}

{
    package Plack::Middleware::ReverseProxyPath::Exception;
    use overload '""' => \&message;
    sub new {
        my ($class, $message) = @_;
        return bless { message => $message }, $class;
    }
    sub code { return 500 }
    sub message { return $_[0]->{message} }
}

1;

__END__

=head1 NAME

Plack::Middleware::ReverseProxyPath - adjust proxied env to match client-facing

=head1 SYNOPSIS

Generally you'll simple use the middle-ware:

  enable "ReverseProxy";
  enable "ReverseProxyPath";

Below is an elaborate example that includes both a dummy reverse proxy
front-end and the back-end using ReverseProxyPath.  Run with something like:

  PLACK_SERVER=Starman perl -x -Ilib ./lib/Plack/Middleware/ReverseProxyPath.pm

(Sample output below)

#!perl -MPlack::Runner
#line 85
  sub mw(&);

  use Plack::Builder;

  # Configure your reverse proxy (perlbal, varnish, apache, squid)
  # to send X-Forwarded-Script-Name and X-Traversal-Path headers.

  # This example just uses Plack::App::Proxy to demonstrate:
  sub proxy_builder {
    require Plack::App::Proxy;

    # imagine this is https://somehost/fepath/from
    mount "http://localhost/fepath/from" => builder {
      enable mw {
          my ($app, $env) = @_;

          # Headers for ReverseProxyPath
          $env->{'HTTP_X_FORWARDED_SCRIPT_NAME'} = '/fepath/from';
          $env->{'HTTP_X_TRAVERSAL_PATH'}        = '/bepath/to';

          # Headers for ReverseProxy (often already sent)
          $env->{'HTTP_X_FORWARDED_HOST'}        = 'somehost'; # pretending..
          $env->{'HTTP_X_FORWARDED_PORT'}        = 443;

          die "Need MP" if !$env->{'psgi.multiprocess'}
                        && !$env->{'psgi.multithread'};
          $app->($env);
      };
      Plack::App::Proxy->new(
            remote => 'http://0:5000/bepath/to' ) ->to_app;
    };
  };

  # In your Plack back-end
  my $app = builder {

    # /bepath/to/* is proxied (can also be accessed directly)
    mount "/bepath/to" => builder {        # base adjustments:
                                           # 1) http://0:5000/bepath/to/x
      # ReverseProxy fixes scheme/host/port
      enable "ReverseProxy";
                                           # 2) https://somehost/bepath/to/x
      # ReverseProxyPath uses new headers
      # fixes SCRIPT_NAME and PATH_INFO
      enable "ReverseProxyPath";
                                           # 3) https://somehost/fepath/from/x

      # $req->base + $req->path now is the client-facing url
      # so URLs, Set-Cookie, Location can work naively
      mount "/base" => \&echo_base;
      mount "/env"  => \&echo_env;
    };
    mount "/env" => \&echo_env;

    # proxy to myself to keep the synopsis short (needs >1 worker)
    proxy_builder();
  };

  # synopsis plumbing:
  sub echo_base { require Plack::Request;
      [200, [ qw(Content-type text/plain) ],
            [ Plack::Request->new(shift)->base . "\n" ] ]
  }
  sub echo_env {
      my ($env) = @_;
      [200, [ qw(Content-type text/plain) ],
            [ map { "$_: $env->{$_}\n" } keys %$env ] ]
  }
  sub mw(&) { my $code = shift;
    sub { my $app = shift; sub { $code->($app, @_); } } };

  Plack::Runner->new->run($app);
__END__

 # with ReverseProxyPath and ReverseProxy applied
 GET http://localhost:5000/fepath/from/base
 https://somehost/fepath/from/base

 # talking directly to the back-end
 GET http://localhost:5000/bepath/to/base
 http://localhost:5000/bepath/to/base

=head1 DESCRIPTION

Use case: reverse proxying /sub/path/ to http://0:5000/other/path/ .
This middleware sits on the back-end and uses headers sent by the proxy
to hide the proxy plumbing from the back-end app.

Plack::Middleware::B<ReverseProxy> does the host, port and scheme.

Plack::Middleware::B<ReverseProxyPath> adds handling of paths.

The goal is to allow proxied back-end apps to reconstruct and use
the client-facing url.  ReverseProxy does most of the work
and ReverseProxyPath does the paths.  The inner app can simply
use $req->base to redirect, set cookies and the like.

I find the term B<reverse proxy> leads to confusion, so I'll
use B<front-end> to refer to the reverse proxy (eg. squid) which
the client hits first, and B<back-end> to refer to the server
that runs your PSGI application (eg. starman).

Plack::Middleware::ReverseProxyPath adjusts SCRIPT_NAME and PATH_INFO
based on headers from a front-end so that it's inner app can pretend
there is no proxy there.  This is useful when you aren't proxying and
entire server, but only a deeper path.  In Apache terms:

  ProxyPass /mirror/foo/ http://localhost:5000/bar/

It should be used with Plack::Middleware::ReverseProxy which does equivalent
adjustments to the scheme, host and port environment attributes.

=head2 Required Headers

In order for this middleware to perform the path adjustments
you will need to configure your reverse proxy to send the following
headers (as applicable):

=over 4

=item X-Forwarded-Script-Name

The front-end prefix being forwarded FROM.  This is the replacement.

The value of SCRIPT_NAME on the front-end.

=item X-Traversal-Path

The back-end prefix being forwarded TO.  This is to be replaced.

This is the part of the back-end URI that is just plumbing which
should be hidden from the app.

If you aren't forwarding to the root of a server, but to some
deeper path, this contains the deeper path portion. So if you
forward to http://localhost:8080/myapp, and there is a request for
/article/1, then the full path forwarded to will be
/myapp/article/1. X-Traversal-Path will contain /myapp.

=back

=head2 Path Adjustment Logic

If there is either X-Traversal-Path or X-Forwarded-Script-Name, roughly:

  SCRIPT_NAME . PATH_INFO =~ s/^${X-Traversal-Path}/${X-Forwarded-Script-Name}/

The X-Traversal-Path prefix will be stripped from SCRIPT_NAME
(borrowing from PATH_INFO if needed) and
SCRIPT_NAME will be prefixed with X-Forwarded-Script-Name.

In the absence of reverse proxy headers, leave SCRIPT_NAME and PATH_INFO alone.
This allows direct connections to the back-end to function.
Also, leave REQUEST_URI alone with the old/original value.

Front-ends should clear client-sent X-Traversal-Path,
and X-Forwarded-Script-Name
(for security).

Note that while it is intended that this module operates on one
directory segment at a time, that is not enforced at present.
For example, /script_name adjusted with ( /script => /cgi ) would
result in /cgi_name.

=head2 Examples

See the F<examples> directory.

If you do use this with a new front-end then please send the configuration
for inclusion.

=head2 Exceptions

If there are problems with the configuration or headers then a
Plack::Middleware::HTTPException compatible exception will be thrown.
It will be a 500 that stringifies with information about the bad
headers.  This might be considered sensitive information, in which
case, you should catch and handle them.

=head1 TODO

 * Should REQUEST_URI be touched?
 * Plack::Middleware::Lint

=head1 LICENSE

This software is licensed under the same terms as Perl itself.

=head1 AUTHOR

Brad Bowman

Feedback from Chris Prather (perigrin)

=head1 SEE ALSO

L<Plack::Middleware::ReverseProxy>

L<http://pythonpaste.org/wsgiproxy/> python middleware used as
a template (although it uses X-Script-Name, instead).

=cut
