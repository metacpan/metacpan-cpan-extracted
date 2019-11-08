package Net::SecurityCenter::API::Plugin;

use warnings;
use strict;

use Carp;
use MIME::Base64;
use English qw( -no_match_vars );
use Params::Check qw(allow);

use parent 'Net::SecurityCenter::API';

use Net::SecurityCenter::Utils qw(:all);

our $VERSION = '0.204';

my $common_template = {

    id => {
        required => 1,
        allow    => qr/^\d+$/,
        messages => {
            required => 'Plugin ID is required',
            allow    => 'Invalid Plugin ID',
        },
    },

    filter => {
        allow => [ 'usable', 'manageable' ],
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
        raw    => {},
        fields => $common_template->{'fields'},
        type   => {
            allow => [ 'active', 'all', 'compliance', 'custom', 'lce', 'notPassive', 'passive' ],
        },
        sort_field => {
            allow => [ 'modifiedTime', 'id', 'name', 'family', 'type' ],
            remap => 'sortDirection',
        },
        start_offset => {
            allow => qr/^\d+$/,
            remap => 'startOffset',
        },
        end_offset => {
            allow => qr/^\d+$/,
            remap => 'endOffset',
        },
        sort_direction => {
            allow  => [ 'ASC', 'DESC' ],
            remap  => 'sortDirection',
            filter => sub { uc $_[0] },
        },
        since => {
            allow => qr/^\d+$/,
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
        op => {
            allow => [ 'eq', 'gt', 'gte', 'like', 'lt', 'lte' ]
        },
        value  => {},
        filter => {},
    };

    if ( defined( $args{'filter'} ) ) {

        if ( ref $args{'filter'} ne 'ARRAY' ) {
            carp "Filter is not ARRAY";
            croak 'Usage: ' . __PACKAGE__ . '->list ( filter => [ FIELD, OPERATOR, VALUE ], ... )';
        }

        my ( $filter_field, $operator, $value ) = @{ $args{'filter'} };

        $args{'filter_field'} = $filter_field;
        $args{'op'}           = $operator;
        $args{'value'}        = $value;

        delete( $args{'filter'} );

    }

    my $params  = sc_check_params( $tmpl, \%args );
    my $raw     = delete( $params->{'raw'} );
    my $plugins = $self->client->get( '/plugin', $params );

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
        raw    => {},
    };

    my $params    = sc_check_params( $tmpl, \%args );
    my $raw       = delete( $params->{'raw'} );
    my $plugin_id = delete( $params->{'id'} );
    my $plugin    = $self->client->get( "/plugin/$plugin_id", $params );

    return if ( !$plugin );
    return $plugin if ($raw);

    return sc_normalize_hash($plugin);

}

#-------------------------------------------------------------------------------

sub download {

    my ( $self, %args ) = @_;

    my $tmpl = {
        filename => {},
        id       => $common_template->{'id'},
    };

    my $params    = sc_check_params( $tmpl, \%args );
    my $plugin_id = delete( $params->{'id'} );
    my $filename  = delete( $params->{'filename'} );

    my $plugin_data   = $self->client->get( "/plugin/$plugin_id", { 'fields' => 'id,source' } )->{'source'};
    my $plugin_source = decode_base64($plugin_data);

    return $plugin_source if ( !$filename );

    open my $fh, '>', $filename
        or croak("Could not open file '$filename': $OS_ERROR");

    print $fh $plugin_source;

    close $fh
        or carp("Failed to close file '$filename': $OS_ERROR");

    return 1;

}

#-------------------------------------------------------------------------------

1;

__END__
=pod

=encoding UTF-8


=head1 NAME

Net::SecurityCenter::API::Plugin - Perl interface to Tenable.sc (SecurityCenter) Plugin REST API


=head1 SYNOPSIS

    use Net::SecurityCenter::REST;
    use Net::SecurityCenter::API::Plugin;

    my $sc = Net::SecurityCenter::REST->new('sc.example.org');

    $sc->login('secman', 'password');

    my $api = Net::SecurityCenter::API::Plugin->new($sc);

    $sc->logout();


=head1 DESCRIPTION

This module provides Perl scripts easy way to interface the Plugin REST API of Tenable.sc
(SecurityCenter).

For more information about the Tenable.sc (SecurityCenter) REST API follow the online documentation:

=over 4

=item * L<https://docs.tenable.com/sccv/api/index.html>

=item * L<https://docs.tenable.com/sccv/api/Plugin.html>

=back


=head1 CONSTRUCTOR

=head2 Net::SecurityCenter::API::Plugin->new ( $client )

Create a new instance of B<Net::SecurityCenter::API::Plugin> using L<Net::SecurityCenter::REST> class.


=head1 METHODS

=head2 list

Gets the list of all Nessus Plugins.

    # Get all Nessus Plugin associated to CVE-2017-1000251

    $sc->list(
        filter_field => 'xrefs:CVE',
        op           => 'like',
        value        => 'CVE-2017-1000251',
        fields       => 'id,name,description,exploitAvailable'
    );

    # or using 'filter' param facility ( field, operator, value )

    $sc->list(
        filter => [ 'xrefs:CVE', 'like', 'CVE-2017-1000251' ],
        fields => 'id,name,description,exploitAvailable'
    );

=head2 get

Get information about Nessus plugin associated with plugin C<id>.

    $sc->get(
        id     => 19506,
        fields => [ 'description', 'name' ]
    );

=head2 download

Download plugin source (NASL) associated with plugin C<id>.

    my $nasl_source = $plugin->download( id => 19506 );

    # or save the plugin source in file

    $plugin->download( id => 19506, filename => '/tmp/19506.nasl' );


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
