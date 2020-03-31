package Mojolicious::Plugin::DataTables;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::JSON qw(decode_json encode_json true false);
use Mojo::Collection;
use Mojo::DOM::HTML;
use Mojo::ByteStream;

use Mojolicious::Plugin::DataTables::SSP::Column;
use Mojolicious::Plugin::DataTables::SSP::Params;
use Mojolicious::Plugin::DataTables::SSP::Results;

our $VERSION = '1.03';

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

    my $dt_version = '1.10.20';
    my $dt_js_url  = $url || "//cdn.datatables.net/$dt_version/js/jquery.dataTables.min.js";

    return _tag( 'script', 'src' => $dt_js_url );

}

sub _dt_css {

    my ( $c, $url ) = @_;

    my $dt_version = '1.10.20';
    my $dt_js_url  = $url || "//cdn.datatables.net/$dt_version/css/jquery.dataTables.min.css";

    return _tag( 'link', 'rel' => 'stylesheet', 'href' => $dt_js_url );

}

sub _dt_ssp {

    my ( $c, %args ) = @_;

    my $table   = delete $args{table};
    my $options = delete $args{options};
    my $db      = delete $args{db};
    my @columns = delete $args{columns};
    my $debug   = delete $args{debug};
    my $where   = delete $args{where};

    if ( !$db ) {
        $c->app->log->error('Missing "db" param') if ($debug);
        return {};
    }

    my $regexp_operator = 'REGEXP';    # REGEXP operator for MySQL and SQLite
    my $db_type         = ref $db;

    # "~" operator for PostgreSQL
    if ( $db_type =~ /Mojo::Pg/ ) {
        $regexp_operator = '~';
    }

    my $ssp = $c->datatable->ssp_params($options);

    return {} if ( !$ssp->draw );

    my $db_filter  = '';
    my @db_filters = ();
    my $db_order   = '';
    my @db_bind    = ();
    my @db_columns = $ssp->db_columns;

    push @db_columns, @columns;

    if ($where) {
        if (ref $where eq 'ARRAY') {
            my ($where_sql, @where_bind) = @{$where};
            push @db_filters, $where_sql;
            push @db_bind, @where_bind;
        } else {
            push @db_filters, $where;
        }
    }

    # Column filter
    my @col_filters;

    foreach ( @{ $ssp->columns } ) {
        if ( $_->database && $_->searchable != 0 && $_->search->{value} ) {

            if ( $_->search->{regex} ) {
                push @col_filters, $_->database . " $regexp_operator ?";
                push @db_bind,     $_->search->{value};
            } else {
                push @col_filters, $_->database . " LIKE ?";
                push @db_bind,     '%' . $_->search->{value} . '%';
            }

        }
    }

    if (@col_filters) {
        push @db_filters, '(' . join( ' AND ', @col_filters ) . ')';
    }

    # Global Search
    if ( $ssp->search->{value} ) {

        my @global_filters;

        foreach ( @{ $ssp->columns } ) {
            if ( $_->database && $_->searchable != 0 ) {

                if ( $ssp->search->{regex} ) {
                    push @global_filters, $_->database . " $regexp_operator ?";
                    push @db_bind,        $ssp->search->{value};
                } else {
                    push @global_filters, $_->database . " LIKE ?";
                    push @db_bind,        '%' . $ssp->search->{value} . '%';
                }

            }
        }

        if (@global_filters) {
            push @db_filters, '(' . join( ' OR ', @global_filters ) . ')';
        }

    }

    # Filter
    if (@db_filters) {
        $db_filter = 'WHERE ' . join( ' AND ', @db_filters );
    }

    # Order
    if ( %{ $ssp->db_order } ) {

        my @db_orders;
        my $order = $ssp->db_order;

        foreach ( keys %{$order} ) {
            push @db_orders, $_ . ' ' . $order->{$_};
        }

        $db_order = 'ORDER BY ' . join( ',', @db_orders );

    }

    my $sql = sprintf(
        'SELECT %s FROM %s %s %s LIMIT %s OFFSET %s',
        join( ',', @db_columns ),
        $table, $db_filter, $db_order, $ssp->length, $ssp->start
    );

    if ($debug) {
        $c->app->log->debug("SSP - Query: $sql");
        $c->app->log->debug( "SSP - Bind: " . encode_json \@db_bind );
    }

    my $query = $db->query( $sql, @db_bind );

    my @results;

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

    my $total    = $db->query( sprintf( 'SELECT COUNT(*) AS TOT FROM %s', $table ) )->hash->{tot};
    my $filtered = $total;

    if (@db_bind) {
        $filtered
            = $db->query( sprintf( 'SELECT COUNT(*) AS TOT FROM %s %s', $table, $db_filter ), @db_bind )->hash->{tot};
    }

    my $ssp_results = $c->datatable->ssp_results(
        draw             => $ssp->draw,
        data             => \@results,
        records_total    => $total,
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

    my $dt_ssp = $c->datatable->ssp(
        table   => 'users',
        db      => $db,
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

=item C<db>: An instance of L<Mojo::Pg> or compatible class

=item C<columns>: Extra columns to fetch

=item C<debug>: Write debug information using L<Mojo::Log> class

=item C<where>: WHERE condition in SQL format

=item C<options>: Array of options (see below)

=back

Options:

=over 4

=item C<label>: Column label

=item C<db>: Database column name

=item C<dt>: DataTable column ID

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
        db      => $db,
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

The C<searchable> flag enable or disable a filter for specified column.

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

Use the C<where> option to filter the table:

    $c->datatable->ssp(
        table   => 'users',
        db      => $db,
        where   => 'status = 1',
        options => [ ... ]
    );

It's possible to use array (C<[ where, bind_1, bind_2, ... ]>) to bind values:

    $c->datatable->ssp(
        table   => 'users',
        db      => $db,
        where   => [ 'status = ?', 'active' ],
        options => [ ... ]
    );


=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>, L<https://datatables.net/>, L<Mojolicious::Plugin::DataTables::SSP::Params>, L<Mojolicious::Plugin::DataTables::SSP::Results>, L<Mojolicious::Plugin::DataTables::SSP::Column>.

=cut
