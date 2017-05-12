package Sys::Bprsync::Worker;
{
  $Sys::Bprsync::Worker::VERSION = '0.25';
}
BEGIN {
  $Sys::Bprsync::Worker::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: bprsync worker, does all the work

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
use English qw( -no_match_vars );

use Carp;
use File::Blarf;

use Sys::Run;

extends 'Job::Manager::Worker';

has 'parent' => (
    'is'       => 'ro',
    'isa'      => 'Sys::Bprsync',
    'required' => 1,
);

has 'sys' => (
    'is'      => 'rw',
    'isa'     => 'Sys::Run',
    'lazy'    => 1,
    'builder' => '_init_sys',
);

has 'name' => (
    'is'       => 'ro',
    'isa'      => 'Str',
    'required' => 1,
);

has '_job_prefix' => (
    'is'      => 'ro',
    'isa'     => 'Str',
    'lazy'    => 1,
    'builder' => '_init_job_prefix',
);

sub _init_job_prefix {
    return 'Jobs';
}

# ArrayRef[Str] - not required
foreach my $key (qw(execpre execpost exclude)) {
    has $key => (
        'is'       => 'ro',
        'isa'      => 'ArrayRef[Str]',
        'required' => 0,
        'default'  => sub { [] },
    );
}

# Str - not required
foreach my $key (qw(description source destination timeframe excludefrom options rsh rshopts)) {
    has $key => (
        'is'        => 'ro',
        'isa'       => 'Str',
        'required'  => 0,
        'clearer'   => 'clear_'.$key,
        'predicate' => 'has_'.$key,
    );
}

# Bool - not required - default 0
foreach my $key (qw(compression numericids verbose delete nocrossfs hardlink dry sudo)) {
    has $key => (
        'is'        => 'ro',
        'isa'       => 'Bool',
        'required'  => 0,
        'clearer'   => 'clear_'.$key,
        'predicate' => 'has_'.$key,
    );
}

# Int - not required
foreach my $key (qw(bwlimit)) {
    has $key => (
        'is'       => 'ro',
        'isa'      => 'Int',
        'required' => 0,
        'clearer'   => 'clear_'.$key,
        'predicate' => 'has_'.$key,
    );
}
has 'runloops' => (
    'is'      => 'ro',
    'isa'     => 'Int',
    'default' => 3,
);

has 'loop_status' => (
    'is'      => 'ro',
    'isa'     => 'HashRef',
    'default' => sub { {} },
);

has 'logfile' => (
    'is'      => 'ro',
    'isa'     => 'Str',
    'lazy'    => 1,
    'builder' => '_init_logfile',
);

has '_init_done' => (
  'is'      => 'rw',
  'isa'     => 'Bool',
  'default' => 0,
);

sub _init_sys {
    my $self = shift;

    return $self->parent()->sys();
}

sub _init {
    my $self = shift;

    return 1 if $self->_init_done();

    # ok, now we have a config and a job name, we should be able to
    # get everything else from the config ...
    # scalars ...
    my $common_config_prefix = $self->parent()->config_prefix() . q{::} . $self->_job_prefix() . q{::} . $self->name() . q{::};
    foreach my $key (qw(description timeframe excludefrom rsh rshopts compression options delete numericids bwlimit source destination nocrossfs hardlink sudo)) {
      my $predicate = 'has_'.$key;
      if ( !$self->$predicate() ) {
            my $config_key = $common_config_prefix . $key;
            my $val        = $self->parent()->config()->get($config_key);
            if ( defined($val) ) {
                $self->parent()->logger()->log( message => 'Set '.$key.' ('.$config_key.') for job ' . $self->name() . ' to '.$val, level => 'debug', );
                $self->{$key} = $val;
            }
            else {
                my $msg = 'Recommended configuration key '.$key.' ('.$config_key.') not found!';
                $self->parent()->logger()->log( message => $msg, level => 'debug', );
            }
        }
        else {
            $self->parent()->logger()->log( message => "Configration key $key is " . $self->{$key}, level => 'debug', );
        }
    }

    # arrays ...
    foreach my $key (qw(execpre execpost exclude)) {
        if ( !defined( $self->{$key} ) || ref( $self->{$key} ) ne 'ARRAY' || scalar( @{ $self->{$key} } ) < 1 ) {
            my $config_key = $common_config_prefix . $key;
            my @vals       = $self->parent()->config()->get_array($config_key);
            if (@vals) {
                $self->parent()->logger()->log( message => 'Set '.$key.' ('.$config_key.') for job ' . $self->name() . ' to ' . join( q{:}, @vals ), level => 'debug', );
                $self->{$key} = [@vals] if @vals;
            }
        }
        else {
            $self->parent()->logger()->log( message => 'Configration key '.$key.' is ' . $self->{$key}, level => 'debug', );
        }
    }

    if ( !$self->source() || !$self->destination() ) {
        croak('Missing source or destination!');
    }

    $self->_init_done(1);

    return 1;
}

sub _init_logfile {
    my $self = shift;

    return $self->parent()->logfile() . '.rsync.' . $PID;
}

sub run {
    my $self = shift;

    $self->_init();
    $self->_prepare();
    if ( !$self->_exec_pre() ) {
        $self->logger()->log( message => 'Exec-Pre failed', level => 'error', );
        return;
    }
    my $status = $self->_mainloop();
    $self->_cleanup($status);
    $self->_exec_post();
    return $status;
}

sub _prepare {
    my $self = shift;

    # Nothing to do.
    return 1;
}

sub _cleanup {
    my $self   = shift;
    my $status = shift;

    # cleanup logfile
    if ( -e $self->logfile() ) {
        my $target = $self->parent()->logfile() . '.rsync';
        if ( File::Blarf::cat( $self->logfile(), $target, { Flock => 1, Append => 1, } ) ) {
            $self->logger()->log( message => 'Appended temporary logfile (' . $self->logfile() . ') to '.$target, level => 'debug', );
            my $cmd = 'rm -f '.$self->logfile();
            if($self->sys()->run_cmd($cmd)) {
                $self->logger()->log( message => 'Removed temporary logfile: '.$self->logfile(), level => 'debug', );
            } else {
                $self->logger()->log( message => 'Failed to remove temporary logfile: '.$self->logfile(), level => 'warning', );
            }
        }
        else {
            $self->logger()->log( message => 'Failed to append temporary logfile (' . $self->logfile() . ') to '.$target, level => 'warning', );
        }
    }
    else {
        $self->logger()->log( message => 'No temporary logfile found at ' . $self->logfile(), level => 'notice', );
    }

    # Nothing to do.
    return 1;
}

sub _exec_pre {
    my $self = shift;

    my $ok = 1;
    foreach my $cmd ( @{ $self->execpre() } ) {
        if ( $self->sys()->run_cmd($cmd) ) {
            $self->logger()->log( message => 'Executed CMD '.$cmd.' w/ success.', level => 'debug', );
        }
        else {
            $self->logger()->log( message => 'Could not execute CMD '.$cmd.' w/o error.', level => 'error', );
            $ok = 0;
        }
    }
    return $ok;
}

sub _exec_post {
    my $self = shift;

    foreach my $cmd ( @{ $self->execpost() } ) {
        if ( $self->sys()->run_cmd($cmd) ) {
            $self->logger()->log( message => 'Executed CMD '.$cmd.' w/ success.', level => 'debug', );
        }
        else {
            $self->logger()->log( message => 'Could not execute CMD '.$cmd.' w/o error.', level => 'error', );
        }
    }

    return 1;
}

sub _rsync_cmd {
    my $self = shift;

    my $cmd = q{};
    $cmd .= $self->parent()->get_cmd_prefix();
    $cmd .= '/usr/bin/rsync';

    my $rsyncd_mode = 0;
    if ( $self->source() =~ m/::/ || $self->destination() =~ m/::/ || ( $self->rsh() && $self->rsh() =~ m/rsyncd/ ) ) {
        $rsyncd_mode = 1;
    }

    my $opts = q{};
    if ( $self->excludefrom() ) {
        $opts .= " --exclude-from=" . $self->excludefrom();
    }
    if ( $self->exclude() ) {
        my @excludes = @{ $self->exclude() };
        if (@excludes) {
            $opts .= ' --exclude="';
            $opts .= join( '" --exclude="', @excludes );
            $opts .= q{"};
        }
    }
    if ($rsyncd_mode) {
        $self->logger()->log( message => 'Skipping rsh handling, using rsyncd mode.', level => 'debug', );
        if ( $self->rshopts() ) {

            # for e.g. password-file
            $opts .= q{ } . $self->rshopts();
        }
    } else { # ssh mode
        if ( $self->rsh() ) {
          $opts .= ' -e "' . $self->rsh();
          if ( $self->rsh() eq 'ssh' ) {
            $opts .= $self->sys()->_ssh_opts();
          }
        }
        else {
          $opts .= ' -e "ssh '.$self->sys()->_ssh_opts();
        }
        if ( $self->rshopts() ) {
            $opts .= q{ } . $self->rshopts();
        }
        $opts .= q{"};    # finish args to -e (remote shell)
    }
    $opts .= ' -a';      # always set archive mode
    if ( $self->hardlink() ) {
        $opts .= ' -H';
    }
    if ( $self->nocrossfs() ) {
        $opts .= ' -x';
    }
    if ( $self->verbose() ) {
        $opts .= ' -v';
    }
    if ( $self->compression() ) {
        $opts .= ' -z';
    }
    if ( $self->options() ) {
        $self->parent()->logger()->log(
            message => q{DEPRECATION WARNING: The use of 'options' is deprecated! Please don't use it anymore! There are individual options now.},
            level   => 'warning'
        );

        # don't prepend '-' if already present
        if ( $self->options() =~ m/^\s*-/ ) {
            $opts .= q{ } . $self->options();
        }
        else {
            $opts .= q{ -} . $self->options();
        }
    }
    if ( $self->numericids() ) {
        $opts .= ' --numeric-ids';
    }
    if ( $self->bwlimit() ) {
        $opts .= ' --bwlimit=' . $self->bwlimit();
    }
    if ( $self->delete() ) {
        $opts .= ' --delete';
    }
    if ( $self->dry() ) {
        $opts .= ' --dry-run';
    }

    my $dirs = q{};
    $dirs .= q{ } . $self->source();
    $dirs .= q{ } . $self->destination();

    my @cmd = ( $cmd, $opts, $dirs );

    return wantarray ? @cmd : join( q{}, @cmd );
}

sub _mainloop {
    my $self   = shift;
    my %status = ();

    my $cmd = $self->_rsync_cmd();

    foreach my $runloop ( 1 .. $self->runloops() ) {
        last if ( !$self->_check_timeframe() );
        $self->parent()->logger()->log(
            message => 'Job: [' . $self->name() . '] ' . $self->description . ' (Runloop: '.$runloop.q{/} . $self->runloops() . ') starting ...',
            level   => 'debug'
        );

        $self->parent()->logger()->log( message => 'Starting ' . $self->description . q{ - } . $cmd, level => 'debug', );
        $self->parent()->logger()->log( message => 'CMD: '.$cmd, level => 'debug', );
        $self->loop_status()->{$runloop}->{'time_start'} = time();

        my $opts = {
            'Logfile'  => $self->logfile(),
            'ReturnRV' => 1,
            'Timeout'  => 60 * 60 * 23,       # 23h
        };

        my $rv;
        if ( $self->parent()->config()->get( $self->parent()->config_prefix() . '::Dry' ) ) {
            $rv = 0;
        }
        else {
            $rv = $self->sys()->run_cmd( $cmd, $opts );
        }

        my $reason   = q{};
        my $severity = 'debug';
        if ( $self->parent()->rsync_codes()->{$rv} ) {
            if ( $self->parent()->rsync_codes()->{$rv}[0] ) {
                $severity = $self->parent()->rsync_codes()->{$rv}[0];
            }
            if ( $self->parent()->rsync_codes()->{$rv}[1] ) {
                $reason = $self->parent()->rsync_codes()->{$rv}[1];
            }
        }
        $severity ||= 'debug';
        $self->parent()->logger()->log( message => 'Command finished with RV '.$rv.'. Reason: '.$reason, level => $severity, );
        $self->loop_status()->{$runloop}->{'rv'}          = $rv;
        $self->loop_status()->{$runloop}->{'reason'}      = $reason;
        $self->loop_status()->{$runloop}->{'severity'}    = $severity;
        $self->loop_status()->{$runloop}->{'time_finish'} = time();

        # end loop if fatal or no error, otherwise loop again
        if ( $self->parent()->rsync_codes()->{$rv}[0] eq 'fatal' ) {
            $self->logger()
              ->log( message => 'Exiting mainloop after runloop ' . $runloop . ' of ' . $self->runloops() . ' due to: a FATAL error', level => 'error', );
            return;
        }
        elsif ( $self->parent()->rsync_codes()->{$rv}[0] ne 'error' ) {
            $self->logger()
              ->log( message => 'Exiting mainloop after runloop ' . $runloop . ' of ' . $self->runloops() . ' due to: SUCCESS', level => 'debug', );
            return 1;
        }
    }

    $self->logger()->log(
        message => 'Exiting mainloop after runloop ' . $self->runloops() . ' of ' . $self->runloops() . ' due to: no more runloops left',
        level   => 'debug',
    );
    return 1;
}

sub _check_timeframe {
    my $self = shift;

    ## no critic (ProhibitExcessComplexity)
    my ( $from_hour, $from_min, $to_hour, $to_min ) = ( 0, 0, 0, 0 );
    if (   $self->timeframe()
        && $self->timeframe() =~ m/0?(\d?\d):0?(\d?\d)-0?(\d?\d):0?(\d?\d)/ )
    {
        $from_hour = $1;
        $from_min  = $2;
        $to_hour   = $3;
        $to_min    = $4;
        my $now_min  = ( localtime() )[1];
        my $now_hour = ( localtime() )[2];
        my $now_mday = ( localtime() )[3];
        my $now_mon  = ( localtime() )[4];
        my $now_year = ( localtime() )[5];

        # Check if this job may run now
        if (
            (
                (

                    # from < to
                    ( $from_hour < $to_hour || ( $from_hour == $to_hour && $from_min < $to_min ) )
                    && (
                        ## now < from
                        ( $now_hour < $from_hour || ( $now_hour == $from_hour && $now_min < $from_min ) )
                        ## now > to
                        || ( $now_hour > $to_hour || ( $now_hour == $to_hour && $now_min > $to_min ) )
                    )
                )
                || (

                    # from > to
                    ( $from_hour > $to_hour || ( $from_hour == $to_hour && $from_min > $to_min ) )
                    &&
                    ## now > to && now < from
                    ( $now_hour > $to_hour || ( $now_hour == $to_hour && $now_min > $to_min ) )
                    && ( $now_hour < $from_hour || ( $now_hour == $from_hour && $now_min < $from_min ) )
                )
            )
          )
        {
            $self->parent()->logger()->log(
                message => 'Skipping Job: '
                  . $self->description()
                  . ' because not within timeframe (time: '
                  . $now_hour . q{:}
                  . $now_min
                  . ', from: '
                  . $from_hour . q{:}
                  . $from_min
                  . ', to: '
                  . $to_hour . q{:}
                  . $to_min,
                level => 'debug'
            );
            return;
        }
    }
    ## use critic
    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Bprsync::Worker - bprsync worker, does all the work

=head1 METHODS

=head2 run

Run a sync job.

=head1 NAME

Sys::Bprsync::Worker - a BPrsync worker

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
