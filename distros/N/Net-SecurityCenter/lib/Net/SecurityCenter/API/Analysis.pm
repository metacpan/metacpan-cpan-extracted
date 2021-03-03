package Net::SecurityCenter::API::Analysis;

use warnings;
use strict;

use Carp;

use parent 'Net::SecurityCenter::Base';

use Net::SecurityCenter::Utils qw(:all);

our $VERSION = '0.310';

my $common_template = {
    tool => {
        allow => [
            'cceipdetail',           'cveipdetail',  'iavmipdetail',   'iplist',
            'listmailclients',       'listservices', 'listos',         'listsoftware',
            'listsshservers',        'listvuln',     'listwebclients', 'listwebservers',
            'sumasset',              'sumcce',       'sumclassa',      'sumclassb',
            'sumclassc',             'sumcve',       'sumdnsname',     'sumfamily',
            'sumiavm',               'sumid',        'sumip',          'summsbulletin',
            'sumport',               'sumprotocol',  'sumremediation', 'sumseverity',
            'sumuserresponsibility', 'trend',        'vulndetails',    'vulnipdetail',
            'vulnipsummary'
        ],
    },
    view => {
        allow => [ 'all', 'new', 'patched' ]
    },
    limit => {
        allow   => qr/^\d+$/,
        default => 1000,
    },
    page => {
        allow   => qr/^(\d+|all)$/,
        default => 'all',
    },
    sort_dir => {
        allow  => [ 'ASC', 'DESC' ],
        filter => sub { uc $_[0] },
    },
    scan_id => {
        allow => qr/^\d+$/,
    },
    lce_id => {
        allow => qr/^\d+$/,
    },
    query_id => {
        allow => qr/^\d+$/,
    },
    date => {
        allow => qr/^(\d+|all)$/,
    }
};

#-------------------------------------------------------------------------------
# METHODS
#-------------------------------------------------------------------------------

sub get {

    my ( $self, %args ) = @_;

    my $tmpl = {
        type => {
            allow    => [ 'scLog', 'vuln', 'event', 'mobile', 'user' ],
            required => 1,
        },
        tool   => $common_template->{'tool'},
        source => {
            allow => [ 'cumulative', 'individual', 'archive', 'patched', 'lce' ],
        },
        sort_dir   => $common_template->{'sort_dir'},
        sort_field => {},
        view       => $common_template->{'view'},
        scan_id    => $common_template->{'scan_id'},
        lce_id     => $common_template->{'lce_id'},
        query_id   => $common_template->{'query_id'},
        query      => {},
        filters    => {},
        date       => $common_template->{'date'},
        limit      => $common_template->{'limit'},
        page       => $common_template->{'page'},
        download   => {},
        columns    => {},
    };

    my $params = sc_check_params( $tmpl, \%args );

    my $scan_id    = delete( $params->{'scan_id'} );
    my $query_id   = delete( $params->{'query_id'} );
    my $lce_id     = delete( $params->{'lce_id'} );
    my $tool       = delete( $params->{'tool'} );
    my $type       = delete( $params->{'type'} );
    my $filters    = delete( $params->{'filters'} );
    my $date       = delete( $params->{'date'} );
    my $source     = delete( $params->{'source'} );
    my $sort_dir   = delete( $params->{'sort_dir'} );
    my $sort_field = delete( $params->{'sort_field'} );
    my $view       = delete( $params->{'view'} );

    # Fallback sourceType param
    if ( defined( $params->{'source_type'} ) ) {
        $type = $params->{'source_type'};
    }

    # Pagination
    my $count = 0;
    my $page  = delete( $params->{'page'} );
    my $limit = delete( $params->{'limit'} );
    my $total = $limit;

    # For download API
    my $download = delete( $params->{'download'} );
    my $columns  = delete( $params->{'columns'} );

    my $analysis_params = {
        type  => $type,
        query => {
            filters => [],
            type    => $type,
        }
    };

    my @results = ();

    # If not defined the query build the query using "filters" argument
    if ($filters) {

        if ( ref $filters->[0] eq 'ARRAY' ) {

            foreach my $filter ( @{$filters} ) {

                push(
                    @{ $analysis_params->{'query'}->{'filters'} },
                    {
                        'filterName' => $filter->[0],
                        'operator'   => $filter->[1],
                        'value'      => $filter->[2],
                        'type'       => $type,
                    }
                );
            }

        } else {
            $analysis_params->{'query'}->{'filters'} = $filters;
        }

    }

    if ($query_id) {
        $analysis_params->{'query'}->{'id'} = $query_id;
    }

    if ($source) {
        $analysis_params->{'sourceType'} = $source;
    }

    if ($tool) {
        $analysis_params->{'query'}->{'tool'} = $tool;
    }

    if ($sort_dir) {
        $analysis_params->{'sortDir'} = $sort_dir;
    }

    if ($sort_field) {
        $analysis_params->{'sortField'} = $sort_field;
    }

    if ($view) {
        $analysis_params->{'view'} = $view;
    }

    if ($scan_id) {
        $analysis_params->{'scanID'} = $scan_id;
    }

    # Add pagination
    if ( $page eq 'all' ) {
        $analysis_params->{'query'}->{'startOffset'} = 0;
        $analysis_params->{'query'}->{'endOffset'}   = $limit;
    } else {
        $analysis_params->{'query'}->{'startOffset'} = $page * $limit;
        $analysis_params->{'query'}->{'endOffset'}   = ( $page + 1 ) * $limit;
    }

    # Add date params for "scLog" analysis type
    if ( $type eq 'scLog' ) {
        $analysis_params->{'date'} = $date;
    }

    # Download API
    if ($download) {

        my @columns_params = ();

        foreach my $column ( split( /,/, $columns ) ) {
            push( @columns_params, { 'name' => $column } );
        }

        $analysis_params->{'columns'} = \@columns_params;

        # TODO check offset
        my $result = $self->client->post( '/analysis/download', $analysis_params );
        return $result;
    }

    while ( $total > $count ) {
        my $result = $self->client->post( '/analysis', $analysis_params );

        return if ( !$result );

        push( @results, @{ $result->{'results'} } );

        $total = $result->{'totalRecords'};

        if ( $page eq 'all' ) {
            $count                                       = $result->{'endOffset'};
            $analysis_params->{'query'}->{'startOffset'} = $count;
            $analysis_params->{'query'}->{'endOffset'}   = $count + $limit;
        } else {
            $count = $total;
        }

    }

    return \@results;

}

#-------------------------------------------------------------------------------

sub download {

    my ( $self, %args ) = @_;

    $args{'download'} = 1;

    return $self->get(%args);

}

#-------------------------------------------------------------------------------

sub get_vulnerabilities {

    my ( $self, %args ) = @_;

    my $tmpl = {
        query_id   => $common_template->{'query_id'},
        sort_dir   => $common_template->{'sort_dir'},
        sort_field => {},
        source     => {
            allow => [ 'individual', 'cumulative', 'patched' ],
        },
        view    => $common_template->{'view'},
        scan_id => $common_template->{'scan_id'},
        tool    => {
            allow   => $common_template->{'tool'}->{'allow'},
            default => 'vulndetails',
        },
        page    => $common_template->{'page'},
        limit   => $common_template->{'limit'},
        filters => {}
    };

    my $params = sc_check_params( $tmpl, \%args );

    $params->{'type'} = 'vuln';

    return $self->get( %{$params} );

}

#-------------------------------------------------------------------------------

sub get_events {

    my ( $self, %args ) = @_;

    my $tmpl = {
        query_id   => $common_template->{'query_id'},
        sort_dir   => $common_template->{'sort_dir'},
        sort_field => {},
        source     => {
            allow => [ 'lce', 'archive' ],
        },
        lce_id => $common_template->{'lce_id'},
        view   => {},
        limit  => $common_template->{'limit'},
        page   => $common_template->{'page'},
        tool   => {
            allow => [
                'listdata',    'sumasset', 'sumclassa', 'sumclassb', 'sumclassc', 'sumconns',
                'sumdate',     'sumdstip', 'sumevent',  'sumevent2', 'sumip',     'sumport',
                'sumprotocol', 'sumsrcip', 'sumtime',   'sumtype',   'sumuser',   'syslog',
                'timedist'
            ],
            default => 'syslog'
        }
    };

    my $params = sc_check_params( $tmpl, \%args );

    $params->{'type'} = 'event';

    return $self->get( %{$params} );

}

#-------------------------------------------------------------------------------

sub get_mobile {

    my ( $self, %args ) = @_;

    my $tmpl = {
        query_id   => $common_template->{'query_id'},
        sort_dir   => $common_template->{'sort_dir'},
        sort_field => {},
        tool       => {
            allow => [
                'listvuln', 'sumdeviceid', 'summdmuser',  'summodel',
                'sumoscpe', 'sumpluginid', 'sumseverity', 'vulndetails'
            ],
            default => 'vulndetails'
        },
        limit => $common_template->{'limit'},
        page  => $common_template->{'page'},
    };

    my $params = sc_check_params( $tmpl, \%args );

    $params->{'type'} = 'mobile';

    return $self->get( %{$params} );

}

#-------------------------------------------------------------------------------

sub get_log {

    my ( $self, %args ) = @_;

    my $severity_filter = sub {

        my $severity = { 'INFO' => 0, 'WARNING' => 1, 'CRITICAL' => 2 };

        return {
            filterName => 'severity',
            value      => {
                id       => $severity->{ uc( $_[0] ) },
                operator => '=',
                name     => uc( $_[0] ),
            }
        };

    };

    my $keyword_filter = sub {
        return { filterName => 'keyword', operator => '=', value => $_[0] };
    };

    my $module_filter = sub {
        return { filterName => 'module', operator => '=', value => $_[0] };
    };

    my $organization_filter = sub {
        return { filterName => 'module', operator => '=', value => { id => $_[0] } };
    };

    my $initiator_filter = sub {
        return { filterName => 'initiator', operator => '=', value => { id => $_[0] } };
    };

    my $tmpl = {
        severity => {
            allow       => [ 'info', 'warning', 'critical' ],
            post_filter => \&$severity_filter,
        },
        keywords => {
            filter => \&$keyword_filter,
        },
        module => {
            filter => \&$module_filter,
        },
        organization => {
            filter => \&$organization_filter,
        },
        initiator => {
            filter => \&$initiator_filter,
        },
        date  => $common_template->{'date'},
        limit => $common_template->{'limit'},
        page  => $common_template->{'page'},
    };

    my $params = sc_check_params( $tmpl, \%args );

    my $analysis_params = {
        type    => 'scLog',
        date    => $params->{'date'},
        filters => [],
    };

    my $severity     = delete( $params->{'severity'} );
    my $keyword      = delete( $params->{'keyword'} );
    my $module       = delete( $params->{'module'} );
    my $organization = delete( $params->{'orgwnization'} );
    my $initiator    = delete( $params->{'initiator'} );

    if ($severity) {
        push( @{ $analysis_params->{'filters'} }, $severity );
    }

    if ($keyword) {
        push( @{ $analysis_params->{'filters'} }, $keyword );
    }

    if ($module) {
        push( @{ $analysis_params->{'filters'} }, $module );
    }

    if ($organization) {
        push( @{ $analysis_params->{'filters'} }, $organization );
    }

    if ($initiator) {
        push( @{ $analysis_params->{'filters'} }, $initiator );
    }

    return $self->get( %{$analysis_params} );

}

#-------------------------------------------------------------------------------

1;

__END__
=pod

=encoding UTF-8


=head1 NAME

Net::SecurityCenter::API::Analysis - Perl interface to Tenable.sc (SecurityCenter) Analysis REST API


=head1 SYNOPSIS

    use Net::SecurityCenter::REST;
    use Net::SecurityCenter::API::Analysis;

    my $sc = Net::SecurityCenter::REST->new('sc.example.org');

    $sc->login('secman', 'password');

    my $api = Net::SecurityCenter::API::Analysis->new($sc);

    $sc->logout();


=head1 DESCRIPTION

This module provides Perl scripts easy way to interface the Analysis REST API of Tenable.sc
(SecurityCenter).

For more information about the Tenable.sc (SecurityCenter) REST API follow the online documentation:

L<https://docs.tenable.com/sccv/api/index.html>


=head1 CONSTRUCTOR

=head2 Net::SecurityCenter::API::Analysis->new ( $client )

Create a new instance of B<Net::SecurityCenter::API::Analysis> using L<Net::SecurityCenter::REST> class.


=head1 METHODS

=head2 get

Processes a query for analysis

Params:

=over 4

=item * C<type> : Type of analysis (I<required>)

Allowed types:

=over 4

=item * C<scLog>

=item * C<vuln>

=item * C<event>

=item * C<mobile>

=item * C<user>

=back

=item * C<source> : Type of source

Allowed values for C<vuln> type:

=over 4

=item * C<individual>

=item * C<cumulative>

=item * C<patched>

=back

Allowed values for C<event> type:

=over 4

=item * C<lce>

=item * C<archive>

=back

=item * C<tool> : Tool

Allowed values:

=over 4

=item * C<cceipdetail>

=item * C<cveipdetail>

=item * C<iavmipdetail>

=item * C<listmailclients>

=item * C<listservices>

=item * C<listos>

=item * C<listsoftware>

=item * C<listsshservers>

=item * C<listvuln>

=item * C<listwebclients>

=item * C<listwebservers>

=item * C<sumasset>

=item * C<sumcce>

=item * C<sumclassa>

=item * C<sumclassb>

=item * C<sumclassc>

=item * C<sumcve>

=item * C<sumdnsname>

=item * C<sumfamily>

=item * C<sumiavm>

=item * C<sumid>

=item * C<sumip>

=item * C<summsbulletin>

=item * C<sumport>

=item * C<sumprotocol>

=item * C<sumremediation>

=item * C<sumseverity>

=item * C<sumuserresponsibility>

=item * C<trend>

=item * C<vulndetails>

=item * C<vulnipdetail>

=item * C<vulnipsummary>

=back

=item * C<filters> : Filter array for I<field>, I<operator> and I<value> (eg. C<[ 'ip', '=', '10.10.0.0/16' ]>)

=item * C<query_id> : ID of query

=item * C<sort_dir> : Sort direction C<ASC> or C<DESC>

=item * C<sort_field> : Sort field

=item * C<scan_id> : Scan ID (only for C<individual> source type and C<vuln> type values)

=item * C<lce_id> : LCE ID (only for C<archive> source type and C<event> type values)

=item * C<view> : View type (only for C<individual> source type and C<vuln> type values and C<archive> source type and C<event> type values)

=over 4

=item * C<view>

=item * C<all>

=item * C<new>

=item * C<patched>

=back

=item * C<page> : Number of page for pagination

=item * C<limit> : Number of items (default is C<1000>)

=back


=head2 download

Downloads an analysis of a query in CSV format.

B<NOTE>: This is a facility for C<$sc-E<gt>get( download =E<gt> 1, ... )> method

Params:

=over 4

=item * C<type> : Type of analysis (I<required>)

=item * C<query_id> : ID of query

=item * C<sort_dir> : Sort direction C<ASC> or C<DESC>

=item * C<sort_field> : Sort field

=item * C<scan_id> : Scan ID (only for C<individual> source type and C<vuln> type values)

=item * C<view> : View type (only for C<individual> source type and C<vuln> type values and C<archive> source type and C<event> type values)

=item * C<columns> : Report columns (comma-separated value, eg. C<pluginID,name>)

=back


=head2 get_log

Processes a query for log analysis.

B<NOTE>: This is a facility for C<$sc-E<gt>get( type =E<gt> 'scLog', ... )> method

Params:

=over 4

=item * C<date> : Log basename (C<YYYYMM> eg. C<201901>) or C<all>

=item * C<severity> : Log severity (C<info>, C<warning> or C<critical>)

=item * C<initiator> : ID of SecurityCenter user

=item * C<module> : Module (eg. C<auth>)

=item * C<organization> : ID of SecurityCenter organization

=item * C<page> : Number of page for pagination (default is C<all>)

=item * C<limit> : Number of items (default is C<1000>)

=back


=head2 get_vulnerabilities

Processes a query for vulnerability analysis.

B<NOTE>: This is a facility for C<$sc-E<gt>get( type =E<gt> 'vuln', ... )> method

Params:

=over 4

=item * C<query_id> : ID of query

=item * C<sort_dir> : Sort direction C<ASC> or C<DESC>

=item * C<sort_field> : Sort field

=item * C<source> : Type of source

=over 4

=item C<individual>

=item C<cumulative>

=item C<patched>

=back

=item * C<view> : View type (see C<$sc-E<gt>get( view =E<gt> ... )> for allowed values)

=item * C<scan_id> : Scan ID

=item * C<tool> : Tool (see C<$sc-E<gt>get( tool =E<gt> ... )> for allowed params)

=item * C<page> : Number of page for pagination

=item * C<limit> : Number of items (default is C<1000>)

=item * C<filters> : Filter array for I<field>, I<operator> and I<value> (eg. C<[ 'ip', '=', '10.10.0.0/16' ]>)

=back

=head2 get_events

Processes a query for event analysis.

B<NOTE>: This is a facility for C<$sc-E<gt>get( type =E<gt> 'event', ... )> method

Params:

=over 4

=item * C<query_id> : ID of query

=item * C<sort_dir> : Sort direction C<ASC> or C<DESC>

=item * C<sort_field> : Sort field

=item * C<source> : Type of source

=over 4

=item C<lce>

=item C<archive>

=back

=item * C<view> : View type (see C<$sc-E<gt>get( view =E<gt> ... )> for allowed values)

=item * C<lce_id> : LCE ID

=item * C<tool> : Tool

=over 4

=item * C<listdata>

=item * C<sumasset>

=item * C<sumclassa>

=item * C<sumclassb>

=item * C<sumclassc>

=item * C<sumconns>

=item * C<sumdate>

=item * C<sumdstip>

=item * C<sumevent>

=item * C<sumevent2>

=item * C<sumip>

=item * C<sumport>

=item * C<sumprotocol>

=item * C<sumsrcip>

=item * C<sumtime>

=item * C<sumtype>

=item * C<sumuser>

=item * C<syslog>

=item * C<timedist>

=back

=item * C<page> : Number of page for pagination

=item * C<limit> : Number of items (default is C<1000>)

=item * C<filters> : Filter array for I<field>, I<operator> and I<value> (eg. C<[ 'ip', '=', '10.10.0.0/16' ]>)

=back

=head2 get_mobile

Processes a query for mobile analysis.

B<NOTE>: This is a facility for C<$sc-E<gt>get( type =E<gt> 'mobile', ... )> method

Params:

=over 4

=item * C<query_id> : ID of query

=item * C<sort_dir> : Sort direction C<ASC> or C<DESC>

=item * C<sort_field> : Sort field

=item * C<tool> : Tool

=over 4

=item * C<listvuln>

=item * C<sumdeviceid>

=item * C<summdmuser>

=item * C<summodel>

=item * C<sumoscpe>

=item * C<sumpluginid>

=item * C<sumseverity>

=item * C<vulndetails>

=back

=item * C<page> : Number of page for pagination

=item * C<limit> : Number of items (default is C<1000>)

=item * C<filters> : Filter array for I<field>, I<operator> and I<value> (eg. C<[ 'ip '= '10.10.0.0/16' ]>)

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

This software is copyright (c) 2018-2021 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
