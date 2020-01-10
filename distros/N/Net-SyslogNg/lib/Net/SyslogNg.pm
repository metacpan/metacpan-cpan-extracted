package Net::SyslogNg;

use 5.14.2;
use strict;
use warnings;
use utf8;
use Carp qw/croak carp/;
use IO::Socket::INET;
use Sys::Hostname;
use DateTime;

our $VERSION    = '0.02';

my %SYSLOG_PRIORITIES = (
    'emerg'         => 0,
    'emergency'     => 0,
    'alert'         => 1,
    'crit'          => 2,
    'critical'      => 2,
    'err'           => 3,
    'error'         => 3,
    'warning'       => 4,
    'notice'        => 5,
    'info'          => 6,
    'informational' => 6,
    'debug'         => 7
);

my %SYSLOG_FACILITIES = (
    'kern'      => 0,
    'kernel'    => 0,
    'user'      => 1,
    'mail'      => 2,
    'daemon'    => 3,
    'system'    => 3,
    'auth'      => 4,
    'syslog'    => 5,
    'internal'  => 5,
    'lpr'       => 6,
    'printer'   => 6,
    'news'      => 7,
    'uucp'      => 8,
    'cron'      => 9,
    'clock'     => 9,
    'authpriv'  => 10,
    'security2' => 10,
    'ftp'       => 11,
    'FTP'       => 11,
    'NTP'       => 11,
    'audit'     => 13,
    'alert'     => 14,
    'clock2'    => 15,
    'local0'    => 16,
    'local1'    => 17,
    'local2'    => 18,
    'local3'    => 19,
    'local4'    => 20,
    'local5'    => 21,
    'local6'    => 22,
    'local7'    => 23,
);

sub new {
    my ($class, %opt) = @_;
    my $self = {};

    #Params
    $self->{'facility'}         = $opt{'-facility'}         // 'local5';
    $self->{'priority'}         = $opt{'-priority'}         // 'error';
    $self->{'syslog_port'}      = $opt{'-syslog_port'}      // 514;
    $self->{'syslog_host'}      = $opt{'-syslog_host'}      // '127.0.0.1';
    $self->{'debug'}            = $opt{'-debug'};

    return bless $self, $class;
}

sub send {
    my ($self, %opt) = @_;

    my $pid             = $opt{'-pid'}              // $$;
    my $msg             = $opt{'-msg'}              // '';
    my $version         = $opt{'-version'}          // 1;
    my $timestamp       = $opt{'-timestamp'}        // DateTime->now()->iso8601 . '.000Z';
    my $hostname        = $opt{'-hostname'}         // inet_ntoa( ( gethostbyname(hostname) )[4] );
    my $message_id      = $opt{'-message_id'}       // '-';
    my $structured_data = $opt{'-structured_data'}  // '-';
    my $application     = $opt{'-application'}      // '-';
    my $facility        = $opt{'-facility'}         // $self->{'facility'};
    my $priority        = $opt{'-priority'}         // $self->{'priority'};

    my $facility_i = $SYSLOG_FACILITIES{$facility} // croak "Wrong facility: '$facility'";
    my $priority_i = $SYSLOG_PRIORITIES{$priority} // croak "Wrong priority: '$priority'";

    my $priority_raw = ( ( $facility_i << 3 ) | ($priority_i) );
    my $msg_raw = "<$priority_raw>" . join(' ', $version, $timestamp, $hostname, $application, $pid, $message_id, $structured_data, $msg);

    my $sock = IO::Socket::INET->new(
        'PeerAddr'      => $self->{'syslog_host'},
        'PeerPort'      => $self->{'syslog_port'},
        'Proto'         => 'udp',
    ) or croak "Can't connect to $self->{'syslog_host'}:$self->{'syslog_port'} $@";

    print $sock $msg_raw;
    close $sock;

    if ($self->{'debug'}) {
        print STDOUT 'Syslog raw message: ' . $msg_raw, "\n";
    }

    return 1;
}



=pod

=encoding UTF-8

=head1 NAME

B<Net::SyslogNg> - client module for writing to syslog server (rfc5424)

=head1 VERSION

version 0.02

=head1 SYNOPSYS

    use Net::SyslogNg;

    # Create Net::SyslogNg object
    my $syslog = Net::SyslogNg->new(
        '-syslog_host'      => '127.0.0.1',
        '-syslog_port'      => 514,
    );

    # Send message to syslog
    $syslog->send(
        '-facility'         => 'daemon',
        '-priority'         => 'error',
        '-msg'              => 'Syslog error message',
    );

=head1 METHODS

=head2 new(%opt)

Create Net::SyslogNg object

    Options:
        -syslog_host            => Syslog host address
        -syslog_port            => Syslog port number
        -facility               => Facility name
        -priority               => Priority name
        -debug                  => Enable printing debug messages (default: 0)

=head2 send(%opt)

Send message to syslog daemon

    Options:
        -facility               => Facility name
        -priority               => Priority name
        -pid                    => Process id number (default: current process id)
        -msg                    => String of message
        -version                => Version number (default: 1)
        -timestamp              => Timestamp of message (default: current time in UTC)
        -hostname               => Hostname of syslog client (default: current hostname)
        -message_id             => Message id
        -structured_data        => Structured data field
        -application            => Application name

=head1 DEPENDENCE

L<Sys::Hostname>, L<IO::Socket::INET>, L<DateTime>

=head1 AUTHORS

=over 4

=item *

Pavel Andryushin <vrag867@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Pavel Andryushin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
