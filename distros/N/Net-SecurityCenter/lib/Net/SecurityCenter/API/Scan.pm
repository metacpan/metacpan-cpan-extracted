package Net::SecurityCenter::API::Scan;

use warnings;
use strict;

use Carp;
use English qw( -no_match_vars );
use List::Util qw( any );

use parent 'Net::SecurityCenter::API';

use Net::SecurityCenter::Utils qw(:all);

our $VERSION = '0.202';

my $common_template = {

    id => {
        required => 1,
        allow    => qr/^\d+$/,
        messages => {
            required => 'Scan ID is required',
            allow    => 'Invalid Scan ID',
        },
    },

    filter => {
        allow => [ 'usable', 'manageable' ]
    },

    fields => {
        filter => \&sc_filter_array_to_string,
    }

};

#-------------------------------------------------------------------------------
# METHODS
#-------------------------------------------------------------------------------

sub add {

    my ( $self, %args ) = @_;

    my $single_id_filter = sub {
        return { 'id' => $_[0] };
    };

    my $array_ids_filter = sub {

        my $data = [];

        foreach my $id ( @{ $_[0] } ) {
            push( @{$data}, { 'id' => $id } );
        }

        return $data;

    };

    my $report_filter = sub {

        my $data         = [];
        my $report_types = [ 'cumulative', 'patched', 'individual', 'lce', 'archive', 'mobile' ];

        require Params::Check;

        foreach my $id ( keys %{ $_[0] } ) {

            my $type = $_[0]->{$id};

            if ( !Params::Check::allow( $type, @{$report_types} ) ) {
                croak( "Invalid 'reports ($type) value (allowed values: " . join( ', ', @{$report_types} ) . ')' );
            }

            push( @{$data}, { 'id' => $id, 'reportSource' => $type } );

        }

        return $data;

    };

    my $tmpl = {
        name => {
            required => 1,
            errors   => { required => 'Specify scan name' }
        },
        description => {},
        targets     => {
            filter => \&sc_filter_array_to_string,
            remap  => 'ipList'
        },
        assets => {
            filter => \&$array_ids_filter,
        },
        zone => {
            allow  => qr/\d+/,
            errors => { allow => 'Invalid Scan Zone ID' },
            filter => \&$single_id_filter
        },
        policy => {
            allow  => qr/\d+/,
            errors => { allow => 'Invalid Policy ID' },
            filter => \&$single_id_filter
        },
        plugin => {
            allow  => qr/\d+/,
            errors => { allow => 'Invalid Plugin ID' },
            filter => \&$single_id_filter
        },
        repository => {
            allow  => qr/\d+/,
            errors => { allow => 'Invalid Repository ID' },
            filter => \&$single_id_filter
        },
        credentials => {
            filter => \&$array_ids_filter,
        },
        max_time => {
            allow => qr/\d+/,
            remap => 'maxScanTime'
        },
        email_on_launch => {
            remap  => 'emailOnLaunch',
            filter => \&sc_filter_int_to_bool,
            allow  => qr/\d/,
        },
        email_on_finish => {
            remap  => 'emailOnFinish',
            filter => \&sc_filter_int_to_bool,
            allow  => qr/\d/,
        },
        dhcp_tracking => {
            remap  => 'dhcpTracking',
            filter => \&sc_filter_int_to_bool,
            allow  => qr/\d/,
        },
        reports => {
            filter => \&$report_filter,
        },
        type => {
            allow => [ 'plugin', 'policy' ]
        },
        timeout => {
            allow => [ 'discard', 'import', 'rollover' ],
            remap => 'timeoutAction',
        },
        schedule => {
            filter => sub {
                return sc_schedule( %{ $_[0] } );
            },
        },
        rollover => {
            allow => [ 'nextDay', 'template' ],
            remap => 'rolloverType',
        },
        scan_vhost => {
            remap => 'scanningVirtualHosts'
        },
    };

    my $params = sc_check_params( $tmpl, \%args );

    croak('"policy" and "plugin" are not allowed in same time')
        if ( defined( $params->{'policy'} ) && defined( $params->{'plugin'} ) );

    if ( !defined( $params->{'type'} ) ) {
        $params->{'type'} = ( $params->{'policy'} ) ? 'policy' : 'plugin';
    }

    my $result = $self->client->post( '/scan', $params );

    # Return the Scan Result ID for schedule=now scans
    if ( defined( $result->{'scanResultID'} ) ) {
        return $result->{'scanResultID'};
    }

    # Return the Scan ID
    if ( defined( $result->{'id'} ) ) {
        return $result->{'id'};
    }

}

#-------------------------------------------------------------------------------

sub execute {

    my ( $self, %params ) = @_;

    $params{'schedule'} = { 'type' => 'now' };

    return $self->add(%params);

}

#-------------------------------------------------------------------------------

sub launch {

    my ( $self, %args ) = @_;

    my $tmpl = {
        diagnostic_target   => { remap => 'diagnosticTarget' },
        diagnostic_password => { remap => 'diagnosticPassword' },
        id                  => $common_template->{'id'},
    };

    my $params  = sc_check_params( $tmpl, \%args );
    my $scan_id = delete( $params->{'id'} );
    my $result  = $self->client->post( "/scan/$scan_id/launch", $params );

    if ( !defined( $result->{'scanResult'}->{'id'} ) ) {
        croak('Invalid response from SecurityCenter');    # TODO
    }

    return $result->{'scanResult'}->{'id'};

}

#-------------------------------------------------------------------------------

sub list {

    my ( $self, %args ) = @_;

    my $tmpl = {
        fields => $common_template->{'fields'},
        filter => $common_template->{'filter'},
        raw    => {},
    };

    my $params = sc_check_params( $tmpl, \%args );
    my $raw    = delete( $params->{'raw'} );
    my $scans  = $self->client->get( '/scan', $params );

    return if ( !$scans );
    return $scans if ($raw);
    return sc_merge($scans);
}

#-------------------------------------------------------------------------------

sub get {

    my ( $self, %args ) = @_;

    my $tmpl = {
        fields => $common_template->{'fields'},
        id     => $common_template->{'id'},
    };

    my $params  = sc_check_params( $tmpl, \%args );
    my $scan_id = delete( $params->{'id'} );
    my $raw     = delete( $params->{'raw'} );
    my $scan    = $self->client->get( "/scan/$scan_id", $params );

    return if ( !$scan );
    return $scan if ($scan);
    return sc_normalize_hash($scan);

}

#-------------------------------------------------------------------------------

sub delete {

    my ( $self, %args ) = @_;

    my $tmpl = { id => $common_template->{'id'}, };

    my $params  = sc_check_params( $tmpl, \%args );
    my $scan_id = delete( $params->{'id'} );

    return $self->client->delete("/scan/$scan_id");    # TODO

}

#-------------------------------------------------------------------------------

1;

__END__
=pod

=encoding UTF-8


=head1 NAME

Net::SecurityCenter::API::Scan - Perl interface to Tenable.sc (SecurityCenter) Scan REST API


=head1 SYNOPSIS

    use Net::SecurityCenter::REST;
    use Net::SecurityCenter::API::Scan;

    my $sc = Net::SecurityCenter::REST->new('sc.example.org');

    $sc->login('secman', 'password');

    my $api = Net::SecurityCenter::API::Scan->new($sc);

    my $scan_id = $api->add(
        name        => 'Test API scan',
        target      => [ '192.168.1.2', '192.168.1.3' ],
        description => 'Test from Net::SecurityCenter Perl module',
        policy      => 1,
        repository  => 2,
        zone        => 1
    );

    $sc->logout();


=head1 DESCRIPTION

This module provides Perl scripts easy way to interface the Scan REST API of Tenable.sc
(SecurityCenter).

For more information about the Tenable.sc (SecurityCenter) REST API follow the online documentation:

L<https://docs.tenable.com/sccv/api/index.html>


=head1 CONSTRUCTOR

=head2 Net::SecurityCenter::API::Scan->new ( $client )

Create a new instance of B<Net::SecurityCenter::API::Scan> using L<Net::SecurityCenter::REST> class.


=head1 METHODS

=head2 list

Get list of scans.

Params:

=over 4

=item * C<fields> : List of fields

=item * C<filter> : Filter (C<usable>, C<manageable>)

=back

=head2 add

Create a new scan on Tenable.sc (SecurityCenter) and return the C<scan_id> (or C<scan_result_id>
for C<schedule=now> argument).

    my $scan_id = $scan->add(
        name        => 'Test API scan',
        target      => [ '192.168.1.2', '192.168.1.3' ],
        description => 'Test from Net::SecurityCenter Perl module',
        policy      => 1,
        repository  => 2,
        zone        => 1
    );

Params:

=over 4

=item * C<name> : Name of scan (I<required>)

=item * C<description> : Description of scan

=item * C<type> : Type of scan

=over 4

=item * C<policy>: Create a policy scan (need C<policy>)

=item * C<plugin>: Create a plugin scan (need C<plugin>)

=back

=item * C<targets> : Array of targets (IP, subnet or ranges)

=item * C<assets> : Array of Asset ID

=item * C<zone> : Scan Zone ID (default: C<0>)

=item * C<policy> : Policy ID for C<type=policy> scan type

=item * C<plugin> : Plugin ID for C<type=plugin> scan type

=item * C<repository> : Repository ID

=item * C<credentials> : Array of credential ID (default: C<[]>)

=item * C<max_time> : Max scan time (default: C<3600>)

=item * C<email_on_launch> : Send the email on scan launch (default: C<0>)

=item * C<email_on_finish> : Send the email on scan finish (default: C<0>)

=item * C<dhcp_tracking> : Enable DHCP tracking (default: C<0>)

=item * C<rollover> : Rollover type on C<timeout> action

Allowed values:

=over 4

=item * C<nextDay>

=item * C<template> (default)

=back

=item * C<timeout> : Timeout action

=over 4

=item * C<discard>

=item * C<import> (default)

=item * C<rollover>

=back

=item * C<reports> : Reports hash ( id => type )

=item * C<schedule> : Schedule type

=over 4

=item * C<dependent>

=item * C<ical>

=item * C<never>

=item * C<rollover>

=item * C<template>

=item * C<now> (Execute the scan on Nessus scanner and return the scan result C<id>)

=back

=back

=head2 launch

Launches the scan associated with C<id> to Nessus scanner.

Params:

=over 4

=item * C<id> : Scan ID

=item * C<diagnostic_target> : Valid IP/hostname

=item * C<diagnostic_password> : Diagnostic password

=back

=head2 execute

This is a facility for run immediatly a scan in Tenable.sc (SecurityCenter)
using Nessus Scanner without create a scan.

B<NOTE>: This method is an alias for C<$sc-E<gt>add ( schedule =E<gt> 'now', ... )>.

See C<$sc-E<gt>add_scan> paragraph for information about the allowed C<params>.

=head2 delete

Delete the scan associated with C<id>.

Params:

=over 4

=item * C<id> : Scan ID

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/LotarProject/perl-Net-SecurityCenter/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/LotarProject/perl-Net-SecurityCenter>

    git clone https://github.com/LotarProject/perl-Net-SecurityCenter.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2018-2019 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
