package Net::SecurityCenter::API::ScanResult;

use warnings;
use strict;

use Carp;
use English qw( -no_match_vars );
use IO::Uncompress::Unzip qw(unzip $UnzipError);

use parent 'Net::SecurityCenter::API';

use Net::SecurityCenter::Utils qw(:all);

our $VERSION = '0.201';

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
            allow => qr/^\d+$/,
            remap => 'startDate'
        },
        end_date => {
            allow => qr/^\d+$/,
            remap => 'endDate'
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

sub get_progress {

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

sub get_status {

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

sub stop {

    my ( $self, %args ) = @_;

    my $tmpl = { id => $common_template->{'id'}, };

    my $params         = sc_check_params( $tmpl, \%args );
    my $scan_result_id = delete( $params->{'id'} );

    $self->client->post("/scanResult/$scan_result_id/stop");
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

Params:

=over 4

=item * C<fields> : List of fields

=item * C<filter> : Filter (C<usable>, C<manageable>, C<running> or C<completed>)

=back


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

=item * C<fields> : Fields

=back


=head2 get_progress

Get scan progress associated with C<id>.

    print 'Scan progress: ' . $sc->get_scan_progress( id => 1337 ) . '%';

Params:

=over 4

=item * C<id> : Scan result ID

=back


=head2 get_status

Get scan status associated with C<id>.

    print 'Scan status: ' . $sc->get_status( id => 1337 );

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


=head2 stop

Stop a scan associated with C<id>.

    if ($sc->get_status( id => 1337 ) eq 'running') {
        $sc->stop( id => 1337 );
    }

Params:

=over 4

=item * C<id> : Scan result ID

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
