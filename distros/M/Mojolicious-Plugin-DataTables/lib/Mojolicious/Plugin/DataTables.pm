package Mojolicious::Plugin::DataTables;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::JSON qw(decode_json encode_json true false);
use Mojo::Collection;
use Mojo::DOM::HTML;
use Mojo::ByteStream;
use Mojo::Util qw(dumper deprecated);

use Carp;

use Mojolicious::Plugin::DataTables::SSP::Column;
use Mojolicious::Plugin::DataTables::SSP::Params;
use Mojolicious::Plugin::DataTables::SSP::Results;

our $VERSION = '2.01';

sub register {

    my ( $c, $app, $conf ) = @_;

    $app->helper( 'datatable_js'          => \&_dt_js );
    $app->helper( 'datatable_css'         => \&_dt_css );
    $app->helper( 'datatable.ssp'         => \&_dt_ssp );
    $app->helper( 'datatable.ssp_params'  => \&_dt_ssp_params );
    $app->helper( 'datatable.ssp_results' => \&_dt_ssp_results );

}

sub _dt_js {

    my ( $c, $url ) = @_;

    my $dt_version = '1.10.24';
    my $dt_js_url  = $url || "//cdn.datatables.net/$dt_version/js/jquery.dataTables.min.js";

    return _tag( 'script', 'src' => $dt_js_url );

}

sub _dt_css {

    my ( $c, $url ) = @_;

    my $dt_version = '1.10.24';
    my $dt_js_url  = $url || "//cdn.datatables.net/$dt_version/css/jquery.dataTables.min.css";

    return _tag( 'link', 'rel' => 'stylesheet', 'href' => $dt_js_url );

}

sub _dt_ssp {

    my ( $c, %args ) = @_;

    my $table   = delete $args{table} || Carp::croak 'Missing table';
    my $options = delete $args{options};
    my $columns = delete $args{columns};
    my $debug   = delete $args{debug};
    my $where   = delete $args{where};
    my $sql     = delete $args{sql};

    if ( defined( $args{db} ) ) {

        deprecated '[Mojolicious::Plugin::DataTables] db is DEPRECATED in favor of sql';

        my $db = $args{db};

        $sql = $db->sqlite if ( ref $db eq 'Mojo::SQLite::Database' );
        $sql = $db->pg     if ( ref $db eq 'Mojo::Pg::Database' );
        $sql = $db->mysql  if ( ref $db eq 'Mojo::mysql::Database' );

    }

    my $log = $c->app->log->context('[DataTables]');

    my $regexp_operator = 'REGEXP';    # REGEXP operator for MySQL and SQLite

    my $sql_class = ref $sql;

    # "~" operator for PostgreSQL
    if ( $sql_class =~ /Mojo::Pg/ ) {
        $regexp_operator = '~';
    }

    my $ssp = $c->datatable->ssp_params($options);

    return {} if ( !$ssp->draw );

    my @columns = $ssp->db_columns;

    if ($columns) {
        if ( ref $columns eq 'ARRAY' ) {
            push @columns, @{$columns};
        } else {
            push @columns, $columns;
        }
    }

    my $abstract = {
        'where' => {
            '-and' => [],
            '-or'  => [],
        },
        'order'  => [],
        'filter' => [],
    };

    # Global filter
    if ($where) {
        if ( ref $where eq 'ARRAY' ) {
            my ( $where_stmt, @where_bind ) = @{$where};
            foreach (@where_bind) {
                $where_stmt =~ s/\?/'$_'/;    # TODO improve
            }
            push @{ $abstract->{where}->{'-and'} }, { '-bool' => $where_stmt };
            push @{ $abstract->{filter} },          { '-bool' => $where_stmt };
        } else {
            push @{ $abstract->{where}->{'-and'} }, { '-bool' => $where };
            push @{ $abstract->{filter} },          { '-bool' => $where };
        }
    }

    # Column Search
    foreach ( @{ $ssp->columns } ) {
        if ( $_->database && $_->searchable != 0 && $_->search->{value} ) {

            if ( $_->search->{regex} ) {
                push @{ $abstract->{where}->{'-and'} }, { $_->database => { $regexp_operator => $_->search->{value} } };
            } else {
                push @{ $abstract->{where}->{'-and'} },
                    { $_->database => { -like => '%' . $_->search->{value} . '%' } };
            }

        }
    }

    # Global Search
    if ( $ssp->search->{value} ) {
        foreach ( @{ $ssp->columns } ) {
            if ( $_->database && $_->searchable != 0 ) {

                if ( $ssp->search->{regex} ) {
                    push @{ $abstract->{where}->{'-or'} },
                        { $_->database => { $regexp_operator => $ssp->search->{value} } };
                } else {
                    push @{ $abstract->{where}->{'-or'} },
                        { $_->database => { -like => '%' . $ssp->search->{value} . '%' } };
                }
            }
        }
    }

    # Order
    if ( %{ $ssp->db_order } ) {

        my $order = $ssp->db_order;

        foreach my $column ( keys %{$order} ) {
            my $clausole = $order->{$column};
            push @{ $abstract->{order} }, { "-$clausole" => $column };
        }
    }

    delete $abstract->{where}->{'-and'} if ( scalar @{ $abstract->{where}->{'-and'} } < 1 );
    delete $abstract->{where}->{'-or'}  if ( scalar @{ $abstract->{where}->{'-or'} } < 1 );

    my ( $stmt, @bind ) = $sql->abstract->select( $table, \@columns, $abstract->{where}, $abstract->{order} );

    $stmt .= sprintf ' LIMIT %s OFFSET %s', $ssp->length, $ssp->start;    # TODO

    if ($debug) {
        $log->debug("Query: $stmt");
        $log->debug( "Bind: " . encode_json \@bind );
    }

    my $query = $sql->db->query( $stmt, @bind );

    my @results = ();

    while ( my $row = $query->hash ) {

        my $data = {};

        foreach my $column ( @{ $ssp->columns } ) {

            $column->row($row);

            my $col_db    = $column->database || '';
            my $col_value = $row->{$col_db};

            if ( ref $column->formatter eq 'CODE' ) {
                $col_value = $column->formatter->( $col_value, $column );
            }

            $data->{ $column->data } = $col_value;

        }

        push @results, $data;

    }

    my ( $stmt_total,  @bind_total )  = $sql->abstract->select( $table, [ \'COUNT(*) AS tot' ], $abstract->{filter} );
    my ( $stmt_filter, @bind_filter ) = $sql->abstract->select( $table, [ \'COUNT(*) AS tot' ], $abstract->{where} );

    if ($debug) {
        $log->debug("Query Total: $stmt_total");
        $log->debug( "Bind Total: " . encode_json \@bind_total );
        $log->debug("Query Filtered: $stmt_filter");
        $log->debug( "Bind Filtered: " . encode_json \@bind_filter );
    }

    my $total    = $sql->db->query( $stmt_total, @bind_total )->hash->{tot};
    my $filtered = $total;

    if (@bind_filter) {
        $filtered = $sql->db->query( $stmt_filter, @bind_filter )->hash->{tot};
    }

    my $ssp_results = Mojolicious::Plugin::DataTables::SSP::Results->new(
        draw           => $ssp->draw,
        data           => \@results,
        records_total  => $total,
        records_filtered => $filtered
    );

    return $ssp_results;

}

sub _dt_ssp_params {

    my ( $c, $dt_options ) = @_;

    my $req_params = {};
    $req_params = $c->req->query_params if ( $c->req->{method} eq 'GET' );
    $req_params = $c->req->body_params  if ( $c->req->{method} eq 'POST' );

    return Mojolicious::Plugin::DataTables::SSP::Params->new( %{ _decode_params( $req_params, $dt_options ) } );

}

sub _dt_ssp_results {
    my ( $c, %args ) = @_;
    return Mojolicious::Plugin::DataTables::SSP::Results->new(%args);
}

sub _tag { Mojo::ByteStream->new( Mojo::DOM::HTML::tag_to_html(@_) ) }

sub _decode_params {

    my ( $req_params, $dt_options ) = @_;

    my $dt_params = {};

    $dt_params->{draw}      = $req_params->param('draw')   || false;
    $dt_params->{length}    = $req_params->param('length') || 0;
    $dt_params->{start}     = $req_params->param('start')  || 0;
    $dt_params->{timestamp} = $req_params->param('_')      || 0;
    $dt_params->{columns}   = [];
    $dt_params->{order}     = [];
    $dt_params->{where}     = undef;

    foreach ( @{ $req_params->names } ) {

        my $value = $req_params->param($_);
        $value = true  if ( $value eq 'true' );
        $value = false if ( $value eq 'false' );

        $dt_params->{columns}[$1]->{$2} = $value if ( $_ =~ /columns\[(\d+)\]\[(data|name|searchable|orderable)\]/ );
        $dt_params->{columns}[$1]->{search}->{$2} = $value if ( $_ =~ /columns\[(\d+)\]\[search\]\[(regex|value|)\]/ );
        $dt_params->{order}[$1]->{$2}             = $value if ( $_ =~ /order\[(\d+)\]\[(column|dir)\]/ );
        $dt_params->{search}->{$1}                = $value if ( $_ =~ /search\[(value|regex)\]/ );

    }

    for ( my $i = 0; $i < @{$dt_options}; $i++ ) {

        my $dt_option = $dt_options->[$i];

        if ( !defined $dt_option->{dt} ) {
            $dt_option->{dt} = $i;
        }

        $dt_params->{columns}[ $dt_option->{dt} ]->{database}  = $dt_option->{db}        || undef;
        $dt_params->{columns}[ $dt_option->{dt} ]->{formatter} = $dt_option->{formatter} || undef;
        $dt_params->{columns}[ $dt_option->{dt} ]->{label}     = $dt_option->{label}     || undef;

        if ( defined $dt_option->{searchable} ) {
            $dt_params->{columns}[ $dt_option->{dt} ]->{searchable} = $dt_option->{searchable};
        }
        if ( defined $dt_option->{orderable} ) {
            $dt_params->{columns}[ $dt_option->{dt} ]->{orderable} = $dt_option->{orderable};
        }
    }

    for ( my $i = 0; $i < @{ $dt_params->{columns} }; $i++ ) {
        my $column = $dt_params->{columns}[$i];
        $dt_params->{columns}[$i] = Mojolicious::Plugin::DataTables::SSP::Column->new( %{$column} );
    }

    for ( my $i = 0; $i < @{ $dt_params->{order} }; $i++ ) {
        $dt_params->{order}[$i]->{column} = $dt_params->{columns}[ $dt_params->{order}[$i]->{column} ];
    }

    # $dt_params->{columns} = Mojo::Collection->new ( $dt_params->{columns} );
    # $dt_params->{order}   = Mojo::Collection->new ( $dt_params->{order} );

    return $dt_params;

}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::DataTables - DataTables Plugin for Mojolicious

=head1 SYNOPSIS

    # Mojolicious
    $self->plugin('DataTables');

    # Mojolicious::Lite
    plugin 'DataTables';

    [...]

    my $sql = Mojo::Pg->new;

    my $dt_ssp = $c->datatable->ssp(
        table   => 'users',
        sql     => $sql,
        columns => qw/role create_date/,
        debug   => 1,
        where   => 'status = "active"'
        options => [
            {
                label     => 'UID',
                db        => 'uid',
                dt        => 0,
                formatter => sub {
                    my ($value, $column) = @_;
                    return '<a href="/user/' . $value . '">' . $value . '</a>';
                }
            },
            {
                label => 'e-Mail',
                db    => 'mail',
                dt    => 1,
            },
            {
                label => 'Status',
                db    => 'status',
                dt    => 2,
            },
        ]
    );

    return $c->render(json => $dt_ssp);

=head1 DESCRIPTION

L<Mojolicious::Plugin::DataTables> is a L<Mojolicious> plugin to add DataTables SSP (Server-Side Protocol) support in your Mojolicious application.


=head1 METHODS

L<Mojolicious::Plugin::DataTables> implements the following methods.

=head2 datatable_js

Generate C<script> tag for include DataTables script file in your template.

=head2 datatable_css

Generate C<link rel="stylesheet"> tag for include DataTable CSS style in your template.

=head2 datatable.ssp

Params:

=over 4

=item C<table>: Database table

=item C<sql>: An instance of L<Mojo::Pg>, L<Mojo::SQLite>, L<Mojo::mysql> or compatible class

=item C<db>: An instance of L<Mojo::Pg::Database> or compatible class (B<DEPRECATED> use C<sql> instead)

=item C<columns>: Extra columns to fetch

=item C<debug>: Write useful debug information using L<Mojo::Log> class

=item C<where>: WHERE condition in L<SQL::Abstract> format

=item C<options>: Array of options (see below)

=back

Options:

=over 4

=item C<label>: Column label (optional)

=item C<db>: Database column name (required)

=item C<dt>: DataTable column ID (optional)

=item C<formatter>: Formatter sub

=back

=head2 datatable.ssp_params

Return an instance of L<Mojolicious::Plugin::DataTables::SSP::Params> class

=head2 datatable.ssl_results

Return an instance of L<Mojolicious::Plugin::DataTables::SSP::Results> class

=head1 EXAMPLES

=head2 Simple table

Template:

    <table id="users_table" class="display" style="width:100%">
        <thead>
            <th>UID</th>
            <th>e-Mail</th>
            <th>Status</th>
        </thead>
    </table>

    <script>
        jQuery('#users_table').DataTable({
            serverSide : true,
            ajax       : '/users_table',
        });
    </script>

Controller:

    $c->datatable->ssp(
        table   => 'users',
        sql     => $sql,
        options => [
            {
                label => 'UID',
                db    => 'uid',
                dt    => 0,
            },
            {
                label => 'e-Mail',
                db    => 'mail',
                dt    => 1,
            },
            {
                label => 'Status',
                db    => 'status',
                dt    => 2,
            },
        ]
    );

=head2 Formatter

The anonymous C<formatter> sub accept this arguments:

=over 4

=item C<$value>: the column value

=item C<$column>: A L<Mojolicious::Plugin::DataTables::SSP::Column> instance


    options => [
        {
            label     => 'Name',
            db        => 'username',
            dt        => 0,
            formatter => sub {
                my ($value, $column) = @_;
                my $row = $column->row;
                return '<a href="/user/' . $row->{id} . '">' .$value . '</a>';
            }
        },
        {
            ...
        }
    ]

=head2 Search flag

The C<searchable> flag enable=1 or disable=0 a filter for specified column.

    options => [
        {
            label      => 'Name',
            db         => 'username',
            dt         => 0,
            searchable => 0,
        },
        {
            ...
        }
    ]

=head2 Where condition

Use the C<where> option to filter the table using L<SQL::Abstract> syntax:

    $c->datatable->ssp(
        table   => 'users',
        sql     => $sql,
        where   => { status => 'active' }
        options => [ ... ]
    );

It's possible to use array (C<[ where, bind_1, bind_2, ... ]>) to bind values:

    $c->datatable->ssp(
        table   => 'users',
        sql     => $sql,
        where   => [ 'status = ?', 'active' ],
        options => [ ... ]
    );


=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>, L<https://datatables.net/>, L<SQL::Abstract>
L<Mojolicious::Plugin::DataTables::SSP::Params>, L<Mojolicious::Plugin::DataTables::SSP::Results>, L<Mojolicious::Plugin::DataTables::SSP::Column>.


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Mojolicious-Plugin-DataTables/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Mojolicious-Plugin-DataTables>

    git clone https://github.com/giterlizzi/perl-Mojolicious-Plugin-DataTables.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020-2021 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

