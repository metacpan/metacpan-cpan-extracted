package Sys::RevoBackup::Cmd::Command::cleanup;
{
  $Sys::RevoBackup::Cmd::Command::cleanup::VERSION = '0.27';
}
BEGIN {
  $Sys::RevoBackup::Cmd::Command::cleanup::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: cleanup command

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
use Sys::RevoBackup;
use Sys::RotateBackup;

# extends ...
extends 'Sys::RevoBackup::Cmd::Command';
# has ...
# with ...
# initializers ...

# your code here ...
sub execute {
    my $self = shift;

    my $Revo = Sys::RevoBackup::->new({
        'config'    => $self->config(),
        'logger'    => $self->logger(),
        'logfile'     => $self->config()->get( 'Sys::RevoBackup::Logfile', { Default => '/tmp/revo.log', } ),
        'bank' => $self->config()->get('Sys::RevoBackup::Bank', { Default => '/srv/backup/revobackup', } ),
        'concurrency' => 1,
    });

    my $vault_ref = $Revo->vaults();
    if($vault_ref && ref($vault_ref) eq 'ARRAY') {
        foreach my $vault (sort @{$vault_ref}) {
            # rotate the backups
            my $Rotor = Sys::RotateBackup::->new(
                {
                    'logger'  => $self->logger(),
                    'sys'     => $Revo->sys(),
                    'vault'   => $Revo->fs()->filename( ( $Revo->bank(), $vault ) ),
                    'daily'   => $self->config()->get( 'RevoBackup::Rotations::Daily', { Default => 10, } ),
                    'weekly'  => $self->config()->get( 'RevoBackup::Rotations::Weekly', { Default => 4, } ),
                    'monthly' => $self->config()->get( 'RevoBackup::Rotations::Monthly', { Default => 12, } ),
                    'yearly'  => $self->config()->get( 'RevoBackup::Rotations::Yearly', { Default => 10, } ),
                }
            );
            $Rotor->cleanup();
        }
    }

    return 1;
}

sub abstract {
    return 'Cleanup old and/or broken backups';
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::RevoBackup::Cmd::Command::cleanup - cleanup command

=head1 METHODS

=head2 abstract

Workaround

=head2 execute

Clean up old rotations.

=head1 NAME

Sys::RevoBackup::Cmd::Command::cleanup - Remove old/broken directories

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
