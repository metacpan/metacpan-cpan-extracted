package Sys::RevoBackup::Worker;
{
  $Sys::RevoBackup::Worker::VERSION = '0.27';
}
BEGIN {
  $Sys::RevoBackup::Worker::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: a Revobackup Worker, does all the work

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
use English qw( -no_match_vars );

use File::Blarf;
use Sys::FS;

use Sys::RotateBackup;
use Sys::RevoBackup::Utils;

extends 'Sys::Bprsync::Worker';

sub _check_timeframe {
    return 1;
}

foreach my $key (qw(bank vault)) {
    has $key => (
        'is'       => 'ro',
        'isa'      => 'Str',
        'required' => 1,
    );
}

has 'rotation' => (
    'is'      => 'ro',
    'isa'     => 'Str',
    'lazy'    => 1,
    'builder' => '_init_rotation',
);

has 'dir_daily' => (
    'is'       => 'rw',
    'isa'      => 'Str',
    'required' => 0,
);

has 'dir_last_tree' => (
    'is'       => 'rw',
    'isa'      => 'Str',
    'required' => 0,
);

has 'linkdir' => (
    'is'      => 'rw',
    'isa'     => 'ArrayRef[Str]',
    'default' => sub { [] },
);

# loosen the inherited requirement
# the base class (bprsync) requires a destination
# but revobackup generates it itself
# based on the bank, vault and rotation
has '+destination' => ( 'required' => 0, );

has 'fs' => (
    'is'      => 'rw',
    'isa'     => 'Sys::FS',
    'lazy'    => 1,
    'builder' => '_init_fs',
);

sub _init_fs {
    my $self = shift;

    my $FS = Sys::FS::->new(
        {
            'logger' => $self->logger(),
            'sys'    => $self->sys(),
        }
    );

    return $FS;
}

sub _init_job_prefix {
    return 'Vaults';
}

sub _init {
    my $self = shift;

    return 1 if $self->_init_done();

    $self->{'hardlink'}    = 1;
    $self->{'delete'}      = 1;
    $self->{'numericids'}  = 1;
    $self->{'verbose'}     = 1;
    $self->{'description'} = $self->{'name'} unless $self->{'description'};

    # ok, now we have a config and a job name, we should be able to
    # get everything else from the config ...
    # scalars ...
    my $common_config_prefix = $self->parent()->config_prefix() . q{::} . $self->_job_prefix() . q{::} . $self->name() . q{::};
    foreach my $key (qw(description timeframe excludefrom rsh rshopts compression options bwlimit source nocrossfs sudo)) {
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
          } else {
            $self->parent()->logger()->log( message => 'Key '.$key.' ('.$common_config_prefix.$key.') was already set to '.$self->$key(), level => 'debug', );
          }
    }

    # arrays ...
    foreach my $key (qw(execpre execpost exclude linkdir)) {
        if ( !defined( $self->{$key} ) || ref( $self->{$key} ) ne 'ARRAY' || scalar( @{ $self->{$key} } ) < 1 ) {
            my $config_key = $common_config_prefix . $key;
            my @vals       = $self->parent()->config()->get_array($config_key);
            if (@vals) {
                $self->parent()->logger()->log( message => 'Set '.$key.' ('.$config_key.') for job ' . $self->name() . ' to ' . join( q{:}, @vals ), level => 'debug', );
                $self->{$key} = [@vals] if @vals;
            }
        }
    }

    if ( !defined( $self->{'nocrossfs'} ) ) {
        $self->logger()->log( message => 'Setting default value of nocrossfs to 1 because it was not previously defined.', level => 'debug', );
        $self->{'nocrossfs'} = 1;
    }

    $self->_init_done(1);

    return 1;
}

sub _init_rotation {
    my $self = shift;

    my $logfile = $self->fs()->filename( ( $self->bank(), $self->vault(), 'daily', '0', 'log' ) );

    # if less
    if ( -e $logfile ) {
        my @log = File::Blarf::slurp($logfile);
        if ( $log[0] =~ m/^BACKUP-STARTING:\s+(\d+)$/ ) {
            my $ts = $1;
            my $d  = time() - $ts;
            if ( $d < ( 23 * 60 * 60 ) ) {
                $self->logger()->log( message => 'Found timestamp ('.$ts.'), it is younger than one day ('.$d.' s old). Using 0 as rotation.', level => 'debug', );
                return '0';
            }
            else {
                $self->logger()->log( message => 'Found timestamp ('.$ts.'), but it is older than one day ('.$d.' s old). Creating new rotation.', level => 'debug', );
            }
        }
        else {
            $self->logger()->log( message => 'No timestamp found in logfile at '.$logfile.'. Creating new rotation.', level => 'debug', );
        }
    }
    else {
        $self->logger()->log( message => 'No logfile found at '.$logfile.'. Creating new rotation.', level => 'debug', );
    }

    return 'inprogress';
}

sub _prepare {
    my $self = shift;

    # Write timestamp to logfile
    my $logfile = $self->fs()->filename( ( $self->bank(), $self->vault(), 'daily', $self->rotation(), 'log' ) );
    File::Blarf::blarf( $logfile, 'BACKUP-STARTING: ' . time(),  { Append => 1, Flock => 1, Newline => 1, } );
    File::Blarf::blarf( $logfile, '# Localtime: ' . localtime(), { Append => 1, Flock => 1, Newline => 1, } );

    return 1;
}

sub BUILD {
    my $self = shift;

    $self->dir_daily( $self->fs()->filename( ( $self->bank(), $self->vault(), 'daily' ) ) );

    $self->{'destination'} = $self->fs()->filename( ( $self->dir_daily(), $self->rotation(), 'tree' ) ) . q{/};
    my $last_rotation = '0';
    if ( $self->rotation() eq 'inprogress' ) {
        $last_rotation = '0';

        # remove old inprogress-dir, if any
        my $progressdir = $self->fs()->filename( ( $self->dir_daily(), $self->rotation() ) );
        if ( -d $progressdir ) {
            my $cmd = 'rm -rf "' . $progressdir . q{"};
            $self->sys()->run_cmd($cmd);
        }
    }
    elsif ( $self->rotation() =~ m/^\d+$/ ) {
        $last_rotation = $self->rotation() - 1;
    }
    my $last_tree = $self->fs()->filename( ( $self->dir_daily(), $last_rotation, 'tree' ) );

    if ( !-d $self->destination() ) {
        my $cmd = 'mkdir -p ' . $self->destination();
        if ( $self->fs()->makedir( $self->destination() ) ) {
            $self->logger()->log( message => 'Created destination ' . $self->destination(), level => 'debug', );
        }
        else {
            $self->logger()->log( message => 'Could not create destination at ' . $self->destination() . ' - '.$OS_ERROR, level => 'error', );
        }
    }

    # we'll hardlink against last_tree if it exists
    if ( -d $last_tree ) {
        $self->dir_last_tree($last_tree);
    }

    return 1;
}

sub _cleanup {
    my $self = shift;
    my $ok   = shift;

    # Logfiles
    my $rsync_logfile = $self->logfile();
    my $logfile = $self->fs()->filename( ( $self->bank(), $self->vault(), 'daily', $self->rotation(), 'log' ) );

    # Read amount of transfered data from rsync logfile
    if ( -r $rsync_logfile ) {
        # DGR: the rsync logfile is probably huge, we MUST NOT slurp it into main memory
        ## no critic (RequireBriefOpen)
        if ( open( my $FH, '<', $rsync_logfile ) ) {
            while ( my $line = <$FH> ) {
                ## no critic (ProhibitComplexRegexes)
                if ( $line =~ m/^sent (\d+) bytes\s+received (\d+) bytes\s+([\d\.]+) bytes\/sec/i ) {
                    ## use critic
                    my ( $bytes_sent, $bytes_recv, $bytes_per_sec ) = ( $1, $2, $3 );
                    File::Blarf::blarf( $logfile, 'BYTES-SENT: ' . $bytes_sent,       { Append => 1, Flock => 1, Newline => 1, } );
                    File::Blarf::blarf( $logfile, 'BYTES-RECV: ' . $bytes_recv,       { Append => 1, Flock => 1, Newline => 1, } );
                    File::Blarf::blarf( $logfile, 'BYTES-PER-SEC: ' . $bytes_per_sec, { Append => 1, Flock => 1, Newline => 1, } );
                }
            }
            # DGR: just reading
            ## no critic (RequireCheckedClose)
            close($FH);
            ## use critic
        }
        ## use critic
    }

    # Move Rsync logfile into backupdir
    my $destfile = $self->dir_daily() . q{/} . $self->rotation() . '/rsync';

    # if we sync multiple times per day the logfile may already exist, so we append instead of overwriting
    if ( -e $destfile . '.gz' ) {

        # uncompress old logfile
        my $cmd = 'gzip -d -f "' . $destfile . '.gz"';
        $self->logger()->log( message => "CMD: $cmd", level => 'debug', );
        $self->sys()->run_cmd($cmd);

        # append new log
        $cmd = 'cat "' . $rsync_logfile . q{" >> "} . $destfile . q{"};
        $self->logger()->log( message => "CMD: $cmd", level => 'debug', );
        $self->sys()->run_cmd($cmd);

        # remove temp logfile
        $cmd = 'rm -f "' . $rsync_logfile . q{"};
        $self->logger()->log( message => "CMD: $cmd", level => 'debug', );
        $self->sys()->run_cmd($cmd);
    }
    else {
        my $cmd = 'mv '.$rsync_logfile.q{ } . $destfile;
        $self->logger()->log( message => "CMD: $cmd", level => 'debug', );
        if ( !$self->sys()->run_cmd($cmd) ) {
            return;
        }
    }

    # Compress rsync logfile
    my $cmd = 'gzip -f --fast ' . $destfile;
    $self->logger()->log( message => "CMD: $cmd", level => 'debug', );
    $self->sys()->run_cmd($cmd);

    # Create (compressed) index file
    $cmd = 'find ' . $self->dir_daily() . q{/} . $self->rotation() . '/tree/ -ls | gzip --fast > ' . $self->dir_daily() . q{/} . $self->rotation() . '/index.gz';
    $self->logger()->log( message => "CMD: $cmd", level => 'debug', );
    if ( !$self->sys()->run_cmd($cmd) ) {
        return;
    }

    # Write timestamp to logfile
    my $status = q{};
    $status .= 'RUNLOOPS:' . "\n";
    foreach my $runloop ( sort keys %{ $self->loop_status() } ) {
        my $rv     = $self->loop_status()->{$runloop}->{'rv'};
        my $reason = $self->loop_status()->{$runloop}->{'reason'};
        my $sev    = $self->loop_status()->{$runloop}->{'severity'};
        my $tstart = $self->loop_status()->{$runloop}->{'time_start'};
        my $tend   = $self->loop_status()->{$runloop}->{'time_finish'};
        $status .=
          "\tNo. " . $runloop . ' - Return-Code: ' . $rv . ' - Explaination: ' . $reason . ' - Severity: ' . $sev . ' - Starttime: '.$tstart.' - Endtime: '.$tend."\n";
    }
    $status .= 'BACKUP-STATUS: ';
    if ($ok) {
        $status .= 'OK';
    }
    else {
        $status .= 'ERROR';
    }
    File::Blarf::blarf( $logfile, $status . "\n" . 'BACKUP-FINISHED: ' . time(), { Append => 1, Flock => 1, Newline => 1, } );
    File::Blarf::blarf( $logfile, '# Localtime: ' . localtime(), { Append => 1, Flock => 1, Newline => 1, } );

    # Transfer the summary logfile to the host backed up
    $self->_upload_summary_log($logfile);

    # Rotate the backup, but only on successfull backups
    if ( $self->rotation() eq 'inprogress' && $ok ) {
        my $arg_ref = {
            'logger'  => $self->logger(),
            'sys'     => $self->sys(),
            'vault'   => $self->fs()->filename( ( $self->bank(), $self->vault() ) ),
            'daily'   => $self->config()->get( 'Sys::RevoBackup::Rotations::Daily', { Default => 10, } ),
            'weekly'  => $self->config()->get( 'Sys::RevoBackup::Rotations::Weekly', { Default => 4, } ),
            'monthly' => $self->config()->get( 'Sys::RevoBackup::Rotations::Monthly', { Default => 12, } ),
            'yearly'  => $self->config()->get( 'Sys::RevoBackup::Rotations::Yearly', { Default => 10, } ),
        };

        my $common_prefix = $self->parent()->config_prefix() . q{::} . $self->_job_prefix() . q{::} . $self->name() . q{::};
        if ( $self->config()->get( $common_prefix . 'Rotations' ) ) {
            $arg_ref->{'daily'}   = $self->config()->get( $common_prefix . 'Rotations::Daily',   { Default => 10, } );
            $arg_ref->{'weekly'}  = $self->config()->get( $common_prefix . 'Rotations::Weekly',  { Default => 4, } );
            $arg_ref->{'monthly'} = $self->config()->get( $common_prefix . 'Rotations::Monthly', { Default => 12, } );
            $arg_ref->{'yearly'}  = $self->config()->get( $common_prefix . 'Rotations::Yearly',  { Default => 10, } );
        }

        my $Rotor = Sys::RotateBackup::->new($arg_ref);
        $Rotor->rotate();
    } else {
      $self->logger()->log( message => 'Not rotating a failed backup!', level => 'debug', );
    }

    return 1;
}

sub _upload_summary_log {
    my $self    = shift;
    my $logfile = shift;

    if ( $self->source() =~ m/::/ ) {
        $self->logger()->log( message => 'Log-Upload not supported for rsyncd. Offending source: ' . $self->source(), level => 'notice', );
        return;
    }
    if ( $self->source() !~ m/:/ ) {
        $self->logger()->log( message => 'Log-Upload not supported for local backups. Offending source: ' . $self->source(), level => 'notice', );
        return;
    }
    if ( $self->source() =~ m/\@/ && $self->source() !~ m/^root\@/ && !$self->sudo() ) {
        $self->logger()
          ->log( message => 'Log-Upload not supported for remote backups as non-root user w/o sudo. Offending source: ' . $self->source(), level => 'notice', );
        return;
    }

    my $destination = $self->source();
    if ( $destination !~ m#/$# ) {
        $destination .= q{/};
    }
    $destination .= '.revobackup.log';
    my $source = $logfile;

    my ( $rsync_cmd, $rsync_opts, $dirs ) = $self->_rsync_cmd();
    $dirs = q{ } . $source . q{ } . $destination;
    my $cmd = $rsync_cmd . $rsync_opts . $dirs;

    my $opts = {
        'ReturnRV' => 0,
        'Timeout'  => 60,    # 1m
    };

    my $rv;
    if ( $self->parent()->config()->get( $self->parent()->config_prefix() . '::Dry' ) ) {
        $self->logger()->log( message => 'Log-Upload skipped due to dry-mode.', level => 'debug', );
        return 1;
    }
    else {
        $self->logger()->log( message => 'Log-Upload to commencing: ' . $cmd, level => 'debug', );
        if ( $self->sys()->run_cmd( $cmd, $opts ) ) {
            $self->logger()->log( message => 'Log-Upload successful to: ' . $dirs, level => 'debug', );
            return 1;
        }
        else {
            $self->logger()->log( message => 'Log-Upload failed to: ' . $dirs, level => 'warning', );
        }
    }
    return;
}

# try to find the last successfull backup
sub _find_last_working_backup {
    my $self = shift;
    my $start = shift || 0;

    foreach my $rotation ( $start .. $self->config()->get( 'Sys::RevoBackup::Rotations::Daily', { Default => 10, } ) ) {
        my $rot_dir = $self->fs()->filename( ( $self->dir_daily(), $rotation ) );
        # return the first OK backup
        if(Sys::RevoBackup::Utils::_backup_status_ok($rot_dir)) {
            return $self->fs()->filename( $rot_dir, 'tree' );
        }
    }

    return;
}

override '_rsync_cmd' => sub {
    my $self = shift;

    $self->_init();

    my ( $cmd, $opts, $dirs ) = super();

    # Hardlink unchanged files to the files of the last rotation
    if ( $self->dir_last_tree() && -d $self->dir_last_tree() ) {
        $opts .= ' --link-dest=' . $self->dir_last_tree();
    } else {
        my $dir = $self->dir_last_tree() || '';
        $self->logger()->log( message => 'No last rotation tree for this job found. Can not hardlink. Dir: '.$dir, level => 'warning', );
    }

    # If we do not have root access to the target host, we can also use
    # sudo to run rsync on the source host as root.
    if ( $self->sudo() ) {
      $opts .= ' --rsync-path="/usr/bin/sudo /usr/bin/rsync"';
    }

    # Rsync after 2.6.4 supports multiple link-dest options.
    # All given directories are searched for matching files
    # and hardlinked if found. This may be useful for initializing
    # large backup vaults based on another backup tool (migration).
    if ( $self->linkdir() ) {
        foreach my $link_dir ( @{ $self->linkdir() } ) {
            if ( $link_dir && -d $link_dir ) {
                $opts .= ' --link-dest='. $link_dir;
            } else {
                $self->logger()->log( message => 'Given linkdir not found for this job. Can not hardlink. Dir: '.$link_dir, level => 'warning', );
            }
        }
    }

    # Add the last successfull backup before daily/0, too
    my $addn_linkdir = $self->_find_last_working_backup(1);
    if( $addn_linkdir && -d $addn_linkdir ) {
        $opts .= ' --link-dest=' . $addn_linkdir;
    }

    my @cmd = ( $cmd, $opts, $dirs );

    return wantarray ? @cmd : join( q{}, @cmd );
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::RevoBackup::Worker - a Revobackup Worker, does all the work

=head1 METHODS

=head2 BUILD

Initialize the configuration.

=head1 NAME

Sys::RevoBackup::Worker - A RevoBackup Worker

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
