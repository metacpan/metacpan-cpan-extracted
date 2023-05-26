package Net::SecurityCenter::API::DeviceInfo;

use warnings;
use strict;

use parent 'Net::SecurityCenter::Base';

use Net::SecurityCenter::Utils qw(:all);

our $VERSION = '0.311';

#-------------------------------------------------------------------------------
# METHODS
#-------------------------------------------------------------------------------

sub get_info {

    my ( $self, %args ) = @_;

    my $tmpl = {
        fields   => {},
        ip       => {},
        uuid     => {},
        dns_name => {
            remap => 'dnsName',
        }
    };

    my $params      = sc_check_params( $tmpl, \%args );
    my $device_info = $self->client->get( "/deviceInfo", $params );

    return if ( !$device_info );
    return sc_normalize_hash $device_info;

}

#-------------------------------------------------------------------------------

1;

__END__
=pod

=encoding UTF-8


=head1 NAME

Net::SecurityCenter::API::DeviceInfo - Perl interface to Tenable.sc (SecurityCenter) Device Information REST API


=head1 SYNOPSIS

    use Net::SecurityCenter::REST;
    use Net::SecurityCenter::API::DeviceInfo;

    my $sc = Net::SecurityCenter::REST->new('sc.example.org');

    $sc->login('secman', 'password');

    my $api = Net::SecurityCenter::API::DeviceInfo->new($sc);

    $sc->logout();


=head1 DESCRIPTION

This module provides Perl scripts easy way to interface the Device Information REST API of Tenable.sc
(SecurityCenter).

For more information about the Tenable.sc (SecurityCenter) REST API follow the online documentation:

L<https://docs.tenable.com/sccv/api/index.html>


=head1 CONSTRUCTOR

=head2 Net::SecurityCenter::API::DeviceInfo->new ( $client )

Create a new instance of B<Net::SecurityCenter::API::DeviceInfo> using L<Net::SecurityCenter::REST> class.


=head1 METHODS

=head2 get_info

Gets the device information from the current user.

B<NOTE>: This will return device information for the first repository. To specify a particular repository, see
L<Net::SecurityCenter::API::Repository>::get_device_info.

    my $scans = $sc->get_info(
        ip => '192.168.8.2',
        fields => 'os,dnsName,severityCritical,severityHigh'
    );


Params:

=over 4

=item * C<uuid> : Device UUID

=item * C<ip> : IP Address

=item * C<dns_name> : DNS Name

=item * C<fields> : List of fields

=back

Allowed Fields:

=over 4

=item * C<ip> *

=item * C<uuid> *

=item * C<repositoryID> *

=item * C<repositories>

=item * C<repository>

=item * C<score>

=item * C<total>

=item * C<severityInfo>

=item * C<severityLow>

=item * C<severityMedium>

=item * C<severityHigh>

=item * C<severityCritical>

=item * C<macAddress>

=item * C<policyName>

=item * C<pluginSet>

=item * C<netbiosName>

=item * C<dnsName>

=item * C<osCPE>

=item * C<biosGUID>

=item * C<tpmID>

=item * C<mcafeeGUID>

=item * C<lastAuthRun>

=item * C<lastUnauthRun>

=item * C<severityAll>

=item * C<os>

=item * C<hasPassive>

=item * C<hasCompliance>

=item * C<lastScan>

=item * C<links>

=back

(*) always comes back




=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Net-SecurityCenter/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Net-SecurityCenter>

    git clone https://github.com/giterlizzi/perl-Net-SecurityCenter.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2018-2023 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
