package Pcore::DBH::DBI;

use Pcore -role;

has _dbh => ( is => 'ro', isa => InstanceOf ['DBI::db'], init_arg => undef );

has async => ( is => 'ro', isa => Bool, default => 0, init_arg => undef );

# DBI
sub _execute {
    my ( $self, $on_finish, $query ) = splice @_, 0, 3, ();
    my $bind = ref $_[0] eq 'ARRAY' ? shift : undef;
    my $cb   = ref $_[-1] eq 'CODE' ? pop   : undef;
    my %args = (
        cache => undef,
        @_,
        cb => $cb,
    );

    my $exec = sub ( $dbh, $async ) {

        # prepare query
        my $query_ref = ref $query;

        if ( !$query_ref ) {
            $args{cache} //= 0;
        }
        elsif ( $query_ref eq 'ARRAY' ) {
            $args{cache} //= 0;

            $query = $self->query( $query->@* );

            $bind //= $query->bind;
        }
        elsif ( $query_ref eq 'DBI::st' ) {
            $args{cache} //= 0;
        }
        else {

            # query object
            if ( !$bind && $query->bind->@* ) {

                # do not cache query by default, when query bind params are used
                $args{cache} //= 0;

                $bind = $query->bind;
            }
            else {
                $args{cache} //= 1;
            }
        }

        if ($async) {
            $dbh->execute_async( $query, $bind, \%args, $on_finish );

            return;
        }
        else {
            my $sth;

            # prepare sth
            if ( $args{cache} ) {
                if ( $query_ref eq 'DBI::st' ) {
                    $sth = $dbh->{_dbh}->prepare_cached( $query->{Statement} );
                }
                else {
                    $sth = $dbh->{_dbh}->prepare_cached("$query");
                }
            }
            else {
                if ( $query_ref eq 'DBI::st' ) {

                    # prepare sth again ONLY if driver support async queries, because we don't know, is sth was prepared for async or not?
                    $sth = $dbh->{_dbh}->prepare( $query->{Statement} ) if $dbh->{async};
                }
                else {
                    $sth = $dbh->{_dbh}->prepare("$query");
                }
            }

            my $rows = $sth->execute( $bind ? $bind->@* : () ) or die $sth->errstr;

            return $on_finish->( \%args, $rows, $sth );
        }
    };

    # called from connection
    if ( !$self->does('Pcore::DBH') ) {
        return $exec->( $self, $self->{async} && !defined wantarray );
    }

    # called from handle
    else {

        # handle is async (pgsql)
        if ( $self->{async} ) {
            if ( defined wantarray ) {
                die q[Invalid usage, can't execute query synchronously via async connection];
            }

            # get connection
            else {
                $self->dbh(
                    sub ($dbh) {
                        $exec->( $dbh, 1 );

                        return;
                    }
                );

                return;
            }
        }

        # handle is not async (sqlite)
        else {
            return $exec->( $self, 0 );
        }
    }
}

sub prepare {
    my $self = shift;

    return $self->{_dbh}->prepare(@_);
}

# this is slower, than selectall_arrayref
sub selectall {
    my $self = shift;

    # accepted args:
    # slice    => undef,
    # max_rows => undef,
    my $on_finish = sub ( $args, $exec_res, $sth ) {
        my $res;

        my $slice = $args->{slice} // {};

        $res = $sth->fetchall_arrayref( $slice, $args->{max_rows} );

        $sth->finish if defined $args->{max_rows};

        $args->{cb}->( $res->@* ? $res : undef ) if $args->{cb};

        return $res->@* ? $res : ();
    };

    return $self->_execute( $on_finish, @_ );
}

# this is faster, than selectall
sub selectall_arrayref {
    my $self = shift;

    # accepted args:
    # slice    => undef,
    # cols     => undef, same as slice => [0,1]
    # max_rows => undef,
    #
    # if slice is ArrayRef - return ArrayRef[ArrayRef] with columns, specified in slice by 0-based indexes, eg: [0, 1, -1, -2]
    # if slice is HashRef - return ArrayRef[HashRef] with only columns, specified in slice HashRef, if slice is empty HashRef - returns all columns, eg: {col1 => 1, col2 => 1}
    # if slice is \HashRef - return ArrayRef[HashRef] with only columns, specifies be theirs 0-based indexes, eg: \{0 => 'col1', -5 => 'col2'}

    my $on_finish = sub ( $args, $exec_res, $sth ) {
        my $res;

        $res = $sth->fetchall_arrayref( $args->{slice} // $args->{cols}, $args->{max_rows} );

        $sth->finish if defined $args->{max_rows};

        $args->{cb}->( $res->@* ? $res : undef ) if $args->{cb};

        return $res->@* ? $res : ();
    };

    return $self->_execute( $on_finish, @_ );
}

sub selectall_hashref {
    my $self = shift;

    # accepted args:
    # key_cols => 0,    # ex: 1, 'col1', [1, 2, 5], ['col1', 'col5'], index is 0-based

    my $on_finish = sub ( $args, $exec_res, $sth ) {
        my $rows;

        $args->{key_cols} //= 0;

        my @key_cols = ref $args->{key_cols} ? $args->{key_cols}->@* : ( $args->{key_cols} );

        # make cols indexes 1-based
        for (@key_cols) {
            $_++ if DBI::looks_like_number($_);
        }

        $rows = $sth->fetchall_hashref( \@key_cols );

        $args->{cb}->( $rows->%* ? $rows : undef ) if $args->{cb};

        return $rows->%* ? $rows : ();
    };

    return $self->_execute( $on_finish, @_ );
}

# alias for selectrow_hashref
sub selectrow {
    my $self = shift;

    return $self->selectrow_hashref(@_);
}

sub selectrow_hashref {
    my $self = shift;

    my $on_finish = sub ( $args, $exec_res, $sth ) {
        my $row = $sth->fetchrow_hashref and $sth->finish;

        $args->{cb}->($row) if $args->{cb};

        return $row;
    };

    return $self->_execute( $on_finish, @_ );
}

sub selectrow_arrayref {
    my $self = shift;

    my $on_finish = sub ( $args, $exec_res, $sth ) {
        my $row = $sth->fetchrow_arrayref and $sth->finish;

        $args->{cb}->($row) if $args->{cb};

        return $row;
    };

    return $self->_execute( $on_finish, @_ );
}

# alias for selectcol_arrayref
sub selectcol {
    my $self = shift;

    return $self->selectcol_arrayref(@_);
}

sub selectcol_arrayref {
    my $self = shift;

    # accepted args:
    # cols     => undef,    # required columns indexes, index is 0-based, ex: 5, [0, 2, 5]
    # max_rows => undef,    # specify max. rows to proceed

    my $on_finish = sub ( $args, $exec_res, $sth ) {
        my @cols;

        $args->{cols} //= [0];

        $args->{cols} = [ $args->{cols} ] if !ref $args->{cols};

        my @values = (undef) x $args->{cols}->@*;

        my $idx = 0;

        for ( $args->{cols}->@* ) {
            $sth->bind_col( $_ + 1, \$values[ $idx++ ] ) || die;
        }

        if ( my $max = $args->{max_rows} ) {
            push @cols, @values while 0 < $max-- && $sth->fetch;
        }
        else {
            push @cols, @values while $sth->fetch;
        }

        $args->{cb}->( @cols ? \@cols : undef ) if $args->{cb};

        return @cols ? \@cols : ();
    };

    return $self->_execute( $on_finish, @_ );
}

sub selectval {
    my $self = shift;

    # accepted args:
    # col     => 0,    # ex: 1, 'col1', index is 0-based

    my $on_finish = sub ( $args, $exec_res, $sth ) {
        my $val;

        $args->{col} //= 0;

        if ( DBI::looks_like_number( $args->{col} ) ) {
            if ( my $row = $sth->fetchrow_arrayref and $sth->finish ) {
                die qq[Invalid column index "$args->{col}" for slice] if $args->{col} >= $row->@*;

                $val = \$row->[ $args->{col} ];
            }
        }
        else {
            my $name2idx = $sth->FETCH('NAME_lc_hash');

            my $idx = $name2idx->{ lc $args->{col} };

            die qq[Invalid column name "$args->{col}" for slice] if not defined $idx;

            if ( my $row = $sth->fetchrow_arrayref and $sth->finish ) {
                $val = \$row->[$idx];
            }
        }

        $args->{cb}->($val) if $args->{cb};

        return $val;
    };

    return $self->_execute( $on_finish, @_ );
}

# TODO sth caching is not supported for multiple queries
# add workaround for queries, that contains multiply queries
# see DBD::SQLite do implementation
sub do {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    my $self = shift;

    my $on_finish = sub ( $args, $exec_res, $sth ) {
        my $rows = $sth->rows;

        $args->{cb}->($rows) if $args->{cb};

        return $rows;
    };

    return $self->_execute( $on_finish, @_ );
}

# TRANSACTIONS
sub begin_work ($self) {
    return $self->{_dbh}->begin_work;
}

sub commit ($self) {
    return $self->{_dbh}->commit;
}

sub rollback ($self) {
    return $self->{_dbh}->rollback;
}

sub last_insert_id ( $self, @ ) {
    my %args = (
        catalog => undef,
        schema  => undef,
        table   => undef,
        field   => undef,
        attr    => undef,
        splice @_, 1,
    );

    return $self->{_dbh}->last_insert_id( $args{catalog}, $args{schema}, $args{table}, $args{field}, $args{attr} );
}

# QUOTE
sub quote ( $self, @ ) {
    return $self->{_dbh}->quote( splice @_, 1 );
}

sub quote_id ( $self, @ ) {
    if ( scalar @_ == 2 ) {
        my $res = $self->{_dbh}->quote_identifier( split /[.]/sm, $_[1] );

        $res =~ s/["`'][*]["`']/*/smg;    # unquote *

        return $res;
    }
    else {
        return $self->{_dbh}->quote_identifier( splice @_, 1 );
    }
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 10                   | Subroutines::ProhibitExcessComplexity - Subroutine "_execute" with high complexity score (28)                  |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 273, 276             | ControlStructures::ProhibitPostfixControls - Postfix control "while" used                                      |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::DBH::DBI

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
