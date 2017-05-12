package Sys::RevoBackup::Cmd::Command::configcheck;
{
  $Sys::RevoBackup::Cmd::Command::configcheck::VERSION = '0.27';
}
BEGIN {
  $Sys::RevoBackup::Cmd::Command::configcheck::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: revobackup config self-test

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
# use Try::Tiny;
use File::Blarf;
use Sys::RevoBackup;
use List::MoreUtils;

# extends ...
extends 'Sys::RevoBackup::Cmd::Command';
# has ...
has 'revobackup' => (
    'is'    => 'rw',
    'isa'   => 'Sys::RevoBackup',
    'lazy'  => 1,
    'builder' => '_init_revobackup',
);
# with ...
# initializers ...
sub _init_revobackup {
    my $self = shift;

    my $Revo = Sys::RevoBackup::->new({
        'config'        => $self->config(),
        'logger'        => $self->logger(),
        'logfile'       => $self->config()->get( 'Sys::RevoBackup::Logfile', { Default => '/tmp/revo.log', } ),
        'bank'          => $self->config()->get('Sys::RevoBackup::Bank', { Default => '/srv/backup/revobackup', } ),
        'concurrency'   => 1,
    });

    return $Revo;
}

# your code here ...
sub execute {
    my $self = shift;

    # verify configuration
    # - bankdir writeable
    # - at least one vault
    # - log writeable
    # - diskspace available
    # check config and configured dirs

    my $status = 1;

    # do we have a bank?
    my $bank = $self->revobackup()->bank();
    if($bank) {
        say 'OK - Bank directory configured: '.$bank;
        # is the bank a directory?
        if(-d $bank) {
            say 'OK - Bank location is a directory';
            # is it writeable?
            if(-w $bank) {
                say 'OK - Bank location is writeable';
            } else {
                say 'ERROR - Bank directory is not writebale!';
                $status = 0;
            }
        } else {
            say 'ERROR - Configured Bank is no directory!';
            $status = 0;
        }
    } else {
        say 'ERROR - No bank configured!';
        $status = 0;
    }

    # do we have at least one vault?
    my $vault_ref = $self->revobackup()->vaults();
    my $num_vaults = 0;
    if($vault_ref && ref($vault_ref) eq 'ARRAY') {
        # check each vault if it is accessible
        foreach my $vault (sort @{$vault_ref}) {
            if($self->_check_vault($vault)) {
                say 'OK - Valid vault '.$vault;
                $num_vaults++;
            } else {
                say 'ERROR - Invalid vault. See above for errors on '.$vault;
                $status = 0;
            }
        }
    }

    if(!$num_vaults) {
        say 'ERROR - No vaults configured';
        $status = 0;
    }

    return $status;
}

sub _check_vault {
    my $self = shift;
    my $vault = shift;

    my $source = $self->revobackup()->config()->get('Sys::Revobackup::Vaults::'.$vault.'::source');

    if($self->_check_vault_writeable($vault)) {
        # ok
    } else {
        return;
    }

    # make sure the source is defined
    if(!$source) {
        say ' ERROR - Source for '.$vault.' not defined!';
        return;
    }

    # check if pw-less ssh access works
    # make sure we connection to the source, if it is remote
    if($source =~ m#^([^:]+):#) {
        my $hostname = $1;
        if($self->_check_vault_ssh_connection($hostname)) {
            say ' OK - SSH access working to '.$vault;
        } else {
            say ' ERROR - SSH access failed! Check your public key setup for '.$vault;
            say '  HINT: ssh-copy-id -i '.$hostname;
            return;
        }
    }

    if($self->_check_vault_excludes($vault)) {
        # nop
    } else {
        return;
    }

    return 1;
}

sub _check_vault_writeable {
    my $self = shift;
    my $vault = shift;

    my $bank = $self->revobackup()->bank();

    # make sure the vault directory is writeable
    my $vault_dir = $bank.'/'.$vault;
    if(-e $vault_dir && -w $vault_dir) {
        say ' OK - Vault dir '.$vault_dir.' is writeable';
        return 1;
    } else {
        say ' ERROR - Vault dir '.$vault_dir.' not writeable!';
        return;
    }
}

sub _check_vault_excludes {
    my $self = shift;
    my $vault = shift;

    my $source = $self->revobackup()->config()->get('Sys::Revobackup::Vaults::'.$vault.'::source');
    my $xcl    = $self->revobackup()->config()->get('Sys::Revobackup::Vaults::'.$vault.'::excludefrom');
    my $ncfs   = $self->revobackup()->config()->get('Sys::Revobackup::Vaults::'.$vault.'::nocrossfs');
    my $status = 1;

    # check excludes
    if($xcl) {
        if(-e $xcl) {
            my @xcls = File::Blarf::slurp($xcl);
            if(!@xcls) {
                say ' WARNING - Exclude file for '.$vault.' exists but is empty!';
            }
            # if nocrossfs is disabled and the source is a fs root we require
            # exclusion of /proc/, /sys/ and /dev/
            if($ncfs == 0 && $source =~ m#:/$#) {
                foreach my $dir (qw(proc sys dev)) {
                    if(List::MoreUtils::none { $_ =~ m/$dir/ } @xcls) {
                        say ' ERROR - Missing mandatory exclude '.$dir.' in '.$xcl.' for '.$vault;
                        $status = 0;
                    }
                }
            }
        } else {
            say ' ERROR - Exclude file for '.$vault.' not found at '.$xcl;
        }
    }

    return $status;
}

sub _check_vault_ssh_connection {
    my $self = shift;
    my $hostname = shift;

    if ( $self->revobackup()->sys()->run_remote_cmd( $hostname, '/bin/true', { Timeout => 10, } ) ) {
        return 1;
    } else {
        return;
    }
}

sub abstract {
    return 'Check integrity of the configuration';
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::RevoBackup::Cmd::Command::configcheck - revobackup config self-test

=head1 METHODS

=head2 abstract

Workaround.

=head2 execute

Run the config check.

=head1 NAME

Sys::RevoBackup::Cmd::Command::configcheck - Perform a thorough configuration check

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
