package Net::SecurityCenter::API::ScanResult;

use warnings;
use strict;

use Carp;
use English qw( -no_match_vars );
use IO::Uncompress::Unzip qw(unzip $UnzipError);

use parent 'Net::SecurityCenter::API';

use Net::SecurityCenter::Utils qw(:all);

our $VERSION = '0.206';

my $common_template = {

    id => {
        required => 1,
        allow    => qr/^\d+$/,
        messages => {
            required => 'Scan Result ID is required',
            allow    => 'Invalid Scan Result ID',
        },
    },

    filter => {
        allow => [ 'usable', 'manageable', 'running', 'completed' ]
    },

    fields => {
        allow => \&sc_filter_array_to_string,
    }

};

#-------------------------------------------------------------------------------
# METHODS
#-------------------------------------------------------------------------------

sub download {

    my ( $self, %args ) = @_;

    my $tmpl = {
        filename => {},
        id       => $common_template->{'id'},
    };

    my $params = sc_check_params( $tmpl, \%args );

    my $scan_result_id = delete( $params->{'id'} );
    my $filename       = delete( $params->{'filename'} );

    my $sc_scan_data     = $self->client->post( "/scanResult/$scan_result_id/download", { 'downloadType' => 'v2' } );
    my $nessus_scan_data = q{};

    if ($sc_scan_data) {
        unzip \$sc_scan_data => \$nessus_scan_data or croak "Failed to uncompress Nessus scan: $UnzipError\n";
    }

    return $nessus_scan_data if ( !$filename );

    open my $fh, '>', $filename
        or croak("Could not open file '$filename': $OS_ERROR");

    print $fh $nessus_scan_data;

    close $fh
        or carp("Failed to close file '$filename': $OS_ERROR");

    return 1;

}

#-------------------------------------------------------------------------------

sub list {

    my ( $self, %args ) = @_;

    my $tmpl = {
        fields     => $common_template->{'fields'},
        filter     => $common_template->{'filter'},
        raw        => {},
        start_date => {
            filter => \&sc_filter_datetime_to_epoch,
            remap  => 'startTime',
        },
        end_date => {
            filter => \&sc_filter_datetime_to_epoch,
            remap  => 'endTime',
        },
        start_time => {
            allow => qr/^\d+$/,
            remap => 'startTime'
        },
        end_time => {
            allow => qr/^\d+$/,
            remap => 'endTime'
        }
    };

    my $params = sc_check_params( $tmpl, \%args );
    my $raw    = delete( $params->{'raw'} );
    my $scans  = $self->client->get( '/scanResult', $params );

    if ($raw) {
        return $scans;
    }

    return sc_merge($scans);

}

#-------------------------------------------------------------------------------

sub list_running {

    my ( $self, %args ) = @_;

    my $tmpl = { fields => $common_template->{'fields'}, raw => {}, };

    my $params = sc_check_params( $tmpl, \%args );

    $params->{'filter'} = 'running';

    return $self->list( %{$params} );

}

#-------------------------------------------------------------------------------

sub list_completed {

    my ( $self, %args ) = @_;

    my $tmpl = { fields => $common_template->{'fields'}, raw => {}, };

    my $params = sc_check_params( $tmpl, \%args );

    $params->{'filter'} = 'completed';

    return $self->list( %{$params} );

}

#-------------------------------------------------------------------------------

sub get {

    my ( $self, %args ) = @_;

    my $tmpl = {
        id     => $common_template->{'id'},
        fields => $common_template->{'fields'},
        raw    => {},
    };

    my $params         = sc_check_params( $tmpl, \%args );
    my $scan_result_id = delete( $params->{'id'} );
    my $raw            = delete( $params->{'raw'} );

    my $scan_result = $self->client->get( "/scanResult/$scan_result_id", $params );

    if ($raw) {
        return $scan_result;
    }

    return sc_normalize_hash($scan_result);

}

#-------------------------------------------------------------------------------

sub progress {

    my ( $self, %args ) = @_;

    my $tmpl = { id => $common_template->{'id'}, };

    my $params         = sc_check_params( $tmpl, \%args );
    my $scan_result_id = delete( $params->{'id'} );

    my $scan_data = $self->get(
        id     => $scan_result_id,
        fields => [ 'id', 'totalChecks', 'completedChecks' ]
    );

    return sprintf( '%d', ( $scan_data->{'completedChecks'} * 100 ) / $scan_data->{'totalChecks'} );

}

#-------------------------------------------------------------------------------

sub status {

    my ( $self, %args ) = @_;

    my $tmpl = { id => $common_template->{'id'}, };

    my $params         = sc_check_params( $tmpl, \%args );
    my $scan_result_id = delete( $params->{'id'} );

    my $scan_data = $self->get(
        id     => $scan_result_id,
        fields => [ 'id', 'status' ]
    );

    return lc( $scan_data->{'status'} );

}

#-------------------------------------------------------------------------------

sub pause {

    my ( $self, %args ) = @_;

    my $tmpl = { id => $common_template->{'id'}, };

    my $params         = sc_check_params( $tmpl, \%args );
    my $scan_result_id = delete( $params->{'id'} );

    $self->client->post("/scanResult/$scan_result_id/pause");
    return 1;

}

#-------------------------------------------------------------------------------

sub resume {

    my ( $self, %args ) = @_;

    my $tmpl = { id => $common_template->{'id'}, };

    my $params         = sc_check_params( $tmpl, \%args );
    my $scan_result_id = delete( $params->{'id'} );

    $self->client->post("/scanResult/$scan_result_id/resume");
    return 1;

}

#-------------------------------------------------------------------------------

sub reimport {

    my ( $self, %args ) = @_;

    my $tmpl = {
        id         => $common_template->{'id'},
        scan_vhost => {
            remap  => 'scanningVirtualHosts',
            filter => \&sc_filter_int_to_bool,
            allow  => qr/\d/,
        },
        dhcp_tracking => {
            remap  => 'dhcpTracking',
            filter => \&sc_filter_int_to_bool,
            allow  => qr/\d/,
        },
        classify_mitigated_age => { remap => 'classifyMitigatedAge' }
    };

    my $params         = sc_check_params( $tmpl, \%args );
    my $scan_result_id = delete( $params->{'id'} );

    $self->client->post("/scanResult/$scan_result_id/import");
    return 1;

}

#-------------------------------------------------------------------------------

sub import {

    my ( $self, %args ) = @_;

    my $single_id_filter = sub {
        return { 'id' => $_[0] };
    };

    my $tmpl = {
        filename      => {},
        dhcp_tracking => {
            remap  => 'dhcpTracking',
            filter => \&sc_filter_int_to_bool,
            allow  => qr/\d/,
        },
        classify_mitigated_age => { remap => 'classifyMitigatedAge' },
        scan_vhost             => {
            remap  => 'scanningVirtualHosts',
            filter => \&sc_filter_int_to_bool,
            allow  => qr/\d/,
        },
        repository => {
            allow  => qr/\d+/,
            errors => { allow => 'Invalid Repository ID' },
            filter => \&$single_id_filter
        },
    };

    my $params      = sc_check_params( $tmpl, \%args );
    my $filename    = delete( $params->{'filename'} );
    my $sc_filename = $self->client->upload($filename)->{'filename'};

    $params->{'filename'} = $sc_filename;

    $self->client->post( "/scanResult/import", $params );
    return 1;

}

#-------------------------------------------------------------------------------

sub email {

    my ( $self, %args ) = @_;

    my $tmpl = { id => $common_template->{'id'}, email => {} };

    my $params         = sc_check_params( $tmpl, \%args );
    my $scan_result_id = delete( $params->{'id'} );

    $self->client->post( "/scanResult/$scan_result_id/import", $params );
    return 1;

}

#-------------------------------------------------------------------------------

sub stop {

    my ( $self, %args ) = @_;

    my $tmpl = {
        id   => $common_template->{'id'},
        type => {
            allow => ['import']
        }
    };

    my $params         = sc_check_params( $tmpl, \%args );
    my $scan_result_id = delete( $params->{'id'} );

    $self->client->post( "/scanResult/$scan_result_id/stop", $params );
    return 1;

}

#-------------------------------------------------------------------------------

1;

__END__
=pod

=encoding UTF-8


=head1 NAME

Net::SecurityCenter::API::ScanResult - Perl interface to Tenable.sc (SecurityCenter) Scan Result REST API


=head1 SYNOPSIS

    use Net::SecurityCenter::REST;
    use Net::SecurityCenter::API::ScanResult;

    my $sc = Net::SecurityCenter::REST->new('sc.example.org');

    $sc->login('secman', 'password');

    my $api = Net::SecurityCenter::API::ScanResult->new($sc);

    $sc->logout();


=head1 DESCRIPTION

This module provides Perl scripts easy way to interface the Scan Result REST API of Tenable.sc
(SecurityCenter).

For more information about the Tenable.sc (SecurityCenter) REST API follow the online documentation:

L<https://docs.tenable.com/sccv/api/index.html>


=head1 CONSTRUCTOR

=head2 Net::SecurityCenter::API::ScanResult->new ( $client )

Create a new instance of B<Net::SecurityCenter::API::ScanResult> using L<Net::SecurityCenter::REST> class.


=head1 METHODS

=head2 download

Download the Nessus (XML) scan result.

    my $nessus_scan = $sc->download( id => 1337 );

    $sc->download( id       => 1337,
                   filename => '/var/nessus/scans/1337.nessus' );

Params:

=over 4

=item * C<id> : Scan result ID

=item * C<filename> : File

=back


=head2 list

Get list of scans results (completed, running, etc.).


    my $scans = $sc->list(
        start_date => '2020-01-01',
        end_date => '2020-02-01',
        fields => 'id,name,description,startTime,finishTime',
    );


    # Using Time::Piece

    use Time::Piece;
    use Time::Seconds;

    my $t = Time::Piece->new;
    $t -= ONE_DAY; # Yesterday

    my $scans = $sc->list(
        start_date => $t,
    );


Params:

=over 4

=item * C<fields> : List of fields

=item * C<start_date> : Start date of scan in ISO 8601 format (YYYY-MM-DD, YYYY-MM-DD HH:MM:SS or YYYY-MM-DDTHH:MM:SS) or L<Time::Piece> object

=item * C<end_date> : End date of scan (see C<start_date>)

=item * C<start_time> : Start date in epoch

=item * C<end_date> : End date in epoch 

=item * C<filter> : Filter (C<usable>, C<manageable>, C<running> or C<completed>)

=back

Allowed Fields:

=over 4

=item * C<id> *

=item * C<name> **

=item * C<description> **

=item * C<status> **

=item * C<initiator>

=item * C<owner>

=item * C<ownerGroup>

=item * C<repository>

=item * C<scan>

=item * C<job>

=item * C<details>

=item * C<importStatus>

=item * C<importStart>

=item * C<importFinish>

=item * C<importDuration>

=item * C<downloadAvailable>

=item * C<downloadFormat>

=item * C<dataFormat>

=item * C<resultType>

=item * C<resultSource>

=item * C<running>

=item * C<errorDetails>

=item * C<importErrorDetails>

=item * C<totalIPs>

=item * C<scannedIPs>

=item * C<startTime>

=item * C<finishTime>

=item * C<scanDuration>

=item * C<completedIPs>

=item * C<completedChecks>

=item * C<totalChecks>

=back

(*) always comes back
(**) comes back if fields list not specified


=head2 list_running

Get list of running scans.

Params:

=over 4

=item * C<fields> : Fields

=back


=head2 list_completed

Get list of completed scans.

Params:

=over 4

=item * C<fields> : Fields

=back


=head2 get

Gets the scan information associated with C<id>.

Params:

=over 4

=item * C<id> : Scan result ID

=item * C<fields> : Fields (see C<list>)

=back


=head2 progress

Get scan progress associated with C<id>.

    print 'Scan progress: ' . $sc->progress( id => 1337 ) . '%';

Params:

=over 4

=item * C<id> : Scan result ID

=back


=head2 status

Get scan status associated with C<id>.

    print 'Scan status: ' . $sc->status( id => 1337 );

Params:

=over 4

=item * C<id> : Scan result ID

=back


=head2 pause

Pause a scan associated with C<id>.

    if ($sc->get_status( id => 1337 ) eq 'running') {
        $sc->pause( id => 1337 );
    }

Params:

=over 4

=item * C<id> : Scan result ID

=back


=head2 resume

Resume a paused scan associated with C<id>.

    if ($sc->get_status( id => 1337 ) eq 'paused') {
        $sc->resume( id => 1337 );
    }

Params:

=over 4

=item * C<id> : Scan result ID

=back


=head2 import

Imports the Scan Result associated with the uploaded file, identified by C<filename>.

    $sc->import( filename => '/tmp/report.nessus', repository => 1 );

Params:

=over 4

=item * C<filename> : Nessus report filename (I<required>)

=item * C<repository> : Repository ID (I<required>)

=item * C<scan_vhost> : Scan VirtualHost

=item * C<classify_mitigated_age> : Classify Mitigated Age

=item * C<dhcp_tracking>  DHCP Tracking

=back


=head2 reimport

Re-imports the Scan Result associated with C<id>.

    $sc->reimport( id => 1337 );

Params:

=over 4

=item * C<id> : Scan result ID

=back


=head2 stop

Stop a scan associated with C<id>.

    if ($sc->get_status( id => 1337 ) eq 'running') {
        $sc->stop( id => 1337 );
    }

Params:

=over 4

=item * C<id> : Scan result ID

=item * C<type> : Stop type (values: C<import>)

=back


=head2 email

Emails the Scan Result associated with C<id>.

    $sc->email( id => 1337, email => 'john@example.org' );

Params:

=over 4

=item * C<id> : Scan result ID

=item * C<email> : Email address

=back


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

This software is copyright (c) 2018-2020 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
