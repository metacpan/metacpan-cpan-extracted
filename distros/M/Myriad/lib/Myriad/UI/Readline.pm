package Myriad::UI::Readline;

use strict;
use warnings;

our $VERSION = '1.001'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

use parent qw(IO::Async::Notifier);

no indirect qw(fatal);
use utf8;

=encoding utf8

=head1 NAME

Myriad::UI::Readline - L<Term::ReadLine> support for L<Myriad>

=head1 DESCRIPTION

Provides a basic line-based interface with history support.

=cut

use Syntax::Keyword::Try;
use Syntax::Keyword::Dynamically;
use Future::AsyncAwait;
use Term::ReadLine;
use Scope::Guard;

use Scalar::Util qw(blessed);
use Log::Any qw($log);

=head1 METHODS

=cut

=head2 readline

Returns the L<Term::ReadLine> instance.

=cut

sub readline { shift->{readline} //= Term::ReadLine->new('myriad') }

=head2 setup

Prepares the L</readline> instance for usage.

=cut

async sub setup {
    my ($self) = @_;
    my $f = $self->loop->new_future;
    $self->readline->event_loop(sub {
        $f->get;
        $f = $self->loop->new_future;
    }, sub {
        my ($fh) = @_;
        my $scope = Scope::Guard->new(sub {
            return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
            $log->tracef('Cleaning up readline watched handle');
            $self->loop->unwatch_io(
                handle => $fh
            );
        });
        $log->tracef('Watching readline handle');
        $self->loop->watch_io(
            handle => $fh,
            on_read_ready => sub {
                $f->done unless $f->is_ready
            },
        );
        return [ $scope ];
    });
}

=head2 cleanup

Shut down the L</readline> instance before exit.

=cut

async sub cleanup {
    my ($self) = @_;
    my $rl = delete $self->{readline} or return;
    $rl->event_loop(undef);
}

=head2 handle_item

Used internally to process requests.

=cut

async sub handle_item {
    my ($self, $src) = @_;
    if(blessed($src)) {
        my $int = $self->loop->new_future;
        $SIG{INT} = sub { # ideally would go through dynamically here
            $log->warnf("Ctrl-C");
            $int->fail('Interrupted') unless $int->is_ready;
        };
        if($src->isa('Ryu::Source')) {
            await Future->wait_any(
                $src->say->completed,
                $int,
            );
        } elsif($src->isa('Future')) {
            for my $rslt (await Future->wait_any(
                $src,
                $int
            )) {
                print "$rslt\n";
            }
        } else {
            $log->errorf('Unknown blessed instance returned: %s', $src);
        }
    } elsif(defined $src) {
        print "$src\n";
    } else {
        print "<undef?>\n";
    }
}

=head2 run

Runs the event loop for readline processing. Only resolves
after completion.

=cut

async sub run {
    my ($self) = @_;
    my $rl = $self->readline;
    try {
        await $self->setup;
        my $prompt = 'myriad> ';
        my $active = 1;
        my %command = (
            help => sub {
                return Future->done(
                    'No help available, sorry'
                );
            },
            infinite => sub {
                return $self->loop->new_future;
            },
            exit => sub {
                $active = 0;
                return Future->done(
                    'Will exit eventually'
                )
            }
        );
        $command{quit} = $command{exit};

        # The call to ->readline will enter the event loop
        while($active && defined(my $line = $rl->readline($prompt))) {
            try {
                my ($cmd, $args) = $line =~ /^(\S+)(?: (.*))?/s;
                if(my $code = $command{$cmd}) {
                    if(my $src = $code->($args)) {
                        # Once the call to ->readline returns, we should no longer
                        # be in the event loop, so this ->get will reënter the event
                        # loop long enough to complete the request
                        $self->handle_item($src)->get;
                    }
                } else {
                    $log->errorf("Unknown command: %s", $cmd);
                }
            } catch ($e) {
                $log->errorf('Failed to execute %s - %s', $line, $e);
            }
            $rl->addhistory($line) if $line =~ /\S/;
        }
    } catch ($e) {
        $log->errorf('Failure during readline loop - %s', $e);
    }
    await $self->cleanup;
}

1;

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2022. Licensed under the same terms as Perl itself.

