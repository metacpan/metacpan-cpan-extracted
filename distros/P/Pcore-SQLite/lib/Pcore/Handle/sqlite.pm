package Pcore::Handle::sqlite;

use Pcore -class, -const, -result;
use DBI qw[];
use Pcore::Handle::DBI::Const qw[:CONST];
use DBD::SQLite qw[];
use DBD::SQLite::Constants qw[:file_open];
use Pcore::Util::Scalar qw[weaken is_blessed_ref looks_like_number is_plain_arrayref is_plain_coderef is_blessed_arrayref];
use Pcore::Util::UUID qw[uuid_str];
use Pcore::Util::Data qw[to_json];

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

has mode => ( is => 'ro', isa => Enum [ keys $SQLITE_OPEN->%* ], default => 'rwc' );
has busy_timeout => ( is => 'ro', isa => PositiveOrZeroInt, default => 1_000 * 3 );    # milliseconds, set to 0 to disable timeout, default - 3 seconds

# SQLITE PRAGMAS
has temp_store   => ( is => 'ro', isa => Enum [qw[FILE MEMORY]],                            default => 'MEMORY' );
has journal_mode => ( is => 'ro', isa => Enum [qw[DELETE TRUNCATE PERSIST MEMORY WAL OFF]], default => 'WAL' );      # WAL is the best
has synchronous  => ( is => 'ro', isa => Enum [qw[FULL NORMAL OFF]],                        default => 'OFF' );      # OFF - data integrity on app failure, NORMAL - data integrity on app and OS failures, FULL - full data integrity on app or OS failures, slower
has cache_size   => ( is => 'ro', isa => Int,  default => -1_048_576 );                                              # 0+ - pages,  -kilobytes, default 1G
has foreign_keys => ( is => 'ro', isa => Bool, default => 1 );

has is_sqlite    => ( is => 'ro', isa => Bool,      default  => 1, init_arg => undef );
has h            => ( is => 'ro', isa => Object,    init_arg => undef );
has prepared_sth => ( is => 'ro', isa => HashRef,   init_arg => undef );
has query        => ( is => 'ro', isa => ScalarRef, init_arg => undef );                                             # ref to the last query

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
        #     # escape_scalar $msg;
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

    my $dbname = $self->uri->path->to_string || ':memory:';

    my $dbh = DBI->connect( "dbi:SQLite:dbname=$dbname", q[], q[], $attr );

    $dbh->do('PRAGMA encoding = "UTF-8"');
    $dbh->do( 'PRAGMA temp_store = ' . $self->{temp_store} );
    $dbh->do( 'PRAGMA journal_mode = ' . $self->{journal_mode} );
    $dbh->do( 'PRAGMA synchronous = ' . $self->{synchronous} );
    $dbh->do( 'PRAGMA cache_size = ' . $self->{cache_size} );
    $dbh->do( 'PRAGMA foreign_keys = ' . $self->{foreign_keys} );

    $dbh->sqlite_busy_timeout( $self->{busy_timeout} );

    # create custom functions
    $dbh->sqlite_create_function( 'uuid', 0, sub { return uuid_str } );

    $self->{on_connect}->($self) if $self->{on_connect};

    $self->{h} = $dbh;

    return;
}

# STH
sub prepare ( $self, $query ) {
    my $sth = bless {
        id    => uuid_str,
        query => $query,
      },
      'Pcore::Handle::DBI::STH';

    return $sth;
}

sub destroy_sth ( $self, $id ) {
    delete $self->{prepared_sth}->{$id};

    return;
}

# SCHEMA PATCH
sub _get_schema_patch_table_query ( $self, $table_name ) {
    return <<"SQL";
        CREATE TABLE IF NOT EXISTS "$table_name" (
            "id" INTEGER PRIMARY KEY NOT NULL,
            "timestamp" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
SQL
}

# QUOTE
sub _get_sqlite_type ($type) : prototype($) {

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
            $var = to_json( $var->[1] )->$*;
        }
        else {
            $var = $var->[1];
        }
    }
    else {

        # transparently encode arrays to JSON
        if ( is_plain_arrayref $var) {
            $type = $SQLITE_BLOB;

            $var = to_json($var)->$*;
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
    warn qq[DBI: "$DBI::errstr"] . ( defined $self->{query} ? qq[, current query: "$self->{query}->$*"] : q[] );

    return;
}

sub _die ($self) {
    die qq[DBI: "$DBI::errstr"] . ( defined $self->{query} ? qq[, current query: "$self->{query}->$*"] : q[] );
}

sub _execute ( $self, $sth, $bind, $bind_pos ) {

    # make a copy
    my @bind = $bind->@[ $bind_pos .. $bind_pos + $sth->{NUM_OF_PARAMS} - 1 ];

    $bind_pos += $sth->{NUM_OF_PARAMS};

    # bind types
    for ( my $i = 0; $i <= $#bind; $i++ ) {
        if ( is_blessed_arrayref $bind[$i] ) {
            $sth->bind_param( $i + 1, undef, _get_sqlite_type $bind[$i]->[0] );

            if ( $bind[$i]->[0] == $SQL_BOOL ) {
                $bind[$i] = $bind[$i]->[1] ? 1 : 0;
            }
            elsif ( $bind[$i]->[0] == $SQL_JSON ) {
                $bind[$i] = to_json( $bind[$i]->[1] )->$*;
            }
            else {
                $bind[$i] = $bind[$i]->[1];
            }
        }
        elsif ( is_plain_arrayref $bind[$i] ) {
            $sth->bind_param( $i + 1, undef, $SQLITE_BLOB );

            $bind[$i] = to_json( $bind[$i] )->$*;
        }
    }

    return $sth->execute(@bind);
}

# PUBLIC DBI METHODS
sub do ( $self, $query, @args ) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]

    # parse args
    my $bind = is_plain_arrayref $args[0] ? shift @args : undef;
    my $cb   = is_plain_coderef $args[-1] ? pop @args   : undef;
    my %args = @args;

    my ( $dbh, $rows ) = $self->{h};

    # query is sth
    if ( is_blessed_ref $query) {
        my $sth;

        if ( ref $query eq 'Pcore::Handle::DBI::STH' ) {
            $sth = $self->{prepared_sth}->{ $query->{id} };

            if ( !defined $sth ) {
                $self->{query} = \$query->{query};

                $sth = $dbh->prepare( $query->{query} );

                # check error
                if ( defined $DBI::err ) {
                    if ( defined $cb ) { $self->_warn; $cb->( $self, result( [ 500, $DBI::errstr ], rows => $rows ), undef ); return $rows }
                    else               { $self->_die }
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
            if ( defined $cb ) { $self->_warn; $cb->( $self, result( [ 500, 'Invalid STH class' ], rows => $rows ), undef ); return $rows }
            else               { die 'Invalid STH class' }
        }

        # bind and exec
        if ( defined $bind ) {
            $rows = $self->_execute( $sth, $bind, 0 );
        }
        else {
            $rows = $sth->execute;
        }

        # check error
        if ( defined $DBI::err ) {
            if ( defined $cb ) { $self->_warn; $cb->( $self, result( [ 500, $DBI::errstr ], rows => $rows ), undef ); return $rows }
            else               { $self->_die }
        }

        $rows = 0 if $rows == 0;    # convert "0E0" to "0"

        $cb->( $self, result( 200, rows => $rows ), undef ) if defined $cb;

        return $rows;
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
            if ( defined $cb ) { $self->_warn; $cb->( $self, result( [ 500, $DBI::errstr ], rows => $rows ), undef ); return $rows }
            else               { $self->_die }
        }

        $rows = 0 if $rows == 0;    # convert "0E0" to "0"

        $cb->( $self, result( 200, rows => $rows ), undef ) if defined $cb;

        return $rows;
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
                if ( defined $cb ) { $self->_warn; $cb->( $self, result( [ 500, $DBI::errstr ], rows => $rows ), undef ); return $rows }
                else               { $self->_die }
            }

            # bind and exec
            $self->_execute( $sth, $bind, $bind_pos );

            # execute error
            if ( defined $DBI::err ) {
                if ( defined $cb ) { $self->_warn; $cb->( $self, result( [ 500, $DBI::errstr ], rows => $rows ), undef ); return $rows }
                else               { $self->_die }
            }

            $rows += $sth->rows;

            $query = $sth->{sqlite_unprepared_statements};
        }

        $cb->( $self, result( 200, rows => $rows ), undef ) if defined $cb;

        return $rows;
    }
}

# key_field => [0, 1, 'id'], key_field => 'id'
sub selectall ( $self, @ ) {
    my ( $rows, $sth, $args, $cb ) = &_exec_sth;    ## no critic qw[Subroutines::ProhibitAmpersandSigils]

    # check error
    if ( defined $DBI::err ) {
        if ( defined $cb ) { $self->_warn; $cb->( $self, result( [ 500, $DBI::errstr ], rows => $rows ), undef ); return }
        else               { $self->_die }
    }

    my $data;

    if ( defined $args->{key_field} ) {

        # make fields indexes 0-based
        my @key_fields = map { looks_like_number $_ ? $_ + 1 : $_ } is_plain_arrayref $args->{key_field} ? $args->{key_field}->@* : $args->{key_field};

        $data = $sth->fetchall_hashref( \@key_fields );

        # check error
        if ( defined $DBI::err ) {
            if ( defined $cb ) { $self->_warn; $cb->( $self, result( [ 500, $DBI::errstr ], rows => $rows ), undef ); return }
            else               { $self->_die }
        }

        undef $data if !$data->%*;
    }
    else {
        $data = $sth->fetchall_arrayref( {}, undef );

        undef $data if !$data->@*;
    }

    $cb->( $self, result( 200, rows => $rows ), $data ) if defined $cb;

    return $data;
}

sub selectall_arrayref ( $self, @ ) {
    my ( $rows, $sth, $args, $cb ) = &_exec_sth;    ## no critic qw[Subroutines::ProhibitAmpersandSigils]

    # check error
    if ( defined $DBI::err ) {
        if ( defined $cb ) { $self->_warn; $cb->( $self, result( [ 500, $DBI::errstr ], rows => $rows ), undef ); return }
        else               { $self->_die }
    }

    my $data = $sth->fetchall_arrayref( undef, undef );

    undef $data if !$data->@*;

    $cb->( result( $self, 200, rows => $rows ), $data ) if defined $cb;

    return $data;
}

sub selectrow ( $self, @ ) {
    my ( $rows, $sth, $args, $cb ) = &_exec_sth;    ## no critic qw[Subroutines::ProhibitAmpersandSigils]

    # check error
    if ( defined $DBI::err ) {
        if ( defined $cb ) { $self->_warn; $cb->( $self, result( [ 500, $DBI::errstr ], rows => $rows ), undef ); return }
        else               { $self->_die }
    }

    my $data = $sth->fetchrow_hashref;

    $sth->finish;

    $cb->( $self, result( 200, rows => $rows ), $data ) if defined $cb;

    return $data;
}

sub selectrow_arrayref ( $self, @ ) {
    my ( $rows, $sth, $args, $cb ) = &_exec_sth;    ## no critic qw[Subroutines::ProhibitAmpersandSigils]

    # check error
    if ( defined $DBI::err ) {
        if ( defined $cb ) { $self->_warn; $cb->( $self, result( [ 500, $DBI::errstr ], rows => $rows ), undef ); return }
        else               { $self->_die }
    }

    my $data = $sth->fetchrow_arrayref;

    $sth->finish;

    $cb->( $self, result( 200, rows => $rows ), $data ) if defined $cb;

    return $data;
}

# col => [0, 'id'], col => 'id', default col => 0
sub selectcol ( $self, @ ) {
    my ( $rows, $sth, $args, $cb ) = &_exec_sth;    ## no critic qw[Subroutines::ProhibitAmpersandSigils]

    # check error
    if ( defined $DBI::err ) {
        if ( defined $cb ) { $self->_warn; $cb->( $self, result( [ 500, $DBI::errstr ], rows => $rows ), undef ); return }
        else               { $self->_die }
    }

    my ( $data, $name2idx, $idx, @vals );

    my $num_of_fields = $sth->{NUM_OF_FIELDS} - 1;

    $args->{col} //= 0;

    for my $col ( is_plain_arrayref $args->{col} ? $args->{col}->@* : $args->{col} ) {
        if ( looks_like_number $col) {
            if ( $col > $num_of_fields ) {
                if ( defined $cb ) { $self->_warn; $cb->( $self, result( [ 500, qq[Invalid column index: "$col"] ], rows => $rows ), undef ); return }
                else               { die qq[Invalid column index: "$col"] }
            }

            $sth->bind_col( $col + 1, \$vals[ $idx++ ] );
        }
        else {
            $name2idx //= $sth->{NAME_hash};

            if ( !exists $name2idx->{$col} ) {
                if ( defined $cb ) { $self->_warn; $cb->( $self, result( [ 500, qq[Invalid column name: "$col"] ], rows => $rows ), undef ); return }
                else               { die qq[Invalid column name: "$col"] }
            }

            $sth->bind_col( $name2idx->{$col} + 1, \$vals[ $idx++ ] );
        }
    }

    push $data->@*, @vals while $sth->fetch;

    $cb->( $self, result( 200, rows => $rows ), $data ) if defined $cb;

    return $data;
}

# TRANSACTIONS
sub begin_work ( $self, $cb = undef ) {
    $self->{h}->begin_work;

    # check error
    if ( defined $DBI::err ) {
        if ( defined $cb ) { $self->_warn; $cb->( $self, result [ 500, $DBI::errstr ] ); return }
        else               { $self->_die }
    }

    $cb->( $self, result 200 ) if defined $cb;

    return;
}

sub commit ( $self, $cb = undef ) {
    $self->{h}->commit;

    # check error
    if ( defined $DBI::err ) {
        if ( defined $cb ) { $self->_warn; $cb->( $self, result [ 500, $DBI::errstr ] ); return }
        else               { $self->_die }
    }

    $cb->( $self, result 200 ) if defined $cb;

    return;
}

sub rollback ( $self, $cb = undef ) {
    $self->{h}->rollback;

    # check error
    if ( defined $DBI::err ) {
        if ( defined $cb ) { $self->_warn; $cb->( $self, result [ 500, $DBI::errstr ] ); return }
        else               { $self->_die }
    }

    $cb->( $self, result 200 ) if defined $cb;

    return;
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
## |    3 | 157                  | Subroutines::ProhibitUnusedPrivateSubroutines - Private subroutine/method '_get_schema_patch_table_query'      |
## |      |                      | declared but not used                                                                                          |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 377                  | Subroutines::ProhibitExcessComplexity - Subroutine "do" with high complexity score (36)                        |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 451                  | Subroutines::ProtectPrivateSubs - Private subroutine/method used                                               |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 233                  | ValuesAndExpressions::ProhibitEscapedCharacters - Numeric escapes in interpolated string                       |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 352                  | ControlStructures::ProhibitCStyleForLoops - C-style "for" loop used                                            |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 632                  | ControlStructures::ProhibitPostfixControls - Postfix control "while" used                                      |
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
