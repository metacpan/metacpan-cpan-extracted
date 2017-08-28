package Pcore::Handle::DBI;

use Pcore -role, -const, -result;

use Pcore::Util::Scalar qw[is_ref is_plain_scalarref is_plain_hashref is_plain_arrayref is_plain_refref];
use Pcore::Handle::DBI::STH;

with qw[Pcore::Handle];

requires qw[_get_schema_patch_table_query prepare quote];

has on_connect => ( is => 'ro', isa => Maybe [CodeRef] );

has _schema_patch => ( is => 'ro', isa => HashRef, init_arg => undef );

const our $SCHEMA_PATCH_TABLE_NAME => '__schema_patch';

const our $SQL_FILTER_OPERATOR => {
    '<'    => '<',
    '<='   => '<=',
    '='    => '=',
    '>='   => '>=',
    '>'    => '>',
    '!='   => '!=',
    'like' => 'LIKE',

    # TODO not yet supported
    # 'is null'     => 'IS NULL', # automatically use this operator, if value in undef
    # 'is not null' => 'IS NOT NULL',
    # 'in'          => 'IN',
    # 'notin'       => 'NOT IN',
    # 'not in'      => 'NOT IN',
};

# WHERE context:
# { field => value }
# { field => [ value ] }
# { field => [ operator, value ] }
#
# ORDER BY context
# [ [field1, 'ASC'], [field2, 'DESC'], ... ]
#
# VALUES context:
# { aa => 1, bb => 2 },
# [ { aa => 1, bb => 2 }, { aa => 3, bb => 4 } ],
# [ [ 1, 2 ], [ 3, 4 ] ],
# [ \['col1', 'col2'], { aa => 1, col2 => 2 }, { aa => 3, bb => 4 } ],
# [ \['col1', 'col2', 'col3'], [ 1, 2 ], [ 3, 4, 5 ], [6] ],
sub prepare_query ( $self, $query ) {
    state $context_re = do {
        my @keywords = ( 'SET', 'VALUES', 'WHERE', 'ORDER BY' );

        my $context_keywords_prepared = join q[|], sort { length $b <=> length $a } map {s/\s+/\\s+/smgr} @keywords;

        qr/(?:(?<=\A)|(?<=\s))(?:$context_keywords_prepared)(?=\s|\z)/smi;
    };

    my ( @sql, $bind, $i, $last_not_ref, $concat, $context );

    for my $arg ( $query->@* ) {
        if ( !is_ref $arg ) {
            if ( $arg eq '' ) {
                $concat = 1;

                next;
            }

            if ($concat) {
                $concat = 0;
            }
            else {
                die q[SQL query builder doesn't allow several consecutive non-ref argument] if $last_not_ref;
            }

            $last_not_ref = 1;

            # trim
            my $str = $arg =~ s/\A\s+|\s+\z//smgr;

            push @sql, $str;

            # analyse context
            if ( my $last_kw = ( $str =~ /$context_re/smgi )[-1] ) {
                $context = uc $last_kw =~ s/\s+/ /smgr;
            }
        }
        else {
            die q[SQL query builder doesn't allow to pass params after concat operator] if $concat;

            $last_not_ref = 0;

            if ( is_plain_scalarref $arg) {
                push @sql, '$' . ++$i;

                push $bind->@*, $arg->$*;
            }
            else {

                # SET context
                if ( $context eq 'SET' ) {
                    my @fields;

                    for my $field ( sort keys $arg->%* ) {
                        push @fields, $self->quote_id($field) . ' = $' . ++$i;

                        push $bind->@*, $arg->{$field};
                    }

                    push @sql, join q[, ], @fields;
                }

                # WHERE context
                elsif ( $context eq 'WHERE' ) {
                    if ( is_plain_hashref $arg) {
                        my @fields;

                        for my $field ( keys $arg->%* ) {
                            my ( $op, $val );

                            if ( !is_ref $arg->{$field} ) {
                                ( $op, $val ) = ( '=', $arg->{$field} );
                            }
                            elsif ( is_plain_arrayref $arg->{$field} ) {
                                if ( $arg->{$field}->@* == 1 ) {
                                    ( $op, $val ) = ( '=', $arg->{$field}->[0] );
                                }
                                else {
                                    ( $op, $val ) = $arg->{$field}->@*;
                                }
                            }
                            else {
                                die q[SQL field type is invalid];
                            }

                            die q[SQL operator is invalid] unless exists $SQL_FILTER_OPERATOR->{ lc $op };

                            push @fields, $self->quote_id($field) . q[ ] . $SQL_FILTER_OPERATOR->{ lc $op } . ' $' . ++$i;
                            push $bind->@*, $val;
                        }

                        push @sql, '(' . join( ' AND ', @fields ) . ')';
                    }
                    elsif ( is_plain_arrayref $arg) {
                        push @sql, '(' . join( ', ', map { '$' . ++$i } $arg->@* ) . ')';

                        push $bind->@*, $arg->@*;
                    }
                    else {
                        die q[SQL "WHERE" context support only HashRef or ArrayReh arguments];
                    }
                }

                # ORDER BY context
                elsif ( $context eq 'ORDER BY' ) {
                    if ( is_plain_arrayref $arg) {
                        my @fields;

                        state $SORT_ORDER = {
                            asc  => 'ASC',
                            desc => 'DESC',
                        };

                        for my $cond ( $arg->@* ) {
                            die q[SQL sort order is invalid] unless my $order = $SORT_ORDER->{ lc $cond->[1] };

                            push @fields, $self->quote_id( $cond->[0] ) . q[ ] . $order;
                        }

                        push @sql, join q[, ], @fields;
                    }
                    else {
                        die q[SQL "ORDER BY" context support only ArrayRef argument];
                    }
                }

                # VALUES context
                elsif ( $context eq 'VALUES' ) {
                    my ( $fields, $rows );

                    if ( is_plain_hashref $arg) {
                        $arg = [$arg];
                    }

                    my $is_first_row = 1;

                    for my $row ( $arg->@* ) {
                        if ($is_first_row) {
                            $is_first_row = 0;

                            # first argument is fields, must be \[]
                            if ( is_plain_refref $row ) {
                                $fields = $row->$*;

                                next;
                            }
                            elsif ( is_plain_hashref $row) {
                                $fields = [ sort keys $row->%* ];
                            }
                        }

                        if ( is_plain_hashref $row) {
                            die 'Fields names are not specified' if !defined $fields;

                            push $rows->@*, '(' . join( ', ', map { $self->quote( is_plain_arrayref $_ ? $_->@* : $_ ) } $row->@{ $fields->@* } ) . ')';
                        }

                        # TODO fill rest of columns with undef if number of columns is known
                        elsif ( is_plain_arrayref $row) {
                            push $rows->@*, '(' . join( ', ', map { $self->quote( is_plain_arrayref $_ ? $_->@* : $_ ) } $row->@* ) . ')';
                        }
                        else {
                            die 'Unsupported row format';
                        }
                    }

                    if ($fields) {
                        my $values_sql = '(' . join( ', ', map { $self->quote_id($_) } $fields->@* ) . ') VALUES';

                        $sql[-1] =~ s/VALUES.*\z/$values_sql/smi;
                    }

                    push @sql, join ', ', $rows->@*;
                }
                else {
                    die 'Unknown SQL context';
                }
            }
        }
    }

    return join( q[ ], @sql ), $bind;
}

# SCHEMA PATCH
sub add_schema_patch ( $self, $id, $query ) {
    die qq[Schema patch id "$id" already exists] if exists $self->{_schema_patch}->{$id};

    $self->{_schema_patch}->{$id} = {
        id    => $id,
        query => $query,
    };

    return;
}

sub upgrade_schema ( $self, $cb ) {
    my $on_finish = sub ( $dbh, $status ) {
        delete $self->{_schema_patch};

        if ($status) {
            $dbh->commit(
                sub ( $dbh, $status ) {
                    $cb->($status);

                    return;
                }
            );
        }
        else {
            if ( !$dbh ) {
                $cb->($status);
            }
            else {
                $dbh->rollback(
                    sub ( $dbh, $status1 ) {
                        $cb->($status);

                        return;
                    }
                );
            }
        }

        return;
    };

    # start transaction
    $self->begin_work(
        sub ( $dbh, $status ) {
            return $on_finish->( $dbh, $status ) if !$status;

            # create patch table
            $dbh->do(
                $self->_get_schema_patch_table_query($SCHEMA_PATCH_TABLE_NAME),
                sub ( $dbh, $status, $data ) {
                    return $on_finish->( $dbh, $status ) if !$status;

                    $self->_apply_patch(
                        $dbh,
                        sub ($status) {
                            return $on_finish->( $dbh, $status );
                        }
                    );
                }
            );

            return;
        }
    );

    return;
}

sub _apply_patch ( $self, $dbh, $cb ) {
    return $cb->( result 200 ) if !$self->{_schema_patch}->%*;

    my $id = ( sort keys $self->{_schema_patch}->%* )[0];

    my $patch = delete $self->{_schema_patch}->{$id};

    $dbh->selectrow(
        qq[SELECT "id" FROM "$SCHEMA_PATCH_TABLE_NAME" WHERE "id" = \$1],
        [ $patch->{id} ],
        sub ( $dbh, $status, $data ) {
            return $cb->($status) if !$status;

            # patch is already exists
            if ($data) {
                @_ = ( $self, $dbh, $cb );

                goto $self->can('_apply_patch');
            }

            # apply patch
            $dbh->do(
                $patch->{query},
                sub ( $dbh, $status, $data ) {
                    return $cb->( result [ 500, qq[Failed to apply schema patch "$id": $status->{reason}] ] ) if !$status;

                    # register patch
                    $dbh->do(
                        qq[INSERT INTO "$SCHEMA_PATCH_TABLE_NAME" ("id") VALUES (\$1)],
                        [ $patch->{id} ],
                        sub ( $dbh, $status, $data ) {
                            return $cb->( result [ 500, qq[Failed to register patch "$id": $status->{reason}] ] ) if !$status;

                            # patch registered successfully
                            @_ = ( $self, $dbh, $cb );

                            goto $self->can('_apply_patch');
                        }
                    );
                }
            );

            return;
        }
    );

    return;
}

# QUOTE
# https://www.postgresql.org/docs/current/static/sql-syntax-lexical.html
sub quote_id ( $self, $id ) {
    if ( index( $id, q[.] ) != -1 ) {
        my @id = split /[.]/sm, $id;

        for my $s (@id) {
            $s =~ s/"/""/smg;

            $s = qq["$s"];
        }

        return join q[.], @id;
    }
    else {
        $id =~ s/"/""/smg;

        return qq["$id"];
    }
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 49                   | Subroutines::ProhibitExcessComplexity - Subroutine "prepare_query" with high complexity score (44)             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 117, 120, 124, 163,  | ControlStructures::ProhibitDeepNests - Code structure is deeply nested                                         |
## |      | 187, 191, 201        |                                                                                                                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 62                   | ValuesAndExpressions::ProhibitEmptyQuotes - Quotes used with a string containing no non-whitespace characters  |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 53                   | BuiltinFunctions::ProhibitReverseSortBlock - Forbid $b before $a in sort blocks                                |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Handle::DBI

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
