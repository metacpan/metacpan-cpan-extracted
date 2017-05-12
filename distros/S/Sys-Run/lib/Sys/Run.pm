package Sys::Run;
{
  $Sys::Run::VERSION = '0.16';
}
BEGIN {
  $Sys::Run::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: Run commands and handle their output.

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;

use Carp;
use File::Temp qw();
use File::Blarf;
use Net::Domain qw();
use Time::HiRes qw(gettimeofday tv_interval);

has 'ssh_agent' => (
    'is'        => 'rw',
    'isa'       => 'Bool',
    'default'   => 0,
);

has 'ssh_hostkey_check' => (
    'is'        => 'rw',
    'isa'       => 'Bool',
    'default'   => 1,
);

has 'log_times' => (
    'is'        => 'rw',
    'isa'       => 'Bool',
    'default'   => 0,
);

with qw(Log::Tree::RequiredLogger);

sub check_ssh_login {
    my $self   = shift;
    my $target = shift;
    my $opts   = shift || {};

    # check if pw-less ssh access works
    if ( $self->run_remote_cmd( $target, '/bin/true', $opts ) ) {
        $self->logger()->log( message => 'Password-less SSH access to '.$target.' is OK', level => 'debug', );
        return 1;
    }
    else {
        $self->logger()->log( message => 'Password-less SSH access to '.$target.' does not work. Aborting!', level => 'error', );
        return;
    }
}

sub clear_caches {
    my $self = shift;
    my $opts = shift || {};

    if(
       $self->run_cmd( 'echo 3 > /proc/sys/vm/drop_caches', $opts )
       &&
        $self->run_cmd( 'sync',                              $opts )
    ) { return 1; }

    return;
}

sub run_cmd {
    my $self = shift;
    my $cmd  = shift;
    my $opts = shift || {};

    my $outfile;
    my $tempdir;
    if ( $opts->{Logfile} ) {
        $cmd .= ' >>' . $opts->{Logfile} . ' 2>&1';
    }
    elsif ( $opts->{CaptureOutput} ) {
      if ( $opts->{Outfile} ) {
        if ( $opts->{Append} ) {
          $cmd .= ' >>'.$opts->{Outfile};
        } else {
          $cmd .= ' >' .$opts->{Outfile};
        }
      } else {
        # mktemp, redirect to tempfile
        $tempdir = File::Temp::->newdir( CLEANUP => 1, );
        $outfile = $tempdir . '/cmd.out';
        $cmd .= ' >'.$outfile;
      }
      # only redirect STDERR if not already redirected
      if($cmd !~ m/\s2>/) {
        $cmd .= ' 2>&1';
      }
    }
    else {
        if ( !$opts->{Verbose} && $cmd !~ m/>/ ) {
            $cmd .= ' >/dev/null 2>&1';
        }
    }

    my $msg = 'CMD: '.$cmd;
    $self->logger()->log( message => $msg, level => 'debug', );

    if ( $opts->{Logfile} ) {
        local $opts->{Append} = 1;
        File::Blarf::blarf( $opts->{Logfile}, time().' - '.$msg . "\n", $opts );
    }

    my $rv           = undef;
    my $timeout      = $opts->{Timeout} // 0;
    my $prev_timeout = 0;
    my $t0           = [gettimeofday];
    eval {
        local $SIG{ALRM} = sub { die "alarm-sys-run-cmd\n"; };
        $prev_timeout = alarm $timeout if $timeout > 0;
        if( $opts->{DryRun} ) {
          $rv = 0;
        } else {
          $rv = system($cmd) >> 8;
        }
    };
    alarm $prev_timeout if $timeout > 0;
    if ( $self->log_times() ) {
        my $d0 = tv_interval( $t0 );
        $self->logger()->log( message => 'CMD ran for '.$d0.'s', level => 'debug', );
    }
    if ( $@ && $@ eq "alarm-sys-run-cmd\n" ) {
        $rv = 1;
        $self->logger()->log( message => 'CMD timed out after '.$timeout, level => 'warning', );
    }
    if ( $opts->{Logfile} ) {
        local $opts->{Append} = 1;
        my $output = time().' - CMD finished. Exit Code: '.$rv."\n";
        if( $opts->{DryRun} ) {
          $output = 'CMD finished in DryRun mode. Faking exit code: 0.'."\n";
        }
        File::Blarf::blarf( $opts->{Logfile}, $output, $opts );
    }
    if ( defined($rv) && $rv == 0 ) {
        $self->logger()->log( message => 'Command completed successfully', level => 'debug', );
        if ( $opts->{CaptureOutput} && !$opts->{Outfile} ) {
            return File::Blarf::slurp( $outfile, $opts );
        }
        else {
            if ( $opts->{ReturnRV} ) {
                return $rv;
            }
            else {
                return 1;
            }
        }
    }
    else {
        $rv ||= '';
        $self->logger()->log( message => 'Could not execute '.$cmd.' without error. Exit Code: '.$rv.', Error: ' . $!, level => 'warning', );
        if ( $opts->{ReturnRV} ) {
            return $rv;
        }
        else {
            return;
        }
    }
}

sub run {
    my $self = shift;
    my $host = shift;
    my $cmd  = shift;
    my $opts = shift || {};

    if ( $host eq 'localhost' || $host eq Net::Domain::hostname() || $host eq Net::Domain::hostfqdn() ) {
        return $self->run_cmd( $cmd, $opts );
    }
    else {
        return $self->run_remote_cmd( $host, $cmd, $opts );
    }
}

sub _ssh_opts {
    my $self = shift;
    my $opts = shift || {};

    my $ssh_opts = '-oBatchMode=yes ';
    if ( $opts->{NoSSHStrictHostKeyChecking} || !$self->ssh_hostkey_check() ) {
        $ssh_opts .= '-oStrictHostKeyChecking=no ';
        $ssh_opts .= '-oUserKnownHostsFile=/dev/null ';
    }
    if ( $opts->{SSHVerbose} ) {
        $ssh_opts .= q{-v };
    } else {
        # if we're not supposed to be verbose, we're quiet
        $ssh_opts .= q{-q };
    }
    # add any extra ssh options, like ports et.al.
    if ( $opts->{SSHOpts} ) {
        $ssh_opts .= $opts->{SSHOpts}.q{ };
    }
    return $ssh_opts;
}

sub run_remote_cmd {
    my $self = shift;
    my $host = shift;
    my $cmd  = shift;
    my $opts = shift || {};

    if ( $opts->{NoHup} ) {

        # run remote cmds in background, this requires nohup
        $cmd = 'nohup ' . $cmd;
        if ( $cmd !~ m/>/ ) {

            # redirect output if not already done
            $cmd .= ' >/dev/null 2>/dev/null';
        }
        if ( $cmd !~ m/</ ) {

            # redirect input if not already done
            $cmd .= ' </dev/null';
        }
        $cmd .= ' &';
    }

    my $rcmd = 'ssh '.$self->_ssh_opts( $opts ).q{ }.$host.q{ '}.$cmd.q{'};

    # Do not use a forwarded SSH agent unless
    # explicitly asked for. Otherwise a long running operation, e.g. a sync,
    # may be started in a screen w/ the ssh auth of the user. When this users
    # logs off and a new ssh connection is opened it will fail if there
    # is no host key.
    local $ENV{SSH_AGENT_PID} = $ENV{SSH_AGENT_PID};
    local $ENV{SSH_AUTH_SOCK} = $ENV{SSH_AUTH_SOCK};
    if ( !$opts->{UseSSHAgent} || !$self->ssh_agent() ) {

        # DGR: already properly localized above
        ## no critic (RequireLocalizedPunctuationVars)
        $ENV{SSH_AGENT_PID} = q{};
        $ENV{SSH_AUTH_SOCK} = q{};
        ## use critic
    }
    $self->logger()->log( message => 'CMD: '.$rcmd, level => 'debug', );
    my $rv = $self->run_cmd( $rcmd, $opts );

    # WARNING: $rv IS NOT the OS return code! run_cmd has already
    # interpreted it and changed a OS-return-code of 0 to a true value (1)
    # UNLESS ReturnRV was set!
    #
    # unfortunately ReturnRV changes the semantics of $rv here
    # if ReturnRV is NOT set $rv must have a (perl) true value to indicate
    # success
    # if ReturnRV is set $rv must be exactly zer0 (i.e. a perl false) to indicate
    # sucess, any other value (usually) indicates an error
    if ( ( $opts->{ReturnRV} && defined($rv) && $rv == 0 ) || $rv ) {
        $self->logger()->log( message => 'Command successful', level => 'debug', );
        return $rv;
    }
    elsif ( $opts->{Retry} ) {
        $self->logger()->log( message => 'Command failed. Retrying.', level => 'notice', );
        my $i = 0;
        my $sleep = $opts->{Sleep} || 10;
        while ( $i++ < $opts->{Retry} ) {
            sleep $sleep;
            if ( my $rv_rtr = $self->run_cmd( $rcmd, $opts ) ) {
                $self->logger()->log( message => 'Command successful', level => 'debug', );
                return $rv_rtr;
            }
        }
        $self->logger()->log( message => 'Command failed. After ' . $opts->{Retry} . ' retries.', level => 'notice', );
        if ( $opts->{ReturnRV} ) {
            return $rv;
        }
        else {
            return;
        }
    }
    else {
        $self->logger()->log( message => 'Command failed. Without retry.', level => 'notice', );
        if ( $opts->{ReturnRV} ) {
            return $rv;
        }
        else {
            return;
        }
    }
}

sub check_binary {
    my $self   = shift;
    my $binary = shift;
    my $opts   = shift || {};

    my @path = split /:/, $ENV{PATH};

    # add common locations to search path, in case they are missing in PATH
    push( @path, qw(/sbin /bin /usr/sbin /usr/bin /usr/local/sbin /usr/local/bin) );
    foreach my $dir (@path) {
        my $loc = "$dir/$binary";
        if ( -x $loc ) {
            $self->logger()->log( message => 'Found binary '.$binary.' at '.$loc, level => 'debug', );
            return $loc;
        }
    }
    $self->logger()->log( message => 'Binary '.$binary.' not found in path ' . join( ':', @path ), level => 'notice', );
    return;
}

sub check_remote_binary {
    my $self   = shift;
    my $host   = shift;
    my $binary = shift;
    my $opts   = shift || {};

    local $opts->{CaptureOutput} = 1;
    local $opts->{Retry}         = 2;
    local $opts->{Chomp}         = 1;

    if ( $binary !~ m#^/# ) {
        $binary = $self->run_remote_cmd( $host, 'which ' . $binary, $opts );
    }
    if ( $binary !~ m#^/# ) {
        my $msg = 'Command '.$binary.' not found on host '.$host."!\n";
        $self->logger()->log( message => $msg, level => 'warning', );
        return;
    }
    local $opts->{CaptureOutput} = 0;

    return $self->run_remote_cmd( $host, 'test -x ' . $binary, $opts );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Run - Run commands and handle their output.

=head1 SYNOPSIS

    use Sys::Run;
    my $Sys = Sys::Run::->new({
        'logger' => Log::Tree::->new(),
    });
    my $ok = $Sys->run('sleep 60');

=head1 METHODS

=head2 check_ssh_login

Make sure an password-less SSH access to the target is working.

=head2 clear_caches

Clear all OS-level (linux) caches.

=head2 run_cmd

Run the given command.

Available options:
- Logfile
- CaptureOutput
-- Outfile
--- Append
- Verbose
- Timeout
- ReturnRV

=head2 run

Run the given command on the given hostname (maybe localhost).

=head2 run_remote_cmd

Run the given command on the remote host.

Available Options:
- NoHup
- UseSSHAgent
- NoSSHStrictHostKeyChecking
- SSHOpts
- ReturnRV
- Retry

=head2 check_binary

Make sure the given (unqalified) binary exists somewhere in the search path.

=head2 check_remote_binary

Make sure the given command is an executeable binary on the remote host.

=head1 NAME

Sys::Run - Run commands and handle their output.

=head1 DESCIRPTION

Run commands and handle output.

=head1 AUTHOR

Dominik Schulz <tex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
