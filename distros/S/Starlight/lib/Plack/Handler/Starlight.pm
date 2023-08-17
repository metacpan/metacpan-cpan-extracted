package Plack::Handler::Starlight;

=head1 NAME

Plack::Handler::Starlight - Plack adapter for Starlight

=head1 SYNOPSIS

=for markdown ```perl

    use Plack::Loader;

    my $loader = Plack::Loader->load('Starlight', port => 80);
    $loader->run(sub { [200, ['Content-Type', 'text/plain'], ['PSGI app']] });

=for markdown ```

=head1 DESCRIPTION

This is a stub module that allows Starlight to be loaded up under L<plackup>
and other L<Plack> tools. Set C<$ENV{PLACK_SERVER}> to C<'Starlight'> or use
the -s parameter to L<plackup> to use Starlight under L<Plack>.

See L<plackup> and L<starlight> (lower case) for available command line
options.

=cut

use strict;
use warnings;

our $VERSION = '0.0503';

use base qw(Starlight::Server);

use Config ();
use English '-no_match_vars';
use Fcntl ();
use File::Spec;
use POSIX ();
use Plack::Util;

use constant HAS_WIN32_PROCESS => $^O eq 'cygwin' && eval { require Win32::Process; 1; } && 1;

use constant DEBUG => $ENV{PERL_STARLIGHT_DEBUG};

sub new {
    my ($class, %args) = @_;

    # setup before instantiation
    my $max_workers = 10;
    for (qw(max_workers workers)) {
        $max_workers = delete $args{$_}
            if defined $args{$_};
    }

    # instantiate and set the variables
    my $self = $class->SUPER::new(%args);
    if ($^O eq 'MSWin32') {

        # forks are emulated
        $self->{is_multithread} = Plack::Util::TRUE;
        $self->{is_multiprocess} = Plack::Util::FALSE;
    } else {

        # real forks
        $self->{is_multithread} = Plack::Util::FALSE;
        $self->{is_multiprocess} = Plack::Util::TRUE;
    }
    $self->{max_workers} = $max_workers;

    $self->{main_process} = $$;
    $self->{processes} = +{};

    $self->{_kill_stalled_processes_delay} = 10;

    $self;
}

sub run {
    my ($self, $app) = @_;

    $self->_daemonize();

    warn "*** starting main process $$" if DEBUG;
    $self->setup_listener();

    $self->_setup_privileges();

    local $SIG{PIPE} = 'IGNORE';

    local $SIG{CHLD} = sub {
        my ($sig) = @_;
        warn "*** SIG$sig received in process $$" if DEBUG;
        local ($!, $?);
        my $pid = waitpid(-1, &POSIX::WNOHANG);    ## no critic
        return if $pid == -1;
        delete $self->{processes}->{$pid};
    };

    my $sigint = $self->{_sigint};
    my $sigterm = $^O eq 'MSWin32' ? 'KILL' : 'TERM';

    if ($self->{max_workers} != 0) {
        local $SIG{$sigint} = local $SIG{TERM} = sub {
            my ($sig) = @_;
            warn "*** SIG$sig received in process $$" if DEBUG;
            $self->{term_received}++;
        };
        for (my $loop = 0; not $self->{term_received}; $loop++) {
            warn "*** running ", scalar keys %{ $self->{processes} }, " processes" if DEBUG;
            if ($loop >= $self->{_kill_stalled_processes_delay} / ($self->{main_process_delay} || 1)) {
                $loop = 0;

                # check stalled processes once per n sec
                foreach my $pid (keys %{ $self->{processes} }) {
                    delete $self->{processes}->{$pid} if not kill 0, $pid;
                }
            }
            foreach my $n (1 + scalar keys %{ $self->{processes} } .. $self->{max_workers}) {
                $self->_create_process($app);
                $self->_sleep($self->{spawn_interval});
            }

            # slow down main process
            $self->_sleep($self->{main_process_delay});
        }
        if (my @pids = keys %{ $self->{processes} }) {
            warn "*** stopping ", scalar @pids, " processes" if DEBUG;
            foreach my $pid (@pids) {
                warn "*** stopping process $pid" if DEBUG;
                kill $sigterm, $pid;
            }
            if (HAS_WIN32_PROCESS) {
                $self->_sleep(1);
                foreach my $pid (keys %{ $self->{processes} }) {
                    my $winpid = Cygwin::pid_to_winpid($pid) or next;
                    warn "*** terminating process $pid winpid $winpid" if DEBUG;
                    Win32::Process::KillProcess($winpid, 0);
                }
            }
            $self->_sleep(1);
            foreach my $pid (keys %{ $self->{processes} }) {
                warn "*** waiting for process ", $pid if DEBUG;
                waitpid $pid, 0;
            }
        }
        if ($^O eq 'cygwin' and not HAS_WIN32_PROCESS) {
            warn "Win32::Process is not installed. Some processes might be still active.\n";
        }
        warn "*** stopping main process $$" if DEBUG;
        exit 0;
    } else {

        # run directly, mainly for debugging
        local $SIG{$sigint} = local $SIG{TERM} = sub {
            my ($sig) = @_;
            warn "*** SIG$sig received in process $$" if DEBUG;
            exit 0;
        };
        while (1) {
            $self->accept_loop($app, $self->_calc_reqs_per_child());
            $self->_sleep($self->{spawn_interval});
        }
    }
}

1;

__END__

=head1 SEE ALSO

L<starlight>,
L<Starlight>,
L<Plack>,
L<Plack::Runner>.

=head1 LICENSE

Copyright (c) 2013-2016, 2020, 2023 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>
