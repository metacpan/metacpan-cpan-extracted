package Net::Gearman::Administrative;
# ABSTRACT: A wrapper around Gearmans administrative protocol

use Moo;
use IO::Socket;
use Scalar::Util qw( looks_like_number );

has hostname => (
    is  => 'ro',
    isa => sub {
        my $valid_hostname = 1
            if $_[0]
            =~ /^(([a-zA-Z]|[a-zA-Z][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9])$/
            ;    # RFC 1123 Hostnames
        my $valid_ipv4 = 1
            if $_[0]
            =~ /^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/
            ;    # IPv4 Addresses
        my $valid_ipv6 = 1
            if $_[0]
            =~ /(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))/
            ;    # IPv6, obviously and fugly

        $valid_hostname || $valid_ipv4 || $valid_ipv6 || die('Neither a valid hostname, nor an IPv(4|6)!');
    },
    required => 1,
);

has port => (
    is  => 'ro',
    isa => sub {
        die('Port has to be a number') unless looks_like_number($_[0]);
        die('Port has to be a number between 1 and 65535') unless ($_[0] >= 1 && $_[0] <= 65535);
    },
    required => 1,
);

has socket => (
    is  => 'ro',
    isa => sub {
        die('Socket has to be a IO::Socket::INET reference!') unless ref($_[0]) eq 'IO::Socket::INET';
    },
    lazy    => 1,
    default => sub {
        my ($self) = @_;

        return IO::Socket::INET->new(
            PeerAddr => $self->hostname,
            PeerPort => $self->port,
            Proto    => 'tcp',
        );
    },
);

sub get_status {
    my ($self) = @_;

    my $socket = $self->socket;
    print $socket "status\n";

    my $ret = {};

    while ((my $line = readline $socket) ne ".\n") {
        chomp $line;
        my ($function, $pending_jobs, $current_jobs, $num_workers) = split("\t", $line);

        $ret->{$function}->{'pending_jobs'} = $pending_jobs;
        $ret->{$function}->{'current_jobs'} = $current_jobs;
        $ret->{$function}->{'num_workers'}  = $num_workers;
    }

    return $ret;
}

sub get_workers {
    my ($self) = @_;

    my $socket = $self->socket;
    print $socket "workers\n";

    my $ret = {};

    while ((my $line = readline $socket) ne ".\n") {
        chomp $line;

        my ($fd, $ip, $client_id, $seperator, @functions) = split(' ', $line);

        $ret->{$client_id}->{'fd'} = $fd;
        $ret->{$client_id}->{'ip'} = $ip;

        for my $function (@functions) {
            push(@{$ret->{$client_id}->{'functions'}}, $function);
        }
    }

    return $ret;
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Gearman::Administrative - A wrapper around Gearmans administrative protocol

=head1 VERSION

version 0.00101

=head1 DESCRIPTION

This module wraps around the administrative protocol of Gearman. You can use it to quere the registered workers, the number of pending jobs per function, ...

We only tested this module against Gearman::Server 1.12.

=head1 ATTRIBUTES

=head2 hostname

The address of the server to connect to.

Will be checked it either a valid hostname, a valid IPv4 oder a valid IPv6 address.

=head2 port

The port to connect to.

Must be a number between 1 and 65535 (inclusive).

=head1 METHODS

=head2 get_workers

Returns a HashRef with all registered workers.

    {
        $client_id => {
            fd        => $file_descriptor,
            ip        => $ip_address_of_worker,
            functions => [
                'mega_cool_function',
                'only_super_cool_function',
            ],
        }
    }

=head2 get_status

Returns a HashRef with all functions and the number of jobs.

    {
        $function => {
            num_workers  => $num_workers_with_this_function,
            pending_jobs => $jobs_in_queue_waiting_to_be_picked_up,
            current_jobs => $jobs_currently_being_processed_by_a_worker,
        }
    }

=head1 SYNOPSYS

    use Net::Gearman::Administrative;

    my $admin   = modules::Gearman::Administrative->new(hostname => '127.0.0.1', port => 7003);
    my $workers = $admin->get_workers;
    my $status  = $admin->get_status;

=head1 BUGS

Please report bugs and/or feature-requests at our GitHub repository:
https://github.com/autinitysystems/Net-Gearman-Administrative/issues

=head1 AUTHOR

Moritz Grosch <moritz.grosch@autinity.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by afr-consulting GmbH.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
