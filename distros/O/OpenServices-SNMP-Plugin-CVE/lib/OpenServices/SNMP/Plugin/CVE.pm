package OpenServices::SNMP::Plugin::CVE;

use 5.006;
use strict;
use warnings FATAL => 'all';

use NetSNMP::agent qw(:all);
use NetSNMP::ASN qw(:all);


# Extend this hash map with future vulnerabilities_checks.
# Each new chack should increment
my %checks = (
    '.2014.6271' => sub {
        return qx/env x='() { :;}; echo vulnerable' bash -c 'true'/ =~ /^vulnerable$/ ? 0xFF : 0x00;
    },
    '.2014.7169' => sub {
        return qx/env X='() { (a)=>\' sh -c 'echo safe'; cat echo/ !~ /^safe$/ ? 0xFF : 0x00;
    },
    '.2014.7186' => sub {
        return qx/bash -c 'true <<EOF <<EOF <<EOF <<EOF <<EOF <<EOF <<EOF <<EOF <<EOF <<EOF <<EOF <<EOF <<EOF <<EOF' || echo 'vulnerable'/ =~ /^vulnerable$/ ? 0xFF : 0x00;
    },
    '.2014.7187' => sub {
        return qx/bash -c '(for x in {1..200} ; do echo "for x\$x in ; do :"; done; for x in {1..200} ; do echo done ; done) | bash || echo "vulnerable"'/ =~ /^vulnerable$/ ? 0xFF : 0x00;
    },
);

=head1 NAME

OpenServices::SNMP::Plugin::CVE - Check for local CVEs

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 BASE OID

    NetSNMP::OID(".1.3.6.1.4.1.36425.256.1");

=cut

our $BASEOID = new NetSNMP::OID(".1.3.6.1.4.1.36425.256.1");

=head1 SYNOPSIS

Check if local CVEs are exploitable on the system. This currently covers the following CVEs.

CVE-2014-6271
CVE-2014-7169
CVE-2014-7186
CVE-2014-7187

To use this submodule in your snmpd agent add the following line to your snmpd.conf file.

    perl require OpenServices::SNMP::Plugin; OpenServices::SNMP::Plugin->init($agent);

It exposes the number of found exploitable CVEs on the OID 1.3.6.1.4.1.36425.256.1 and each separate CVE as an integer at the OID
1.3.6.1.4.1.36425.256.1.<YEAR>.<CVE> where 1 means the CVE is exploitable and 0 that the CVE is not found.

=head1 SUBROUTINES/METHODS

=head2 init

=cut

sub init {
    my ($self, $agent) = @_;
    if (!$agent) {
        print STDERR "No \$agent defined\n";
        print STDERR "Please check your snmp_perl.pl that should be included in you net-snmp distribution.\n";
        exit 1;
    }

    printf STDERR "Registering %s handler.\n", __PACKAGE__;
    $agent->register(__PACKAGE__, $BASEOID, \&handler);
}

=head2 handler

=cut

sub handler {
    my ($handler, $registration_info, $request_info, $requests) = @_;
    my $request;

    if (!keys %checks) {
        return;
    }

    for($request = $requests; $request; $request = $request->next()) {
        my $oid = $request->getOID();
        if ($request_info->getMode() == MODE_GET) {
            if ($oid == $BASEOID) {
                $request->setValue(ASN_INTEGER, scalar keys %checks);
            } else {
                foreach my $check_oid (sort keys %checks) {
                    if ($oid == $BASEOID + $check_oid) {
                        $request->setValue(ASN_INTEGER, $checks{$check_oid}->());
                    }
                }
            }
        } elsif ($request_info->getMode() == MODE_GETNEXT) {
            if ($oid < $BASEOID) {
                $request->setOID($BASEOID);
                $request->setValue(ASN_INTEGER, scalar keys %checks);
            } else {
                foreach my $check_oid (sort keys %checks) {
                    if ($oid < $BASEOID + $check_oid) {
                        $request->setOID($BASEOID + $check_oid);
                        $request->setValue(ASN_INTEGER, $checks{$check_oid}->());
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

Please report any bugs or feature requests to C<bug-openservices-snmp-plugin-cve at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=OpenServices-SNMP-Plugin-CVE>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc OpenServices::SNMP::Plugin::CVE


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=OpenServices-SNMP-Plugin-CVE>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/OpenServices-SNMP-Plugin-CVE>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/OpenServices-SNMP-Plugin-CVE>

=item * Search CPAN

L<http://search.cpan.org/dist/OpenServices-SNMP-Plugin-CVE/>

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

1; # End of OpenServices::SNMP::Plugin::CVE
