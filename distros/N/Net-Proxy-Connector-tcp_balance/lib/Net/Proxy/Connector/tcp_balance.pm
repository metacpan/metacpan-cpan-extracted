## no critic (RequireUseStrict)
package Net::Proxy::Connector::tcp_balance;
$Net::Proxy::Connector::tcp_balance::VERSION = '0.006';
## use critic (RequireUseStrict)
use strict;
use warnings;

require Net::Proxy::Connector::tcp;
use base "Net::Proxy::Connector::tcp";

sub connect {
    my @params = @_;
    my ($self) = shift @params;
    my @hosts_sorted = sort {int(rand(3))-1} @{$self->{hosts}};
    if ( $self->{sort} and $self->{sort} eq 'order' ){
        @hosts_sorted = sort @{$self->{hosts}};
    }
    elsif ( $self->{sort} and $self->{sort} eq 'none' ){
        @hosts_sorted = @{$self->{hosts}};
    }
    warn "[ ".localtime." ] tcp_balance hosts_sorted are: ".join(',', @hosts_sorted)."\n" if $self->{verbose};
    for ( @hosts_sorted ) {
        $self->{host} = $_;
        my $sock = eval { $self->SUPER::connect(@params); };
        if ($@) { # connect() dies if the connection fails
            warn "[ ".localtime." ] tcp_balance failed to connect to ".$self->{host} ." '$@'\n";
            next;
        }
        warn "[ ".localtime." ] tcp_balance connected to ".$self->{host} ." '$@'\n" if $self->{verbose};
        return $sock if $sock;
    }
    die "[ ".localtime." ] tcp_balance failed all hosts";
}

1;

=pod

=encoding UTF-8

=head1 NAME

Net::Proxy::Connector::tcp_balance - A Net::Proxy connector for outbound tcp balancing and failover

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    # sample proxy using Net::Proxy::Connector::tcp_balance
    use Net::Proxy;
    use Net::Proxy::Connector::tcp_balance; # optional

    # proxy connections from localhost:6789 to remotehost:9876
    # using standard TCP connections
    my $proxy = Net::Proxy->new(
        {   in  => { type => 'tcp', port => '6789' },
            out => { type => 'tcp_balance', hosts => [ 'remotehost1', 'remotehost2' ], port => '9876', verbose => 1 },
        }
    );
    $proxy->register();

    Net::Proxy->mainloop();

=head1 DESCRIPTION

C<Net::Proxy::Connector::tcp_balance> is an outbound tcp connector for C<Net::Proxy> that provides randomized load balancing and also provides failover when outbound tcp hosts are unavailable.

It will randomly connect to one of the specified hosts. If that host is unavailable, it will continue to try the other hosts until it makes a connection.

The capabilities of the C<Net::Proxy::Connector::tcp_balance> are otherwise identical to those C<Net::Proxy::Connector::tcp>

=head1 NAME

Net::Proxy::Connector::tcp_balance - connector for outbound tcp balancing and failover

=head1 CONNECTOR OPTIONS

The connector accept the following options:

=head2 C<in>

=over 4

=item * host

The listening address. If not given, the default is C<localhost>.

=item * port

The listening port.

=back

=head2 C<out>

=over 4

=item * hosts

The remote hosts.  An array ref.

=item * port

The remote port.

=item * sort

(Optional) Connect to the hosts in sort algorithm.  Possible values: order, none, random.  Default is random.

=item * timeout

The socket timeout for connection (C<out> only).

=item * verbose

(Optional) Will print to STDERR the list of sorted hosts for every request.

=back

=head1 AUTHOR

Jesse Thompson <zjt@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Jesse Thompson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: A Net::Proxy connector for outbound tcp balancing and failover

