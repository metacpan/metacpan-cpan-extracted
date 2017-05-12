package Nagios::Plugin::CheckHost;

use strict;
use warnings;

our $VERSION = 0.05;
our $URL = 'https://check-host.net/';

use Net::CheckHost;
use Monitoring::Plugin;
use Class::Load qw(load_class);
use Nagios::Plugin::CheckHost::Node;
use Try::Tiny;

sub new {
    my ($class, %args) = @_;

    my $self = bless {
        checkhost    => Net::CheckHost->new(),
        delay        => 2,
        max_waittime => 30,
        %args,
    }, $class;

    $self->_initialize();
}

sub _initialize_nagios {
    my ($self, %args) = @_;

    $self->{nagios} = Monitoring::Plugin->new(
        shortname => 'CHECKHOST',
        usage     => 'Usage: %s -H <host> -w <warning> -c <critical>',
        url       => $URL,
        version   => $VERSION,
        %args
    );
}

sub nagios { $_[0]->{nagios} }

sub run {
    my $self = shift;
    my $np   = $self->{nagios};

    $np->getopts;
    my $opts      = $np->opts;
    my $host      = $opts->get('host');
    my $max_nodes = $opts->get('max_nodes');

    my $result = $self->_check(
        $self->{check}, $host,
        max_nodes   => $max_nodes,
    );
    $self->process_check_result($result);
}

sub _result_class {
    my ($self, $type) = @_;

    "Nagios::Plugin::CheckHost::Result::" . ucfirst($type)
}

sub _check {
    my ($self, $type, $host, %args) = @_;

    my $max_nodes = delete $args{max_nodes} || 3;
    my $max_failed_nodes = delete $args{max_failed_nodes};
    $max_failed_nodes = 1 unless defined $max_failed_nodes;
    my $result_args = delete $args{result_args} || {};

    my $result;

    try {
        my $check = $self->{checkhost}
          ->request("check-$type", host => $host, max_nodes => $max_nodes);

        my $rid = $check->{request_id};
        $self->{request_id} = $rid;

        my $result_class = $self->_result_class($type);
        load_class($result_class);
        $result = $result_class->new(%$result_args,
            nodes => $self->nodes_class($check->{nodes}));

        my $start = time();
        do {
            sleep $self->{delay};
            $result->store_result(
                $self->{checkhost}->request("check-result/$rid"));
          } while (time() - $start < $self->{max_waittime}
            && $result->unfinished_nodes);
    }
    catch {
        $self->{nagios}->die($_);
    };

    $result->remove_unfinished_nodes;
    $self->{nagios}->die("No check results. Report " . $self->report_url)
      unless $result->nodes;

    return $result;
}

sub nodes_class {
    my ($self, $nodes_list) = @_;
    my @nodes =
      map { Nagios::Plugin::CheckHost::Node->new($_ => $nodes_list->{$_}) }
      keys %$nodes_list;
    \@nodes;
}

sub report_url {
    my $self = shift;

    $URL . "check-report/" . $self->{request_id};
}

1;
__END__

=head1 NAME

Nagios::Plugin::CheckHost - Nagios plugin for checking checking availability of
hosts with L<http://Check-Host.net>.

=head1 SYNOPSIS

Command line usage:

    checkhost_http -H metacpan.org
    checkhost_ping -H metacpan.org

Usefull Nagios commands are available in C<nagios-checkhost.cfg>. 
You need to copy it to C</etc/nagios-plugins/config/>.
Next example show usage in Nagios:

    define service {
            service_description     HTTP CheckHost
            host_name               my.host.com
            check_command           checkhost_http
            use                     generic-service
    }

    define service {
            service_description     Ping CheckHost
            host_name               my.host.com
            check_command           checkhost_ping
            use                     generic-service
    }
    
=head1 SEE ALSO

L<http://Check-Host.net>

=head1 AUTHOR

Sergey Zasenko, C<undef@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016, Sergey Zasenko.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
