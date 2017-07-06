package Pcore::Handle::DBI;

use Pcore -role, -const, -result;

use Pcore::Util::Scalar qw[is_ref is_plain_scalarref is_plain_hashref is_plain_arrayref is_plain_refref];
use Pcore::Handle::DBI::STH;

with qw[Pcore::Handle];

requires qw[_get_schema_patch_table_query prepare quote quote_id];

has on_connect => ( is => 'ro', isa => Maybe [CodeRef] );

has _schema_patch => ( is => 'ro', isa => HashRef, init_arg => undef );

const our $SCHEMA_PATCH_TABLE_NAME => '__schema_patch';

# VALUES context:
# { aa => 1, bb => 2 },
# [ { aa => 1, bb => 2 }, { aa => 3, bb => 4 } ],
# [ [ 1, 2 ], [ 3, 4 ] ],
# [ \['col1', 'col2'], { aa => 1, col2 => 2 }, { aa => 3, bb => 4 } ],
# [ \['col1', 'col2', 'col3'], [ 1, 2 ], [ 3, 4, 5 ], [6] ],
sub prepare_query ( $self, $query ) {
    state $context_re = do {
        my @keywords = qw[SET VALUES WHERE];

        my $context_keywords_prepared = join q[|], sort { length $b <=> length $a } map {s/\s+/\\s+/smgr} @keywords;

        qr/(?:(?<=\A)|(?<=\s))(?:$context_keywords_prepared)(?=\s|\z)/smi;
    };

    my ( @sql, $bind, $i, $last_not_ref, $context );

    for my $arg ( $query->@* ) {
        if ( !is_ref $arg ) {
            die q[SQL query builder doesn't allow several consecutive non-ref argument] if $last_not_ref;

            $last_not_ref = 1;

            # trim
            push @sql, $arg =~ s/\A\s+|\s+\z//smgr;

            # analyse context
            if ( my $last_kw = ( $arg =~ /$context_re/smgi )[-1] ) {
                $context = uc $last_kw =~ s/\s+/ /smgr;
            }
        }
        else {
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
                            push @fields, $self->quote_id($field) . ' = $' . ++$i;

                            push $bind->@*, $arg->{$field};
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
    my $on_finish = sub ( $status, $dbh ) {
        delete $self->{_schema_patch};

        if ($status) {
            $dbh->commit(
                sub ( $status, $dbh ) {
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
                    sub ( $status1, $dbh ) {
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
        sub ( $status, $dbh ) {
            return $on_finish->( $status, $dbh ) if !$status;

            # create patch table
            $dbh->do(
                $self->_get_schema_patch_table_query($SCHEMA_PATCH_TABLE_NAME),
                sub ( $status, $dbh, $data ) {
                    return $on_finish->( $status, $dbh ) if !$status;

                    $self->_apply_patch(
                        $dbh,
                        sub ($status) {
                            return $on_finish->( $status, $dbh );
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
        sub ( $status, $dbh, $data ) {
            return $cb->($status) if !$status;

            # patch is already exists
            if ($data) {
                @_ = ( $self, $dbh, $cb );

                goto $self->can('_apply_patch');
            }

            # apply patch
            $dbh->do(
                $patch->{query},
                sub ( $status, $dbh, $data ) {
                    return $cb->( result [ 500, qq[Failed to apply schema patch "$id": $status->{reason}] ] ) if !$status;

                    # register patch
                    $dbh->do(
                        qq[INSERT INTO "$SCHEMA_PATCH_TABLE_NAME" ("id") VALUES (\$1)],
                        [ $patch->{id} ],
                        sub ( $status, $dbh, $data ) {
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

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 24                   | Subroutines::ProhibitExcessComplexity - Subroutine "prepare_query" with high complexity score (29)             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 77, 106, 110, 120    | ControlStructures::ProhibitDeepNests - Code structure is deeply nested                                         |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 28                   | BuiltinFunctions::ProhibitReverseSortBlock - Forbid $b before $a in sort blocks                                |
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
