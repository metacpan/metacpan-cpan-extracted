package Sys::RevoBackup;
{
  $Sys::RevoBackup::VERSION = '0.27';
}
BEGIN {
  $Sys::RevoBackup::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: an rsync-based backup script

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
use English qw( -no_match_vars );
use Try::Tiny;

use Sys::Run;
use Job::Manager;
use Sys::RevoBackup::Job;

extends 'Sys::Bprsync' => { -version => 0.17 };

has 'bank' => (
    'is'       => 'ro',
    'isa'      => 'Str',
    'required' => 1,
);

has 'sys' => (
    'is'      => 'rw',
    'isa'     => 'Sys::Run',
    'lazy'    => 1,
    'builder' => '_init_sys',
);

has 'job_filter' => (
  'is'      => 'rw',
  'isa'     => 'Str',
  'default' => '',
);

with qw(Config::Yak::OrderedPlugins);

sub _plugin_base_class { return 'Sys::RevoBackup::Plugin'; }

sub _init_sys {
    my $self = shift;

    my $Sys = Sys::Run::->new( {
      'logger' => $self->logger(),
      'ssh_hostkey_check' => 0,
    } );

    return $Sys;
}

sub _init_config_prefix {
    return 'Sys::RevoBackup';
}

sub _init_jobs {
    my $self = shift;

    my $JQ = Job::Manager::->new(
        {
            'logger'      => $self->logger(),
            'concurrency' => $self->concurrency(),
        }
    );

    my $verbose = $self->config()->get( $self->config_prefix() . '::Verbose' ) ? 1 : 0;
    my $dry     = $self->config()->get( $self->config_prefix() . '::Dry' )     ? 1 : 0;

    VAULT: foreach my $job_name ( @{$self->vaults()} ) {
      if($self->job_filter() && $job_name ne $self->job_filter()) {
        # skip this job if it doesn't match the job filter
        $self->logger()->log( message => 'Skipping Job '.$job_name.' because it does not match the filter', level => 'debug', );
        next VAULT;
      }
        try {
            my $Job = Sys::RevoBackup::Job::->new(
                {
                    'parent'  => $self,
                    'name'    => $job_name,
                    'verbose' => $verbose,
                    'logger'  => $self->logger(),
                    'config'  => $self->config(),
                    'bank'    => $self->bank(),
                    'vault'   => $job_name,
                    'dry'     => $dry,
                }
            );
            $JQ->add($Job);
        }
        catch {
            $self->logger()->log( message => 'caught error: '.$_, level => 'error', );
        };
    }

    return $JQ;
}

sub vaults {
    my $self = shift;

    return [$self->config()->get_array( $self->config_prefix() . '::Vaults' )];
}

sub run {
    my $self = shift;

    foreach my $Plugin (@{$self->plugins()}) {
        try {
            $Plugin->run_config_hook();
        } catch {
            $self->logger()->log( message => 'Failed to run config hook of plugin '.ref($Plugin).' w/ error: '.$_, level => 'error', );
        };
    }

    foreach my $Plugin (@{$self->plugins()}) {
        try {
            $Plugin->run_prepare_hook();
        } catch {
            $self->logger()->log( message => 'Failed to run prepare hook of plugin '.ref($Plugin).' w/ error: '.$_, level => 'error', );
        };
    }

    if ( !$self->_exec_pre() ) {
        $self->_cleanup(0);
    }
    if ( $self->jobs()->run() ) {
        $self->_cleanup(1);
        $self->_exec_post();
        return 1;
    }
    else {
        return;
    }
}

sub _cleanup {
    my $self = shift;
    my $ok   = shift;

    foreach my $Plugin (@{$self->plugins()}) {
        try {
            $Plugin->run_cleanup_hook($ok);
        } catch {
            $self->logger()->log( message => 'Failed to run cleanup hook of plugin '.ref($Plugin).' w/ error: '.$_, level => 'error', );
        };
    }

    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::RevoBackup - an rsync-based backup script

=head1 METHODS

=head2 run

Run the backups.

=head2 vaults

Return a list of all vaults (i.e. backup jobs).

=head1 CONFIGURATION

Place the configuration inside /etc/revobackup/revobackup.conf

    <Sys>
        <RevoBackup>
            bank = /srv/backup/bank
            <Rotations>
                    daily = 10
                    weekly = 4
                    monthly = 12
                    yearly = 10
            </Rotations>
            <Vaults>
                    <test001>
                            source = /home/
                            description = Uhm
                            hardlink = 1
                            nocrossfs = 1
                    </test001>
                    <anotherhost>
                            source = anotherhost:/
                            description = Backup anotherhost
                    </anotherhost>
            </Vaults>
        </RevoBackup>
    </Sys>

=head1 NAME

Sys::RevoBackup - Rsync based backup script

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
