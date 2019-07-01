package Pcore::Handle::sqlite;

use Pcore -class, -const, -res;
use DBI qw[];
use Pcore::Handle::DBI::Const qw[:CONST];
use DBD::SQLite qw[];
use DBD::SQLite::Constants qw[:file_open];
use Pcore::Util::Scalar qw[weaken is_blessed_ref looks_like_number is_plain_arrayref is_plain_coderef is_blessed_arrayref];
use Pcore::Util::UUID qw[uuid_v1mc_str uuid_v4_str];
use Pcore::Util::Data qw[to_json];
use Pcore::Util::Text qw[encode_utf8];
use Time::HiRes qw[];

# NOTE http://habrahabr.ru/post/149635/
# для вставки данных в цикле надо использовать h->begin_work ... h->commit

with qw[Pcore::Handle::DBI];

const our $SQLITE_OPEN_RO  => SQLITE_OPEN_READONLY | SQLITE_OPEN_SHAREDCACHE;
const our $SQLITE_OPEN_RW  => SQLITE_OPEN_READWRITE | SQLITE_OPEN_SHAREDCACHE;
const our $SQLITE_OPEN_RWC => SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_SHAREDCACHE;

const our $SQLITE_OPEN => {
    ro  => $SQLITE_OPEN_RO,
    rw  => $SQLITE_OPEN_RW,
    rwc => $SQLITE_OPEN_RWC,
};

has mode         => 'rwc';        # Enum [ keys $SQLITE_OPEN->%* ]
has busy_timeout => 1_000 * 3;    # PositiveOrZeroInt ), milliseconds, set to 0 to disable timeout, default - 3 seconds

# SQLITE PRAGMAS
has temp_store   => 'MEMORY';      # Enum [qw[FILE MEMORY]]
has journal_mode => 'WAL';         # Enum [qw[DELETE TRUNCATE PERSIST MEMORY WAL OFF]], WAL is the best
has synchronous  => 'OFF';         # Enum [qw[FULL NORMAL OFF]], OFF - data integrity on app failure, NORMAL - data integrity on app and OS failures, FULL - full data integrity on app or OS failures, slower
has cache_size   => -1_048_576;    # Int, 0+ - pages,  -kilobytes, default 1G
has foreign_keys => 1;             # Bool

has is_sqlite    => ( 1, init_arg => undef );    # Bool
has h            => ( init_arg    => undef );    # Object
has prepared_sth => ( init_arg    => undef );    # HashRef
has query        => ( init_arg    => undef );    # ScalarRef, ref to the last query

# SQLite types
const our $SQLITE_UNKNOWN => 0;
const our $SQLITE_INTEGER => 4;
const our $SQLITE_REAL    => 6;
const our $SQLITE_TEXT    => 12;
const our $SQLITE_BLOB    => 30;

# postgreSQL types to SQLite
const our $TYPE_TO_SQLITE => {
    $SQL_BOOL    => $SQLITE_INTEGER,
    $SQL_BYTEA   => $SQLITE_BLOB,
    $SQL_CHAR    => $SQLITE_TEXT,
    $SQL_FLOAT4  => $SQLITE_REAL,
    $SQL_FLOAT8  => $SQLITE_REAL,
    $SQL_JSON    => $SQLITE_BLOB,
    $SQL_INT2    => $SQLITE_INTEGER,
    $SQL_INT4    => $SQLITE_INTEGER,
    $SQL_INT8    => $SQLITE_INTEGER,
    $SQL_MONEY   => $SQLITE_REAL,
    $SQL_NUMERIC => $SQLITE_REAL,
    $SQL_TEXT    => $SQLITE_TEXT,
    $SQL_UNKNOWN => $SQLITE_UNKNOWN,
    $SQL_UUID    => $SQLITE_BLOB,
    $SQL_VARCHAR => $SQLITE_TEXT,
};

sub BUILD ( $self, $args ) {
    my $attr = {
        AutoCommit                       => 1,
        sqlite_open_flags                => $SQLITE_OPEN->{ $self->{mode} },
        sqlite_unicode                   => 1,
        sqlite_allow_multiple_statements => 1,
        sqlite_use_immediate_transaction => 1,
        sqlite_see_if_its_a_number       => 1,

        Warn               => 1,
        PrintWarn          => 0,
        PrintError         => 0,
        RaiseError         => 0,
        ShowErrorStatement => 1,

        # HandleError => sub {
        #     my $msg = shift;
        #
        #     # escape_perl $msg;
        #
        #     P->sendlog( 'Pcore-DBH.ERROR', $msg );
        #
        #     return;
        # },
        # Callbacks          => {
        #     connected => sub {
        #         P->sendlog( 'Pcore-DBH.DEBUG', 'Connected to: ' . $_[1] ) if $ENV{PCORE_DBH_DEBUG};
        #
        #         return;
        #     },
        #     prepare => sub {
        #         return;
        #     },
        #     do => sub {
        #         P->sendlog( 'Pcore-DBH.DEBUG', 'Do: ' . $_[1] ) if $ENV{PCORE_DBH_DEBUG};
        #
        #         return;
        #     },
        #     ChildCallbacks => {
        #         execute => sub {
        #             P->sendlog( 'Pcore-DBH.DEBUG', 'Execute: ' . $_[0]->{Statement} ) if $ENV{PCORE_DBH_DEBUG};
        #
        #             return;
        #         }
        #     }
        # },
    };

    my $dbname = $self->{uri}->{path} ? $self->{uri}->{path}->to_string : ':memory:';

    my $dbh = DBI->connect( "dbi:SQLite:dbname=$dbname", $EMPTY, $EMPTY, $attr );

    $dbh->do('PRAGMA encoding = "UTF-8"');
    $dbh->do( 'PRAGMA temp_store = ' . $self->{temp_store} );
    $dbh->do( 'PRAGMA journal_mode = ' . $self->{journal_mode} );
    $dbh->do( 'PRAGMA synchronous = ' . $self->{synchronous} );
    $dbh->do( 'PRAGMA cache_size = ' . $self->{cache_size} );
    $dbh->do( 'PRAGMA foreign_keys = ' . $self->{foreign_keys} );

    $dbh->sqlite_busy_timeout( $self->{busy_timeout} );

    # create custom functions
    $dbh->sqlite_create_function( 'uuid_generate_v1mc', 0, sub { return uuid_v1mc_str } );
    $dbh->sqlite_create_function( 'uuid_generate_v4',   0, sub { return uuid_v4_str } );
    $dbh->sqlite_create_function( 'gen_random_uuid',    0, sub { return uuid_v4_str } );
    $dbh->sqlite_create_function( 'time_hires',         0, sub { return Time::HiRes::time() } );

    $self->{on_connect}->($self) if $self->{on_connect};

    $self->{h} = $dbh;

    return;
}

# SCHEMA PATCH
sub _get_schema_patch_table_query ( $self, $table_name ) {
    return <<"SQL";
        CREATE TABLE IF NOT EXISTS "$table_name" (
            "module" TEXT NOT NULL,
            "id" INTEGER NOT NULL,
            "timestamp" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY ("module", "id")
        )
SQL
}

# QUOTE
sub _get_sqlite_type : prototype($) ($type) {

    # use TEXT as default type
    if ( !defined $type || !exists $TYPE_TO_SQLITE->{$type} ) {
        $type = $SQLITE_TEXT;
    }
    else {
        $type = $TYPE_TO_SQLITE->{$type};
    }

    return $type;
}

sub quote ( $self, $var ) {
    return 'NULL' if !defined $var;

    my $type;

    if ( is_blessed_arrayref $var) {
        return 'NULL' if !defined $var->[1];

        $type = _get_sqlite_type( $var->[0] );

        if ( $var->[0] == $SQL_BOOL ) {
            $var = $var->[1] ? 1 : 0;
        }
        elsif ( $var->[0] == $SQL_JSON ) {
            $var = to_json $var->[1];
        }
        else {
            $var = $var->[1];
        }
    }
    else {

        # transparently encode arrays to JSON
        if ( is_plain_arrayref $var) {
            $type = $SQLITE_BLOB;

            $var = to_json $var;
        }
        else {
            $type = $SQLITE_TEXT;
        }
    }

    # NUMBER
    if ( ( $type == $SQLITE_INTEGER || $type == $SQLITE_REAL ) && looks_like_number $var) {
        return $var;
    }

    # BLOB
    elsif ( $type == $SQLITE_BLOB ) {
        utf8::encode $var if utf8::is_utf8 $var;

        $var = q[x'] . unpack( 'H*', $var ) . q['];

        return $var;
    }

    # TEXT, default
    # a string constant is formed by enclosing the string in single quotes (')
    # a single quote within the string can be encoded by putting two single quotes in a row
    else {

        # quote \x00 in literal
        if ( index( $var, "\x00" ) != -1 ) {
            utf8::encode $var if utf8::is_utf8 $var;

            return q[CAST(x'] . unpack( 'H*', $var ) . q[' AS TEXT)];
        }
        else {
            $var =~ s/'/''/smg;

            return qq['$var'];
        }
    }
}

# https://sqlite.org/lang_keywords.html
sub quote_id ( $self, $id ) {
    utf8::encode $id if utf8::is_utf8 $id;

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

sub _exec_sth ( $self, $query, @args ) {

    # parse args
    my $bind = is_plain_arrayref $args[0] ? shift @args : undef;
    my $cb   = is_plain_coderef $args[-1] ? pop @args   : undef;
    my %args = @args;

    my ( $dbh, $sth, $rows ) = $self->{h};

    # query is prepared sth
    if ( ref $query eq 'DBI::st' ) {
        $sth = $query;
    }

    # query is sth
    elsif ( ref $query eq 'Pcore::Handle::DBI::STH' ) {
        $sth = $self->{prepared_sth}->{ $query->{id} };

        if ( !defined $sth ) {
            $self->{query} = \$query->{query};

            $sth = $dbh->prepare( $query->{query} );

            return $rows, $sth, \%args, $cb if defined $DBI::err;

            $self->{prepared_sth}->{ $query->{id} } = $sth;

            push $query->{dbh}->@*, $self;

            weaken $query->{dbh}->[-1];
        }
    }

    # query is ArrayRef
    elsif ( is_plain_arrayref $query) {
        ( $query, $bind ) = $self->prepare_query($query);
    }

    # prepare sth
    if ( !defined $sth ) {
        $self->{query} = \$query;

        $sth = $dbh->prepare($query);

        return $rows, $sth, \%args, $cb if defined $DBI::err;
    }

    if ( defined $bind ) {

        # bind and exec
        $rows = $self->_execute( $sth, $bind, 0 );
    }
    else {
        $rows = $sth->execute;
    }

    if ( defined $DBI::err ) {
        return $rows, $sth, \%args, $cb;
    }
    else {
        $rows = 0 if $rows == 0;    # convert "0E0" to "0"

        return $rows, $sth, \%args, $cb;
    }
}

sub _warn ($self) {
    warn qq[DBI: "$DBI::errstr"] . ( defined $self->{query} ? qq[, current query: "$self->{query}->$*"] : $EMPTY );

    return;
}

sub _execute ( $self, $sth, $bind, $bind_pos ) {

    # make a copy
    my @bind = $bind->@[ $bind_pos .. $bind_pos + $sth->{NUM_OF_PARAMS} - 1 ];

    $bind_pos += $sth->{NUM_OF_PARAMS};

    # bind types
    for ( my $i = 0; $i <= $#bind; $i++ ) {
        if ( is_blessed_arrayref $bind[$i] ) {
            $sth->bind_param( $i + 1, undef, _get_sqlite_type $bind[$i]->[0] );

            # values is not defined
            if ( !defined $bind[$i]->[1] ) {
                $bind[$i] = undef;
            }
            elsif ( $bind[$i]->[0] == $SQL_BOOL ) {
                $bind[$i] = $bind[$i]->[1] ? 1 : 0;
            }
            elsif ( $bind[$i]->[0] == $SQL_JSON ) {
                $bind[$i] = to_json $bind[$i]->[1];
            }
            elsif ( $bind[$i]->[0] == $SQL_BYTEA ) {
                $bind[$i] = encode_utf8 $bind[$i]->[1];
            }
            else {
                $bind[$i] = $bind[$i]->[1];
            }
        }

        # encode ArrayRef as JSON
        elsif ( is_plain_arrayref $bind[$i] ) {
            $sth->bind_param( $i + 1, undef, $SQLITE_BLOB );

            $bind[$i] = to_json $bind[$i];
        }
    }

    return $sth->execute(@bind);
}

sub get_dbh ( $self, $cb = undef ) {
    return $cb ? $cb->( res(200), $self ) : ( res(200), $self );
}

# PUBLIC DBI METHODS
sub do ( $self, $query, @args ) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]

    # parse args
    my $bind = is_plain_arrayref $args[0] ? shift @args : undef;
    my $cb   = is_plain_coderef $args[-1] ? pop @args   : undef;
    my %args = @args;

    my ( $dbh, $rows, $res ) = $self->{h};

    # query is sth
    if ( is_blessed_ref $query) {
        my $sth;

        if ( ref $query eq 'Pcore::Handle::DBI::STH' ) {
            $sth = $self->{prepared_sth}->{ $query->{id} };

            if ( !defined $sth ) {
                $self->{query} = \$query->{query};

                # prepare sth
                $sth = $dbh->prepare( $query->{query} );

                # check error
                if ( defined $DBI::err ) {
                    $self->_warn;

                    $res = res [ 500, $DBI::errstr ];
                }

                $self->{prepared_sth}->{ $query->{id} } = $sth;

                push $query->{dbh}->@*, $self;

                weaken $query->{dbh}->[-1];
            }
        }
        elsif ( ref $query eq 'DBI::st' ) {
            $sth = $query;
        }
        else {
            warn 'Invalid STH class';

            $res = res [ 400, 'Invalid STH class' ];
        }

        # bind and exec
        if ( !defined $res ) {
            if ( defined $bind ) {
                $rows = $self->_execute( $sth, $bind, 0 );
            }
            else {
                $rows = $sth->execute;
            }

            # check error
            if ( defined $DBI::err ) {
                $self->_warn;

                $res = res [ 500, $DBI::errstr ];
            }
        }

        # success
        if ( !defined $res ) {
            $rows = 0 if $rows == 0;    # convert "0E0" to "0"

            $res = res 200, rows => $rows;
        }

        return $cb ? $cb->($res) : $res;
    }

    # query is ArrayRef
    elsif ( is_plain_arrayref $query) {
        ( $query, $bind ) = $self->prepare_query($query);
    }

    # simple query mode
    # execute query directly without prepare and bind params
    # multiple queries in single statement are allowed
    if ( !defined $bind ) {
        $self->{query} = \$query;

        $rows = DBD::SQLite::db::_do( $dbh, $query );

        # check error
        if ( defined $DBI::err ) {
            $self->_warn;

            $res = res [ 500, $DBI::errstr ];
        }
        else {
            $rows = 0 if $rows == 0;    # convert "0E0" to "0"

            $res = res 200, rows => $rows;
        }

        return $cb ? $cb->($res) : $res;
    }

    # extended query mode
    # multiple queries in single statement are allowed
    else {
        my $bind_pos = 0;

        while ($query) {
            $self->{query} = \$query;

            # prepare sth
            my $sth = $dbh->prepare($query);

            # prepare sth error
            if ( defined $DBI::err ) {
                $self->_warn;

                $res = res [ 500, $DBI::errstr ];

                last;
            }

            # bind and exec
            $self->_execute( $sth, $bind, $bind_pos );

            # execute error
            if ( defined $DBI::err ) {
                $self->_warn;

                $res = res [ 500, $DBI::errstr ];

                last;
            }

            $rows += $sth->rows;

            $query = $sth->{sqlite_unprepared_statements};
        }

        $res = res 200, rows => $rows if !defined $res;

        return $cb ? $cb->($res) : $res;
    }
}

# key_col => [0, 1, 'id'], key_col => 'id'
sub selectall ( $self, @ ) {
    my ( $rows, $sth, $args, $cb ) = &_exec_sth;    ## no critic qw[Subroutines::ProhibitAmpersandSigils]

    my $res;

    # check error
    if ( defined $DBI::err ) {
        $self->_warn;

        $res = res [ 500, $DBI::errstr ];
    }
    else {
        my $data;

        if ( defined $args->{key_col} ) {

            # make fields indexes 0-based
            my @key_cols = map { looks_like_number $_ ? $_ + 1 : $_ } is_plain_arrayref $args->{key_col} ? $args->{key_col}->@* : $args->{key_col};

            $data = $sth->fetchall_hashref( \@key_cols );

            # check error
            if ( defined $DBI::err ) {
                $self->_warn;

                $res = res [ 500, $DBI::errstr ];
            }
            else {
                $res = res 200, $data, rows => $rows;
            }
        }
        else {
            $res = res 200, $sth->fetchall_arrayref( {}, undef ), rows => $rows;
        }
    }

    return $cb ? $cb->($res) : $res;
}

sub selectall_arrayref ( $self, @ ) {
    my ( $rows, $sth, $args, $cb ) = &_exec_sth;    ## no critic qw[Subroutines::ProhibitAmpersandSigils]

    my $res;

    # check error
    if ( defined $DBI::err ) {
        $self->_warn;

        $res = res [ 500, $DBI::errstr ];
    }
    else {
        $res = res 200, $sth->fetchall_arrayref( undef, undef ), rows => $rows;
    }

    return $cb ? $cb->($res) : $res;
}

sub selectrow ( $self, @ ) {
    my ( $rows, $sth, $args, $cb ) = &_exec_sth;    ## no critic qw[Subroutines::ProhibitAmpersandSigils]

    my $res;

    # check error
    if ( defined $DBI::err ) {
        $self->_warn;

        $res = res [ 500, $DBI::errstr ];
    }
    else {
        $res = res 200, $sth->fetchrow_hashref, rows => $rows;

        $sth->finish;
    }

    return $cb ? $cb->($res) : $res;
}

sub selectrow_arrayref ( $self, @ ) {
    my ( $rows, $sth, $args, $cb ) = &_exec_sth;    ## no critic qw[Subroutines::ProhibitAmpersandSigils]

    my $res;

    # check error
    if ( defined $DBI::err ) {
        $self->_warn;

        $res = res [ 500, $DBI::errstr ];
    }
    else {
        $res = res 200, $sth->fetchrow_arrayref, rows => $rows;

        $sth->finish;
    }

    return $cb ? $cb->($res) : $res;
}

# col => [0, 'id'], col => 'id', default col => 0
sub selectcol ( $self, @ ) {
    my ( $rows, $sth, $args, $cb ) = &_exec_sth;    ## no critic qw[Subroutines::ProhibitAmpersandSigils]

    my $res;

    # check error
    if ( defined $DBI::err ) {
        $self->_warn;

        $res = res [ 500, $DBI::errstr ];
    }
    else {
        my ( $name2idx, $idx, @vals );

        my $num_of_fields = $sth->{NUM_OF_FIELDS} - 1;

        $args->{col} //= 0;

        for my $col ( is_plain_arrayref $args->{col} ? $args->{col}->@* : $args->{col} ) {
            if ( looks_like_number $col) {
                if ( $col > $num_of_fields ) {
                    warn qq[Invalid column index: "$col"];

                    $res = res [ 400, qq[Invalid column index: "$col"] ];

                    last;
                }

                $sth->bind_col( $col + 1, \$vals[ $idx++ ] );
            }
            else {
                $name2idx //= $sth->{NAME_hash};

                if ( !exists $name2idx->{$col} ) {
                    warn qq[Invalid column name: "$col"];

                    $res = res [ 400, qq[Invalid column name: "$col"] ];

                    last;
                }

                $sth->bind_col( $name2idx->{$col} + 1, \$vals[ $idx++ ] );
            }
        }

        if ( !defined $res ) {
            my $data;

            push $data->@*, @vals while $sth->fetch;

            $res = res 200, $data, rows => $rows;
        }
    }

    return $cb ? $cb->($res) : $res;
}

# TRANSACTIONS
sub begin_work ( $self, $cb = undef ) {
    $self->{h}->begin_work;

    my $res;

    # check error
    if ( defined $DBI::err ) {
        $self->_warn;

        $res = res [ 500, $DBI::errstr ];
    }
    else {
        $res = res 200;
    }

    return $cb ? $cb->($res) : $res;
}

sub commit ( $self, $cb = undef ) {
    $self->{h}->commit;

    my $res;

    # check error
    if ( defined $DBI::err ) {
        $self->_warn;

        $res = res [ 500, $DBI::errstr ];
    }
    else {
        $res = res 200;
    }

    return $cb ? $cb->($res) : $res;
}

sub rollback ( $self, $cb = undef ) {
    $self->{h}->rollback;

    my $res;

    # check error
    if ( defined $DBI::err ) {
        $self->_warn;

        $res = res [ 500, $DBI::errstr ];
    }
    else {
        $res = res 200;
    }

    return $cb ? $cb->($res) : $res;
}

# LAST INSERT ID
sub last_insert_id ( $self ) {
    return $self->{h}->sqlite_last_insert_rowid;
}

# ATTACH
sub attach ( $self, $name, $path = undef ) {
    $path //= ':memory:';

    $self->{h}->do(qq[ATTACH DATABASE '$path' AS "$name"]);

    $self->{h}->do(qq[PRAGMA $name.encoding = "UTF-8"]);
    $self->{h}->do( qq[PRAGMA $name.temp_store = ] . $self->{temp_store} );
    $self->{h}->do( qq[PRAGMA $name.journal_mode = ] . $self->{journal_mode} );
    $self->{h}->do( qq[PRAGMA $name.synchronous = ] . $self->{synchronous} );
    $self->{h}->do( qq[PRAGMA $name.cache_size = ] . $self->{cache_size} );
    $self->{h}->do( qq[PRAGMA $name.foreign_keys = ] . $self->{foreign_keys} );

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 145                  | Subroutines::ProhibitUnusedPrivateSubroutines - Private subroutine/method '_get_schema_patch_table_query'      |
## |      |                      | declared but not used                                                                                          |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 376                  | Subroutines::ProhibitExcessComplexity - Subroutine "do" with high complexity score (28)                        |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 459                  | Subroutines::ProtectPrivateSubs - Private subroutine/method used                                               |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 338                  | ControlStructures::ProhibitCStyleForLoops - C-style "for" loop used                                            |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 666                  | ControlStructures::ProhibitPostfixControls - Postfix control "while" used                                      |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Handle::sqlite

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
