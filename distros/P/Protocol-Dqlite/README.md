# NAME

Protocol::Dqlite - [Dqlite](https://dqlite.io) in Perl

# SYNOPSIS

    use autodie;

    my $dqlite = Protocol::Dqlite->new();

    my $socket = IO::Socket::INET->new('127.0.0.1:9001') or die;

    syswrite $s, Protocol::Dqlite::handshake();

    # Register ourselves as a Dqlite client:
    syswrite $s, Protocol::Dqlite::request( Protocol::Dqlite::REQUEST_CLIENT, 0 );

    # Await the server’s acknowledgement:
    while (sysread $s, my $buf, 512) {
        my ($msg) = $dqlite->feed($buf);
        next if !$msg;

        last if $msg isa Protocol::Dqlite::Response::WELCOME;

        # An unexpected response. Better bail out …
        #
        require Data::Dumper;
        die Data::Dumper::Dumper($msg);
    }

… and now you can exchange messages as you wish.

# DESCRIPTION

This module implements message parsing and creation for
[Dqlite](https://dqlite.io) clients. To use this module you’ll need to
write the I/O logic yourself.

# CHARACTER ENCODING

Strings designated as “blob”s are _byte_ strings.

All other strings into & out of this module are _character_ strings.

Decode & encode accordingly.

# CONSTANTS

The following derive from the
[documentation of Dqlite’s wire protocol](https://dqlite.io/docs/protocol)
as well as
[protocol.h](https://github.com/canonical/dqlite/blob/master/src/protocol.h)
in Dqlite’s source code.

## Role Codes

`ROLE_VOTER`, `ROLE_STANDBY`, `ROLE_SPARE`

## Tuple Member Types

- Numbers: `TUPLE_INT64`, `TUPLE_FLOAT`
- Buffers: `TUPLE_STRING`, `TUPLE_BLOB`
- Time: `TUPLE_UNIXTIME`, `TUPLE_ISO8601`
- Other: `TUPLE_NULL`, `TUPLE_BOOLEAN`

## Request Message Types

- `REQUEST_LEADER` (0)
- `REQUEST_CLIENT` (1)
- `REQUEST_OPEN`      (3)
- `REQUEST_PREPARE`   (4)
- `REQUEST_EXEC`      (5)
- `REQUEST_QUERY`     (6)
- `REQUEST_FINALIZE`  (7)
- `REQUEST_EXEC_SQL`  (8)
- `REQUEST_QUERY_SQL` (9)
- `REQUEST_INTERRUPT` (10)
- `REQUEST_CONNECT`   (11)
- `REQUEST_ADD`       (12)
- `REQUEST_ASSIGN`    (13)
- `REQUEST_REMOVE`    (14)
- `REQUEST_DUMP`      (15)
- `REQUEST_CLUSTER`   (16)

## Other

- `handshake` - The string to send after establishing
a connection to the server.

# STATIC FUNCTIONS

## $bytes = request( $TYPE, @ARGUMENTS )

Returns a byte buffer of a Dqlite message. $TYPE is one of the
`REQUEST_*` constants listed above.

@ARGUMENTS are as Dqlite’s
[wire protocol documentation](https://dqlite.io/docs/protocol) indicates.
Dqlite tuples are expressed as type/value pairs.

Example:

    my $bytes = Protocol::Dqlite::request(
        Protocol::Dqlite::REQUEST_PREPARE,
        12,
        "SELECT ?, ?",
        Protocol::Dqlite::TUPLE_INT64 => 12345,
        Protocol::Dqlite::TUPLE_BLOB => "\x00\x01\x02",
    );

# METHODS

## $obj = _CLASS_->new()

Instantiates _CLASS_.

## @messages = _OBJ_->feed( $BYTES )

Give new input to _OBJ_. Returns any messages parsed out of $BYTES
as `Protocol::Dqlite::Response` instances.

# RESPONSE CLASSES

All of the below extend `Protocol::Dqlite::Response`.
They expose various accessors as documented below:

- `Protocol::Dqlite::Response::FAILURE`: `code()`, `message()`
- `Protocol::Dqlite::Response::SERVER`: `id()`, `address()`,
`role()`
- `Protocol::Dqlite::Response::WELCOME`: (none)
- `Protocol::Dqlite::Response::SERVERS`: `count()`, `id()`,
`address()`, `role()`; the latter 3 require an index argument, which
MUST be between 0 and (`count()` - 1), inclusive.
- `Protocol::Dqlite::Response::DB`: `id()`
- `Protocol::Dqlite::Response::STMT`: `database_id()`,
`statement_id()`, `params_count()`
- `Protocol::Dqlite::Response::RESULT`: `last_row_id()`,
`rows_count()`
- `Protocol::Dqlite::Response::ROWS`:
    - `is_final()`
    - `column_names()` - returns a list, or a count in scalar context
    - `rows_count()`
    - `row_types()`, `row_data()` - these need an index,
    max=(`rows_count()`-1)
- `Protocol::Dqlite::Response::EMPTY`: (none)
- `Protocol::Dqlite::Response::FILES`: `names()` (list/count) and
`content()` (takes an index)
