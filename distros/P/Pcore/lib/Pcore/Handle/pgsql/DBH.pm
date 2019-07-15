package Pcore::Handle::pgsql::DBH;

use Pcore -class, -res, -const;
use Pcore::Handle::DBI::Const qw[:CONST];
use Pcore::Handle::pgsql qw[:ALL];
use Pcore::Lib::Scalar qw[weaken looks_like_number is_plain_arrayref is_plain_coderef is_blessed_arrayref];
use Pcore::Lib::Digest qw[md5_hex];
use Pcore::Lib::Data qw[from_json];

has pool => ( required => 1 );    # InstanceOf ['Pcore::Handle::pgsql']

has is_pgsql => ( 1, init_arg => undef );
has state => ( $STATE_CONNECT, init_arg => undef );
has id    => sub { P->uuid->v1mc_str }, init_arg => undef;

has _on_connect_guard => ( init_arg => undef );    # $self
has h                 => ( init_arg => undef );    # InstanceOf['Pcore::Handle']
has parameter         => ( init_arg => undef );    # HashRef, backen run-time parameters
has key_data          => ( init_arg => undef );    # HashRef, backend key data, can be used to cancel request
has tx_status         => ( init_arg => undef );    # Enum [ $TX_STATUS_IDLE, $TX_STATUS_TRANS, $TX_STATUS_ERROR ], current transaction status
has wbuf              => ( init_arg => undef );    # ArrayRef, outgoing messages buffer
has sth               => ( init_arg => undef );    # HashRef, currently executed sth
has prepared_sth      => ( init_arg => undef );    # HashRef, index of akready prepares sth for this dbh
has query             => ( init_arg => undef );    # ScalarRef, ref to the last query
has error_status      => ( init_arg => undef );    # fatal error status

const our $PROTOCOL_VER => "\x00\x03\x00\x00";     # v3

# FRONTEND
const our $PG_MSG_BIND             => 'B';
const our $PG_MSG_CANCEL_REQUEST   => $EMPTY;
const our $PG_MSG_CLOSE            => 'C';
const our $PG_MSG_CLOSE_STATEMENT  => 'S';
const our $PG_MSG_CLOSE_PORTAL     => 'P';
const our $PG_MSG_DESCRIBE         => 'D';
const our $PG_MSG_EXECUTE          => 'E';
const our $PG_MSG_FLUSH            => 'H';
const our $PG_MSG_FUNCTION_CALL    => 'F';
const our $PG_MSG_PARSE            => 'P';
const our $PG_MSG_PASSWORD_MESSAGE => 'p';
const our $PG_MSG_QUERY            => 'Q';
const our $PG_MSG_SSL_REQUEST      => $EMPTY;
const our $PG_MSG_STARTUP_MESSAGE  => $EMPTY;
const our $PG_MSG_SYNC             => 'S';
const our $PG_MSG_TERMINATE        => 'X';

# BACKEND
const our $PG_MSG_AUTHENTICATION                    => 'R';
const our $PG_MSG_AUTHENTICATION_OK                 => 0;
const our $PG_MSG_AUTHENTICATION_KERBEROS_V5        => 2;
const our $PG_MSG_AUTHENTICATION_CLEARTEXT_PASSWORD => 3;
const our $PG_MSG_AUTHENTICATION_MD5_PASSWORD       => 5;
const our $PG_MSG_AUTHENTICATION_SCM_CREDENTIAL     => 6;
const our $PG_MSG_AUTHENTICATION_GSS                => 7;
const our $PG_MSG_AUTHENTICATION_GSS_CONTINUE       => 8;
const our $PG_MSG_AUTHENTICATION_SSPI               => 9;
const our $PG_MSG_BACKEND_KEY_DATA                  => 'K';
const our $PG_MSG_BIND_COMPLETE                     => 2;
const our $PG_MSG_CLOSE_COMPLETE                    => 3;
const our $PG_MSG_COMMAND_COMPLETE                  => 'C';
const our $PG_MSG_DATA_ROW                          => 'D';
const our $PG_MSG_EMPTY_QUERY_RESPONSE              => 'I';
const our $PG_MSG_ERROR_RESPONSE                    => 'E';
const our $PG_MSG_FUNCTION_CALL_RESPONSE            => 'V';
const our $PG_MSG_NO_DATA                           => 'n';
const our $PG_MSG_NOTICE_RESPONSE                   => 'N';
const our $PG_MSG_NOTIFICATION_RESPONSE             => 'A';
const our $PG_MSG_PARAMETER_DESCRIPTION             => 't';
const our $PG_MSG_PARAMETER_STATUS                  => 'S';
const our $PG_MSG_PARSE_COMPLETE                    => 1;
const our $PG_MSG_PORTAL_SUSPENDED                  => 's';
const our $PG_MSG_READY_FOR_QUERY                   => 'Z';
const our $PG_MSG_ROW_DESCRIPTION                   => 'T';

# COPY
const our $PG_MSG_COPY_DATA          => 'd';    # frontend, backend
const our $PG_MSG_COPY_DONE          => 'c';    # frontend, backend
const our $PG_MSG_COPY_FAIL          => 'f';    # frontend
const our $PG_MSG_COPY_IN_RESPONSE   => 'G';    # backend
const our $PG_MSG_COPY_OUT_RESPONSE  => 'H';    # backend
const our $PG_MSG_COPY_BOTH_RESPONSE => 'W';    # backend

const our $ERROR_STRING_TYPE => {
    S => 'severity',
    C => 'code',
    M => 'message',
    D => 'detail',
    H => 'hint',
    P => 'position',
    p => 'internal_position',
    q => 'internal_query',
    W => 'where',
    F => 'file',
    L => 'line',
    R => 'routine',
    V => 'text',
};

const our $MESSAGE_METHOD => {

    # GENERAL MESSAGES
    $PG_MSG_AUTHENTICATION        => \&_ON_AUTHENTICATION,
    $PG_MSG_PARAMETER_STATUS      => \&_ON_PARAMETER_STATUS,
    $PG_MSG_BACKEND_KEY_DATA      => \&_ON_BACKEND_KEY_DATA,
    $PG_MSG_READY_FOR_QUERY       => \&_ON_READY_FOR_QUERY,
    $PG_MSG_ERROR_RESPONSE        => \&_ON_ERROR_RESPONSE,
    $PG_MSG_NOTICE_RESPONSE       => \&_ON_NOTICE_RESPONSE,
    $PG_MSG_NOTIFICATION_RESPONSE => \&_ON_NOTIFICATION_RESPONSE,

    # STH RELATED MESSAGES
    $PG_MSG_PARSE_COMPLETE   => \&_ON_PARSE_COMPLETE,
    $PG_MSG_BIND_COMPLETE    => \&_ON_BIND_COMPLETE,
    $PG_MSG_ROW_DESCRIPTION  => \&_ON_ROW_DESCRIPTION,
    $PG_MSG_NO_DATA          => \&_ON_NO_DATA,
    $PG_MSG_DATA_ROW         => \&_ON_DATA_ROW,
    $PG_MSG_PORTAL_SUSPENDED => \&_ON_PORTAL_SUSPENDED,
    $PG_MSG_COMMAND_COMPLETE => \&_ON_COMMAND_COMPLETE,
    $PG_MSG_CLOSE_COMPLETE   => \&_ON_CLOSE_COMPLETE,
};

sub DESTROY ( $self ) {
    $self->{pool}->push_dbh($self) if ( ${^GLOBAL_PHASE} ne 'DESTRUCT' ) && defined $self->{pool};

    return;
}

# https://www.postgresql.org/docs/current/static/protocol-flow.html#PROTOCOL-FLOW-EXT-QUERY
# https://www.postgresql.org/docs/current/static/protocol-message-formats.html
sub BUILD ( $self, $args ) {
    weaken $self->{pool};

    $self->{_on_connect_guard} = $self;

    $self->_connect;

    return;
}

sub _connect ($self) {
    Coro::async {
        weaken $self;

        my $h = $self->{h} = P->handle( [ $self->{pool}->{uri}->connect ], timeout => undef );

        # connection error
        return $self->_on_fatal_error if !$h;

        # create start message params
        my $params = [
            user                        => $self->{pool}->{uri}->{username},
            database                    => $self->{pool}->{uri}->query_params->{db},
            client_encoding             => 'UTF8',
            bytea_output                => 'hex',
            backslash_quote             => 'off',
            standard_conforming_strings => 'on',
            options                     => '--client-min-messages=warning',
        ];

        # send start message
        push $self->{wbuf}->@*, [ $PG_MSG_STARTUP_MESSAGE, $PROTOCOL_VER . join( "\x00", $params->@* ) . "\x00\x00" ];

        $self->_flush;

        while () {
            return if !defined $self || $self->{state} >= $STATE_ERROR;

            my $chunk = $h->read_chunk(5);

            return if !defined $self || $self->{state} >= $STATE_ERROR;

            # read error
            return $self->_on_fatal_error if !$h;

            # unpack message type and length
            my ( $type, $msg_len ) = unpack 'AN', $chunk->$*;

            my $data = $h->read_chunk( $msg_len - 4 );

            return if !defined $self || $self->{state} >= $STATE_ERROR;

            # read error
            return $self->_on_fatal_error if !$h;

            if ( my $method = $MESSAGE_METHOD->{$type} ) {
                $method->( $self, $data );
            }

            # UNSUPPORTED MESSAGE EXCEPTION
            else {
                return $self->_on_fatal_error(qq[Unknown message "$type"]);
            }
        }

        return;
    };

    return;
}

sub _on_fatal_error ( $self, $reason = undef ) {
    my $state = $self->{state};

    # fatal error is already processed
    return if $state >= $STATE_ERROR;

    $self->{state} = $state == $STATE_CONNECT ? $STATE_CONNECT_ERROR : $STATE_ERROR;

    my $status = $self->{error_status} = defined $reason ? res [ 500, $reason ] : res [ $self->{h}->{status}, $self->{h}->{reason} ];

    warn qq[DBI FATAL ERROR: "$status"] . ( defined $self->{query} ? qq[, current query: "$self->{query}->$*"] : $EMPTY );

    $self->{h}->shutdown;

    if ( $state == $STATE_CONNECT ) {
        delete $self->{_on_connect_guard};
    }
    elsif ( $state == $STATE_BUSY ) {
        $self->{sth}->{error} = $reason;

        $self->_finish_sth;
    }

    $self->{pool}->push_dbh($self);

    return;
}

sub _finish_sth ($self) {
    delete $self->{query};

    my $sth = delete $self->{sth};

    return if !defined $sth;

    my $cb = delete $sth->{cb};

    if ( $sth->{error} ) {
        $cb->( $sth, res [ 500, $sth->{error} ] );
    }
    else {
        $cb->( $sth, res 200, rows => $sth->{rows_tag} );
    }

    return;
}

# PG MESSAGES HANDLERS
sub _ON_AUTHENTICATION ( $self, $dataref ) {

    # we are expecting authentication messages only on connect state
    die q[Unexpected] if $self->{state} != $STATE_CONNECT;

    my $auth_type = unpack 'N', substr $dataref->$*, 0, 4, $EMPTY;

    if ( $auth_type != $PG_MSG_AUTHENTICATION_OK ) {
        my $password = $self->{pool}->{uri}->{password} // $EMPTY;

        if ( $auth_type == $PG_MSG_AUTHENTICATION_CLEARTEXT_PASSWORD ) {
            push $self->{wbuf}->@*, [ $PG_MSG_PASSWORD_MESSAGE, "$password\x00" ];

            $self->_flush;
        }
        elsif ( $auth_type == $PG_MSG_AUTHENTICATION_MD5_PASSWORD ) {
            my $pwdhash = md5_hex $password . $self->{pool}->{uri}->{username};

            my $hash = 'md5' . md5_hex $pwdhash . $dataref->$*;

            push $self->{wbuf}->@*, [ $PG_MSG_PASSWORD_MESSAGE, "$hash\x00" ];

            $self->_flush;
        }

        # unsupported auth type
        else {
            $self->_on_fatal_error(qq[Unimplemented authentication type: "$auth_type"]);
        }
    }

    return;
}

sub _ON_PARAMETER_STATUS ( $self, $dataref ) {
    my ( $key, $val ) = split /\x00/sm, $dataref->$*;

    $self->{parameter}->{$key} = $val;

    return;
}

# Identifies the message as cancellation key data.
# The frontend must save these values if it wishes to be able to issue CancelRequest messages later.
sub _ON_BACKEND_KEY_DATA ( $self, $dataref ) {
    ( $self->{key_data}->{pid}, $self->{key_data}->{secret} ) = unpack 'NN', $dataref->$*;

    return;
}

# READY FOR QUERY
sub _ON_READY_FOR_QUERY ( $self, $dataref ) {
    $self->{tx_status} = $dataref->$*;

    my $state = $self->{state};

    $self->{state} = $STATE_READY;

    # connected
    if ( $state == $STATE_CONNECT ) {
        delete $self->{_on_connect_guard};
    }
    elsif ( $state == $STATE_BUSY ) {
        $self->_finish_sth;
    }

    return;
}

# QUERY ERROR
sub _ON_ERROR_RESPONSE ( $self, $dataref ) {
    my $error;

    for my $str ( split /\x00/sm, $dataref->$* ) {
        my $str_type = substr $str, 0, 1, $EMPTY;

        $error->{ $ERROR_STRING_TYPE->{$str_type} } = $str if exists $ERROR_STRING_TYPE->{$str_type};
    }

    if ( $self->{state} == $STATE_CONNECT ) {
        $self->_on_fatal_error( $error->{message} );
    }
    else {
        $self->{sth}->{error} = $error->{message};

        warn qq[DBI: "$error->{message}"] . ( defined $self->{query} ? qq[, current query: "$self->{query}->$*"] : $EMPTY );
    }

    return;
}

sub _ON_NOTICE_RESPONSE ( $self, $dataref ) {
    my $warn;

    for my $str ( split /\x00/sm, $dataref->$* ) {
        my $str_type = substr $str, 0, 1, $EMPTY;

        $warn->{ $ERROR_STRING_TYPE->{$str_type} } = $str if exists $ERROR_STRING_TYPE->{$str_type};
    }

    warn join q[, ], $warn->{message} // $EMPTY, $warn->{hint} // $EMPTY;

    return;
}

sub _ON_NOTIFICATION_RESPONSE ( $self, $dataref ) {
    my $pid = unpack 'N', substr $dataref->$*, 0, 4, $EMPTY;

    my ( $channel, $payload ) = split /\x00/sm, $dataref->$*;

    my $pool = $self->{pool};

    if ( my $cb = $pool->{on_notification} ) {
        $cb->( $pool, $pid, $channel, $payload );
    }

    return;
}

sub _ON_PARSE_COMPLETE ( $self, $dataref ) {
    $self->{sth}->{is_parse_complete} = 1;

    # store query id in prepared sth
    $self->{prepared_sth}->{ $self->{sth}->{id} } = undef if defined $self->{sth}->{id};

    return;
}

sub _ON_BIND_COMPLETE ( $self, $dataref ) {
    $self->{sth}->{is_bind_complete} = 1;

    return;
}

sub _ON_ROW_DESCRIPTION ( $self, $dataref ) {
    my $num_of_cols = unpack 'n', substr $dataref->$*, 0, 2;

    my $pos = 2;

    my $cols;

    for my $i ( 1 .. $num_of_cols ) {
        my $idx = index $dataref->$*, "\x00", $pos;

        # 0 - The field name.
        # 1 - If the field can be identified as a column of a specific table, the object ID of the table; otherwise zero.
        # 2 - If the field can be identified as a column of a specific table, the attribute number of the column; otherwise zero.
        # 3 - The object ID of the field's data type.
        # 4 - The data type size (see pg_type.typlen). Note that negative values denote variable-width types.
        #         -1 - indicates a "varlena" type (one that has a length word);
        #         -2 - indicates a null-terminated C string;
        # 5 - The type modifier (see pg_attribute.atttypmod). The meaning of the modifier is type-specific.
        # 6 - The format code being used for the field. Currently will be 0 (text) or 1 (binary). In a RowDescription returned from the statement variant of Describe, the format code is not yet known and will always be zero.

        push $cols->@*, [ unpack 'Z*l>s>l>s>l>s>', substr $dataref->$*, $pos, $idx + 18 ];

        $pos += $idx - $pos + 19;
    }

    $self->{sth}->{cols} = $cols;

    # store description in prepared sth
    if ( defined $self->{sth}->{id} && exists $self->{prepared_sth}->{ $self->{sth}->{id} } ) {
        $self->{prepared_sth}->{ $self->{sth}->{id} } = $cols;
    }

    return;
}

sub _ON_NO_DATA ( $self, $dataref ) {
    $self->{sth}->{cols} = [];

    # store description in prepared sth
    if ( defined $self->{sth}->{id} && exists $self->{prepared_sth}->{ $self->{sth}->{id} } ) {
        $self->{prepared_sth}->{ $self->{sth}->{id} } = [];
    }

    return;
}

# TODO decode array
sub _ON_DATA_ROW ( $self, $dataref ) {
    my $num_of_cols = unpack 'n', substr $dataref->$*, 0, 2;

    my $pos = 2;

    my $row;

    my \$sth = \$self->{sth};

    for my $i ( 1 .. $num_of_cols ) {
        my $len = unpack 'l>', substr $dataref->$*, $pos, 4;

        $pos += 4;

        my $col;

        if ($len) {

            # col value is defined
            if ( $len != -1 ) {
                $col = substr $dataref->$*, $pos, $len;

                $pos += $len;

                # get col type
                my $type = $sth->{cols}->[ $i - 1 ]->[3];

                # decode bytes array
                if ( $type == $SQL_BYTEA ) {
                    $col = pack 'H*', substr $col, 2;
                }

                elsif ( $type == $SQL_BOOL ) {
                    $col = $col eq 'f' ? 0 : 1;
                }

                # TODO decode ARRAY
                # elsif ( $type == $SQL_TEXTARRAY ) {
                # }

                # decode JSON
                elsif ( $type == $SQL_JSON ) {
                    $col = from_json $col;
                }

                # decode text value
                else {
                    utf8::decode $col;
                }
            }
        }
        else {
            $col = $EMPTY;
        }

        push $row->@*, $col;
    }

    push $sth->{rows}->@*, $row;

    return;
}

sub _ON_PORTAL_SUSPENDED ( $self, $dataref ) {
    $self->{sth}->{portal_suspended} = 1;

    return;
}

sub _ON_COMMAND_COMPLETE ( $self, $dataref ) {

    # remove trailing "\x00"
    chop $dataref->$*;

    if ( $dataref->$* =~ /\s(\d+)\z/sm ) {
        $self->{sth}->{rows_tag} = $1;
    }

    return;
}

sub _ON_CLOSE_COMPLETE ( $self, $dataref ) {
    return;
}

# flush outgoing messages buffer
sub _flush ( $self ) {
    my $buf;

    while ( my $msg = shift $self->{wbuf}->@* ) {
        $buf .= $msg->[0];

        if ( defined $msg->[1] ) {
            $buf .= pack 'NA*', 4 + length $msg->[1], $msg->[1];
        }
        else {
            $buf .= "\x00\x00\x00\x04";
        }
    }

    if ( defined $buf ) {
        $self->{h}->write($buf);

        # write error
        return $self->_on_fatal_error if !$self->{h};
    }

    return;
}

sub _execute ( $self, $query, $bind, $cb, %args ) {
    if ( $self->{state} != $STATE_READY ) {
        warn 'DBI: DBH is busy';

        $cb->( undef, res [ 500, 'DBH is busy' ] );

        return;
    }

    $self->{state} = $STATE_BUSY;

    $self->{sth}->{cb} = $cb;

    my $use_extended_query = defined $bind || defined $args{max_rows};

    # query is prepared sth
    if ( ref $query eq 'Pcore::Handle::DBI::STH' ) {
        $use_extended_query = 1;

        $self->{sth}->{id} = $query->{id};

        # query is already prepared
        if ( exists $self->{prepared_sth}->{ $query->{id} } ) {
            $self->{sth}->{is_parse_complete} = 1;

            # query is already described
            if ( defined $self->{prepared_sth}->{ $query->{id} } ) {
                $self->{sth}->{cols} = $self->{prepared_sth}->{ $query->{id} };
            }
        }

        $query = $query->{query};
    }

    # query is ArrayRef
    elsif ( is_plain_arrayref $query) {
        ( $query, $bind ) = $self->{pool}->prepare_query($query);

        $use_extended_query = defined $bind;
    }

    # query is plain text
    else {

        # convert "?" placeholders to the "$1" style
        if ( defined $bind ) {
            my $i;

            $query =~ s/[?]/'$' . ++$i/smge;
        }

        utf8::encode $query if utf8::is_utf8 $query;
    }

    $self->{query} = \$query;

    # simple query mode
    # multiple queries in single statement are allowed
    if ( !$use_extended_query ) {
        push $self->{wbuf}->@*, [ $PG_MSG_QUERY, "$query\x00" ];
    }

    # extended query mode
    else {
        my $query_id  = $self->{sth}->{id} // $EMPTY;
        my $portal_id = $EMPTY;                         # uuid_v1mc_str, currently we use unnamed portals

        # parse query
        if ( !$self->{sth}->{is_parse_complete} ) {
            push $self->{wbuf}->@*, [ $PG_MSG_PARSE, "$query_id\x00$query\x00\x00\x00" ];
        }

        # prepare bind params
        my ( $params_vals, $param_format_codes );

        # query has bind params
        if ( defined $bind ) {
            $params_vals = $param_format_codes = pack 'n', scalar $bind->@*;

            # make a copy
            my @bind = $bind->@*;

            for my $param (@bind) {
                if ( is_blessed_arrayref $param) {

                    # value is not defined
                    if ( !defined $param->[1] ) {
                        $param_format_codes .= "\x00\x00";    # text

                        $param = undef;
                    }

                    # BLOB
                    elsif ( $param->[0] == $SQL_BYTEA ) {
                        $param_format_codes .= "\x00\x01";    # binary

                        $param = $param->[1];
                    }
                    else {
                        $param_format_codes .= "\x00\x00";    # text

                        if ( $param->[0] == $SQL_BOOL ) {
                            $param = $param->[1] ? '1' : '0';
                        }
                        elsif ( $param->[0] == $SQL_JSON ) {
                            $param = $self->encode_json( $param->[1] )->$*;
                        }
                        else {
                            $param = $param->[1];
                        }
                    }
                }

                # array
                elsif ( is_plain_arrayref $param) {
                    $param_format_codes .= "\x00\x00";    # text

                    $param = $self->encode_array($param)->$*;
                }

                # text by default
                else {
                    $param_format_codes .= "\x00\x00";    # text
                }

                if ( defined $param ) {
                    utf8::encode $param if utf8::is_utf8 $param;

                    $params_vals .= pack 'NA*', length $param, $param;
                }
                else {
                    $params_vals .= "\xFF\xFF\xFF\xFF";
                }
            }
        }

        # no bind params specified
        else {
            $params_vals = $param_format_codes = "\x00\x00";
        }

        # bind
        push $self->{wbuf}->@*, [ $PG_MSG_BIND, "$portal_id\x00$query_id\x00${param_format_codes}${params_vals}\x00\x00" ];

        # request portal description if not described
        if ( !defined $self->{sth}->{cols} ) {
            push $self->{wbuf}->@*, [ $PG_MSG_DESCRIBE, "${PG_MSG_CLOSE_PORTAL}$portal_id\x00" ];
        }

        # execute
        push $self->{wbuf}->@*, [ $PG_MSG_EXECUTE, "$portal_id\x00" . pack 'N', ( $args{max_rows} // 0 ) ];

        # close portal if max_rows was used
        push $self->{wbuf}->@*, [ $PG_MSG_CLOSE, "${PG_MSG_CLOSE_PORTAL}$portal_id\x00" ] if defined $args{max_rows};

        # sync
        push $self->{wbuf}->@*, [$PG_MSG_SYNC];

        # flush
        # push $self->{wbuf}->@*, [$PG_MSG_FLUSH];
    }

    $self->_flush;

    return;
}

sub _parse_args ( $args ) {
    my $bind = is_plain_arrayref $args->[0] ? shift $args->@* : undef;
    my $cb   = is_plain_coderef $args->[-1] ? pop $args->@*   : undef;
    my %args = $args->@*;

    return $bind, \%args, $cb;
}

# STH
sub prepare ( $self, $query ) {
    return $self->{pool}->prepare($query);
}

sub get_dbh ( $self, $cb = undef ) {

    # self is ready
    if ( $self->{state} == $STATE_READY && $self->{tx_status} eq $TX_STATUS_IDLE ) {
        return $cb ? $cb->( res(200), $self ) : ( res(200), $self );
    }

    # self is not ready
    else {
        return $self->{pool}->get_dbh($cb);
    }
}

# PUBLIC DBI METHODS
sub do ( $self, $query, @args ) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    my ( $bind, $args, $cb ) = _parse_args( \@args );

    my $on_finish = sub ( $sth, $res ) {
        my $guard = $self;           # keep reference to $self until query is finished

        if ( $res && defined $sth->{rows} ) {
            my @cols_names = map { $_->[0] } $sth->{cols}->@*;

            my $data;

            for my $row ( $sth->{rows}->@* ) {
                my $data_row->@{@cols_names} = $row->@*;

                push $data->@*, $data_row;
            }

            $res->{data} = $data;
        }

        return $cb ? $cb->($res) : $res;
    };

    if ( defined wantarray ) {
        $self->_execute( $query, $bind, my $cv = P->cv );

        return $on_finish->( $cv->recv );
    }
    else {
        $self->_execute( $query, $bind, $on_finish );

        return;
    }
}

# key_col => [0, 1, 'id'], key_col => 'id'
sub selectall ( $self, $query, @args ) {
    my ( $bind, $args, $cb ) = _parse_args( \@args );

    my $on_finish = sub ( $sth, $res ) {
        my $guard = $self;    # keep reference to $self until query is finished

        if ( $res && defined $sth->{rows} ) {
            my @cols_names = map { $_->[0] } $sth->{cols}->@*;

            if ( defined $args->{key_col} ) {
                my $name2idx;

                # create columns index
                for ( my $i = 0; $i <= $sth->{cols}->$#*; $i++ ) {
                    $name2idx->{ $sth->{cols}->[$i]->[0] } = $i;
                }

                my $num_of_fields = $sth->{cols}->@*;
                my @key_col_idx;

                for my $key_col ( is_plain_arrayref $args->{key_col} ? $args->{key_col}->@* : $args->{key_col} ) {
                    if ( looks_like_number $key_col) {
                        if ( $key_col + 1 > $num_of_fields ) {
                            my $res = res [ 400, qq[Invalid field index "$key_col"] ];

                            warn $res;

                            return $cb ? $cb->($res) : $res;
                        }

                        push @key_col_idx, $key_col;
                    }
                    else {
                        my $idx = $name2idx->{$key_col};

                        if ( !defined $idx ) {
                            my $res = res [ 400, qq[DBI: Invalid field name "$key_col"] ];

                            warn $res;

                            return $cb ? $cb->($res) : $res;
                        }

                        push @key_col_idx, $idx;
                    }
                }

                my $data = {};

                for my $row ( $sth->{rows}->@* ) {
                    my $ref = $data;

                    $ref = $ref->{ $row->[$_] // $EMPTY } //= {} for @key_col_idx;

                    $ref->@{@cols_names} = $row->@*;
                }

                $res->{data} = $data;
            }
            else {
                my $data;

                for my $row ( $sth->{rows}->@* ) {
                    my $row_hashref->@{@cols_names} = $row->@*;

                    push $data->@*, $row_hashref;
                }

                $res->{data} = $data;
            }
        }

        return $cb ? $cb->($res) : $res;
    };

    if ( defined wantarray ) {
        $self->_execute( $query, $bind, my $cv = P->cv );

        return $on_finish->( $cv->recv );
    }
    else {
        $self->_execute( $query, $bind, $on_finish );

        return;
    }
}

sub selectall_arrayref ( $self, $query, @args ) {
    my ( $bind, $args, $cb ) = _parse_args( \@args );

    my $on_finish = sub ( $sth, $res ) {
        my $guard = $self;    # keep reference to $self until query is finished

        my $data;

        if ( $res && defined $sth->{rows} ) {
            $res->{data} = $sth->{rows};
        }

        return $cb ? $cb->($res) : $res;
    };

    if ( defined wantarray ) {
        $self->_execute( $query, $bind, my $cv = P->cv );

        return $on_finish->( $cv->recv );
    }
    else {
        $self->_execute( $query, $bind, $on_finish );

        return;
    }
}

sub selectrow ( $self, $query, @args ) {
    my ( $bind, $args, $cb ) = _parse_args( \@args );

    my $on_finish = sub ( $sth, $res ) {
        my $guard = $self;    # keep reference to $self until query is finished

        if ( $res && defined $sth->{rows} ) {
            if ( $sth->{rows} ) {
                my @cols_names = map { $_->[0] } $sth->{cols}->@*;

                $res->{data}->@{@cols_names} = $sth->{rows}->[0]->@*;
            }
        }

        return $cb ? $cb->($res) : $res;
    };

    if ( defined wantarray ) {
        $self->_execute( $query, $bind, my $cv = P->cv, max_rows => 1 );

        return $on_finish->( $cv->recv );
    }
    else {
        $self->_execute( $query, $bind, $on_finish, max_rows => 1 );

        return;
    }
}

sub selectrow_arrayref ( $self, $query, @args ) {
    my ( $bind, $args, $cb ) = _parse_args( \@args );

    my $on_finish = sub ( $sth, $res ) {
        my $guard = $self;    # keep reference to $self until query is finished

        if ( $res && defined $sth->{rows} ) {
            $res->{data} = $sth->{rows}->[0];
        }

        return $cb ? $cb->($res) : $res;
    };

    if ( defined wantarray ) {
        $self->_execute( $query, $bind, my $cv = P->cv, max_rows => 1 );

        return $on_finish->( $cv->recv );
    }
    else {
        $self->_execute( $query, $bind, $on_finish, max_rows => 1 );

        return;
    }
}

# col => [0, 'id'], col => 'id', default col => 0
sub selectcol ( $self, $query, @args ) {
    my ( $bind, $args, $cb ) = _parse_args( \@args );

    my $on_finish = sub ( $sth, $res ) {
        my $guard = $self;    # keep reference to $self until query is finished

        if ( $res && defined $sth->{rows} ) {
            my @slice;

            my $num_of_fields = $sth->{cols}->@* - 1;

            if ( !defined $args->{col} ) {
                push @slice, 0;
            }
            else {
                for my $col ( is_plain_arrayref $args->{col} ? $args->{col}->@* : $args->{col} ) {
                    if ( looks_like_number $col) {
                        if ( $col > $num_of_fields ) {
                            my $res = res [ 400, qq[DBI: Invalid column index: "$col"] ];

                            warn $res;

                            return $cb ? $cb->($res) : $res;
                        }

                        push @slice, $col;
                    }
                    else {

                        # create columns index
                        my $name2idx;

                        if ( !defined $name2idx ) {
                            $name2idx = {};

                            for ( my $i = 0; $i <= $sth->{cols}->$#*; $i++ ) {
                                $name2idx->{ $sth->{cols}->[$i]->[0] } = $i;
                            }
                        }

                        if ( !exists $name2idx->{$col} ) {
                            my $res = res [ 400, qq[DBI: Invalid column name: "$col"] ];

                            warn $res;

                            return $cb ? $cb->($res) : $res;
                        }

                        push @slice, $name2idx->{$col};
                    }
                }
            }

            my $data;

            for my $row ( $sth->{rows}->@* ) {
                push $data->@*, $row->@[@slice];
            }

            $res->{data} = $data;
        }

        return $cb ? $cb->($res) : $res;
    };

    if ( defined wantarray ) {
        $self->_execute( $query, $bind, my $cv = P->cv );

        return $on_finish->( $cv->recv );
    }
    else {
        $self->_execute( $query, $bind, $on_finish );

        return;
    }
}

# TRANSACTIONS
sub begin_work ( $self, $cb = undef ) {
    my $on_finish = sub ( $sth, $res ) {
        return $cb ? $cb->($res) : $res;
    };

    if ( defined wantarray ) {
        $self->_execute( 'BEGIN', undef, my $cv = P->cv );

        return $on_finish->( $cv->recv );
    }
    else {
        $self->_execute( 'BEGIN', undef, $on_finish );

        return;
    }
}

sub commit ( $self, $cb = undef ) {
    my $on_finish = sub ( $sth, $res ) {
        my $guard = $self;    # keep reference to $self until query is finished

        return $cb ? $cb->($res) : $res;
    };

    if ( defined wantarray ) {
        $self->_execute( 'COMMIT', undef, my $cv = P->cv );

        return $on_finish->( $cv->recv );
    }
    else {
        $self->_execute( 'COMMIT', undef, $on_finish );

        return;
    }
}

sub rollback ( $self, $cb = undef ) {
    my $on_finish = sub ( $sth, $res ) {
        my $guard = $self;    # keep reference to $self until query is finished

        return $cb ? $cb->($res) : $res;
    };

    if ( defined wantarray ) {
        $self->_execute( 'ROLLBACK', undef, my $cv = P->cv );

        return $on_finish->( $cv->recv );
    }
    else {
        $self->_execute( 'ROLLBACK', undef, $on_finish );

        return;
    }
}

# QUOTE
sub quote_id ( $self, $id ) {
    return $self->{pool}->quote_id($id);
}

sub quote ( $self, $var ) {
    return $self->{pool}->quote($var);
}

sub encode_array ( $self, $var ) {
    return $self->{pool}->encode_array($var);
}

sub encode_json ( $self, $var ) {
    return $self->{pool}->encode_json($var);
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 539                  | Subroutines::ProhibitExcessComplexity - Subroutine "_execute" with high complexity score (31)                  |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 640, 973             | ControlStructures::ProhibitDeepNests - Code structure is deeply nested                                         |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 782, 973             | ControlStructures::ProhibitCStyleForLoops - C-style "for" loop used                                            |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 821                  | ControlStructures::ProhibitPostfixControls - Postfix control "for" used                                        |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Handle::pgsql::DBH

=head1 SYNOPSIS

=head1 DESCRIPTION

->selectrow method don't returns number of rows.

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
