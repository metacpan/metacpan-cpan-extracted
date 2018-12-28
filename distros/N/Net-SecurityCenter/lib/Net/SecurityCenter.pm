package Net::SecurityCenter;

use warnings;
use strict;

use Carp;
use List::Util qw(first);
use IO::Uncompress::Unzip qw(unzip $UnzipError);

use Net::SecurityCenter::REST;

use Data::Dumper;

our $VERSION = '0.100';

sub new {

    my ($class, $host, $options) = @_;

    my $self = {
        host    => $host,
        options => $options,
        rest    => Net::SecurityCenter::REST->new($host, $options),
    };

    bless $self, $class;

    return $self;

}

sub rest {

    my ($self) = @_;
    return $self->{rest};

}

sub get_device_info {

    my ($self, $repository_id, $ip_address, $params) = @_;

    (@_ == 3 || @_ == 4 || @_ == 5) or croak(q/Usage: $sc->get_device_info(REPOSITORY_ID, IP_ADDRESS [,PARAMS])/);

    croak('Invalid Repository ID') unless ($repository_id =~ /\d/);

    my %params = (
        'ip' => $ip_address,
    );

    if (defined($params->{'fields'})) {
        if (ref $params->{'fields'} eq 'ARRAY') {
            $params{'fields'} = join(',', @{$params->{'fields'}});
        } else {
            $params{'fields'} = $params->{'fields'};
        }
    }

    return $self->rest->get("/repository/$repository_id/deviceInfo", \%params);

}

sub get_ip_info {

    my ($self, $ip_address, $params) = @_;

    (@_ == 2 || @_ == 3) or croak(q/Usage: $sc->get_ip_info(IP_ADDRESS [,PARAMS])/);

    $params->{'ip'} = $ip_address;

    if (defined($params->{'fields'})) {
        if (ref $params->{'fields'} eq 'ARRAY') {
            $params->{'fields'} = join(',', @{$params->{'fields'}});
        }
    }

    return $self->rest->get("/ipInfo", \%{$params});

}

sub get_status {

    my ($self, $fields) = @_;

    (@_ == 1 || @_ == 2) or croak(q/Usage: $sc->get_status([FIELDS])/);

    my %params = ();

    if ($fields) {
        if (ref $fields eq 'ARRAY') {
            $params{'fields'} = join(',', @{$fields});
        } else {
            $params{'fields'} = $fields;
        }
    }

    return $self->rest->get('/status', \%params);


}

sub get_system_info {

    my ($self) = @_;
    return $self->rest->get('/system');

}

sub get_system_diagnostics_info {

    my ($self) = @_;
    return $self->rest->get('/system/diagnostics');

}

sub generate_app_status_diagnostics {

    my ($self) = @_;
    $self->rest->post('/system/diagnostics/generate', { 'task' => 'appStatus' });
    return 1;

}

sub generate_diagnostics_file {

    my ($self, $options) = @_;

    my @options = ( 'all' );

    if ($options && ref $options ne 'ARRAY') {
        @options = split(/,/, $options);
    }

    my @allowed_options = ( 'all', 'apacheLog', 'configuration', 'dependencies',
                            'dirlist', 'environment', 'installLog', 'logs',
                            'sanitize', 'scans', 'serverConf', 'setup', 'sysinfo',
                            'upgradeLog');

    foreach my $option (@options) {
        unless (grep $_ eq $option, @allowed_options) {
            carp(sprintf('Unknown option (allowed: %s)', join(',', @allowed_options)));
            croak(q/Usage: $sc->generate_diagnostics_file([ OPTIONS ])/);
        }
    }

    return $self->rest->post('/system/diagnostics/generate', { 'task' => 'diagnosticsFile', 'options' => \@options });

}

sub download_system_diagnostics {

    my ($self) = @_;
    return $self->rest->post('/system/diagnostics/download');

}

sub get_feed {

    my ($self, $type) = @_;

    if ($type) {

        my @allowed_type = ( 'active', 'passive', 'lce', 'sc' );

        unless (grep $_ eq $type, @allowed_type) {
            carp(sprintf('Unknown type (allowed: %s)', join(',', @allowed_type)));
            croak(q/Usage: $sc->get_feed([ TYPE ])/);
        }

        return $self->rest->get("/feed/$type");
    }

    return $self->rest->get('/feed');

}

sub get_repository_list {

    my ($self, $fields) = @_;

    my %params = ();

    if ($fields) {
        if (ref $fields eq 'ARRAY') {
            $params{'fields'} = join(',', @{$fields});
        } else {
            $params{'fields'} = $fields;
        }
    }

    return $self->rest->get('/repository', \%params);

}

sub get_repository {

    my ($self, $repository_id, $fields) = @_;

    (@_ == 2 || @_ == 3) or croak(q/Usage: $sc->get_repository(REPOSITORY_ID [,FIELDS])/);

    croak('Invalid Repository ID') unless ($repository_id =~ /\d/);

    my %params = ();

    if ($fields) {
        if (ref $fields eq 'ARRAY') {
            $params{'fields'} = join(',', @{$fields});
        } else {
            $params{'fields'} = $fields;
        }
    }

    return $self->rest->get("/repository/$repository_id", \%params);

}

sub get_scan_zone_list {

    my ($self, $fields) = @_;

    my %params = ();

    if ($fields) {
        if (ref $fields eq 'ARRAY') {
            $params{'fields'} = join(',', @{$fields});
        } else {
            $params{'fields'} = $fields;
        }
    }

    return $self->rest->get('/zone', \%params);

}

sub get_scan_zone {

    my ($self, $zone_id, $fields) = @_;

    (@_ == 2 || @_ == 3) or croak(q/Usage: $sc->get_scan_zone(ZONE_ID, [FIELDS])/);

    croak('Invalid Scan Zone ID') unless ($zone_id =~ /\d/);

    my %params = ();

    if ($fields) {
        if (ref $fields eq 'ARRAY') {
            $params{'fields'} = join(',', @{$fields});
        } else {
            $params{'fields'} = $fields;
        }
    }

    return $self->rest->get("/zone/$zone_id", \%params);

}

sub get_policy_list {

    my ($self, $fields) = @_;

    my %params = ();

    if ($fields) {
        if (ref $fields eq 'ARRAY') {
            $params{'fields'} = join(',', @{$fields});
        } else {
            $params{'fields'} = $fields;
        }
    }

    return $self->rest->get('/policy', \%params);

}

sub get_policy {

    my ($self, $policy_id, $fields) = @_;

    (@_ == 2 || @_ == 3) or croak(q/Usage: $sc->get_policy(POLICY_ID [,FIELDS])/);

    croak('Invalid Policy ID') unless ($policy_id =~ /\d/);

    my %params = ();

    if ($fields) {
        if (ref $fields eq 'ARRAY') {
            $params{'fields'} = join(',', @{$fields});
        } else {
            $params{'fields'} = $fields;
        }
    }

    return $self->rest->get("/policy/$policy_id", \%params);

}

sub get_report_list {

    my ($self, %params) = @_;
    return $self->rest->get('/report', \%params);

}

sub get_report {

    my ($self, $report_id, $fields) = @_;

    (@_ == 2 || @_ == 3) or croak(q/Usage: $sc->get_report(REPORT_ID [,FIELDS])/);

    croak('Invalid Report ID') unless ($report_id =~ /\d/);

    my %params = ();

    if ($fields) {
        if (ref $fields eq 'ARRAY') {
            $params{'fields'} = join(',', @{$fields});
        } else {
            $params{'fields'} = $fields;
        }
    }

    return $self->rest->get("/report/$report_id", \%params);

}

sub download_report {

    my ($self, $report_id) = @_;
    return $self->rest->post("/report/$report_id/download");

}

sub get_user_list {

    my ($self, %params) = @_;
    return $self->rest->get('/user', \%params);

}

sub get_user {

    my ($self, $user_id, $fields) = @_;

    (@_ == 2 || @_ == 3) or croak(q/Usage: $sc->get_user(CREDENTIAL_ID [,FIELDS])/);

    croak('Invalid User ID') unless ($user_id =~ /\d/);

    my %params = ();

    if ($fields) {
        if (ref $fields eq 'ARRAY') {
            $params{'fields'} = join(',', @{$fields});
        } else {
            $params{'fields'} = $fields;
        }
    }

    return $self->rest->get("/user/$user_id", \%params);

}

sub get_credential_list {

    my ($self, %params) = @_;
    return $self->rest->get('/credential', \%params);

}

sub get_credential {

    my ($self, $credential_id, $fields) = @_;

    (@_ == 2 || @_ == 3) or croak(q/Usage: $sc->get_credential(CREDENTIAL_ID [,FIELDS])/);

    croak('Invalid Credential ID') unless ($credential_id =~ /\d/);

    my %params = ();

    if ($fields) {
        if (ref $fields eq 'ARRAY') {
            $params{'fields'} = join(',', @{$fields});
        } else {
            $params{'fields'} = $fields;
        }
    }

    return $self->rest->get("/credential/$credential_id", \%params);

}

sub download_nessus_scan {

    my ($self, $scan_id, $filename) = @_;

    (@_ == 2 || @_ == 3) or croak(q/Usage: $sc->download_nessus_scan(SCAN_ID [,FILE])/);

    croak('Invalid Scan ID') unless ($scan_id =~ /\d/);

    my $sc_scan_data     = $self->rest->post("/scanResult/$scan_id/download",  { 'downloadType' => 'v2' });
    my $nessus_scan_data = '';

    if ($sc_scan_data) {
        unzip \$sc_scan_data => \$nessus_scan_data or croak "Failed to uncompress Nessus scan: $UnzipError\n";
    }

    return $nessus_scan_data unless($filename);

    open(my $fh, '>', $filename)
        or croak("Could not open file '$filename': $!");

    print $fh $nessus_scan_data;
    close $fh;

    return 1;

}

sub get_plugin_list {

    my ($self, %params) = @_;
    return $self->rest->get('/plugin', \%params);

}

sub get_plugin {

    my ($self, $plugin_id, $fields) = @_;

    (@_ == 2 || @_ == 3) or croak(q/Usage: $sc->get_plugin(PLUGIN_ID [,FIELDS])/);

    croak('Invalid Plugin ID') unless ($plugin_id =~ /\d/);

    my %params = ();

    if ($fields) {
        if (ref $fields eq 'ARRAY') {
            $params{'fields'} = join(',', @{$fields});
        } else {
            $params{'fields'} = $fields;
        }
    }

    return $self->rest->get("/plugin/$plugin_id", \%params);

}

sub get_plugin_family_list {

    my ($self, %params) = @_;
    return $self->rest->get('/pluginFamily', \%params);

}

sub get_plugin_family {

    my ($self, $plugin_family_id, $fields) = @_;

    (@_ == 2 || @_ == 3) or croak(q/Usage: $sc->get_plugin_family(PLUGIN_FAMILY_ID [,FIELDS])/);

    croak('Invalid Plugin Family ID') unless ($plugin_family_id =~ /\d/);

    my %params = ();

    if ($fields) {
        if (ref $fields eq 'ARRAY') {
            $params{'fields'} = join(',', @{$fields});
        } else {
            $params{'fields'} = $fields;
        }
    }

    return $self->rest->get("/pluginFamily/$plugin_family_id", \%params);

}

sub add_scan {

    my ($self, %params) = @_;

    my $scan_data = {
        'type'     => 'policy',
        'schedule' => { 'repeatRule' => 'FREQ=NOW;INTERVAL=1', 'type' => 'now' },
    };

    my @default_params = qw/name description ipList zone policy repository maxScanTime/;

    foreach (@default_params) {

        next unless (defined($params{$_}));

        if ($_ eq 'ipList' && ref $params{$_} eq 'ARRAY') {
            $params{$_} = join(',', @{$params{$_}});
        }

           if ($_ eq 'policy')     { $scan_data->{$_} = { 'id' => $params{$_} } }
        elsif ($_ eq 'zone')       { $scan_data->{$_} = { 'id' => $params{$_} } }
        elsif ($_ eq 'repository') { $scan_data->{$_} = { 'id' => $params{$_} } }
        else                       { $scan_data->{$_} = $params{$_} }

    }

    my $result = $self->rest->post('/scan', $scan_data);

    if (defined($result->{'scanResultID'})) {
        return $result->{'scanResultID'};
    }

}

sub get_scan_list {

    my ($self, %params) = @_;

    my $scans = $self->rest->get('/scanResult', \%params);

    # NOTE: 'running' and 'completed' filters return always 'manageable' and 'usable' scans
    if (defined($params{'filter'}) && ($params{'filter'} ne 'running' && $params{'filter'} ne 'completed')) {
        if (defined($scans->{$params{'filter'}})) {
            return $scans->{$params{'filter'}};
        } else {
            return [];
        }
    }

    return $scans;

}

sub get_running_scans {

    my ($self, $fields) = @_;

    my %params = ();

    if ($fields) {
        if (ref $fields eq 'ARRAY') {
            $params{'fields'} = join(',', @{$fields});
        } else {
            $params{'fields'} = $fields;
        }
    }

    $params{'filter'} = 'running';
    return $self->get_scan_list( %params );

}

sub get_completed_scans {

    my ($self, $fields) = @_;

    my %params = ();

    if ($fields) {
        if (ref $fields eq 'ARRAY') {
            $params{'fields'} = join(',', @{$fields});
        } else {
            $params{'fields'} = $fields;
        }
    }

    $params{'filter'} = 'completed';
    return $self->get_scan_list( %params );

}

sub get_scan {

    my ($self, $scan_id, $fields) = @_;

    (@_ == 2 || @_ == 3) or croak(q/Usage: $sc->get_scan(SCAN_ID [,FIELDS])/);

    croak('Invalid scan ID') unless ($scan_id =~ /\d/);

    my %params = ();

    if ($fields) {
        if (ref $fields eq 'ARRAY') {
            $params{'fields'} = join(',', @{$fields});
        } else {
            $params{'fields'} = $fields;
        }
    }

    return $self->rest->get("/scanResult/$scan_id", \%params);

}

sub get_scan_progress {

    my ($self, $scan_id) = @_;

    (@_ == 2) or croak(q/Usage: $sc->get_scan_progress(SCAN_ID)/);

    my $scan_data = $self->get_scan($scan_id, { 'fields' => 'id,totalChecks,completedChecks' });
    return sprintf('%d', ( $scan_data->{'completedChecks'} * 100 ) / $scan_data->{'totalChecks'});

}

sub get_scan_status {

    my ($self, $scan_id) = @_;

    (@_ == 2) or croak(q/Usage: $sc->get_scan_status(SCAN_ID)/);

    my $scan_data = $self->get_scan($scan_id, { 'fields' => 'id,status' });
    return lc($scan_data->{'status'});

}

sub pause_scan {

    my ($self, $scan_id) = @_;

    (@_ == 2) or croak(q/Usage: $sc->pause_scan(SCAN_ID)/);

    $self->rest->post("/scanResult/$scan_id/pause");
    return 1;

}

sub resume_scan {

    my ($self, $scan_id) = @_;

    (@_ == 2) or croak(q/Usage: $sc->resume_scan(SCAN_ID)/);

    $self->rest->post("/scanResult/$scan_id/resume");
    return 1;

}

sub stop_scan {

    my ($self, $scan_id) = @_;

    (@_ == 2) or croak(q/Usage: $sc->stop_scan(SCAN_ID)/);

    $self->rest->post("/scanResult/$scan_id/stop");
    return 1;

}

sub login {

    my ($self, $username, $password) = @_;

    (@_ == 3) or croak(q/Usage: $sc->login(USERNAME, PASSWORD)/);

    $self->rest->login($username, $password);
    return 1;

}

sub logout {

    my ($self) = @_;
    $self->rest->logout();
    return 1;

}

1;

__END__
=pod

=encoding UTF-8

=head1 NAME

Net::SecurityCenter - Perl interface to Tenable SecurityCenter REST API

=head1 SYNOPSIS

    use Net::SecurityCenter;
    my $sc = Net::SecurityCenter('sc.example.org');

    $sc->login('secman', 'password');

    my $running_scans = $sc->get_running_scan;

    $sc->logout();

=head1 DESCRIPTION

This module provides Perl scripts easy way to interface the REST API of Tenable
SecurityCenter.

For more information about the SecurityCenter REST API follow the online documentation:

L<https://docs.tenable.com/sccv/api/index.html>

=head1 CONSTRUCTOR

=head2 Net::SecurityCenter->new ( host [, { timeout => $timeout , ssl_options => $ssl_options } ] )

Create a new instance of B<Net::Security::Center> using B<Net::Security::Center::REST> package.

=over 4

=item * C<timeout> : Request timeout in seconds (default is 180) If a socket open,
read or write takes longer than the timeout, an exception is thrown.

=item * C<ssl_options> : A hashref of C<SSL_*> options to pass through to L<IO::Socket::SSL>.

=back

=head1 CORE METHODS

=head2 $sc->rest ()

Return the instance of L<Net::SecurityCenter::REST> class

=head2 $sc->login ( username, password )

Login into SecurityCenter.

=head2 $sc->logout

Logout from SecurityCenter.


=head1 SCAN METHODS

=head2 $sc->add_scan ( name => $name, ipList => $ip_list, description => $description, policy => $policy_id, repository => $repository_id, zone => $zone_id )

Create a new scan on SecurityCenter.

    $sc->add_scan(
        name        => 'Test API scan',
        ipList      => [ '192.168.1.2', '192.168.1.3' ],
        description => 'Test from Net::SecurityCenter Perl module',
        policy      => 1,
        repository  => 2,
        zone        => 1
    );

Params:

=over 4

=item * C<name> : Name of scan (required)

=item * C<description> : Description of scan

=item * C<ipList> : One or more IP address

=item * C<zone> : Scan Zone ID

=item * C<policy> : Policy ID

=item * C<repository> : Repository ID

=item * C<maxScanTime> : Max Scan Time

=back

=head2 $sc->download_nessus_scan ( scan_id [, filename ] )

Download the Nessus (XML) scan result.

    my $nessus_scan = $sc->download_nessus_scan(1337);

    $sc->download_nessus_scan(1337, '/var/nessus/scans/1337.nessus');

=head2 $sc->get_scan_list ( [ fields => $fields, filter => $filter ] )

Get list of scans (completed, running, etc.).

=head2 $sc->get_running_scans ( [fields] )

Get list of running scans.

=head2 $sc->get_completed_scans ( [fields] )

Get list of completed scans

=head2 $sc->get_scan ( scan_id [, fields ] )

Get scan information.

=head2 $sc->get_scan_progress ( scan_id )

Get scan progress.

    print 'Scan progress: ' . $sc->get_scan_progress(1337) . '%';

=head2 $sc->get_scan_status ( scan_id )

Get scan status.

    print 'Scan status: ' . $sc->get_scan_status(1337);

=head2 $sc->pause_scan ( scan_id )

Pause a scan.

    if ($sc->get_scan_status(1337) eq 'running') {
        $sc->pause_scan(1337);
    }

=head2 $sc->resume_scan ( scan_id )

Resume a paused scan.

    if ($sc->get_scan_status(1337) eq 'paused') {
        $sc->resume_scan(1337);
    }

=head2 $sc->stop_scan ( scan_id )

Stop a scan.

    if ($sc->get_scan_status(1337) eq 'running') {
        $sc->stop_scan(1337);
   }

=head1 PLUGIN METHODS

=head2 $sc->get_plugin_list ( [ fields ] )

Gets the list of all Nessus Plugins.

=head2 $sc->get_plugin ( plugin_id [, fields ] )

Get information about Nessus Plugin.

    $sc->get_plugin(19506, [ 'description', 'name' ]);

=head2 $sc->get_plugin_family_list ( [ fields ] )

Get list of Nessus Plugin Family.

=head2 $sc->get_plugin_family ( plugin_family_id [, fields ])

Get ifnrmation about Nessus Plugin Family.

=head1 SYSTEM INFORMATION AND MAINTENANCE METHODS

=head2 $sc->get_status ( [ fields ] )

Gets a collection of status information, including license.

=head2 $sc->get_system_info ()

Gets the system initialization information.

=head2 $sc->get_system_diagnostics_info ()

Gets the system diagnostics information.

=head2 $sc->generate_app_status_diagnostics ()

Starts an on-demand, diagnostics analysis for the System that can be downloaded after its job completes.

=head2 $sc->generate_diagnostics_file ( [ options ] )

Starts an on-demand, diagnostics analysis for the System that can be downloaded after its job completes.

=head2 $sc->download_system_diagnostics ()

Downloads the system diagnostics, debug file that was last generated.

=head2 $sc->get_feed ( [ type ] )

=head1 REPOSITORY METHODS

=head2 $sc->get_repository_list ( [ fields ] )

=head2 $sc->get_repository ( repository_id [, fields ])

=head2 $sc->get_device_info ( repository_id, ip_address [, params ] )

=head2 $sc->get_ip_info ( ip_address [, params ])

=head1 SCAN ZONE METHODS

=head2 $sc->get_scan_zone_list ( [ fields ] )

=head2 $sc->get_scan_zone ( zone_id [, fields ] )

=head1 SCAN POLICY METHODS

=head2 $sc->get_policy_list ( [ fields ] )

=head2 $sc->get_policy ( policy_id [, fields ])

=head1 REPORT METHODS

=head2 $sc->get_report_list ( [ fields ] )

=head2 $sc->get_report ( report_id [, fields ])

=head2 $sc->download_report ( report_id )

=head1 USER METHODS

=head2 $sc->get_user_list ( [ fields ] )

=head2 $sc->get_user ( user_id [, fields ] )

=head1 CREDENTIAL METHODS

=head2 $sc->get_credential_list ( [ fields ] )

=head2 $sc->get_credential ( credential_id [, fields ] )

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

=head1 AUTHORS

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
