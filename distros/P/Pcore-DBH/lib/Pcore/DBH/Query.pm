package Pcore::DBH::Query;

use Pcore -class;
use Pcore::Util::Text qw[trim];
use Pcore::Util::Scalar qw[blessed];
use Pcore::Util::List qw[pairs];

use overload    #
  q[""] => sub {
    return $_[0]->sql;
  },
  q[@{}] => sub {
    return $_[0]->bind;
  },
  fallback => undef;

has dbh => ( is => 'ro', isa => ConsumerOf ['Pcore::DBH'], required => 1, weak_ref => 1 );

has sql => ( is => 'rwp', isa => Str, init_arg => undef );
has bind => ( is => 'lazy', isa => ArrayRef, default => sub { [] }, init_arg => undef );

our $CONTEXT_KEYWORDS = {
    SELECT     => '_sql_cols',
    UPDATE     => '_sql_tables',
    FROM       => '_sql_tables',
    JOIN       => '_sql_tables',
    ON         => '_sql_where',
    INTO       => '_sql_tables',
    SET        => '_sql_set',
    VALUES     => '_sql_values',
    WHERE      => '_sql_where',
    'GROUP BY' => '_sql_group_by',
    'ORDER BY' => '_sql_order_by',
    LIMIT      => '_sql_limit',
};

sub get_context_keywords ($self) {
    return $CONTEXT_KEYWORDS;
}

sub _get_context_keywords_re ($self) {
    state $context_keywords_re = {};

    if ( !$context_keywords_re->{ ref $self } ) {
        my $context_keywords_prepared = join q[|], sort { length $b <=> length $a } map {s/\s+/\\s+/smgr} keys $self->get_context_keywords->%*;

        $context_keywords_re->{ ref $self } = qr/(?:(?<=\A)|(?<=\s))(?:$context_keywords_prepared)(?=\s|\z)/smi;
    }

    return $context_keywords_re->{ ref $self };
}

sub _build_query {
    my $self = shift;

    my $context_keywords = $self->get_context_keywords;

    my $context_keywords_re = $self->_get_context_keywords_re;

    my $sql;

    my $context;

    my $last_not_ref;

    for my $arg (@_) {
        if ( !ref $arg ) {
            die q[SQL query builder doesn't allow several consecutive non-ref argument] if $last_not_ref;

            $last_not_ref = 1;

            trim $arg;

            $sql .= q[ ] . $arg;

            # analyse context
            if ( my $last_kw = ( $arg =~ /$context_keywords_re/smgi )[-1] ) {
                $context = uc $last_kw =~ s/\s+/ /smgr;
            }
        }
        else {
            $last_not_ref = 0;

            if ( ref $arg eq 'SCALAR' ) {
                $sql .= q[ ?];

                push $self->bind->@*, $arg->$*;
            }
            else {
                my $method = $context_keywords->{$context};

                my ( $sql_ref, $bind_ref ) = $self->$method( $arg, \$sql, \$context );

                $sql .= q[ ] . $sql_ref->$* if $sql_ref;

                push $self->bind->@*, $bind_ref->@* if $bind_ref;
            }
        }
    }

    $self->_set_sql( trim $sql );

    return;
}

# QUERY CONTEXT METHODS
sub _sql_cols {
    my $self = shift;
    my $cols = ref $_[0] ? shift : [shift];

    my $sql = [];

    my $bind = [];

    my $dbh = $self->dbh;

    my $add_col = sub {
        my $col = shift;
        my $alias = $_[0] ? q[ AS ] . $dbh->quote_id(shift) : q[];

        if ( my $subquery = $self->_is_subquery($col) ) {
            push $sql->@*, $subquery->subquery_sql . $alias;

            push $bind->@*, $subquery->bind->@*;
        }
        elsif ( ref $col ) {
            push $sql->@*, $col->$* . $alias;
        }
        elsif ( $col eq q[*] ) {
            push $sql->@*, $col;
        }
        else {
            push $sql->@*, $dbh->quote_id($col) . $alias;
        }

        return;
    };

    for my $col ( $cols->@* ) {
        if ( ref $col eq 'HASH' ) {
            for my $alias ( keys $col->%* ) {
                $add_col->( $col->{$alias}, $alias );
            }
        }
        else {
            $add_col->($col);
        }
    }

    return \join( q[, ], $sql->@* ), $bind;
}

sub _sql_tables {
    my $self = shift;
    my $tables = ref $_[0] ? shift : [shift];

    my $sql = [];

    my $bind = [];

    my $dbh = $self->dbh;

    my $from = sub {
        my $tbl = shift;
        my $alias = $_[0] ? q[ ] . $dbh->quote_id(shift) : q[];

        if ( my $subquery = $self->_is_subquery($tbl) ) {
            push $sql->@*, $subquery->subquery_sql . $alias;

            push $bind->@*, $subquery->bind->@*;
        }
        else {
            push $sql->@*, $dbh->quote_id($tbl) . $alias;
        }

        return;
    };

    for my $tbl ( $tables->@* ) {
        if ( ref $tbl eq 'HASH' ) {
            for my $alias ( keys $tbl->%* ) {
                $from->( $tbl->{$alias}, $alias );
            }
        }
        else {
            $from->($tbl);
        }
    }

    return \join( q[, ], $sql->@* ), $bind;
}

sub _sql_set {
    my $self = shift;
    my $row  = shift;

    my ( $cols, $bind ) = $self->_quote_set($row);

    return \join( q[, ], map { $_ . q[ = ?] } $cols->@* ), $bind;
}

sub _sql_group_by {
    my $self = shift;
    my $args = shift;

    my $sql = [];

    my $dbh = $self->dbh;

    for my $col ( $args->@* ) {
        push $sql->@*, $dbh->quote_id($col);
    }

    return \join q[, ], $sql->@*;
}

sub _sql_order_by {
    my $self = shift;
    my $args = shift;

    my $sql = [];

    my $dbh = $self->dbh;

    for my $col ( $args->@* ) {
        if ( ref $col eq 'HASH' ) {
            for my $alias ( keys $col->%* ) {
                push $sql->@*, $dbh->quote_id($alias) . q[ ] . $col->{$alias};
            }
        }
        else {
            push $sql->@*, $dbh->quote_id($col) . q[ ASC];
        }
    }

    return \join q[, ], $sql->@*;
}

sub _sql_limit {
    my $self = shift;

    my $args = $self->_get_limit_args(@_);

    my $sql = q[?];

    my $bind = [];

    push $bind->@*, $args->{limit};

    if ( $args->{offset} ) {
        $sql .= q[, OFFSET ?];

        push $bind->@*, $args->{offset};
    }

    return \$sql, $bind;
}

sub _sql_where {
    my $self = shift;
    my $args = shift;

    my $sql = [];

    my $bind = [];

    my $dbh = $self->dbh;

    if ( ref $args eq 'HASH' ) {
        for my $field ( keys $args->%* ) {
            push $sql->@*, $dbh->quote_id($field) . q[ = ?];

            push $bind->@*, $args->{$field};
        }

        return \( q[(] . join( ' AND ', $sql->@* ) . q[)] ), $bind;
    }
    else {
        return \( q[(] . join( ', ', map {q[?]} $args->@* ) . q[)] ), $args;
    }
}

sub _sql_values {
    my $self    = shift;
    my $args    = shift;
    my $sql_ref = shift;

    my ( $cols, $rows ) = $self->_prepare_values($args);

    my $sql;

    my $dbh = $self->dbh;

    # add columns
    if ( $cols->@* ) {
        $sql .= q[( ] . join( q[, ], map { $dbh->quote_id($_) } $cols->@* ) . q[ ) ];
    }

    # add values
    $sql .= 'VALUES ';

    my $bind = [];

    my $row_values_mask = q[(] . join( q[, ], map {q[?]} ( 0 .. $rows->[0]->$#* ) ) . q[)];

    my $rows_mask = [];

    for my $row ( $rows->@* ) {
        push $bind->@*, $row->@*;

        push $rows_mask->@*, $row_values_mask;
    }

    $sql .= join q[, ], $rows_mask->@*;

    $sql_ref->$* =~ s/VALUES.*\z/$sql/smi;

    return ( undef, $bind );
}

sub _prepare_values {
    my $self = shift;
    my $args = ref $_[0] eq 'HASH' ? [shift] : shift;    # convert HashRef to ArrayRef[HashRef]

    my $cols = [];

    my $bind = [];

    my $cols_index;

    my $has_cols_index;

    # scan columns
    if ( !ref $args->[0] ) {
        if ( ref $args->[-1] ) {    # if last argument is ref - thread first non-ref args as columns
            $has_cols_index = 1;

            while ( !ref $args->[0] ) {
                my $col = shift $args->@*;

                push $cols->@*, $col;

                $cols_index->{$col} = $cols->@* - 1;
            }
        }
        else {                      # or treat arguments as one row
            $args = [$args];
        }
    }

    # dereference ArrayRef[ ArrayRef[ ArrayRef | HashRef ] ] to ArrayRef[ ArrayRef | HashRef ]
    my $rows = $args->@* == 1 && ref $args->[0] eq 'ARRAY' && ref $args->[0]->[0] ? $args->[0] : $args;

    # get colums from first row
    if ( !$has_cols_index && ref $rows->[0] eq 'HASH' ) {
        $has_cols_index = 1;

        for my $col ( keys $rows->[0]->%* ) {
            push $cols->@*, $col;

            $cols_index->{$col} = $cols->@* - 1;
        }
    }

    my $values = [];

    for my $row ( $rows->@* ) {
        if ( ref $row eq 'HASH' ) {
            my $row_values = [];

            for my $col ( $cols->@* ) {
                $row_values->[ $cols_index->{$col} ] = exists $row->{$col} ? $row->{$col} : undef;
            }

            push $values->@*, $row_values;
        }
        else {    # array of values
            if ($has_cols_index) {
                push $values->@*, [ splice $row->@*, 0, scalar $cols->@* ];

                # fill missed values with undef
                $values->[-1]->[ $cols->$#* ] = undef if $values->[-1]->$#* < $cols->$#*;
            }
            else {
                push $values->@*, $row;
            }
        }
    }

    return $cols, $values;
}

# QUERY EXECUTION METHODS
sub _execute_dbi_method {
    my ( $self, $method ) = splice @_, 0, 2, ();

    if ( $_[0] && blessed $_[0] ) {
        my $dbh = shift;

        return $dbh->$method( $self, @_ );
    }
    else {
        return $self->dbh->$method( $self, @_ );
    }
}

sub selectall {
    my $self = shift;

    return $self->_execute_dbi_method( 'selectall', @_ );
}

sub selectall_arrayref {
    my $self = shift;

    return $self->_execute_dbi_method( 'selectall_arrayref', @_ );
}

sub selectall_hashref {
    my $self = shift;

    return $self->_execute_dbi_method( 'selectall_hashref', @_ );
}

sub selectrow {
    my $self = shift;

    return $self->_execute_dbi_method( 'selectrow', @_ );
}

sub selectrow_hashref {
    my $self = shift;

    return $self->_execute_dbi_method( 'selectrow_hashref', @_ );
}

sub selectrow_arrayref {
    my $self = shift;

    return $self->_execute_dbi_method( 'selectrow_arrayref', @_ );
}

sub selectcol {
    my $self = shift;

    return $self->_execute_dbi_method( 'selectcol', @_ );
}

sub selectcol_arrayref {
    my $self = shift;

    return $self->_execute_dbi_method( 'selectcol_arrayref', @_ );
}

sub selectval {
    my $self = shift;

    return $self->_execute_dbi_method( 'selectval', @_ );
}

# NOTE
# queries, that contain multiple sql statements - should be executed with cache => 0 argument
sub do {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    my $self = shift;

    return $self->_execute_dbi_method( 'do', @_ );
}

# UTIL
sub _is_subquery {
    my $self = shift;

    if ( blessed( $_[0] ) ) {
        return shift;
    }
    else {
        return;
    }
}

sub subquery_sql {
    my $self = shift;

    my $sql = $self->sql;

    # $sql =~ s/\n\s*/ /smg;    # serialize subquery into single string

    if ( $sql =~ /\n/sm ) {
        $sql =~ s/^/    /smg;

        $sql =~ s/\A\s+/(   /sm;

        return $sql . $LF . q[)];
    }
    else {
        return q[( ] . $sql . q[ )];
    }
}

# common limit args parser
sub _get_limit_args {
    my $self = shift;
    my $args = ref $_[0] ? shift : [shift];

    my $limit_params = {};

    if ( $args->@* == 1 ) {
        $limit_params->{limit} = shift $args->@*;
    }
    elsif ( $args->@* == 2 ) {
        if ( $args->[0] eq 'limit' ) {
            $limit_params->{limit} = $args->[1];
        }
        else {
            $limit_params->{limit} = $args->[0];

            $limit_params->{offset} = $args->[1];
        }
    }
    elsif ( $args->@* == 4 ) {
        $limit_params->%* = $args->@*;
    }

    return $limit_params;
}

sub _quote_set {
    my $self = shift;
    my $row  = shift;

    my $cols = [];

    my $bind = [];

    my $dbh = $self->dbh;

    if ( ref $row eq 'HASH' ) {
        for my $col ( keys $row->%* ) {
            push $cols->@*, $dbh->quote_id($col);

            push $bind->@*, $row->{$col};
        }
    }
    else {
        for my $pair ( pairs( $row->@* ) ) {
            push $cols->@*, $dbh->quote_id( $pair->key );

            push $bind->@*, $pair->value;
        }
    }

    return $cols, $bind;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 |                      | Subroutines::ProhibitUnusedPrivateSubroutines                                                                  |
## |      | 107                  | * Private subroutine/method '_sql_cols' declared but not used                                                  |
## |      | 153                  | * Private subroutine/method '_sql_tables' declared but not used                                                |
## |      | 193                  | * Private subroutine/method '_sql_set' declared but not used                                                   |
## |      | 202                  | * Private subroutine/method '_sql_group_by' declared but not used                                              |
## |      | 217                  | * Private subroutine/method '_sql_order_by' declared but not used                                              |
## |      | 239                  | * Private subroutine/method '_sql_limit' declared but not used                                                 |
## |      | 259                  | * Private subroutine/method '_sql_where' declared but not used                                                 |
## |      | 283                  | * Private subroutine/method '_sql_values' declared but not used                                                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 45                   | BuiltinFunctions::ProhibitReverseSortBlock - Forbid $b before $a in sort blocks                                |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::DBH::Query - SQL query builder

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over

=item values

    values => [ { aa => 1, bb => 2 }, { aa => 3, bb => 4 } ],
    values => [ 'col1', 'col2', [ { aa => 1, col2 => 2 }, { aa => 3, bb => 4 } ] ],
    values => { aa => 1, bb => 2 },
    values => [ 'col1', 'col2', 'col3', [ [ 1, 2 ], [ 3, 4, 5 ], [6] ] ],
    values => [ [ 1, 2 ], [ 3, 4 ] ],

=back

=cut
