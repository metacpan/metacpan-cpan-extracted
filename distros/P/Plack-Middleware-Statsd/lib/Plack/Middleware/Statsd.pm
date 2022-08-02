package Plack::Middleware::Statsd;

# ABSTRACT: send statistics to statsd

# RECOMMEND PREREQ:  Net::Statsd::Tiny v0.3.0
# RECOMMEND PREREQ:  HTTP::Status 6.16
# RECOMMEND PREREQ:  List::Util::XS
# RECOMMEND PREREQ:  Ref::Util::XS

use v5.14;

use strict;
use warnings;

use parent qw/ Plack::Middleware /;

use Feature::Compat::Try;
use List::Util qw/ first /;
use Plack::Util;
use Plack::Util::Accessor
    qw/ client sample_rate histogram increment set_add catch_errors /;
use Ref::Util qw/ is_coderef /;
use Time::HiRes;

our $VERSION = 'v0.6.0';

# Note: You may be able to omit the client if there is a client
# defined in the environment hash at C<psgix.monitor.statsd>, and the
# L</histogram>, L</increment> and L</attributes> are set.  But that
# is a strange case and unsupported.

sub prepare_app {
    my ($self) = @_;

    if ( my $client = $self->client ) {
        foreach my $init (
            [qw/ histogram timing_ms timing /],
            [qw/ increment increment /],
            [qw/ set_add   set_add   /],
          )
        {
            my ( $attr, @methods ) = @$init;
            next if defined $self->$attr;
            my $method = first { $client->can($_) } @methods;
            warn "No $attr method found for client " . ref($client)
                unless defined $method;
            $self->$attr(
                sub {
                    return unless defined $method;
                    my ($env, @args) = @_;
                    try {
                        $client->$method( grep { defined $_ } @args );
                    }
                    catch($e) {
                        if (my $logger = $env->{'psgix.logger'}) {
                            $logger->( { message => $e, level => 'error' } );
                        }
                        else {
                            $env->{'psgi.errors'}->print($e);
                        }
                    };

                }
            );
        }
    }

    if (my $attr = first { !is_coderef($self->$_) } qw/ histogram increment set_add /) {
        die "$attr is not a coderef";
    }

    if ( my $catch = $self->catch_errors ) {

        unless ( is_coderef($catch) ) {

            $self->catch_errors(
                sub {
                    my ( $env, $error ) = @_;
                    if ( my $logger = $env->{'psgix.logger'} ) {
                        $logger->( { level => 'error', message => $error } );
                    }
                    else {
                        $env->{'psgi.errors'}->print($error);
                    }
                    my $message = 'Internal Error';
                    return [ 500, [ 'Content-Type' => 'text/plain', 'Content-Length' => length($message) ], [$message] ];
                }
            );

        }

    }
}

sub call {
    my ( $self, $env ) = @_;

    my $client = ( $env->{'psgix.monitor.statsd'} //= $self->client );

    my $start = [Time::HiRes::gettimeofday];
    my $res;

    if (my $catch = $self->catch_errors) {
        try {
            $res = $self->app->($env);
        }
        catch($e) {
            $res = $catch->( $env, $e );
        }
    }
    else {
        $res = $self->app->($env);
    }

    return Plack::Util::response_cb(
        $res,
        sub {
            return unless $client;

            my ($res) = @_;

            my $rate = $self->sample_rate;

            $rate = undef if ( defined $rate ) && ( $rate >= 1 );

            my $histogram = $self->histogram;
            my $increment = $self->increment;
            my $set_add   = $self->set_add;

            my $elapsed = Time::HiRes::tv_interval($start);

            $histogram->( $env, 'psgi.response.time', $elapsed * 1000, $rate );

            if ( defined $env->{CONTENT_LENGTH} ) {
                $histogram->( $env,
                    'psgi.request.content-length',
                    $env->{CONTENT_LENGTH}, $rate
                );
            }

            if ( my $method = $env->{REQUEST_METHOD} ) {
                $increment->( $env, 'psgi.request.method.' . $method, $rate );
            }

            if ( my $type = $env->{CONTENT_TYPE} ) {
                $type =~ s#\.#-#g;
                $type =~ s#/#.#g;
                $type =~ s/;.*$//;
                $increment->( $env, 'psgi.request.content-type.' . $type, $rate );
            }

            $set_add->( $env, 'psgi.request.remote_addr', $env->{REMOTE_ADDR} )
                if $env->{REMOTE_ADDR};

            $set_add->( $env, 'psgi.worker.pid', $$ );

            my $h = Plack::Util::headers( $res->[1] );

            my $xsendfile =
                 $env->{'plack.xsendfile.type'}
              || $ENV{HTTP_X_SENDFILE_TYPE}
              || 'X-Sendfile';

            if ( $h->exists($xsendfile) ) {
                $increment->( $env, 'psgi.response.x-sendfile', $rate );
            }

            if ( $h->exists('Content-Length') ) {
                my $length = $h->get('Content-Length') || 0;
                $histogram->( $env, 'psgi.response.content-length', $length, $rate );
            }

            if ( my $type = $h->get('Content-Type') ) {
                $type =~ s#\.#-#g;
                $type =~ s#/#.#g;
                $type =~ s/;.*$//;
                $increment->( $env, 'psgi.response.content-type.' . $type, $rate );
            }

            $increment->( $env, 'psgi.response.status.' . $res->[0], $rate );

            if (
                  $env->{'psgix.harakiri.supported'}
                ? $env->{'psgix.harakiri'}
                : $env->{'psgix.harakiri.commit'}
              )
            {
                $increment->( $env, 'psgix.harakiri' );    # rate == 1
            }

            $client->flush if $client->can('flush');

            return;
        }
    );

}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::Statsd - send statistics to statsd

=head1 VERSION

version v0.6.0

=head1 SYNOPSIS

  use Plack::Builder;
  use Net::Statsd::Tiny;

  builder {

    enable "Statsd",
      client      => Net::Statsd::Tiny->new( ... ),
      sample_rate => 1.0;

    ...

    sub {
      my ($env) = @_;

      # Send statistics via other middleware

      if (my $stats = $env->{'psgix.monitor.statsd'}) {

        $stats->increment('myapp.wibble');

      }

    };

  };

=head1 DESCRIPTION

This middleware gathers metrics from the application send sends them
to a statsd server.

=head1 ATTRIBUTES

=head2 client

This is a statsd client, such as an instance of L<Net::Statsd::Tiny>.

It is required.

C<psgix.monitor.statsd> will be set to the current client if it is not
set.

The only restriction on the client is that it has the same API as
L<Net::Statsd::Tiny> or similar modules, by supporting the following
methods:

=over

=item

C<increment>

=item

C<timing_ms> or C<timing>

=item

C<set_add>

=back

This has been tested with L<Net::Statsd::Lite> and
L<Net::Statsd::Client>.

Other statsd client modules may be used via a wrapper class.

=head2 sample_rate

The default sampling rate to be used, which should be a value between
0 and 1.  This will override the default rate of the L</client>, if
there is one.

The default is C<1>.

=head2 histogram

This is a code reference to a wrapper around the L</client> C<timing>
method.  You do not need to set this unless you want to override it.

It takes as arguments the Plack environment and the arguments to pass
to the client method, and calls that method.  If there are errors then
it attempts to log them.

=head2 increment

This is a code reference to a wrapper around the L</client>
C<increment> method.  You do not need to set this unless you want to
override it.

It takes as arguments the Plack environment and the arguments to pass
to the client method, and calls that method.  If there are errors then
it attempts to log them.

=head2 set_add

This is a code reference to a wrapper around the L</client> C<set_add>
method.  You do not need to set this unless you want to override it.

It takes as arguments the Plack environment and the arguments to pass
to the client method, and calls that method.  If there are errors then
it attempts to log them.

=head2 catch_errors

If this is set to "1", then any fatal errors in the PSGI application
will be caught and logged, and metrics will continue to be logged.

Alternatively, you may specify a subroutine that handles the errors
and returns a valid response, for example.

  sub handle_errors {
    my ( $env, $error ) = @_;

    if ( my $logger = $env->{'psgix.logger'} ) {
        $logger->( { level => 'error', message => $error } );
    }
    else {
        $env->{'psgi.errors'}->print($error);
    }

    return [
      503,
      [
         'Content-Type'   => 'text/plain',
         'Content-Length' => 11,
      ],
      [ 'Unavailable' ]
    ];
  }

  ...

  enable "Statsd",
     catch_errors => \&handle_errors;

This is disable by default, which means that no metrics will be logged
if there is a fatal error.

Added in v0.5.0.

=head1 METRICS

The following metrics are logged:

=over

=item C<psgi.request.method.$METHOD>

This increments a counter for the request method.

=item C<psgi.request.remote_addr>

The remote address is added to the set.

=item C<psgi.request.content-length>

The content-length of the request, if it is specified in the header.

This is treated as a timing rather than a counter, so that statistics
can be saved.

=item C<psgi.request.content-type.$TYPE.$SUBTYPE>

A counter for the content type of request bodies is incremented, e.g.
C<psgi.request.content-type.application.x-www-form-urlencoded>.

Any modifiers in the type, e.g. C<charset>, will be ignored.

=item C<psgi.response.content-length>

The content-length of the response, if it is specified in the header.

This is treated as a timing rather than a counter, so that statistics
can be saved.

=item C<psgi.response.content-type.$TYPE.$SUBTYPE>

A counter for the content type is incremented, e.g. for a JPEG image,
the counter C<psgi.response.content-type.image.jpeg> is incremented.

Any modifiers in the type, e.g. C<charset>, will be ignored.

=item C<psgi.response.status.$CODE>

A counter for the HTTP status code is incremented.

=item C<psgi.response.time>

The response time, in ms.

As of v0.3.1, this is no longer rounded up to an integer. If this
causes problems with your statsd daemon, then you may need to use a
subclassed version of your statsd client to work around this.

=item C<psgi.response.x-sendfile>

This counter is incremented when the C<X-Sendfile> header is added.

The header is configured using the C<plack.xsendfile.type> environment
key, otherwise the C<HTTP_X_SENDFILE_TYPE> environment variable.

See L<Plack::Middleware::XSendfile> for more information.

=item C<psgi.worker.pid>

The worker PID is added to the set.

Note that this is set after the request is processed.  This means that
while the set size can be used to indicate the number of active
workers, if the workers are busy (i.e. longer request processing
times), then this will show a lower number.

This was added in v0.3.10.

=item C<psgix.harakiri>

This counter is incremented when the harakiri flag is set.

=back

If you want to rename these, or modify sampling rates, then you will
need to use a wrapper class for the L</client>.

=head1 EXAMPLES

=head2 Using from Catalyst

You can access the configured statsd client from L<Catalyst>:

  sub finalize {
    my $c = shift;

    if (my $statsd = $c->req->env->{'psgix.monitor.statsd'}) {
      ...
    }

    $c->next::method(@_);
  }

Alternatively, you can use L<Catalyst::Plugin::Statsd>.

=head2 Using with Plack::Middleware::SizeLimit

L<Plack::Middleware::SizeLimit> version 0.11 supports callbacks that
allow you to monitor process size information.  In your F<app.psgi>:

  use Net::Statsd::Tiny;
  use Feature::Compat::Try;

  my $statsd = Net::Statsd::Tiny->new( ... );

  builder {

    enable "Statsd",
      client      => $statsd,
      sample_rate => 1.0;

    ...

    enable "SizeLimit",
      ...
      callback => sub {
          my ($size, $shared, $unshared) = @_;
          try {
              $statsd->timing_ms('psgi.proc.size', $size);
              $statsd->timing_ms('psgi.proc.shared', $shared);
              $statsd->timing_ms('psgi.proc.unshared', $unshared);
          }
          catch($e) {
              warn $e;
          };
      };

=head1 KNOWN ISSUES

=head2 Non-standard HTTP status codes

If your application is returning a status code that is not handled by
L<HTTP::Status>, then the metrics may not be logged for that reponse.

=head1 SEE ALSO

L<Net::Statsd::Client>

L<Net::Statsd::Tiny>

L<PSGI>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Plack-Middleware-Statsd>
and may be cloned from L<git://github.com/robrwo/Plack-Middleware-Statsd.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Plack-Middleware-Statsd/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The initial development of this module was sponsored by Science Photo
Library L<https://www.sciencephoto.com>.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2022 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
