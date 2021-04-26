package Myriad::Bootstrap;

use strict;
use warnings;

use 5.010;

our $VERSION = '0.002'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

=head1 NAME

Myriad::Bootstrap - starts up a Myriad child process ready for loading modules
for the main functionality

=head1 DESCRIPTION

Controller process for managing an application.

Provides a minimal parent process which starts up a child process for
running the real application code. A pipe is maintained between parent
and child for exchanging status information, with a secondary UNIX domain
socket for filedescriptor handover.

The parent process loads only two additional modules - strict and warnings
- with the rest of the app-specific modules being loaded in the child. This
is enforced: any other modules found in C<< %INC >> will cause the process to
exit immediately.

Signals:

=over 4

=item * C<HUP> - Request to recycle all child processes

=item * C<TERM> - Shut down all child processes gracefully

=item * C<KILL> - Immediate shutdown for all child processes

=back

The purpose of this class is to support development usage: it provides a
minimal base set of code that can load up the real modules in separate
forks, and tear them down again when dependencies or local files change.

We avoid even the standard CPAN modules because one of the changes we're
watching for is C<< cpanfile >> content changing, if there's a new module
or updated version we want to be very sure that it's properly loaded.

One thing we explicitly B<don't> try to do is handle Perl version or executable
changing from underneath us - so this is very much a fork-and-call approach,
rather than fork-and-exec.

=cut

our %ALLOWED_MODULES = map {
    $_ => 1
} qw(
        strict
        warnings
    ),
    __PACKAGE__;

our %constant;

# See perldoc perlport for the difference between this and \r\n
my $CRLF = "\x0D\x0A";

=head1 METHODS - Class

=head2 allow_modules

Add modules to the whitelist.

Takes a list of module names in the same format as C<< %INC >> keys.

Don't ever use this.

=cut

sub allow_modules {
    my $class = shift;
    @ALLOWED_MODULES{@_} = (1) x @_;
}


=head2 open_pipe

use socketpair to establish communication between parent/child later.

=cut

sub open_pipe {
    # Establish comms channel for child process
    socketpair my $child_pipe, my $parent_pipe, $constant{AF_UNIX}, $constant{SOCK_STREAM}, $constant{PF_UNSPEC}
        or die $!;

    { # Unbuffered writes
        my $old = select($child_pipe);
        $| = 1; select($parent_pipe);
        $| = 1; select($old);
    }

    make_pipe_nonblocking($parent_pipe);
    make_pipe_nonblocking($child_pipe);

    return ($parent_pipe, $child_pipe);
}


=head2 make_pipe_noneblocking

Takes a pipe and makes it nonblocking by applying C<O_NONBLOCK>

=cut

sub make_pipe_nonblocking {
    my $pipe = shift;
    my $flags = fcntl($pipe, $constant{F_GETFL}, 0)
        or die "Can't get flags for the socket: $!\n";

    $flags = fcntl($pipe, $constant{F_SETFL}, $flags | $constant{O_NONBLOCK})
        or die "Can't set flags for the socket: $!\n";
}

sub check_messages_in_pipe {
    my ($pipe, $on_read) = @_;
    # See https://perldoc.perl.org/functions/select#select-RBITS,WBITS,EBITS,TIMEOUT
    # for a better understanding
    my $input = '';
    my $rin = my $win = '';
    vec($rin, fileno($pipe), 1) = 1;
    my $ein = $rin | $win;

    die $! unless (my $nfound = select my $rout = $rin, my $wout = $win, my $eout = $ein, 0.5) > -1;

    if($nfound) {
        my $rslt = sysread $pipe, my $buf, 4096;
        return 0 unless $rslt;
        $input .= $buf;
        while($input =~ s/^[\x0D\x0A]*(.*)(?:\x0D\x0A)+//) {
            $on_read->($1);
        }
    }

    return 1;
}

=head2 boot

Given a target coderef or classname, prepares the fork and communication
pipe, then starts the code.

=cut

sub boot {
    my ($class, $target) = @_;
    my $parent_pid = $$;
    my @children_pids;

    { # Read constants from various modules without loading them into the main process
        die $! unless defined(my $pid = open my $child, '-|');
        my %constant_map = (
            Socket            => [qw(AF_UNIX SOCK_STREAM PF_UNSPEC)],
            Fcntl             => [qw(F_GETFL F_SETFL O_NONBLOCK)],
            POSIX             => [qw(WNOHANG)],
        );
        unless($pid) {
            # We've forked, so we're free to load any extra modules we'd like here
            require Module::Load;
            for my $pkg (sort keys %constant_map) {
                Module::Load::load($pkg);
                $pkg->import;
                {
                    no strict 'refs';
                    print "$_=" . *{join '::', $pkg, $_}->() . "\n" for @{$constant_map{$pkg}};
                }
            }
            exit 0;
        }
        {
            # A poor attempt at a data-exchange protocol indeed, but one with the advantage
            # of simplicity and readability for anyone investigating via `strace`
            my @constants = map @$_, values %constant_map;
            while(<$child>) {
                my ($k, $v) = /^([^=]+)=(.*)$/;
                $constant{$k} = $v;
            }
            close $child or die $!;
            die "Missing constant $_" for grep !exists $constant{$_}, @constants;
        }
    }

    my ($inotify_parent_pipe, $inotify_child_pipe) = open_pipe();

    {
        if (my $pid = fork // die "fork! $!") {
            push @children_pids, $pid;
            close $inotify_parent_pipe;
        } else {

            close $inotify_child_pipe;

            local $SIG{HUP}= sub {
                say "$pid - inotify process terminated";
                exit 0;
            };

            require Linux::Inotify2;

            my $watch_mask = Linux::Inotify2->IN_CLOSE_WRITE;

            my $watcher = Linux::Inotify2->new();
            $watcher->blocking(0);

            my $on_change;
            $on_change = sub {
                # Some editors like vim will set this flag to true
                # Linux::Inotify2 will cancel the watcher if it gets
                # this flag  https://stackoverflow.com/a/16762193
                my $e = shift;
                if($e->IN_IGNORED) {
                    $watcher->watch($e->fullname, $watch_mask, $on_change);
                }
                print $inotify_parent_pipe "change$CRLF";

            };

            while (1) {
                check_messages_in_pipe($inotify_parent_pipe, sub {
                    my $module_path = shift;
                    say "$$ - Going to watch $module_path for changes";
                    $watcher->watch($module_path, $watch_mask, $on_change);
                });

                $watcher->poll;
            }
            exit 0;
        }
    }


    my $active = 1;
    my $watched_modules = {};

    MAIN:
    while($active) {
        my ($parent_pipe, $child_pipe) = open_pipe();

        if(my $pid = fork // die "fork: $!") {
            close $parent_pipe;
            say "$$ - Parent with $pid child";
            push @children_pids, $pid;

            # Note that we don't have object methods available yet, since that'd pull in IO::Handle

            { # Make sure we didn't pull in anything unexpected
                my %found = map {
                    # Convert filename to package name
                    (s{/}{::}gr =~ s{\.pm$}{}r) => 1,
                } keys %INC;

                # Trim out anything that we arbitrarily decided would be fine
                delete @found{keys %ALLOWED_MODULES};

                my $loaded_modules = join ',', sort keys %found;
                if ($loaded_modules) {
                    kill QUIT => $_ for @children_pids;
                    die "excessive module loading detected: $loaded_modules";
                }
            }

            local $SIG{HUP} = sub {
                say "$$ - HUP detected in parent";
                kill QUIT => $pid;
            };

            print $child_pipe "Parent active$CRLF";
            my $active = 1;
            ACTIVE:
            while ($active) {
                $active = 0 unless check_messages_in_pipe($inotify_child_pipe, sub {
                    say "$$ - File change has been detected, reloading..";
                    kill QUIT => $pid;
                    # wait for the process to finish
                    waitpid $pid, 0;
                    next MAIN;
                });

                $active = 0 unless check_messages_in_pipe($child_pipe, sub {
                    my $module = shift;
                    if (!$watched_modules->{$module}) {
                        print $inotify_child_pipe "${module}${CRLF}";
                        $watched_modules->{$module} = 1;
                    }
                });

                for my $child_pid (@children_pids) {
                    if(my $exit = waitpid $pid, $constant{WNOHANG}) {
                        say "$$ Exit was $exit";
                        # stop the other processes
                        kill QUIT => $_ for grep {$_ eq $child_pid} @children_pids;
                        last MAIN;
                    }
                }
            }
            say "$$ - Done";
            exit 0;
        } else {
            say "$$ - Child with parent " . $parent_pid;
            close $child_pipe;
            close $inotify_child_pipe;
            # We'd expect to pass through some more details here as well
            my %args = (
                parent_pipe => $parent_pipe
            );

            unshift @INC, sub {
                my ($code, $module) = @_;
                my ($path) = grep { !ref and -r "$_/$module"} @INC;
                if ($path) {
                    print $parent_pipe "$path/${module}${CRLF}";
                }
            };

            eval {
                # Support coderef or package name
                if(ref $target) {
                    $target->(%args);
                } else {
                    require Module::Load;
                    Module::Load::load($target);
                    my $module = $target->new;
                    $module->configure_from_argv(@ARGV)->await;
                    $module->run()->await;
                }
                1;
            } or do {
                my $error = $@;
                $error =~ s/\n/\n\t/g;
                print "$$ - target code/module exited unexpectedly due:\n\t$error";
            };

            exit 0;
        }
    }
}

1;

__END__

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2021. Licensed under the same terms as Perl itself.

