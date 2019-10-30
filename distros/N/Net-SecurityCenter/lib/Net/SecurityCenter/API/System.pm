package Net::SecurityCenter::API::System;

use warnings;
use strict;

use parent 'Net::SecurityCenter::API';

use Net::SecurityCenter::Utils qw(:all);

our $VERSION = '0.203';

#-------------------------------------------------------------------------------
# METHODS
#-------------------------------------------------------------------------------

sub get_status {

    my ( $self, %args ) = @_;

    my $tmpl = {
        fields => {
            filter => \&sc_filter_array_to_string
        },
        raw => {},
    };

    my $params = sc_check_params( $tmpl, \%args );
    my $raw    = delete( $params->{'raw'} );
    my $status = $self->client->get( '/status', $params );

    if ($raw) {
        return $status;
    }

    return sc_normalize_hash($status);

}

#-------------------------------------------------------------------------------

sub get_info {

    my ( $self, %args ) = @_;

    my $tmpl = { raw => {}, };

    my $params = sc_check_params( $tmpl, \%args );
    my $raw    = delete( $params->{'raw'} );
    my $info   = $self->client->get('/system');

    if ( !$info ) {
        return;
    }

    if ($raw) {
        return $info;
    }

    return sc_normalize_hash($info);

}

#-------------------------------------------------------------------------------

sub get_diagnostics_info {

    my ( $self, %args ) = @_;

    my $tmpl = { raw => {}, };

    my $params = sc_check_params( $tmpl, \%args );
    my $raw    = delete( $params->{'raw'} );
    my $info   = $self->client->get('/system/diagnostics');

    if ( !$info ) {
        return;
    }

    if ($raw) {
        return $info;
    }

    return sc_normalize_hash($info);

}

#-------------------------------------------------------------------------------

sub generate_diagnostics_app_status {

    my ($self) = @_;
    $self->client->post( '/system/diagnostics/generate', { 'task' => 'appStatus' } );
    return 1;

}

#-------------------------------------------------------------------------------

sub generate_diagnostics_file {

    my ( $self, %args ) = @_;

    my $tmpl = {
        type => {
            default => ['all'],
            allow   => [
                'all',        'apacheLog', 'configuration', 'dependencies', 'dirlist',    'environment',
                'installLog', 'logs',      'sanitize',      'scans',        'serverConf', 'setup',
                'sysinfo',    'upgradeLog'
            ]
        },
    };

    my $params  = sc_check_params( $tmpl, \%args );
    my $options = delete( $params->{'type'} );

    return $self->client->post( '/system/diagnostics/generate',
        { 'task' => 'diagnosticsFile', 'options' => \@{$options} } );

}

#-------------------------------------------------------------------------------

sub download_diagnostics {

    my ($self) = @_;
    return $self->client->post('/system/diagnostics/download');

}

#-------------------------------------------------------------------------------

1;

__END__
=pod

=encoding UTF-8


=head1 NAME

Net::SecurityCenter::API::System - Perl interface to Tenable.sc (SecurityCenter) System REST API


=head1 SYNOPSIS

    use Net::SecurityCenter::REST;
    use Net::SecurityCenter::API::System;

    my $sc = Net::SecurityCenter::REST->new('sc.example.org');

    $sc->login('secman', 'password');

    my $api = Net::SecurityCenter::API::System->new($sc);

    $sc->logout();


=head1 DESCRIPTION

This module provides Perl scripts easy way to interface the System REST API of Tenable.sc
(SecurityCenter).

For more information about the Tenable.sc (SecurityCenter) REST API follow the online documentation:

L<https://docs.tenable.com/sccv/api/index.html>


=head1 CONSTRUCTOR

=head2 Net::SecurityCenter::API::System->new ( $client )

Create a new instance of B<Net::SecurityCenter::API::System> using L<Net::SecurityCenter::REST> class.


=head1 METHODS

=head2 get_status

Gets a collection of status information, including license.

=head2 get_info

Gets the system initialization information.

=head2 get_diagnostics_info

Gets the system diagnostics information.

=head2 generate_diagnostics_app_status

Starts an on-demand, diagnostics analysis for the System that can be downloaded after its job completes.

=head2 generate_diagnostics_file

Starts an on-demand, diagnostics analysis for the System that can be downloaded after its job completes.

=head2 download_diagnostics

Downloads the system diagnostics, debug file that was last generated.


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

This software is copyright (c) 2018-2019 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
