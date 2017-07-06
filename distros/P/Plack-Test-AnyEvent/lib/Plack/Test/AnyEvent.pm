## no critic (RequireUseStrict)
package Plack::Test::AnyEvent;
$Plack::Test::AnyEvent::VERSION = '0.07';
## use critic (RequireUseStrict)
use strict;
use warnings;
use autodie qw(pipe);

use AnyEvent::Handle;
use Carp;
use HTTP::Request;
use HTTP::Message::PSGI;
use IO::Handle;

use Plack::Test::AnyEvent::Response;

# code adapted from Plack::Test::MockHTTP
sub test_psgi {
    my ( %args ) = @_;

    my $client = delete $args{client} or croak "client test code needed";
    my $app    = delete $args{app}    or croak "app needed";

    my $cb     = sub {
        my ( $req ) = @_;
        $req->uri->scheme('http')    unless defined $req->uri->scheme;
        $req->uri->host('localhost') unless defined $req->uri->host;
        my $env = $req->to_psgi;
        $env->{'psgi.streaming'}   = 1;
        $env->{'psgi.nonblocking'} = 1;

        my $res = $app->($env);

        if(ref($res) eq 'CODE') {
            my ( $status, $headers, $body );
            my ( $read, $write );

            my $cond = AnyEvent->condvar;

            $res->(sub {
                my ( $ref ) = @_;
                ( $status, $headers, $body ) = @$ref;

                $cond->send;

                unless(defined $body) {
                    pipe $read, $write;
                    $write = IO::Handle->new_from_fd($write, 'w');
                    $write->autoflush(1);
                    return $write;
                }
            });

            unless(defined $status) {
                local $SIG{__DIE__} = __PACKAGE__->exception_handler($cond);
                my $ex = $cond->recv;
                die $ex if defined $ex;
            }

            if(defined $body) {
                $res = Plack::Test::AnyEvent::Response->from_psgi([ $status, $headers, $body ]);
                $res->{'_cond'} = AnyEvent->condvar;
                $res->{'_cond'}->send;
            } else {
                push @$headers, 'Transfer-Encoding', 'chunked';
                $res = Plack::Test::AnyEvent::Response->from_psgi([ $status, $headers, [] ]);
                my $h;
                $res->{'_cond'} = AnyEvent->condvar(cb => sub {
                    undef $h;
                    close $read;
                    close $write;
                });
                $res->on_content_received(sub {});

                $h = AnyEvent::Handle->new(
                    fh      => $read,
                    on_read => sub {
                        my $buf = $h->rbuf;
                        $h->rbuf = '';
                        $res->content($res->content . $buf);
                        $res->on_content_received->($buf);
                    },
                    on_eof => sub {
                        $res->send;
                    },
                    on_error => sub {
                        my ( undef, undef, $msg ) = @_;
                        warn $msg;
                        $res->send;
                    },
                );
            }
        } else {
            unless(ref($res) eq 'Plack::Test::AnyEvent::Response') {
                $res = Plack::Test::AnyEvent::Response->from_psgi($res);
            }
            my $cond        = AnyEvent->condvar;
            $res->{'_cond'} = $cond;
            $res->on_content_received(sub {});

            # make sure that the on_content_received callback is invoked inside
            # of the event loop
            my $faux_timer;
            $faux_timer = AnyEvent->timer(
                after => 0.001,
                cb    => sub {
                    undef $faux_timer;
                    $res->on_content_received->($res->content);
                    $cond->send;
                },
            );
            $res->request($req);
        }

        return $res;
    };

    $client->($cb);
}

sub exception_handler {
    my ( $class, $cond ) = @_;

    return sub {
        my $i = 0;

        my @last_eval_frame;

        while(my @info = caller($i)) {
            my ( $subroutine, $evaltext ) = @info[3, 6];

            if($subroutine eq '(eval)' && !defined($evaltext)) {
                @last_eval_frame = caller($i + 1);
                last;
            }
        } continue {
            $i++;
        }

        if(@last_eval_frame) {
            my ( $subroutine ) = $last_eval_frame[3];

            if($subroutine =~ /^AnyEvent::Impl|AnyEvent::CondVar::Base/) {
                $cond->send($_[0]);
            }
        }
    };
}

1;

=pod

=encoding UTF-8

=head1 NAME

Plack::Test::AnyEvent - Run Plack::Test on AnyEvent-based PSGI applications

=head1 VERSION

version 0.07

=head1 SYNOPSIS

  use HTTP::Request::Common;
  use Plack::Test;

  $Plack::Test::Impl = 'AnyEvent'; # or 'AE' for short

  test_psgi $app, sub {
    my ( $cb ) = @_;

    my $res = $cb->(GET '/streaming-response');
    is $res->header('Transfer-Encoding'), 'chunked';
    $res->on_content_received(sub {
        my ( $content ) = @_;

        # test chunk of streaming response
    });
    $res->recv;
  }

=head1 DESCRIPTION

This L<Plack::Test> implementation allows you to easily test your
L<AnyEvent>-based PSGI applications.  Normally, L<Plack::Test::MockHTTP>
or L<Plack::Test::Server> work fine for this, but this implementation comes
in handy when you'd like to test your streaming results as they come in, or
if your application uses long-polling.  For non-streaming requests, you can
use this module exactly like Plack::Test::MockHTTP; otherwise, you can set
up a content handler and call C<$res-E<gt>recv>.  The event loop will then
run until the PSGI application closes its writer handle or until your test
client calls C<send> on the response.

=head1 FUNCTIONS

=head2 test_psgi

This function behaves almost identically to L<Plack::Test/test_psgi>; the
main difference is that the returned response object supports a few additional
methods on top of those normally found in an L<HTTP::Response> object:

=head3 $res->recv

Calls C<recv> on an internal AnyEvent condition variable.  Use this after you
get the response object to run the event loop.

=head3 $res->send

Calls C<send> on an internal AnyEvent condition variable.  Use this to stop
the event loop when you're done testing.

=head3 $res->on_content_received($cb)

Sets a callback to be called when a chunk is received from the application.
A single argument is passed to the callback; namely, the chunk itself.

=head1 EXCEPTION HANDLING

As of version 0.02, this module handles uncaught exceptions thrown by your code.
If the exception occurs before your PSGI application returns a response, or
directly in the response subroutine ref (if you return a subroutine as your
application's response), C<$cb> will propagate the exception.  Otherwise,
the exception is propagated by C<$res-E<gt>recv>.  Here's an example:

  my $app = sub {
    die 'thrown by $cb';

    return sub {
        my ( $respond ) = @_;

        die 'still thrown by $cb';
            
        if($streaming) {
            my $writer = $respond->([
                200,
                ['Content-Type' => 'text/plain'],
            ]);

            die 'still thrown by $cb';

            my $timer;
            $timer = AnyEvent->timer(
                after => 2,
                cb    => sub {
                    die 'thrown by $res->recv';
                    $writer->write("Ok");
                    $writer->close;
                    undef $timer;
                },
            );
        } else {
            $respond->([
                200,
                ['Content-Type' => 'text/plain'],
                ['Ok'],
            ]);

            die 'still thrown by $cb';
        }
    };
  };

  test_psgi $app, sub {
    my ( $cb ) = @_;

    my $res = $cb->(GET '/');

    $res->on_content_received(sub {
        ...
    });

    $res->recv;
  };

Note: The exception handling code may or may not work with your event loop.
Please run the tests in this distribution with
L<AnyEvent/"PERL_ANYEVENT_MODEL"> set to see if it works with your event loop
of choice.  Patches will be accepted to accommodate loops, as long as it
doesn't break known good ones.  The known good event loops are:

=over

=item Default

=item Cocoa

=item EV

=item Event

=item Glib

=item Perl

=back

This list isn't exclusive; ie. just because your event loop isn't on this list
doesn't mean it doesn't work.  Also, even if your event loop doesn't pass
the exception tests, the general usage of this module (testing requests,
handling streaming results and long polling) should work on any AnyEvent loop.
Just don't throw any uncaught exceptions =).

=head1 SEE ALSO

L<AnyEvent>, L<Plack>, L<Plack::Test>

=begin comment

=over

=item exception_handler

=back

=end comment

=head1 AUTHOR

Rob Hoelz <rob@hoelz.ro>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rob Hoelz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/hoelzro/plack-test-anyevent/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__END__

# ABSTRACT: Run Plack::Test on AnyEvent-based PSGI applications

