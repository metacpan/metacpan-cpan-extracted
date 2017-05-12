package Sys::RevoBackup::Utils;
{
  $Sys::RevoBackup::Utils::VERSION = '0.27';
}
BEGIN {
  $Sys::RevoBackup::Utils::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: Revobackup utilities

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use strict;
use warnings;

use File::Blarf;

sub backup_status {
    my $Config = shift;
    my $host   = shift;

    my $bankdir = $Config->get('Sys::RevoBackup::Bank');
    my $cfg     = $Config->get( 'Sys::RevoBackup::Vaults::' . $host );
    if ($cfg) {

        # Search string matches Vault name, now get the backup status
        my $backup_dir = $bankdir . q{/} . $host . '/daily/0';
        return _backup_ok($backup_dir);
    }
    else {
        foreach my $vault ( $Config->get_array('Sys::RevoBackup::Vaults') ) {
            my $source = $Config->get( 'Sys::RevoBackup::Vaults::' . $vault . '::Source' );
            if ( $source =~ m/:/ ) {
                my ( $hostname, $path ) = split /:/, $source;
                if ( $hostname =~ m/@/ ) {
                    ( undef, $hostname ) = split /\@/, $hostname;
                }
                if ( $host eq $hostname ) {
                    my $backup_dir = $bankdir . q{/} . $vault . '/daily/0';
                    return _backup_ok($backup_dir);
                }
            }
        }
    }
    return;
}

sub _backup_ok {
    my $dir = shift;

    if ( _backup_status_ok($dir) && _backup_ts_ok($dir) ) {
        return 1;
    }
    else {
        return;
    }
}

sub _backup_status_ok {
    my $dir = shift;

    return unless $dir;
    return unless -e $dir . '/log';

    my @lines        = File::Blarf::slurp( $dir . '/log', { Chomp => 1, } );
    my $status_ok    = 0;
    foreach my $line (@lines) {
        if ( $line =~ m/^BACKUP-STATUS: OK/i ) {
            $status_ok = 1;
        }
    }

    return $status_ok;
}

sub _backup_ts_ok {
    my $dir = shift;

    return unless $dir;
    return unless -e $dir . '/log';

    my @lines        = File::Blarf::slurp( $dir . '/log', { Chomp => 1, } );
    my $timestamp_ok = 0;
    foreach my $line (@lines) {
        if ( $line =~ m/^BACKUP-FINISHED: (\d+)/ ) {
            my $finish_ts = $1;

            # did the backup finish within the last 24h?
            if ( time() - $finish_ts < 24 * 60 * 60 ) {
                $timestamp_ok = 1;
            }
        }
    }

    return $timestamp_ok;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::RevoBackup::Utils - Revobackup utilities

=head1 METHODS

=head2 backup_status

Check the given backup.

=head1 NAME

Sys::RevoBackup::Utils - misc. RevoBackup utilities

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
