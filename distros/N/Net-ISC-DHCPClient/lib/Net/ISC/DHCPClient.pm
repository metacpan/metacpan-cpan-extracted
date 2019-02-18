package Net::ISC::DHCPClient;

use 5.014;
use strict;
use warnings;


=head1 NAME

Net::ISC::DHCPClient - ISC dhclient lease reader

=head1 VERSION

Version 0.14

=cut

our $VERSION = '0.14';


use Net::ISC::DHCPClient::InetLease;
use Net::ISC::DHCPClient::Inet6Lease;
use Time::Local;


sub new {
    my ($class, %opts) = @_;

    die "Missing leases_path!" if (!defined($opts{leases_path}));

    my $self = {};

    # Incoming arguments:
    $self->{INTERFACE} = defined($opts{interface}) ? $opts{interface} : undef;
    $self->{leases_path} = $opts{leases_path};

    # Internal storage:
    $self->{leases_af_inet} = undef;
    $self->{leases_af_inet6} = undef;

    bless ($self, $class);

    return $self;
}


sub is_dhcp($$;$)
{
    my ($self, $af, $inteface_to_query) = @_;

    die "Address family is: inet or inet6!" if (!($af eq 'inet' || $af eq 'inet6'));

    if (defined($inteface_to_query) &&
        defined($self->{INTERFACE}) &&
        $self->{INTERFACE} ne $inteface_to_query) {
        die sprintf("Cannot query interface %s, has %s.", $inteface_to_query, $self->{INTERFACE});
    }
    if (defined($self->{INTERFACE})) {
        if ($af eq 'inet') {
            $self->leases_af_inet();
            return scalar(@{$self->{leases_af_inet}}) > 0;
        }
        if ($af eq 'inet6') {
            $self->leases_af_inet6();
            return scalar(@{$self->{leases_af_inet6}}) > 0;
        }

        return 0;
    }

    die "Need interface!" if (!defined($inteface_to_query));

    # Iterate all found leases and look for given interface
    my $leases_to_check;
    $leases_to_check = $self->{leases_af_inet} if ($af eq 'inet');
    $leases_to_check = $self->{leases_af_inet6} if ($af eq 'inet6');
    for my $lease (@$leases_to_check) {
        return 1 if ($lease->{INTERFACE} eq $inteface_to_query);
    }

    return 0;
}

sub leases_af_inet($)
{
    my ($self) = @_;

    return $self->{leases_af_inet} if ($self->{leases_af_inet});

    $self->{leases_af_inet} = $self->_read_lease_file($self->{leases_path},
                                                $self->{INTERFACE},
                                                'inet');

    return $self->{leases_af_inet};
}

sub leases_af_inet6($)
{
    my ($self) = @_;

    return $self->{leases_af_inet6} if ($self->{leases_af_inet6});

    $self->{leases_af_inet6} = $self->_read_lease_file($self->{leases_path},
                                                $self->{INTERFACE},
                                                'inet6');

    return $self->{leases_af_inet6};
}


sub _read_lease_file($$$$)
{
    my ($self, $path, $interface, $af) = @_;
    my @isc_lease_files;
    my @netplan_lease_files;
    my $leases = [];

    # Search for matching .lease files
    my $leasefile_re1;
    my $leasefile_re2;
    my $leasefile_re3;
    if ($af eq 'inet') {
        if ($interface) {
            $leasefile_re1 = qr/^dhclient-(.*)?-($interface)\.lease$/;
            $leasefile_re2 = qr/^dhclient\.($interface)\.leases$/;
            $leasefile_re3 = qr/^internal-(.*)?-($interface)\.lease$/;
        } else {
            $leasefile_re1 = qr/^dhclient-(.*)?-(.+)\.lease$/;
            $leasefile_re2 = qr/^dhclient\.(.+)\.leases$/;
            $leasefile_re3 = qr/^internal-(.*)?-($interface)\.lease$/;
        }
    } elsif ($af eq 'inet6') {
        if ($interface) {
            $leasefile_re1 = qr/^dhclient6-(.*)?-($interface)\.lease$/;
            $leasefile_re2 = qr/^dhclient6\.($interface)\.leases$/;
        } else {
            $leasefile_re1 = qr/^dhclient6-(.*)?-(.+)\.lease$/;
            $leasefile_re2 = qr/^dhclient6\.(.+)\.leases$/;
        }
    } else {
        die "Unknown AF! '$af'";
    }

    my @paths_to_attempt;
    if (ref($path) eq "ARRAY") {
        @paths_to_attempt = @$path;
    } else {
        @paths_to_attempt = ($path);
    }
    foreach my $lease_path (@paths_to_attempt) {
        next if (! -d $lease_path || ! -X $lease_path);
        opendir(my $dh, $lease_path) or
            die "Cannot read lease directory $lease_path. Error: $!";
        my @all_files = readdir($dh);
        @isc_lease_files = grep { /$leasefile_re1/ && -f "$lease_path/$_" } @all_files;
        @isc_lease_files = grep { /$leasefile_re2/ && -f "$lease_path/$_" } @all_files if (!@isc_lease_files);
        @netplan_lease_files = grep { /$leasefile_re3/ && -f "$lease_path/$_" } @all_files if ($leasefile_re3);
        closedir($dh);

        if (@isc_lease_files) {
            @isc_lease_files = map("$lease_path/$_", @isc_lease_files);
        }
        if (@netplan_lease_files) {
            @netplan_lease_files = map("$lease_path/$_", @netplan_lease_files);
        }
        last if (@isc_lease_files || @netplan_lease_files);
    }

    for my $leaseFile (@isc_lease_files) {
        open (LEASEFILE, $leaseFile) or
            die "Cannot open leasefile $leaseFile. Error: $!";

        my $currentLease;
        my $hasIscLeaseData = 0;
        my $ia_type = [];
        while (<LEASEFILE>) {
            chomp();
            if (/^lease? \{/) {
                $hasIscLeaseData = 1;
                $currentLease = Net::ISC::DHCPClient::InetLease->new();
                next;
            }
            if (/^lease6 \{/) {
                $hasIscLeaseData = 1;
                $currentLease = Net::ISC::DHCPClient::Inet6Lease->new();
                next;
            }
            if (/^\}/) {
                # dhclient will append lease information, newest is last.
                # unshift() will place newest first.
                unshift(@$leases, $currentLease) if ($hasIscLeaseData);
                $hasIscLeaseData = 0;
                next;
            }

            if (!$hasIscLeaseData) {
                next;
            }

            s/^\s+//;   # Eat starting whitespace
            $self->_isc_af_inet_lease_parser($currentLease, $_) if ($af eq 'inet');
            $self->_isc_af_inet6_lease_parser($currentLease, $ia_type, $_) if ($af eq 'inet6');
        } # end while (<LEASEFILE>)
        close (LEASEFILE);
    }

    for my $leaseFile (@netplan_lease_files) {
        open (LEASEFILE, $leaseFile) or
            die "Cannot open leasefile $leaseFile. Error: $!";

        my $currentLease;
        my $ia_type = [];
        while (<LEASEFILE>) {
            chomp();
            next if (!/^([^=]+)=(.*)$/);

            my $freshLease = 0;
            if (!$currentLease) {
                $currentLease = Net::ISC::DHCPClient::InetLease->new();
                $freshLease = 1;
            }
            $self->_netplan_af_inet_lease_parser($currentLease, $1, $2) if ($af eq 'inet');
            if ($freshLease) {
                # Netplan lease file doesn't have interface information in
                # the file. Parse the filename for interface.
                if ($leaseFile =~ /-([^-.]+)\.lease$/) {
                    $currentLease->{INTERFACE} = $1;
                }
            }
        } # end while (<LEASEFILE>)
        close (LEASEFILE);

        # There will be only 1 lease in the netplan lease file
        unshift(@$leases, $currentLease) if ($currentLease);
    }

    return $leases;
}

sub _isc_af_inet_lease_parser($$$)
{
    my ($self, $currentLease, $line) = @_;

    SWITCH: {
        # interface "eth1";
        /^interface\s+"(.+)";/ && do {
            $currentLease->{INTERFACE} = $1;
            last SWITCH;
        };
        # fixed-address 213.28.228.27;
        /^fixed-address\s+(.+);/ && do {
            $currentLease->{FIXED_ADDRESS} = $1;
            last SWITCH;
        };
        # option subnet-mask 255.255.255.0;
        (/^option\s+(\S+)\s*(.+);/) && do {
            $currentLease->{OPTION}{$1} = $2;
            last SWITCH;
        };
        # renew 5 2002/12/27 06:25:31;
        (m#^renew\s+(\d+)\s+(\d+)/(\d+)/(\d+)\s+(\d+):(\d+):(\d+);#) && do {
            my $leaseTime = timegm($7, $6, $5, $4, $3-1, $2);
            $currentLease->{RENEW} = $leaseTime;
            last SWITCH;
        };
        # rebind 5 2002/12/27 06:25:31;
        (m#^rebind\s+(\d+)\s+(\d+)/(\d+)/(\d+)\s+(\d+):(\d+):(\d+);#) && do {
            my $leaseTime = timegm($7, $6, $5, $4, $3-1, $2);
            $currentLease->{REBIND} = $leaseTime;
            last SWITCH;
        };
        # renew 5 2002/12/27 06:25:31;
        (m#^expire\s+(\d+)\s+(\d+)/(\d+)/(\d+)\s+(\d+):(\d+):(\d+);#) && do {
            my $leaseTime = timegm($7, $6, $5, $4, $3-1, $2);
            $currentLease->{EXPIRE} = $leaseTime;
            last SWITCH;
        };
    }
}

sub _isc_af_inet6_lease_parser($$$$)
{
    my ($self, $currentLease, $ia_type, $line) = @_;

    my $context = '';
    my $addr = '';
    $context = $ia_type->[0] if (defined($ia_type->[0]));
    $addr = $ia_type->[1] if (defined($ia_type->[1]));

    SWITCH: {
        # interface "eth1";
        /^interface\s+"(.+)";/ && do {
            $currentLease->{INTERFACE} = $1;
            last SWITCH;
        };
        /^ia-na\s+(\S+)\s*\{/ && do {
            # Identity Association: Non-temporary Address
            push(@$ia_type, 'non-temporary');
            $currentLease->{IA}->{'non-temporary'} = {};
            last SWITCH;
        };
        /^ia-pd\s+(\S+)\s*\{/ && do {
            # Identity Association: Prefix Delegation
            push(@$ia_type, 'prefix');
            $currentLease->{IA}->{'prefix'} = {};
            last SWITCH;
        };
        /^\}/ && do {
            pop(@$ia_type);
            last SWITCH;
        };
        # starts 1517742816;
        # Note: either IA or address
        /^(starts)\s+(\d+);/ && do {
            if (defined($ia_type->[1])) {
                $currentLease->{IA}->{$context}->{$addr}->{$1} = $2;
            } else {
                $currentLease->{IA}->{$context}->{$1} = $2;
            }
            last SWITCH;
        };
        # renew 302400;
        /^(renew)\s+(\d+);/ && do {
            $currentLease->{IA}->{$context}->{$1} = $2;
            last SWITCH;
        };
        # rebind 483840;
        /^(rebind)\s+(\d+);/ && do {
            $currentLease->{IA}->{$context}->{$1} = $2;
            last SWITCH;
        };
        # preferred-life 604800;
        /^(preferred-life)\s+(\d+);/ && do {
            $currentLease->{IA}->{$context}->{$addr}->{$1} = $2;
            last SWITCH;
        };
        # max-life 2592000;
        /^(max-life)\s+(\d+);/ && do {
            $currentLease->{IA}->{$context}->{$addr}->{$1} = $2;
            last SWITCH;
        };
        /^(iaaddr)\s+(\S+)\s*\{/ && do {
            # Identity Association Address
            push(@$ia_type, $1);
            $currentLease->{IA}->{$context}->{$1}->{addr} = $2;
            last SWITCH;
        };
        /^(iaprefix)\s+(\S+)\s*\{/ && do {
            # Identity Association Prefix
            push(@$ia_type, $1);
            $currentLease->{IA}->{$context}->{$1}->{addr} = $2;
            last SWITCH;
        };
        /^option\s+dhcp6\.(\S+)\s+(.+)$/ && do {
            # option dhcp6.<option> <value>
            # Collect only global options, skip the IA options
            $currentLease->{OPTION}->{$1} = $2 if (!$context);
            last SWITCH;
        };
    }
}

sub _netplan_af_inet_lease_parser($$$$)
{
    my ($self, $currentLease, $variable, $value) = @_;

    SWITCH: {
        # ADDRESS=62.248.219.173
        $variable eq "ADDRESS" && do {
            $currentLease->{FIXED_ADDRESS} = $value;
            last SWITCH;
        };
        # NETMASK=255.255.255.0
        $variable eq "NETMASK" && do {
            $currentLease->{OPTION}{'subnet-mask'} = $value;
            last SWITCH;
        };
        # ROUTER=62.248.219.1
        $variable eq "ROUTER" && do {
            $currentLease->{OPTION}{'routers'} = $value;
            last SWITCH;
        };
        # SERVER_ADDRESS=195.74.3.56
        $variable eq "SERVER_ADDRESS" && do {
            $currentLease->{OPTION}{'dhcp-server-identifier'} = $value;
            last SWITCH;
        };
        # DNS=195.197.54.100 212.54.0.3
        $variable eq "DNS" && do {
            # Have the IP-list comma separated
            $currentLease->{OPTION}{'domain-name-servers'} = ($value =~ s/ +/,/gr);
            last SWITCH;
        };
        # NTP=193.66.253.102 193.66.253.82
        $variable eq "NTP" && do {
            # Have the IP-list comma separated
            $currentLease->{OPTION}{'ntp-servers'} = ($value =~ s/ +/,/gr);
            last SWITCH;
        };
        # DOMAINNAME=elisa-laajakaista.fi
        $variable eq "SERVER_ADDRESS" && do {
            $currentLease->{OPTION}{'domain-name'} = $value;
            last SWITCH;
        };
        # T1=3600
        $variable eq "T1" && do {
            # Take current time, and add the value on it.
            # Nowhere near the actual value, but it's better than nothing!
            my $leaseTime = time() + int($value);
            $currentLease->{RENEW} = $leaseTime;
            last SWITCH;
        };
        # T2=6300
        $variable eq "T2" && do {
            # Take current time, and add the value on it.
            # Nowhere near the actual value, but it's better than nothing!
            my $leaseTime = time() + int($value);
            $currentLease->{REBIND} = $leaseTime;
            last SWITCH;
        };
        # LIFETIME=7200
        $variable eq "LIFETIME" && do {
            # Take current time, and add the value on it.
            # Nowhere near the actual value, but it's better than nothing!
            my $leaseTime = time() + int($value);
            $currentLease->{OPTION}{'dhcp-lease-time'} = int($value);
            $currentLease->{EXPIRE} = $leaseTime;
            last SWITCH;
        };
    }
}


=head1 AUTHOR

Jari Turkia, C<< <jatu at hqcodeshop.fi> >>

=head1 BUGS

Please report any bugs or feature requests to GitHub https://github.com/HQJaTu/Net-ISC-DHCPClient.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::ISC::DHCPClient


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-ISC-DHCPClient>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-ISC-DHCPClient>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-ISC-DHCPClient>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-ISC-DHCPClient/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jari Turkia.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut


# vim: tabstop=4 shiftwidth=4 softtabstop=4 expandtab:

1; # End of Net::ISC::DHCPClient
