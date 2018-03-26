package Pcore::Handle::DBI;

use Pcore -role, -const, -result;
use Pcore::Handle::DBI::STH;
use Pcore::Util::Scalar qw[is_ref is_plain_scalarref is_blessed_arrayref is_blessed_hashref];

with qw[Pcore::Handle];

requires qw[_get_schema_patch_table_query prepare quote];

has on_connect => ( is => 'ro', isa => Maybe [CodeRef] );

has _schema_patch => ( is => 'ro', isa => HashRef, init_arg => undef );

const our $SCHEMA_PATCH_TABLE_NAME => '__schema_patch';

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

# QUERY BUILDER
sub prepare_query ( $self, $query ) {
    my ( @sql, @bind );

    my $i = 1;

    for my $token ( $query->@* ) {

        # skip undefined values
        next if !defined $token;

        # Scalar value is processed as SQL
        if ( !is_ref $token) {
            push @sql, $token;
        }

        # ScalarRef value is processed as parameter
        elsif ( is_plain_scalarref $token ) {
            push @sql, '$' . $i++;

            push @bind, $token->$*;
        }

        # blessed ArrayRef value is processed as parameter with type
        elsif ( is_blessed_arrayref $token ) {
            push @sql, '$' . $i++;

            push @bind, $token;
        }

        # Object value
        elsif ( is_blessed_hashref $token) {
            my ( $sql, $bind ) = $token->get_query( $self, 1, \$i );

            if ( defined $sql ) {
                push @sql, $sql;

                push @bind, $bind->@* if defined $bind;
            }
        }
        else {
            die 'Unsupported ref type';
        }
    }

    return join( q[ ], @sql ), @bind ? \@bind : undef;
}

1;
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
