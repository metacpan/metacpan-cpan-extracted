## no critic (RequireUseStrict)
package Plack::Middleware::Delay;
BEGIN {
  $Plack::Middleware::Delay::VERSION = '0.01';
}

## use critic (RequireUseStrict)
use strict;
use warnings;
use parent 'Plack::Middleware';

use Plack::Util;

sub call {
    my ( $self, $env ) = @_;

    my $app      = $self->app;
    my $delay    = $self->{'delay'}    || 0;
    my $sleep_fn = $self->{'sleep_fn'} || sub {
        my ( $delay, $invoke ) = @_;

        sleep $delay;

        $invoke->();
    };

    return sub {
        my ( $respond ) = @_;

        $sleep_fn->($delay, sub {
            my $res = $app->($env);

            if(ref($res) eq 'ARRAY') {
                $respond->($res);
            } elsif(ref($res) eq 'CODE') {
                $res->($respond);
            }
        });
    };
}

1;



=pod

=head1 NAME

Plack::Middleware::Delay - Put delays on your requests

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Plack::Builder;

  builder {
      enable 'Delay', delay => 5; # delays the response by five seconds
      $app;
  };

  # or, if you're in an AnyEvent-based PSGI server...

  builder {
      enable 'Delay', delay => 5, sleep_fn => sub {
        my ( $delay, $invoke ) = @_;

        my $timer;
        $timer = AnyEvent->timer(
            after => $delay,
            cb    => sub {
                undef $timer;
                $invoke->();
            },
        );
      };
      $app;
  };

=head1 DESCRIPTION

This middleware imposes an artifical delay on requests, for purposes of
testing.  It could also be used to implement L<http://xkcd.com/862/>.

=head1 OPTIONS

=head2 delay

The number of seconds to sleep.  It can be an integer or a float; however, the
default sleep_fn only works on integers.

=head2 sleep_fn

A subroutine reference that will be called when it's time to go to sleep.  The
subroutine reference will be provided two arguments: the number of seconds to
sleep (ie. the value you provided to L</delay>), and a subroutine reference
that will continue the PSGI application as normal (think of it as a
continuation).

=head1 SEE ALSO

L<Plack>

=head1 AUTHOR

Rob Hoelz <rob@hoelz.ro>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Rob Hoelz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://github.com/hoelzro/plack-middleware-delay/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut


__END__

# ABSTRACT:  Put delays on your requests

