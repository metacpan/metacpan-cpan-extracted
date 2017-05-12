package Sys::RevoBackup::Plugin::Zabbix;
{
  $Sys::RevoBackup::Plugin::Zabbix::VERSION = '0.27';
}
BEGIN {
  $Sys::RevoBackup::Plugin::Zabbix::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: revobackup plugin for Zabbix::Sender

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
use Try::Tiny;
use Zabbix::Sender;
use Sys::Hostname::FQDN ();

# extends ...
extends 'Sys::RevoBackup::Plugin';
# has ...
# with ...
# initializers ...
sub _init_priority { return 10; }

# your code here ...
sub run_prepare_hook {
    my $self = shift;

    my $hostname = Sys::Hostname::FQDN::fqdn();
    return $self->zabbix_report(time(),$hostname,'revobackup.started');
}

sub run_cleanup_hook {
    my $self = shift;
    my $ok = shift;

    my $hostname = Sys::Hostname::FQDN::fqdn();
    $self->zabbix_report(time(),$hostname,'revobackup.finished');

    return $self->zabbix_report($ok,$hostname,'revobackup.status');
}

sub zabbix_report {
    my $self     = shift;
    my $status   = shift;
    my $hostname = shift;
    my $item     = shift || 'revobackup.status';

    if ( my $zabbix_server = $self->config()->get('Zabbix::Server') ) {
        $self->logger()->log( message => 'Using Zabbix Server at '.$zabbix_server, level => 'debug', );
        my $arg_ref = {
            'server' => $zabbix_server,
            'port'   => $self->config()->get('Zabbix::Port') || 10_051,
        };
        $arg_ref->{'hostname'} = $hostname if $hostname;
        try {
            my $Zabbix = Zabbix::Sender::->new($arg_ref);
            $Zabbix->send( $item, $status );
            $Zabbix = undef;
        }
        catch {
            $self->logger()->log( message => 'Zabbix::Sender failed w/ error: '.$_, level => 'error', );
        };
        return 1;
    }
    else {
        $self->logger()->log( message => 'No Zabbix Server configured.', level => 'debug', );
        return;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::RevoBackup::Plugin::Zabbix - revobackup plugin for Zabbix::Sender

=head1 METHODS

=head2 run_cleanup_hook

Report the backup status to zabbix.

=head2 run_prepare_hook

Report the start time to zabbix.

=head2 zabbix_report

Report to zabbix.

=head1 NAME

Sys::RevoBackup::Plugin::Zabbix - Report backup status to Zabbix

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
