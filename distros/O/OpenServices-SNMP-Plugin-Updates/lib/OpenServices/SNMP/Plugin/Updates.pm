package OpenServices::SNMP::Plugin::Updates;

use 5.006;
use strict;
use warnings FATAL => 'all';

use NetSNMP::agent qw(:all);
use NetSNMP::ASN qw(:all);

use XML::XPath;

my $cache = {};

=head1 NAME

OpenServices::SNMP::Plugin::Updates - Expose pending security updates over SNMP

=head1 VERSION

Version 1.0.4

=cut

our $VERSION = '1.0.4';

=head1 BASE OID

    NetSNMP::OID(".1.3.6.1.4.1.36425.256.2");

=cut

our $BASEOID = new NetSNMP::OID(".1.3.6.1.4.1.36425.256.2");


=head1 SYNOPSIS

Extend net-snmp agent to report pending security updates.

Currently supported distributions:
 * GNU/Debian (apt-get)
 * RHEL/Fedora/CentOS (yum)
 * SLES/SLED/OpenSuSE (zypper)

To load the module in snmpd add the following line to snmpd.conf.

    perl require OpenServices::SNMP::Plugin; OpenServices::SNMP::Plugin->init($agent);

Or use OpenServices::SNMP for a convenient loader.

It exposes the number of pending updates on the OID 1.3.6.1.4.1.36425.256.2 and each separate package with its name on OID
1.3.6.1.4.1.36425.256.2.<N>.

=head1 SUBROUTINES/METHODS

=head2 init

=cut

sub init {
    my ($self, $agent) = @_;
    if (!$agent) {
        print STDERR "No \$agent defined\n";
        print STDERR "Please check your snmp_perl.pl that should be included in your net-snmp distribution.\n";
        exit 1;
    }

    printf STDERR "Registering %s handler.\n", __PACKAGE__;
    # Prepopulate the cache.
    check();
    $agent->register(__PACKAGE__, $BASEOID, \&handler);
}

=head2 check

=cut

sub check {
    my %distributions = (
        '/usr/bin/apt-get' => sub {
            my $output = qx/apt-get upgrade -s/;
            my @packages;
            foreach my $line (split /\n/, $output) {
                if (my ($name, $version) = $line =~ /^Inst (\S+) \[\S+\] \((\S+) (?:Debian:security|Debian-Security:\d+\/\w+) \[\S+\]\)/) {
                    push @packages, "$name-$version";
                }
            }
            return @packages;
        },
        '/usr/bin/zypper' => sub {
            my $output = qx/zypper -x -n -A -q list-patches -g security/;
            my $xp = XML::XPath->new(xml => $output);
            my $nodeset = $xp->find('/stream/update-status/update-list/update[@category="security" and @pkgmanager="false"]');
            return map {$_->getAttribute("name")} $nodeset->get_nodelist;
        },
        '/usr/bin/yum' => sub {
            my $output = qx/yum list-security -y/;
            my @packages;
            foreach my $line (split /\n/, $output) {
                if (my ($name) = $line =~ /^[\w-]+ +(?:Important\/Sec\.|security) +(\S+)$/) {
                    push @packages, $name;
                }
            }
            return @packages;
        }
    );
    my $updates = {};
    my $counter = 0;
    foreach my $binary (keys %distributions) {
        if (-e $binary) {
            my @packages;
            if (exists $cache->{$binary} && $cache->{$binary}->{last} > time() - 3600) {
                @packages = @{$cache->{$binary}->{packages}};
            } else {
                @packages = sort $distributions{$binary}->();
                $cache->{$binary} = {
                    last => time(),
                    packages => \@packages,
                };
            }
            foreach (@packages) {
                $updates->{$counter} = $_;
                print STDERR "Pending security update: $_\n";
                $counter++;
            }
        }
    }
    return $updates;
}

=head2 handler

=cut

sub handler {
    my ($handler, $registration_info, $request_info, $requests) = @_;
    my $request;

    my $updates = check();
    my $size = keys %$updates;

    for($request = $requests; $request; $request = $request->next()) {
        my $oid = $request->getOID();
        if ($request_info->getMode() == MODE_GET) {
            if ($oid == $BASEOID) {
                $request->setValue(ASN_INTEGER, $size);
            } else {
                foreach my $package_oid (sort {$a <=> $b} keys %$updates) {
                    if ($oid == $BASEOID + ".$package_oid") {
                        $request->setValue(ASN_OCTET_STR, $updates->{$package_oid});
                    }
                }
            }
        } elsif ($request_info->getMode() == MODE_GETNEXT) {
            if ($oid < $BASEOID) {
                $request->setOID($BASEOID);
                $request->setValue(ASN_INTEGER, $size);
            } else {
                foreach my $package_oid (sort {$a <=> $b} keys %$updates) {
                    if ($oid < $BASEOID + ".$package_oid") {
                        $request->setOID($BASEOID + ".$package_oid");
                        $request->setValue(ASN_OCTET_STR, $updates->{$package_oid});
                        last;
                    }
                }
            }
        }
    }
}
=head1 AUTHOR

Michael Fladischer, C<< <FladischerMichael at fladi.at> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-openservices-snmp-plugin-updates at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=OpenServices-SNMP-Plugin-Updates>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc OpenServices::SNMP::Plugin::Updates


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=OpenServices-SNMP-Plugin-Updates>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/OpenServices-SNMP-Plugin-Updates>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/OpenServices-SNMP-Plugin-Updates>

=item * Search CPAN

L<http://search.cpan.org/dist/OpenServices-SNMP-Plugin-Updates/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Michael Fladischer.

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

1; # End of OpenServices::SNMP::Plugin::Updates
