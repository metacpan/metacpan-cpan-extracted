package Pcore::Handle::pgsql::DBH;

use Pcore -class, -res, -const;
use Pcore::Handle::DBI::Const qw[:CONST];
use Pcore::Handle::pgsql qw[:ALL];
use Pcore::Util::Scalar qw[weaken looks_like_number is_plain_arrayref is_plain_coderef is_blessed_arrayref];
use Pcore::Util::UUID qw[uuid_v1mc_str];
use Pcore::Util::Digest qw[md5_hex];
use Pcore::Util::Data qw[from_json];
use Pcore::Handle::pgsql::AEHandle;

has handle     => ( required => 1 );    # InstanceOf ['Pcore::Handle::pgsql']
has on_connect => ( required => 1 );    # CodeRef
has password => ();                     # Str

has is_pgsql => 1, init_arg => undef;

has state        => $STATE_CONNECT, init_arg => undef;    # Enum [ $STATE_CONNECT, $STATE_READY, $STATE_BUSY, $STATE_DISCONNECTED ]
has h            => ( init_arg => undef );                # InstanceOf ['Pcore::Handle::pgsql::AEHandle']
has parameter    => ( init_arg => undef );                # HashRef
has key_data     => ( init_arg => undef );                # HashRef
has tx_status    => ( init_arg => undef );                # Enum [ $TX_STATUS_IDLE, $TX_STATUS_TRANS, $TX_STATUS_ERROR ], current transaction status
has wbuf         => ( init_arg => undef );                # ArrayRef, outgoing messages buffer
has sth          => ( init_arg => undef );                # HashRef, currently executed sth
has prepared_sth => ( init_arg => undef );                # HashRef
has query        => ( init_arg => undef );                # ScalarRef, ref to the last query

const our $PROTOCOL_VER => "\x00\x03\x00\x00";            # v3

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

sub DESTROY ( $self ) {
    $self->{handle}->push_dbh($self) if ( ${^GLOBAL_PHASE} ne 'DESTRUCT' ) && defined $self->{handle};

    return;
}

# https://www.postgresql.org/docs/current/static/protocol-flow.html#PROTOCOL-FLOW-EXT-QUERY
# https://www.postgresql.org/docs/current/static/protocol-message-formats.html
sub connect ( $self, %args ) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    my $on_connect = delete $args{on_connect};

    $self = bless \%args, $self;

    $self->{is_pgsql} = 1;

    $self->{state} = $STATE_CONNECT;

    $self->{on_connect} = sub ( $dbh, $res ) {
        undef $self;

        $on_connect->(@_);

        return;
    };

    my $host = $self->{handle}->host;
    my $port = $self->{handle}->{port};

    Pcore::Handle::pgsql::AEHandle->new(
        connect => "pgsql://$host:$port",
        on_error => sub ( $h, $fatal, $reason ) {
            $self->_on_error( $reason, 1 );

            return;
        },
        on_connect => sub ( $h, $host, $port, $retry ) {
            $self->{h} = $h;

            my $params = [
                user                        => $self->{handle}->username,
                database                    => $self->{handle}->database,
                client_encoding             => 'UTF8',
                bytea_output                => 'hex',
                backslash_quote             => 'off',
                standard_conforming_strings => 'on',
                options                     => '--client-min-messages=warning',
            ];

            # send start message
            push $self->{wbuf}->@*, [ $PG_MSG_STARTUP_MESSAGE, $PROTOCOL_VER . join( "\x00", $params->@* ) . "\x00\x00" ];

            $self->_flush;

            # start listen for messages
            $self->_start_listen;

            return;
        }
    );

    return;
}

sub _start_listen ($self) {
    weaken $self;

    $self->{h}->on_read( sub {
        my \$rbuf = \$_[0]->{rbuf};

      REDO:
        if ( length $rbuf > 4 ) {
            my ( $type, $msg_len ) = unpack 'AN', $rbuf;

            if ( length $rbuf > $msg_len ) {
                my $data = substr $rbuf, 0, $msg_len + 1, $EMPTY;

                substr $data, 0, 5, $EMPTY;

                # GENERAL MESSAGES
                if    ( $type eq $PG_MSG_AUTHENTICATION )   { $self->_ON_AUTHENTICATION( \$data ) }
                elsif ( $type eq $PG_MSG_PARAMETER_STATUS ) { $self->_ON_PARAMETER_STATUS( \$data ) }
                elsif ( $type eq $PG_MSG_BACKEND_KEY_DATA ) { $self->_ON_BACKEND_KEY_DATA( \$data ) }
                elsif ( $type eq $PG_MSG_READY_FOR_QUERY )  { $self->_ON_READY_FOR_QUERY( \$data ) }
                elsif ( $type eq $PG_MSG_ERROR_RESPONSE )   { $self->_ON_ERROR_RESPONSE( \$data ) }
                elsif ( $type eq $PG_MSG_NOTICE_RESPONSE )  { $self->_ON_NOTICE_RESPONSE( \$data ) }

                # STH RELATED MESSAGES
                elsif ( $type eq $PG_MSG_PARSE_COMPLETE )   { $self->_ON_PARSE_COMPLETE }
                elsif ( $type eq $PG_MSG_BIND_COMPLETE )    { $self->_ON_BIND_COMPLETE }
                elsif ( $type eq $PG_MSG_ROW_DESCRIPTION )  { $self->_ON_ROW_DESCRIPTION( \$data ) }
                elsif ( $type eq $PG_MSG_NO_DATA )          { $self->_ON_NO_DATA }
                elsif ( $type eq $PG_MSG_DATA_ROW )         { $self->_ON_DATA_ROW( \$data ) }
                elsif ( $type eq $PG_MSG_PORTAL_SUSPENDED ) { $self->_ON_PORTAL_SUSPENDED }
                elsif ( $type eq $PG_MSG_COMMAND_COMPLETE ) { $self->_ON_COMMAND_COMPLETE( \$data ) }
                elsif ( $type eq $PG_MSG_CLOSE_COMPLETE )   { $self->_ON_CLOSE_COMPLETE }

                # UNSUPPORTED MESSAGE EXCEPTION
                else {
                    die qq[Unknown message "$type"];
                }

                goto REDO;
            }
        }

        return;
    } );

    return;
}

sub _on_error ( $self, $reason, $fatal ) {
    my $state = $self->{state};

    # error on connect state is always fatal
    $fatal = 1 if $state == $STATE_CONNECT;

    # disconnect on fatal error
    if ($fatal) {
        $self->{h}->destroy if defined $self->{h};

        $self->{state} = $STATE_DISCONNECTED;
    }

    warn qq[DBI: "$reason"] . ( defined $self->{query} ? qq[, current query: "$self->{query}->$*"] : $EMPTY );

    if ( $state == $STATE_BUSY ) {
        $self->{sth}->{error} = $reason;
    }
    elsif ( $state == $STATE_CONNECT ) {
        delete( $self->{on_connect} )->( undef, res [ 500, $reason ] );
    }

    return;
}

# PG MESSAGES HANDLERS
sub _ON_AUTHENTICATION ( $self, $dataref ) {

    # we are expecting authentication messages only on connect state
    die q[Unexpected] if $self->{state} != $STATE_CONNECT;

    my $auth_type = unpack 'N', substr $dataref->$*, 0, 4, $EMPTY;

    if ( $auth_type != $PG_MSG_AUTHENTICATION_OK ) {
        if ( $auth_type == $PG_MSG_AUTHENTICATION_CLEARTEXT_PASSWORD ) {
            $self->{h}->push_write( $PG_MSG_PASSWORD_MESSAGE . pack 'NZ*', 5 + length $self->{handle}->password, $self->{handle}->password );
        }
        elsif ( $auth_type == $PG_MSG_AUTHENTICATION_MD5_PASSWORD ) {
            my $pwdhash = md5_hex $self->{handle}->password . $self->{handle}->username;

            my $hash = 'md5' . md5_hex $pwdhash . $dataref->$*;

            $self->{h}->push_write( $PG_MSG_PASSWORD_MESSAGE . pack 'NZ*', 5 + length $hash, $hash );
        }

        # unsupported auth type
        else {
            $self->_on_error( qq[Unimplemented authentication type: "$auth_type"], 1 );
        }
    }

    return;
}

sub _ON_PARAMETER_STATUS ( $self, $dataref ) {
    my ( $key, $val ) = split /\x00/sm, $dataref->$*;

    $self->{parameter}->{$key} = $val;

    return;
}

sub _ON_BACKEND_KEY_DATA ( $self, $dataref ) {
    ( $self->{key_data}->{pid}, $self->{key_data}->{secret} ) = unpack 'NN', $dataref->$*;

    return;
}

sub _ON_READY_FOR_QUERY ( $self, $dataref ) {
    $self->{tx_status} = $dataref->$*;

    my $state = $self->{state};

    $self->{state} = $STATE_READY;

    # connected
    if ( $state == $STATE_CONNECT ) {
        delete( $self->{on_connect} )->( $self, res 200 );
    }
    elsif ( $state == $STATE_BUSY ) {
        my $sth = delete $self->{sth};

        my $cb = delete $sth->{cb};

        if ( $sth->{error} ) {
            $cb->( $sth, res [ 500, $sth->{error} ] );
        }
        else {
            $cb->( $sth, res 200, $sth->{tag}->%* );
        }
    }

    return;
}

sub _ON_ERROR_RESPONSE ( $self, $dataref ) {
    my $error;

    for my $str ( split /\x00/sm, $dataref->$* ) {
        my $str_type = substr $str, 0, 1, $EMPTY;

        $error->{ $ERROR_STRING_TYPE->{$str_type} } = $str if exists $ERROR_STRING_TYPE->{$str_type};
    }

    $self->_on_error( $error->{message}, 0 );

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

sub _ON_PARSE_COMPLETE ($self) {
    $self->{sth}->{is_parse_complete} = 1;

    # store query id in prepared sth
    $self->{prepared_sth}->{ $self->{sth}->{id} } = undef if defined $self->{sth}->{id};

    return;
}

sub _ON_BIND_COMPLETE ($self) {
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

sub _ON_NO_DATA ( $self ) {
    $self->{sth}->{cols} = [];

    # store description in prepared sth
    if ( defined $self->{sth}->{id} && exists $self->{prepared_sth}->{ $self->{sth}->{id} } ) {
        $self->{prepared_sth}->{ $self->{sth}->{id} } = [];
    }

    return;
}

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

sub _ON_PORTAL_SUSPENDED ( $self ) {
    $self->{sth}->{portal_suspended} = 1;

    return;
}

sub _ON_COMMAND_COMPLETE ( $self, $dataref ) {

    # remove trailing "\x00"
    chop $dataref->$*;

    my @val = split /\s/sm, $dataref->$*;

    my $tag;

    if ( $val[0] eq 'INSERT' ) {
        $tag = {
            tag  => $val[0],
            oid  => $val[1],
            rows => $val[2],
        };
    }
    elsif ( $val[0] eq 'CREATE' ) {
        $tag = {
            tag  => $val[0],
            rows => 0,
        };
    }
    elsif ( $val[0] eq 'ALTER' ) {
        $tag = {
            tag  => $val[0],
            rows => 0,
        };
    }
    else {
        $tag = {
            tag  => $val[0],
            rows => $val[1],
        };
    }

    if ( exists $self->{sth}->{tag} ) {
        $self->{sth}->{tag}->{rows} += $tag->{rows};
    }
    else {
        $self->{sth}->{tag} = $tag;
    }

    return;
}

sub _ON_CLOSE_COMPLETE ( $self ) {
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

    $self->{h}->push_write($buf) if defined $buf;

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
        ( $query, $bind ) = $self->{handle}->prepare_query($query);

        $use_extended_query = defined $bind;
    }

    # query is plain text
    else {

        # convert "?" placeholders to postgres "$1" style
        my $i;

        $query =~ s/[?]/'$' . ++$i/smge;

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
        my $portal_id = $EMPTY;                         # uuid_v1mc_str;

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
                    if ( $param->[0] == $SQL_BYTEA ) {
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
                elsif ( is_plain_arrayref $param) {
                    $param_format_codes .= "\x00\x00";    # text

                    $param = $self->encode_array($param)->$*;
                }
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
    return $self->{handle}->prepare($query);
}

sub dbh ($self) { return $self }

# TODO
sub destroy_sth ( $self, $id ) {
    if ( exists $self->{prepared_sth}->{$id} ) {

        # TODO run command and delete after command complete
        # delete $self->{prepared_sth}->{$id};
    }

    return;
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

# key_field => [0, 1, 'id'], key_field => 'id'
sub selectall ( $self, $query, @args ) {
    my ( $bind, $args, $cb ) = _parse_args( \@args );

    my $on_finish = sub ( $sth, $res ) {
        my $guard = $self;    # keep reference to $self until query is finished

        if ( $res && defined $sth->{rows} ) {
            my @cols_names = map { $_->[0] } $sth->{cols}->@*;

            if ( defined $args->{key_field} ) {
                my $name2idx;

                # create columns index
                for ( my $i = 0; $i <= $sth->{cols}->$#*; $i++ ) {
                    $name2idx->{ $sth->{cols}->[$i]->[0] } = $i;
                }

                my $num_of_fields = $sth->{cols}->@*;
                my @key_field_idx;

                for my $key_field ( is_plain_arrayref $args->{key_field} ? $args->{key_field}->@* : $args->{key_field} ) {
                    if ( looks_like_number $key_field) {
                        if ( $key_field + 1 > $num_of_fields ) {
                            my $res = res [ 400, qq[Invalid field index "$key_field"] ];

                            warn $res;

                            return $cb ? $cb->($res) : $res;
                        }

                        push @key_field_idx, $key_field;
                    }
                    else {
                        my $idx = $name2idx->{$key_field};

                        if ( !defined $idx ) {
                            my $res = res [ 400, qq[DBI: Invalid field name "$key_field"] ];

                            warn $res;

                            return $cb ? $cb->($res) : $res;
                        }

                        push @key_field_idx, $idx;
                    }
                }

                my $data = {};

                for my $row ( $sth->{rows}->@* ) {
                    my $ref = $data;

                    $ref = $ref->{ $row->[$_] // $EMPTY } //= {} for @key_field_idx;

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
        return $cb ? $cb->( $self, $res ) : ( $self, $res );
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
    return $self->{handle}->quote_id($id);
}

sub quote ( $self, $var ) {
    return $self->{handle}->quote($var);
}

sub encode_array ( $self, $var ) {
    return $self->{handle}->encode_array($var);
}

sub encode_json ( $self, $var ) {
    return $self->{handle}->encode_json($var);
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 179                  | ControlStructures::ProhibitCascadingIfElse - Cascading if-elsif chain                                          |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 533                  | Subroutines::ProhibitExcessComplexity - Subroutine "_execute" with high complexity score (29)                  |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 623, 952             | ControlStructures::ProhibitDeepNests - Code structure is deeply nested                                         |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 761, 952             | ControlStructures::ProhibitCStyleForLoops - C-style "for" loop used                                            |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 800                  | ControlStructures::ProhibitPostfixControls - Postfix control "for" used                                        |
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

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
