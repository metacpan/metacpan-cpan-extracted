package Net::SecurityCenter::API::PluginFamily;

use warnings;
use strict;

use Carp;

use parent 'Net::SecurityCenter::API';

use Net::SecurityCenter::Utils qw(:all);

our $VERSION = '0.205';

my $common_template = {

    id => {
        required => 1,
        allow    => qr/^\d+$/,
        messages => {
            required => 'Plugin Family ID is required',
            allow    => 'Invalid Plugin Family ID',
        },
    },

    op => {
        allow => [ 'eq', 'gt', 'gte', 'like', 'lt', 'lte' ]
    },

    type => {
        allow => [ 'active', 'all', 'compliance', 'custom', 'lce', 'notPassive', 'passive' ],
    },

    sort_field => {
        allow => [ 'modifiedTime', 'id', 'name', 'family', 'type' ],
        remap => 'sortDirection',
    },

    sort_direction => {
        allow  => [ 'ASC', 'DESC' ],
        remap  => 'sortDirection',
        filter => sub { uc $_[0] },
    },

    since => {
        allow => qr/^\d+$/,
    },

    start_offset => {
        allow => qr/^\d+$/,
        remap => 'startOffset',
    },

    end_offset => {
        allow => qr/^\d+$/,
        remap => 'endOffset',
    },

    filter_field => {
        allow => [
            'copyright',          'description',      'exploitAvailable', 'family',
            'id',                 'name',             'patchPubDate',     'patchModDate',
            'pluginPubDate',      'pluginModDate',    'sourceFile',       'type',
            'version',            'vulnPubDate',      'xrefs',            'xrefs:<string>',
            'xrefs:ALAS',         'xrefs:APPLE-SA',   'xrefs:AUSCERT',    'xrefs:BID',
            'xrefs:CERT',         'xrefs:CERT-CC',    'xrefs:CERT-FI',    'xrefs:CERTA',
            'xrefs:CISCO-BUG-ID', 'xrefs:CISCO-SA',   'xrefs:CISCO-SR',   'xrefs:CLSA',
            'xrefs:CONECTIVA',    'xrefs:CVE',        'xrefs:CWE',        'xrefs:DSA',
            'xrefs:EDB-ID',       'xrefs:FEDORA',     'xrefs:FLSA',       'xrefs:FreeBSD',
            'xrefs:GLSA',         'xrefs:HP',         'xrefs:HPSB',       'xrefs:IAVA',
            'xrefs:IAVB',         'xrefs:IAVT',       'xrefs:ICS-ALERT',  'xrefs:ICSA',
            'xrefs:MDKSA',        'xrefs:MDVSA',      'xrefs:MGASA',      'xrefs:MSFT',
            'xrefs:MSVR',         'xrefs:NSFOCUS',    'xrefs:NessusID',   'xrefs:OSVDB',
            'xrefs:OWASP',        'xrefs:OpenPKG-SA', 'xrefs:RHSA',       'xrefs:SSA',
            'xrefs:Secunia',      'xrefs:SuSE',       'xrefs:TLSA',       'xrefs:TSLSA',
            'xrefs:USN',          'xrefs:VMSA',       'xrefs:zone-h'
        ],
        remap => 'filterField',
    },

    fields => {
        filter => \&sc_filter_array_to_string,
    },

};

#-------------------------------------------------------------------------------
# METHODS
#-------------------------------------------------------------------------------

sub list {

    my ( $self, %args ) = @_;

    my $tmpl = {
        fields         => $common_template->{'fields'},
        type           => $common_template->{'type'},
        sort_field     => $common_template->{'sort_field'},
        sort_direction => $common_template->{'sort_direction'},
        since          => $common_template->{'since'},
        filter_field   => $common_template->{'filter_field'},
        op             => $common_template->{'op'},
    };

    my $params   = sc_check_params( $tmpl, \%args );
    my $response = $self->client->get( '/pluginFamily', $params );

    return if ( !$response );
    return $response;

}

#-------------------------------------------------------------------------------

sub list_plugins {

    my ( $self, %args ) = @_;

    my $tmpl = {
        fields         => $common_template->{'fields'},
        id             => $common_template->{'id'},
        type           => $common_template->{'type'},
        sort_field     => $common_template->{'sort_field'},
        sort_direction => $common_template->{'sort_direction'},
        since          => $common_template->{'since'},
        start_offset   => $common_template->{'start_offset'},
        end_offset     => $common_template->{'end_offset'},
        filter_field   => $common_template->{'filter_field'},
        op             => $common_template->{'op'},
    };

    my $params           = sc_check_params( $tmpl, \%args );
    my $raw              = delete( $params->{'raw'} );
    my $plugin_family_id = delete( $params->{'id'} );
    my $plugins          = $self->client->get( "/pluginFamily/$plugin_family_id/plugins", $params );

    return if ( !$plugins );
    return $plugins if ($raw);
    return sc_normalize_array($plugins);

}

#-------------------------------------------------------------------------------

sub get {

    my ( $self, %args ) = @_;

    my $tmpl = {
        fields => $common_template->{'fields'},
        id     => $common_template->{'id'},
    };

    my $params           = sc_check_params( $tmpl, \%args );
    my $plugin_family_id = delete( $params->{'id'} );

    my $response = $self->client->get( "/pluginFamily/$plugin_family_id", $params );

    return if ( !$response );
    return $response;

}

#-------------------------------------------------------------------------------

1;

__END__
=pod

=encoding UTF-8


=head1 NAME

Net::SecurityCenter::API::PluginFamily - Perl interface to Tenable.sc (SecurityCenter) Plugin Family REST API


=head1 SYNOPSIS

    use Net::SecurityCenter::REST;
    use Net::SecurityCenter::API::PluginFamily;

    my $sc = Net::SecurityCenter::REST->new('sc.example.org');

    $sc->login('secman', 'password');

    my $api = Net::SecurityCenter::API::PluginFamily->new($sc);

    $sc->logout();


=head1 DESCRIPTION

This module provides Perl scripts easy way to interface the Plugin Family REST API of Tenable.sc
(SecurityCenter).

For more information about the Tenable.sc (SecurityCenter) REST API follow the online documentation:

L<https://docs.tenable.com/sccv/api/index.html>


=head1 CONSTRUCTOR

=head2 Net::SecurityCenter::API::PluginFamily->new ( $client )

Create a new instance of B<Net::SecurityCenter::API::PluginFamily> using L<Net::SecurityCenter::REST> class.


=head1 METHODS

=head2 list

Get list of Nessus Plugin Family.

=head2 get

Get information about Nessus Plugin Family.

=head2 list_plugins

Get list of Nessus Plugins associated with Nessus Plugin Family.


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
