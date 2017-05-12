# NAME

Net::OBEX - implementation of OBEX protocol

# SYNOPSIS

    use strict;
    use warnings;

    use Net::OBEX;

    my $obex = Net::OBEX->new;

    $obex->connect(
        address => '00:17:E3:37:76:BB',
        port    => 9,
        target  => 'F9EC7BC4953C11D2984E525400DC9E09', # OBEX FTP UUID
    ) or die "Failed to connect: " . $obex->error;

    $obex->success
        or die "Server no liky :( " . $obex->status;

    $obex->set_path
        or die "Error: " . $obex->error;

    $obex->success
        die "Server no liky :( " . $obex->status;

    # this is an OBEX FTP example, so we'll get the folder listing now
    my $response_ref = $obex->get( type => 'x-obex/folder-listing' )
        or die "Error: " . $obex->error;

    $obex->success
        or die "Server no liky :( " . $obes->status;

    print "This is folder listing XML: \n$response_ref->{body}\n";

    # send Disconnect packet with description header and close the socket
    $obex->close('No want you no moar');

# DESCRIPTION

__WARNING!!! This module is still in its early alpha stage, it is
recommended that you use it only for testing. A lot of functionality
is still not implemented.__

The module is a Perl implementation of IrOBEX protocol.

# CONSTRUCTOR

## new

    my $obex = Net::OBEX->new;

Takes no arguments, returns a freshly baked Net::OBEX object ready to
use and abuse.

# STATUS METHODS

## success

    $obex->success
        or die 'Error: (code: ' . $obex->code . ') ' . $obex->status;

Must be called after either `connect()`, `set_path()`, `get()` or
`put()` method. Returns either true or false value indicating whether
or not the call to last `connect()`, `set_path()`, `get()` or
`put()` method ended with a successful response from the server
(code 200). __Note:__ the aforementioned methods returning a non-error
(see descriptions below) does __NOT__ imply that `success()` will return
a true value.

## code

    $obex->success
        or die 'Error: (code: ' . $obex->code . ') ' . $obex->status;

Must be called after either `connect()`, `set_path()`, `get()` or
`put()` method. Returns the status code of the last response from the
server.

## status

    $obex->success
        or die 'Error: (code: ' . $obex->code . ') ' . $obex->status;

Must be called after either `connect()`, `set_path()`, `get()` or
`put()` method. Returns the status code description
of the last response from the server (i.e. "Ok, Success" if `code()`
is `200`)

# METHODS

## connect

    my $response_ref = $obex->connect(
        address => '00:17:E3:37:76:BB',
        port    => 9,
    ) or die "Failed to connect: " . $obex->error;

    $obex->connect(
        address => '00:17:E3:37:76:BB',
        port    => 9,
        version => "\x10",
        mtu     => 4096,
        domain  => 'bluetooth',
        type    => 'stream',
        proto   => 'rfcomm',
        headers => [ $some, $raw, $headers ],
    ) or die "Failed to connect: " . $obex->error;

Creates a new socket and connects it. Takes a bunch of arguments, two
of which (`address` and `port`) are mandatory. Net::OBEX uses
[Socket::Class](https://metacpan.org/pod/Socket::Class) as its "horse" but it _might_ be possible to use
a different socket if you want to (see `sock()` method). Returns a hashref
which is described below after arguments. Possible arguments are as follows:

### address

    ->connect( address => '00:17:E3:37:76:BB', ...

__Mandatory__. Specifies the MAC address of the device to connect to.

### port

    ->connect( port => 9, ...

__Mandatory__. Specifies the port of the device to connect to.

### version

    ->connect( version => "\x10", ...

__Optional__. Specifies the OBEX protocol version to use, takes a "version"
byte to use in the Connect packet encoded with the major number in the high
order 4 bits, and the minor version in the low order 4 bits. Generally
speaking you won't have to touch this one. __Defaults to:__ `0x10`
(version 1.0)

### mtu

    ->connect( mtu     => 4096, ...

__Optional__. Specifies the MTU of your device, i.e. the maximum length
of the packet in bytes it can accept. __Defaults to:__ `4096`

### domain

    ->connect( domain  => 'bluetooth', ...

__Optional__. Specifies the `domain` argument to pass to [Socket::Class](https://metacpan.org/pod/Socket::Class)
constructor. See documentation for [Socket::Class](https://metacpan.org/pod/Socket::Class) for more information.
__Defaults to:__ `bluetooth`

### type

    ->connect( type    => 'stream', ...

__Optional__. Specifies the `type` argument to pass to [Socket::Class](https://metacpan.org/pod/Socket::Class)
constructor. See documentation for [Socket::Class](https://metacpan.org/pod/Socket::Class) for more information.
__Defaults to:__ `stream`

### proto

    ->connect( proto   => 'rfcomm', ...

__Optional__. Specifies the `proto` argument to pass to [Socket::Class](https://metacpan.org/pod/Socket::Class)
constructor. See documentation for [Socket::Class](https://metacpan.org/pod/Socket::Class) for more information.
__Defaults to:__ `rfcomm`

### headers

    ->connect( headers => [ $some, $raw, $headers ], ...

__Optional__. If you want to pass along some additional packet headers
to the Connect packet you can use the `headers` argument which takes
an arrayref elements of which are OBEX packet headers. See
[Net::OBEX::Packet::Headers](https://metacpan.org/pod/Net::OBEX::Packet::Headers) for information on how to make them.
__Defaults to:__ `[]` (no headers)

### target

    ->connect( target => 'F9EC7BC4953C11D2984E525400DC9E09', ....

__Optional__. Since it's common that you will need a `Target` header
in the Connect packet you can use the `target` argument instead of
manually creating the header. __Note:__ the module will automatically
`pack()` what you specify in the `target` argument, so you can just use
the UUID (without dashes). __By default__ no `target` is specified.

### `connect` RETURN VALUE

    $VAR1 = {
        'info' => {
            'flags' => '00000000',
            'packet_length' => 31,
            'obex_version' => '00010000',
            'response_code' => 200,
            'headers_length' => 24,
            'response_code_meaning' => 'OK, Success',
            'mtu' => 5126
        },
        'headers' => {
            'connection_id' => '',
            'who' => '��{ĕ<ҘNRTܞ  '
        },
        'raw_packet' => '�J��{ĕ<ҘNRTܞ   �'
    };

If an error occurred during the request, `connect()` will return either
`undef` or an empty list, depending on the context and the reason
for the error will be available via `error()` method. Otherwise it will
return a hashref presented above. If the
dump above is not self explanatory see [Net::OBEX::Response](https://metacpan.org/pod/Net::OBEX::Response)
`parse_sock()` method description for the return value when
"is connect packet" option is true.

### SPECIAL NOTE ON CONNECTION ID HEADER

If the `Connection ID` header is present in the Connect response packet
the module will _save it_ and _automatically include it in any other
packet as the first header_ as per specification.
The raw generated `Connection ID` header which will be included in all other
packets is accessible via `connection_id()` accessor/mutator. If you
want to override the automatic inclusion of the header in all packets
set `connection_id('')` after the call to `connect()` but generally this
is a BadIdea(tm) and you probably will get a 403 on all the requests.

## disconnect

    my $response_ref = $obex->disconnect
        or die "Error: " . $obex->error;

    my $response_ref = $obex->disconnect(
        description => 'die in a fire!',
        headers     => [ $some, $other, $raw, $headers ],
    ) or die "Error: " . $obex->error;

Instructs the object to send a Disconnect packet without closing the socket
(whether it will actually stay open is another matter). If you want
to close the socket as well, you probably would want to use the
`close()` method instead. Takes two optional arguments:

### description

    $obex->disconnect( description => 'die in a fire!' );

__Optional__. Takes a scalar as an argument which will be passed in the
`Description` header in the Disconnect packet. __By default__ no
description is supplied.

### headers

    $obex->disconnect( headers => [ $some, $raw, $headers ] );

__Optional__. If you want to pass along some additional packet headers
to the Disconnect packet you can use the `headers` argument which takes
an arrayref elements of which are OBEX packet headers. See
[Net::OBEX::Packet::Headers](https://metacpan.org/pod/Net::OBEX::Packet::Headers) for information on how to make them.
__Defaults to:__ `[]` (no headers)

### `disconnect` RETURN VALUE

    $VAR1 = {
        'info' => {
            'packet_length' => 3,
            'response_code' => 200,
            'headers_length' => 0,
            'response_code_meaning' => 'OK, Success'
        },
        'raw_packet' => '�'
    };

If an error occurred during the request, `disconnect()` will return either
`undef` or an empty list, depending on the context and the reason
for the error will be available via `error()` method. Otherwise it will
return a hashref presented above. If the
dump above is not self explanatory see [Net::OBEX::Response](https://metacpan.org/pod/Net::OBEX::Response)
`parse_sock()` method description for the return value when
"is connect packet" option is false.

## set\_path

    my $response_ref = $obex->set_path
        or die "Error: " . $obex->error;

    my $response_ref = $obex->set_path(
        path    => 'there_somewhere',
        headers => [ $bunch, $of, $raw, $headers ],
    ) or die "Error: " . $obex->error;

Instructs the object to send a `SetPath` packet. Takes four optional
arguments which are as follows:

### path

    $obex->set_path( path => 'there_somewhere' );

__Optional__. Whatever you specify in the `path` argument will be sent
out in the packet's `Name` header, which is the path to change to.
__By default__ no path is set, meaning set path to "root folder".

### do\_up

    $obex->set_path( do_up => 1 );

__Optional__. Takes either true or false value, indicating whether or
not to set the "backup a level before applying name" flag in the SetPath
packet. __Defaults to:__ `0`

### no\_create

    $obex->set_path( no_create => 0 );

__Optional__. Takes either true or false value, indicating whether or not
to set the "don't create directory if it does not exist, return an
error instead." flag in the SetPath packet. __Defaults to:__ `1`

### headers

    $obex->set_path( headers => [ $some, $raw, $headers ] );

__Optional__. If you want to pass along some additional packet headers
to the SetPath packet you can use the `headers` argument which takes
an arrayref elements of which are OBEX packet headers. See
[Net::OBEX::Packet::Headers](https://metacpan.org/pod/Net::OBEX::Packet::Headers) for information on how to make them.
__Defaults to:__ `[]` (no headers)

### `set_path` RETURN VALUE

    $VAR1 = {
        'info' => {
            'packet_length' => 3,
            'response_code' => 200,
            'headers_length' => 0,
            'response_code_meaning' => 'OK, Success'
        },
        'raw_packet' => '�'
    };

If an error occurred during the request, `set_path()` will return either
`undef` or an empty list, depending on the context and the reason
for the error will be available via `error()` method. Otherwise it will
return a hashref presented above. If the
dump above is not self explanatory see [Net::OBEX::Response](https://metacpan.org/pod/Net::OBEX::Response)
`parse_sock()` method description for the return value when
"is connect packet" option is false.

## get

    $response_ref = $obex->get
        or die "Error: " . $obex->error;

    $response_ref = $obex->get(
        is_final    => 1,
        headers     => [ $bunch, $of, $raw, $headers ],
        type        => 'x-obex/folder-listing',
        name        => 'some_file',
        no_continue => 1,
        file        => $fh,
    ) or die "Error: " . $obex->error;

Instructs the object to send an OBEX Get packet and any number of
Get (Continue) packets needed to finish the request (by default). Takes
several arguments, all of which are optional. The possible arguments
are as follows:

### is\_final

    $obex->get( is_final => 1 );

__Optional__.  When set to a true value will instruct the object to set the
high bit of the Get packet on. When set to a false value will set the high
bit off. __Defaults to:__ `1`

### headers

    $obex->get( headers => [ $some, $raw, $headers ] );

__Optional__. If you want to pass along some additional packet headers
to the Get packet you can use the `headers` argument which takes
an arrayref elements of which are OBEX packet headers. See
[Net::OBEX::Packet::Headers](https://metacpan.org/pod/Net::OBEX::Packet::Headers) for information on how to make them.
__Defaults to:__ `[]` (no headers)

### type

    $obex->get( type => 'x-obex/folder-listing' );

__Optional__. Takes a scalar as value, whatever you specify will be
packed up into a OBEX `Type` header and shipped along with your Get packet.
__By default__ `type` is not specified.

### name

    $obex->get( name => 'some_file' );

__Optional__. Takes a scalar as value, whatever you specify will be
packed up into a OBEX `Name` header and shipped along with your Get packet.
__By default__ `name` is not specified.

### no\_continue

    $obex->get( no_continue => 1 );

__Optional__. By default the `get()` method will automatically send out
any Get (Continue) packets to get the entire data. However, if that's not
what you want set the `no_continue` to a true value. When set to a false
value will automatically send as many Get (Continue) packets as needed
to get the entire thing, when set to a true value will send only one
Get packet leaving the rest up to you. __Defaults to:__ `0`

### file

    $obex->get( file => $file_handle );

__Optional__. If you are retrieving large quantities of data it is probably
not a good idea to stuff all of it into a hashref. The `file` argument
takes an open file handle, and when specified will write the data into
that file instead of storing it in the return hashref. __By default__
fetched data will be returned in the return hashref.

### `get` RETURN VALUE

    $VAR1 = {
            'body' => '<?xml version="1.0" ?>
    <!DOCTYPE folder-listing SYSTEM "obex-folder-listing.dtd">
    <folder-listing>
    <parent-folder />
    <folder name="audio" size="0" type="folder" modified="19700101T000000Z" user-perm="RW" />
    <folder name="video" size="0" type="folder" modified="19700101T000000Z" user-perm="RW" />
    <folder name="picture" size="0" type="folder" modified="19700101T000000Z" user-perm="RW" />
    </folder-listing>
    ',
            'responses' => [
                            {
                                'info' => {
                                            'packet_length' => 6,
                                            'response_code' => 100,
                                            'headers_length' => 3,
                                            'response_code_meaning' => 'Continue'
                                        },
                                'headers' => {
                                                'body' => ''
                                            },
                                'raw_packet' => '�H'
                            },
                            {
                                'info' => {
                                            'packet_length' => 413,
                                            'response_code' => 100,
                                            'headers_length' => 410,
                                            'response_code_meaning' => 'Continue'
                                        },
                                'headers' => {
                                                'body' => '<?xml version="1.0" ?>
    <!DOCTYPE folder-listing SYSTEM "obex-folder-listing.dtd">
    <folder-listing>
    <parent-folder />
    <folder name="audio" size="0" type="folder" modified="19700101T000000Z" user-perm="RW" />
    <folder name="video" size="0" type="folder" modified="19700101T000000Z" user-perm="RW" />
    <folder name="picture" size="0" type="folder" modified="19700101T000000Z" user-perm="RW" />
    </folder-listing>
    '
                                            },
                                'raw_packet' => '��H�<?xml version="1.0" ?>
    <!DOCTYPE folder-listing SYSTEM "obex-folder-listing.dtd">
    <folder-listing>
    <parent-folder />
    <folder name="audio" size="0" type="folder" modified="19700101T000000Z" user-perm="RW" />
    <folder name="video" size="0" type="folder" modified="19700101T000000Z" user-perm="RW" />
    <folder name="picture" size="0" type="folder" modified="19700101T000000Z" user-perm="RW" />
    </folder-listing>
    '
                            },
                            {
                                'info' => {
                                            'packet_length' => 6,
                                            'response_code' => 200,
                                            'headers_length' => 3,
                                            'response_code_meaning' => 'OK, Success'
                                        },
                                'headers' => {
                                                'end_of_body' => ''
                                            },
                                'raw_packet' => '�I'
                            }
                            ],
            'response_code' => 100,
            'response_code_meaning' => 'Continue'
            };

The `get()` method returns either `undef` or an empty list (depending
on the context) if an error
occurred and the explanation of the error will by available via `error()`
method. Otherwise it returns a big hashref. As opposed to `connect()`,
`disconnect()` and `set_path()` method
the returned hashref from `get()` method is a bit different because
it can send (by default) several Get requests to fetch entire data. The
keys/values of the return are as follows:

#### body

The <body> key will contain the entire data that was retrieved (if
`no_continue` is false) or the contents of the `Body` header of the
packet (if `no_continue` is set to a true value). If `file` argument
is set, the `body` key will be empty.

#### response\_code

The `response_code` key will contain the response code of the _first_
received packet, note that if the request requires several Get packets
to be sent out, the response code will be `100` (Continue) not 200.

#### response\_code\_meaning

The `response_code_meaning` key will contain the meaning of the response
code of the _first_ received packet.

#### responses

The `responses` key will contain an arrayref elements of which will be
the return values of `parse_sock()` method from [Net::OBEX::Headers](https://metacpan.org/pod/Net::OBEX::Headers)
module. There will be as many elements as many Get packets were sent out
to retrieve entire data; of course, there will be only one if `no_continue`
argument to `get()` is set to a true value. For more information, see
`parse_sock()` method in [Net::OBEX::Headers](https://metacpan.org/pod/Net::OBEX::Headers) with the "is connect packet"
flag set to false. If `file` argument is set, `responses` arrayref
will be empty.

## put

    $obex->put( what => 'some_file' )
        or die $obex->error;

    my $response_ref = $obex->put(
        what          => 'some_file',
        body_in_first => 0,
        length        => 12312,
        no_name       => 1,
        name          => 'other_file',
        time          => '20080320T202020Z',
    ) or die $obex->error;

Instructs the object to send `PUT` packet. As of now only sending
of files is supported and due to the limited testing environment this
support may be broken. During my tests (with Motorolla KRZR phone)
doing `put` on files which it doesn't seem to allow (text file instead
of pictures) would end up with `200, OK Success` __BUT__ the file would
not be actually uploaded to the device and trying to `get()` it would
result in `404`. Not sure if this is a "glitch" with my phone or it is
the way it's supposed to be... silently giving OKs when things are failing.

The data to be sent will be split into packets
of the maximum size the other party can accept, if you want to change the
size call the `mtu()` method before calling `put()`.
The `put()` method takes one mandatory and several optional
arguments which are as follows:

### what

    $obex->put( what => 'some_file' );

__Mandatory__. Specifies the file name of the file to `PUT`, later this may
be changed to allow to contain some arbitrary contents.

### body\_in\_first

    $obex->put( what => 'some_file', body_in_first => 1 );

__Optional__. Takes either true or false values. If a true value is specified
will send a `Body` header in the first `PUT` packet. Otherwise
first `Body` header will be sent only after receiving a `Continue`
response from the party. __Defaults to:__ `0`

### length

    $obex->put( what => 'some_file', length => 31232 );

__Optional__. If specified will stuff the `PUT` packet with a `Length`
header containing the value of `length` argument (the length of the
contents to `PUT`), this header is optional and __by default__ will
not be sent.

### time

    $obex->put( what => 'some_file', time => '20080320T202020Z' );

__Optional__. If specified will stuff the `PUT` packet with a Unicode
version of `Time` header (date/time of last modification).
Local times should be represented in the format YYYYMMDDTHHMMSS and UTC
time in the format YYYYMMDDTHHMMSSZ. The letter `T` delimits the date from
the time. UTC time is identified by concatenating a `Z` to the end of the
sequence. __By default__ no `Time` headers will be sent.

### name

    $obex->put( what => 'some_file', name => 'other_file' );

__Optional__. If specified will insert a `Name` header into the `PUT`
packet with the value you specify. __By default__ the value of `what`
argument will be used __unless__ you set the `no_name` argument (see
below) to a true value.

### no\_name

    $obex->put( what => 'some_file', no_name => 1 );

__Optional__. By default the object will insert a `Name` header into the
packet with value being the name of the file specified in `what` argument.
If you want to prevent this set `no_name` argument to a true value.
__Note:__ the `Name` header __WILL__ be sent if you specify the `name`
argument irrelevant of the `no_name` argument's value. __Note 2:__
yo do __NOT__ have to specify the `no_name` argument if you specified the
`name` argument. __Defaults to:__ `0`

### headers

    $obex->put( what => 'file', headers => [ $some, $raw, $headers ] );

__Optional__. If you want to pass along some additional packet headers
to the SetPath packet you can use the `headers` argument which takes
an arrayref elements of which are OBEX packet headers. See
[Net::OBEX::Packet::Headers](https://metacpan.org/pod/Net::OBEX::Packet::Headers) for information on how to make them.
__Defaults to:__ `[]` (no headers)

### `put` RETURN VALUE

    $VAR1 = {
        'info' => {
            'packet_length' => 3,
            'response_code' => 200,
            'headers_length' => 0,
            'response_code_meaning' => 'OK, Success'
        },
        'raw_packet' => '�'
    };

If an error occurred during the request, `put()` will return either
`undef` or an empty list, depending on the context and the reason
for the error will be available via `error()` method. Otherwise it will
return a hashref presented above. If the
dump above is not self explanatory see [Net::OBEX::Response](https://metacpan.org/pod/Net::OBEX::Response)
`parse_sock()` method description for the return value when
"is connect packet" option is false.

## close

    $obex->close;

    $obex->close('No want you no moar');

Similar to `disconnect()` method, except this one also closes the socket.
Takes one optional argument which is the text to send out in the
`Description` header of the `Disconnect` packet. Always returns `1`.

## response

    my $last_response_ref = $obex->response;

Takes no arguments, returns the return value of the last successful
`get()`, `put()`, `set_path()`, `connect()` or `disconnect()` method.

## sock

    my $socket = $obex->sock;

    $obex->sock( $new_socket );

Returns a [Socket::Class](https://metacpan.org/pod/Socket::Class) object which is used by the module for
communications. Technically you can swap it out to the socket of your choice
by giving it as an argument (but should you? :) ).

## error

    my $response_ref = $obex->set_path
        or die "Error: " . $obex->error;

If any of the `connect()`, `disconnect()`, `set_path` or `get()` methods
fail they will return either undef or an empty list depending on the context
and the reason for the failure will be available via `error()` method.
Takes no arguments, returns a human readable error message.

## mtu

    my $server_mtu = $obex->mtu;

Takes no arguments, must be called after a successful call to `connect()`
returns the maximum size of the packet in bytes the device we connected
to can accept (as reported by the device in response to `Connect`).

## connection\_id

    my $raw_connection_id_header = $obex->connection_id;

If `Connection ID` header was present in the response to the `Connect`
packet when calling the `connect()` method the Net::OBEX object will
automatically store it and include it in any other packets sent after
connection (as per specs). The `connection_id()` method returns a
_raw Connection ID header_, it may take an argument which will override
the set header, but it's probably a BadIdea(tm).

## obj\_res

    my $net_obex_response_object = $obex->obj_res;

Takes no arguments, returns a [Net::OBEX::Response](https://metacpan.org/pod/Net::OBEX::Response) object used internally.

## obj\_head

    my $net_obex_packet_headers_object = $obex->obj_head;

Takes no arguments, returns a [Net::OBEX::Packet::Headers](https://metacpan.org/pod/Net::OBEX::Packet::Headers) object used
internally. You can use this object to create any additional headers you'd
want to include in `headers` arguments (where applicable).

## obj\_req

    my $net_obex_packet_request = $obex->obj_req;

Takes no arguments, returns a [Net::OBEX::Packet::Request](https://metacpan.org/pod/Net::OBEX::Packet::Request) object used
internally.

# EXAMPLES

The `examples` directory of this distribution contains `get.pl` and
`put.pl` scripts which work fine for me, note that you'll need to change
address/port as well as filenames for your device.

# REPOSITORY

Fork this module on GitHub:
[https://github.com/zoffixznet/Net-OBEX](https://github.com/zoffixznet/Net-OBEX)

# BUGS

To report bugs or request features, please use
[https://github.com/zoffixznet/Net-OBEX/issues](https://github.com/zoffixznet/Net-OBEX/issues)

If you can't access GitHub, you can email your request
to `bug-Net-OBEX at rt.cpan.org`

# AUTHOR

Zoffix Znet <zoffix at cpan.org>
([http://zoffix.com/](http://zoffix.com/), [http://haslayout.net/](http://haslayout.net/))

# LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the `LICENSE` file included in this distribution for complete
details.
