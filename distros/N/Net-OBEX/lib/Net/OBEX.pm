package Net::OBEX;

use warnings;
use strict;

our $VERSION = '1.001001'; # VERSION

use Carp;
use Socket::Class;
use IO::Handle;
use Net::OBEX::Packet::Request;
use Net::OBEX::Response;
use Net::OBEX::Packet::Headers;
use Devel::TakeHashArgs;

use base qw(Class::Data::Accessor);

__PACKAGE__->mk_classaccessors( qw(
        sock
        error
        mtu
        success
        code
        status
        connection_id
        obj_res
        obj_head
        obj_req
        response
    )
);

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    $self->obj_head( Net::OBEX::Packet::Headers->new );
    $self->obj_req(  Net::OBEX::Packet::Request->new );
    $self->obj_res(  Net::OBEX::Response->new        );

    return $self;
}

sub connect {
    my $self = shift;
    $self->$_(undef) for qw(success code status mtu);
    get_args_as_hash(\@_, \ my %args, {
            version => "\x10",
            mtu     => 4096,
            domain  => 'bluetooth',
            type    => 'stream',
            proto   => 'rfcomm',
            headers => [],
        },
        [ qw(address port) ],
    )
    or croak $@;

    my $sock = Socket::Class->new(
        'domain'        => $args{domain},
        'type'          => $args{type},
        'proto'         => $args{proto},
        'remote_addr'   => $args{address},
        'remote_port'   => $args{port},
    ) or return $self->_set_error(
        'Failed to create socket: ' . Socket::Class->error
    );

    $self->sock( $sock );

     defined $args{target}
        and push @{ $args{headers} },
             $self->obj_head->make( target => pack 'H*', $args{target} );

    my $connect_packet = $self->obj_req->make(
        packet  => 'connect',
        mtu     => $args{mtu},
        version => $args{version},
        headers => $args{headers},
    );
    $sock->send( $connect_packet );

    my $obj_response = $self->obj_res;
    my $response_ref = $obj_response->parse_sock( $sock, 'connect' )
        or return $self->_set_error( $obj_response->error );

    # make and save connection ID header.. we will need it in every
    # packet
    if ( defined (my $id = $response_ref->{headers}{connection_id}) ) {
        $self->connection_id(
            $self->obj_head->make( connection_id => $id )
        );
    }

    # save other party's MTU
    $self->mtu( $response_ref->{info}{mtu} || 255 );

    $response_ref->{info}{response_code} == 200
        and $self->success(1);

    $self->code( $response_ref->{info}{response_code} );
    $self->status( $response_ref->{info}{response_code_meaning} );

    return $self->response( $response_ref );
}

sub disconnect {
    my $self = shift;
    get_args_as_hash( \@_, \ my %args, { headers => [] } )
        or croak $@;

    # Connection ID must be the first header if it's present
    $self->_add_connection_id( $args{headers} );

    defined $args{description}
        and push @{ $args{headers} },
            $self->head->make( description => $args{description} );

    my $disconnect_packet = $self->obj_req->make(
        packet  => 'disconnect',
        headers => $args{headers},
    );

    my $sock = $self->sock;
    $sock->send( $disconnect_packet );

    my $obj_response = $self->obj_res;
    my $response_ref = $obj_response->parse_sock( $sock )
        or return $self->_set_error( $obj_response->error );

    return $self->response( $response_ref );
}

sub set_path {
    my $self = shift;
    $self->$_(undef) for qw(success code status);
    get_args_as_hash( \@_, \ my %args, { headers => [] } )
        or croak $@;

    # Connection ID must be the first header if it's present
    $self->_add_connection_id( $args{headers} );

    # the path to setpath to should go into Name header
    defined $args{path}
        and push @{ $args{headers} },
            $self->obj_head->make( name => $args{path} );

    my $set_path_packet = $self->obj_req->make(
        packet  => 'setpath',
        headers => $args{headers},
        (defined $args{do_up    } ? ( do_up     => $args{do_up    } ) : ()),
        (defined $args{no_create} ? ( no_create => $args{no_create} ) : ()),
    );

    my $sock = $self->sock;
    $sock->send( $set_path_packet );

    my $obj_response = $self->obj_res;
    my $response_ref = $obj_response->parse_sock( $sock )
        or return $self->_set_error( $obj_response->error );

    $response_ref->{info}{response_code} == 200
        and $self->success(1);

    $self->code( $response_ref->{info}{response_code} );
    $self->status( $response_ref->{info}{response_code_meaning} );

    return $self->response( $response_ref );
}

sub get {
    my $self = shift;
    $self->$_(undef) for qw(success code status);
    get_args_as_hash( \@_, \ my %args, { is_final => 1, headers => [] } )
        or croak $@;

    # Connection ID must be the first header if it's present
    $self->_add_connection_id( $args{headers} );

    my $head = $self->obj_head;
    for ( qw(type name ) ) {
        defined $args{ $_ }
            and push @{ $args{headers} }, $head->make( $_ => $args{ $_ } );
    }

    my $obj_request  = $self->obj_req;
    my $packet = $obj_request->make(
        packet   => 'get',
        is_final => $args{is_final},
        headers  => $args{headers},
    );

    my $sock = $self->sock;
    $sock->send( $packet );

    my @responses;
    my $obj_response = $self->obj_res;
    my $full_body = '';
    my $first_response_code;
    my $first_response_code_meaning;
    CONTINIUE_GET: {
        my $response_ref = $obj_response->parse_sock( $sock )
            or return $self->_set_error( $obj_response->error );

        unless ( defined $first_response_code ) {
            ( $first_response_code, $first_response_code_meaning )
            = @{ $response_ref->{info} }{
                qw(response_code  response_code_meaning)
            }
        }

        if ( exists $response_ref->{headers}{body}
            or exists $response_ref->{headers}{end_of_body}
        ) {
            my $body = exists $response_ref->{headers}{end_of_body}
                     ? $response_ref->{headers}{end_of_body}
                     : $response_ref->{headers}{body};

            if ( exists $args{file} ) {
                $args{file}->print($body);
            }
            else {
                $full_body .= $body;
                push @responses, $response_ref;
            }
        }

        # if server asks to "Continue"
        if ( $response_ref->{info}{response_code} == 100
            and not $args{no_continue}
        ) {
            $sock->send(
                $obj_request->make( packet => 'get', is_final => 1 )
            );

            redo CONTINIUE_GET;
        }

        unless (
            $response_ref->{info}{response_code} == 200
            or $response_ref->{info}{response_code} == 100
        ) {
            $self->status(
                $response_ref->{info}{response_code_meaning}
            );
            $self->code( $response_ref->{info}{response_code} );
            $response_ref->{is_error} = 1;
            return $response_ref;
        }
    } # CONTINUTE_GET block end

    $first_response_code == 200 or $first_response_code == 100
        and $self->success(1);

    $self->code( $first_response_code );
    $self->status( $first_response_code_meaning );

    return $self->response( {
            body            => $full_body,
            responses       => \@responses,
            response_code   => $first_response_code,
            response_code_meaning => $first_response_code_meaning,
        }
    );
}

sub put {
    my $self = shift;
    $self->$_(undef) for qw(success code status);
    get_args_as_hash( \@_, \ my %args, {
            headers         => [],
            body_in_first   => 0,
            no_name         => 0,
        },
        [ 'what' ],
    ) or croak $@;

    # Connection ID must be the first header if it's present
    $self->_add_connection_id( $args{headers} );

    my $head = $self->obj_head;
    for ( qw(length time name type) ) {
        exists $args{ $_ }
            and push @{ $args{headers} }, $head->make( $_, $args{$_} );
    }

    unless ( $args{no_name} or exists $args{name} ) {
        push @{ $args{headers} }, $head->make( name => $args{what} );
    }

    open my $fh, '<', $args{what}
        or return $self->_set_error("Failed to open $args{what} ($!)");

    binmode $fh;

    my $mtu = $self->mtu - 2 - length join '', @{ $args{headers} };

    my $sock = $self->sock;
    my $obj_res = $self->obj_res;
    my $obj_req = $self->obj_req;
    unless ( $args{body_in_first} ) {
        my $packet = $obj_req->make(
            packet  => 'put',
            headers => $args{headers},
        );

        $sock->send( $packet );
        my $response_ref = $obj_res->parse_sock( $sock )
            or return $self->_set_error(
                'Socket error: ' . $obj_res->error
            );

        unless (
            $response_ref->{info}{response_code} == 200
            or $response_ref->{info}{response_code} == 100
        ) {
            $self->status(
                $response_ref->{info}{response_code_meaning}
            );
            $self->code( $response_ref->{info}{response_code} );
            return $response_ref;
        }
    }

    {
        local $/ = \$mtu;
        while ( <$fh> ) {

            my $packet = $obj_req->make(
                packet  => 'put',
                headers => [
                    ( $args{body_in_first} ? () : @{ $args{headers} } ),
                    $head->make( body => $_ ),
                ],
            );
            $sock->send( $packet );
            my $response_ref = $obj_res->parse_sock( $sock )
                or return $self->_set_error(
                    'Socket error: ' . $obj_res->error
                );

            unless (
                $response_ref->{info}{response_code} == 200
                or $response_ref->{info}{response_code} == 100
            ) {
                $self->status(
                    $response_ref->{info}{response_code_meaning}
                );
                $self->code( $response_ref->{info}{response_code} );
                $response_ref->{is_error} = 1;
                return $response_ref;
            }
        }
        my $packet = $obj_req->make(
            packet   => 'put',
            is_final => 1,
            headers => [
                @{ $args{headers} },
                $head->make( end_of_body => '' ),
            ],
        );

        $sock->send( $packet );
        my $response_ref = $obj_res->parse_sock( $sock );
        $response_ref->{info}{response_code} == 200
            and $self->success(1);

        $self->code( $response_ref->{info}{response_code} );
        $self->status( $response_ref->{info}{response_code_meaning} );
        return $self->response( $response_ref );
    }
}

sub close {
    my ( $self, $description ) = @_;

    my $sock = $self->sock;
    eval {
        my $disconnect_packet = $self->obj_req->make(
            packet  => 'disconnect',
            headers => [
                defined $description
                ? $self->obj_head->make( description => $description )
                : ()
            ],
        );

        $sock->send( $disconnect_packet );
    };
    $sock->free();

    return 1;
}

sub _add_connection_id {
    my ( $self, $headers_ref ) = @_;
    if ( defined ( my $id = $self->connection_id ) ) {
        unshift @$headers_ref, $id;
    }
}

sub _set_error {
    my ( $self, $error ) = @_;
    $self->error( $error );
    return;
}

1;
__END__

=encoding utf8

=for stopwords AnnoCPAN IrOBEX KRZR MTU Motorolla RT YYYYMMDDTHHMMSS YYYYMMDDTHHMMSSZ mtu proto

=head1 NAME

Net::OBEX - implementation of OBEX protocol

=head1 SYNOPSIS

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

=head1 DESCRIPTION

B<WARNING!!! This module is still in its early alpha stage, it is
recommended that you use it only for testing. A lot of functionality
is still not implemented.>

The module is a Perl implementation of IrOBEX protocol.

=head1 CONSTRUCTOR

=head2 new

    my $obex = Net::OBEX->new;

Takes no arguments, returns a freshly baked Net::OBEX object ready to
use and abuse.

=head1 STATUS METHODS

=head2 success

    $obex->success
        or die 'Error: (code: ' . $obex->code . ') ' . $obex->status;

Must be called after either C<connect()>, C<set_path()>, C<get()> or
C<put()> method. Returns either true or false value indicating whether
or not the call to last C<connect()>, C<set_path()>, C<get()> or
C<put()> method ended with a successful response from the server
(code 200). B<Note:> the aforementioned methods returning a non-error
(see descriptions below) does B<NOT> imply that C<success()> will return
a true value.

=head2 code

    $obex->success
        or die 'Error: (code: ' . $obex->code . ') ' . $obex->status;

Must be called after either C<connect()>, C<set_path()>, C<get()> or
C<put()> method. Returns the status code of the last response from the
server.

=head2 status

    $obex->success
        or die 'Error: (code: ' . $obex->code . ') ' . $obex->status;

Must be called after either C<connect()>, C<set_path()>, C<get()> or
C<put()> method. Returns the status code description
of the last response from the server (i.e. "Ok, Success" if C<code()>
is C<200>)

=head1 METHODS

=head2 connect

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
of which (C<address> and C<port>) are mandatory. Net::OBEX uses
L<Socket::Class> as its "horse" but it I<might> be possible to use
a different socket if you want to (see C<sock()> method). Returns a hashref
which is described below after arguments. Possible arguments are as follows:

=head3 address

    ->connect( address => '00:17:E3:37:76:BB', ...

B<Mandatory>. Specifies the MAC address of the device to connect to.

=head3 port

    ->connect( port => 9, ...

B<Mandatory>. Specifies the port of the device to connect to.

=head3 version

    ->connect( version => "\x10", ...

B<Optional>. Specifies the OBEX protocol version to use, takes a "version"
byte to use in the Connect packet encoded with the major number in the high
order 4 bits, and the minor version in the low order 4 bits. Generally
speaking you won't have to touch this one. B<Defaults to:> C<0x10>
(version 1.0)

=head3 mtu

    ->connect( mtu     => 4096, ...

B<Optional>. Specifies the MTU of your device, i.e. the maximum length
of the packet in bytes it can accept. B<Defaults to:> C<4096>

=head3 domain

    ->connect( domain  => 'bluetooth', ...

B<Optional>. Specifies the C<domain> argument to pass to L<Socket::Class>
constructor. See documentation for L<Socket::Class> for more information.
B<Defaults to:> C<bluetooth>

=head3 type

    ->connect( type    => 'stream', ...

B<Optional>. Specifies the C<type> argument to pass to L<Socket::Class>
constructor. See documentation for L<Socket::Class> for more information.
B<Defaults to:> C<stream>

=head3 proto

    ->connect( proto   => 'rfcomm', ...

B<Optional>. Specifies the C<proto> argument to pass to L<Socket::Class>
constructor. See documentation for L<Socket::Class> for more information.
B<Defaults to:> C<rfcomm>

=head3 headers

    ->connect( headers => [ $some, $raw, $headers ], ...

B<Optional>. If you want to pass along some additional packet headers
to the Connect packet you can use the C<headers> argument which takes
an arrayref elements of which are OBEX packet headers. See
L<Net::OBEX::Packet::Headers> for information on how to make them.
B<Defaults to:> C<[]> (no headers)

=head3 target

    ->connect( target => 'F9EC7BC4953C11D2984E525400DC9E09', ....

B<Optional>. Since it's common that you will need a C<Target> header
in the Connect packet you can use the C<target> argument instead of
manually creating the header. B<Note:> the module will automatically
C<pack()> what you specify in the C<target> argument, so you can just use
the UUID (without dashes). B<By default> no C<target> is specified.

=head3 C<connect> RETURN VALUE

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

If an error occurred during the request, C<connect()> will return either
C<undef> or an empty list, depending on the context and the reason
for the error will be available via C<error()> method. Otherwise it will
return a hashref presented above. If the
dump above is not self explanatory see L<Net::OBEX::Response>
C<parse_sock()> method description for the return value when
"is connect packet" option is true.

=head3 SPECIAL NOTE ON CONNECTION ID HEADER

If the C<Connection ID> header is present in the Connect response packet
the module will I<save it> and I<automatically include it in any other
packet as the first header> as per specification.
The raw generated C<Connection ID> header which will be included in all other
packets is accessible via C<connection_id()> accessor/mutator. If you
want to override the automatic inclusion of the header in all packets
set C<connection_id('')> after the call to C<connect()> but generally this
is a BadIdea(tm) and you probably will get a 403 on all the requests.

=head2 disconnect

    my $response_ref = $obex->disconnect
        or die "Error: " . $obex->error;

    my $response_ref = $obex->disconnect(
        description => 'die in a fire!',
        headers     => [ $some, $other, $raw, $headers ],
    ) or die "Error: " . $obex->error;

Instructs the object to send a Disconnect packet without closing the socket
(whether it will actually stay open is another matter). If you want
to close the socket as well, you probably would want to use the
C<close()> method instead. Takes two optional arguments:

=head3 description

    $obex->disconnect( description => 'die in a fire!' );

B<Optional>. Takes a scalar as an argument which will be passed in the
C<Description> header in the Disconnect packet. B<By default> no
description is supplied.

=head3 headers

    $obex->disconnect( headers => [ $some, $raw, $headers ] );

B<Optional>. If you want to pass along some additional packet headers
to the Disconnect packet you can use the C<headers> argument which takes
an arrayref elements of which are OBEX packet headers. See
L<Net::OBEX::Packet::Headers> for information on how to make them.
B<Defaults to:> C<[]> (no headers)

=head3 C<disconnect> RETURN VALUE

    $VAR1 = {
        'info' => {
            'packet_length' => 3,
            'response_code' => 200,
            'headers_length' => 0,
            'response_code_meaning' => 'OK, Success'
        },
        'raw_packet' => '�'
    };

If an error occurred during the request, C<disconnect()> will return either
C<undef> or an empty list, depending on the context and the reason
for the error will be available via C<error()> method. Otherwise it will
return a hashref presented above. If the
dump above is not self explanatory see L<Net::OBEX::Response>
C<parse_sock()> method description for the return value when
"is connect packet" option is false.

=head2 set_path

    my $response_ref = $obex->set_path
        or die "Error: " . $obex->error;

    my $response_ref = $obex->set_path(
        path    => 'there_somewhere',
        headers => [ $bunch, $of, $raw, $headers ],
    ) or die "Error: " . $obex->error;

Instructs the object to send a C<SetPath> packet. Takes four optional
arguments which are as follows:

=head3 path

    $obex->set_path( path => 'there_somewhere' );

B<Optional>. Whatever you specify in the C<path> argument will be sent
out in the packet's C<Name> header, which is the path to change to.
B<By default> no path is set, meaning set path to "root folder".

=head3 do_up

    $obex->set_path( do_up => 1 );

B<Optional>. Takes either true or false value, indicating whether or
not to set the "backup a level before applying name" flag in the SetPath
packet. B<Defaults to:> C<0>

=head3 no_create

    $obex->set_path( no_create => 0 );

B<Optional>. Takes either true or false value, indicating whether or not
to set the "don't create directory if it does not exist, return an
error instead." flag in the SetPath packet. B<Defaults to:> C<1>

=head3 headers

    $obex->set_path( headers => [ $some, $raw, $headers ] );

B<Optional>. If you want to pass along some additional packet headers
to the SetPath packet you can use the C<headers> argument which takes
an arrayref elements of which are OBEX packet headers. See
L<Net::OBEX::Packet::Headers> for information on how to make them.
B<Defaults to:> C<[]> (no headers)

=head3 C<set_path> RETURN VALUE

    $VAR1 = {
        'info' => {
            'packet_length' => 3,
            'response_code' => 200,
            'headers_length' => 0,
            'response_code_meaning' => 'OK, Success'
        },
        'raw_packet' => '�'
    };

If an error occurred during the request, C<set_path()> will return either
C<undef> or an empty list, depending on the context and the reason
for the error will be available via C<error()> method. Otherwise it will
return a hashref presented above. If the
dump above is not self explanatory see L<Net::OBEX::Response>
C<parse_sock()> method description for the return value when
"is connect packet" option is false.

=head2 get

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

=head3 is_final

    $obex->get( is_final => 1 );

B<Optional>.  When set to a true value will instruct the object to set the
high bit of the Get packet on. When set to a false value will set the high
bit off. B<Defaults to:> C<1>

=head3 headers

    $obex->get( headers => [ $some, $raw, $headers ] );

B<Optional>. If you want to pass along some additional packet headers
to the Get packet you can use the C<headers> argument which takes
an arrayref elements of which are OBEX packet headers. See
L<Net::OBEX::Packet::Headers> for information on how to make them.
B<Defaults to:> C<[]> (no headers)

=head3 type

    $obex->get( type => 'x-obex/folder-listing' );

B<Optional>. Takes a scalar as value, whatever you specify will be
packed up into a OBEX C<Type> header and shipped along with your Get packet.
B<By default> C<type> is not specified.

=head3 name

    $obex->get( name => 'some_file' );

B<Optional>. Takes a scalar as value, whatever you specify will be
packed up into a OBEX C<Name> header and shipped along with your Get packet.
B<By default> C<name> is not specified.

=head3 no_continue

    $obex->get( no_continue => 1 );

B<Optional>. By default the C<get()> method will automatically send out
any Get (Continue) packets to get the entire data. However, if that's not
what you want set the C<no_continue> to a true value. When set to a false
value will automatically send as many Get (Continue) packets as needed
to get the entire thing, when set to a true value will send only one
Get packet leaving the rest up to you. B<Defaults to:> C<0>

=head3 file

    $obex->get( file => $file_handle );

B<Optional>. If you are retrieving large quantities of data it is probably
not a good idea to stuff all of it into a hashref. The C<file> argument
takes an open file handle, and when specified will write the data into
that file instead of storing it in the return hashref. B<By default>
fetched data will be returned in the return hashref.

=head3 C<get> RETURN VALUE

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

The C<get()> method returns either C<undef> or an empty list (depending
on the context) if an error
occurred and the explanation of the error will by available via C<error()>
method. Otherwise it returns a big hashref. As opposed to C<connect()>,
C<disconnect()> and C<set_path()> method
the returned hashref from C<get()> method is a bit different because
it can send (by default) several Get requests to fetch entire data. The
keys/values of the return are as follows:

=head4 body

The <body> key will contain the entire data that was retrieved (if
C<no_continue> is false) or the contents of the C<Body> header of the
packet (if C<no_continue> is set to a true value). If C<file> argument
is set, the C<body> key will be empty.

=head4 response_code

The C<response_code> key will contain the response code of the I<first>
received packet, note that if the request requires several Get packets
to be sent out, the response code will be C<100> (Continue) not 200.

=head4 response_code_meaning

The C<response_code_meaning> key will contain the meaning of the response
code of the I<first> received packet.

=head4 responses

The C<responses> key will contain an arrayref elements of which will be
the return values of C<parse_sock()> method from L<Net::OBEX::Headers>
module. There will be as many elements as many Get packets were sent out
to retrieve entire data; of course, there will be only one if C<no_continue>
argument to C<get()> is set to a true value. For more information, see
C<parse_sock()> method in L<Net::OBEX::Headers> with the "is connect packet"
flag set to false. If C<file> argument is set, C<responses> arrayref
will be empty.

=head2 put

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

Instructs the object to send C<PUT> packet. As of now only sending
of files is supported and due to the limited testing environment this
support may be broken. During my tests (with Motorolla KRZR phone)
doing C<put> on files which it doesn't seem to allow (text file instead
of pictures) would end up with C<200, OK Success> B<BUT> the file would
not be actually uploaded to the device and trying to C<get()> it would
result in C<404>. Not sure if this is a "glitch" with my phone or it is
the way it's supposed to be... silently giving OKs when things are failing.

The data to be sent will be split into packets
of the maximum size the other party can accept, if you want to change the
size call the C<mtu()> method before calling C<put()>.
The C<put()> method takes one mandatory and several optional
arguments which are as follows:

=head3 what

    $obex->put( what => 'some_file' );

B<Mandatory>. Specifies the file name of the file to C<PUT>, later this may
be changed to allow to contain some arbitrary contents.

=head3 body_in_first

    $obex->put( what => 'some_file', body_in_first => 1 );

B<Optional>. Takes either true or false values. If a true value is specified
will send a C<Body> header in the first C<PUT> packet. Otherwise
first C<Body> header will be sent only after receiving a C<Continue>
response from the party. B<Defaults to:> C<0>

=head3 length

    $obex->put( what => 'some_file', length => 31232 );

B<Optional>. If specified will stuff the C<PUT> packet with a C<Length>
header containing the value of C<length> argument (the length of the
contents to C<PUT>), this header is optional and B<by default> will
not be sent.

=head3 time

    $obex->put( what => 'some_file', time => '20080320T202020Z' );

B<Optional>. If specified will stuff the C<PUT> packet with a Unicode
version of C<Time> header (date/time of last modification).
Local times should be represented in the format YYYYMMDDTHHMMSS and UTC
time in the format YYYYMMDDTHHMMSSZ. The letter C<T> delimits the date from
the time. UTC time is identified by concatenating a C<Z> to the end of the
sequence. B<By default> no C<Time> headers will be sent.

=head3 name

    $obex->put( what => 'some_file', name => 'other_file' );

B<Optional>. If specified will insert a C<Name> header into the C<PUT>
packet with the value you specify. B<By default> the value of C<what>
argument will be used B<unless> you set the C<no_name> argument (see
below) to a true value.

=head3 no_name

    $obex->put( what => 'some_file', no_name => 1 );

B<Optional>. By default the object will insert a C<Name> header into the
packet with value being the name of the file specified in C<what> argument.
If you want to prevent this set C<no_name> argument to a true value.
B<Note:> the C<Name> header B<WILL> be sent if you specify the C<name>
argument irrelevant of the C<no_name> argument's value. B<Note 2:>
yo do B<NOT> have to specify the C<no_name> argument if you specified the
C<name> argument. B<Defaults to:> C<0>

=head3 headers

    $obex->put( what => 'file', headers => [ $some, $raw, $headers ] );

B<Optional>. If you want to pass along some additional packet headers
to the SetPath packet you can use the C<headers> argument which takes
an arrayref elements of which are OBEX packet headers. See
L<Net::OBEX::Packet::Headers> for information on how to make them.
B<Defaults to:> C<[]> (no headers)

=head3 C<put> RETURN VALUE

    $VAR1 = {
        'info' => {
            'packet_length' => 3,
            'response_code' => 200,
            'headers_length' => 0,
            'response_code_meaning' => 'OK, Success'
        },
        'raw_packet' => '�'
    };

If an error occurred during the request, C<put()> will return either
C<undef> or an empty list, depending on the context and the reason
for the error will be available via C<error()> method. Otherwise it will
return a hashref presented above. If the
dump above is not self explanatory see L<Net::OBEX::Response>
C<parse_sock()> method description for the return value when
"is connect packet" option is false.

=head2 close

    $obex->close;

    $obex->close('No want you no moar');

Similar to C<disconnect()> method, except this one also closes the socket.
Takes one optional argument which is the text to send out in the
C<Description> header of the C<Disconnect> packet. Always returns C<1>.

=head2 response

    my $last_response_ref = $obex->response;

Takes no arguments, returns the return value of the last successful
C<get()>, C<put()>, C<set_path()>, C<connect()> or C<disconnect()> method.

=head2 sock

    my $socket = $obex->sock;

    $obex->sock( $new_socket );

Returns a L<Socket::Class> object which is used by the module for
communications. Technically you can swap it out to the socket of your choice
by giving it as an argument (but should you? :) ).

=head2 error

    my $response_ref = $obex->set_path
        or die "Error: " . $obex->error;

If any of the C<connect()>, C<disconnect()>, C<set_path> or C<get()> methods
fail they will return either undef or an empty list depending on the context
and the reason for the failure will be available via C<error()> method.
Takes no arguments, returns a human readable error message.

=head2 mtu

    my $server_mtu = $obex->mtu;

Takes no arguments, must be called after a successful call to C<connect()>
returns the maximum size of the packet in bytes the device we connected
to can accept (as reported by the device in response to C<Connect>).

=head2 connection_id

    my $raw_connection_id_header = $obex->connection_id;

If C<Connection ID> header was present in the response to the C<Connect>
packet when calling the C<connect()> method the Net::OBEX object will
automatically store it and include it in any other packets sent after
connection (as per specs). The C<connection_id()> method returns a
I<raw Connection ID header>, it may take an argument which will override
the set header, but it's probably a BadIdea(tm).

=head2 obj_res

    my $net_obex_response_object = $obex->obj_res;

Takes no arguments, returns a L<Net::OBEX::Response> object used internally.

=head2 obj_head

    my $net_obex_packet_headers_object = $obex->obj_head;

Takes no arguments, returns a L<Net::OBEX::Packet::Headers> object used
internally. You can use this object to create any additional headers you'd
want to include in C<headers> arguments (where applicable).

=head2 obj_req

    my $net_obex_packet_request = $obex->obj_req;

Takes no arguments, returns a L<Net::OBEX::Packet::Request> object used
internally.

=head1 EXAMPLES

The C<examples> directory of this distribution contains C<get.pl> and
C<put.pl> scripts which work fine for me, note that you'll need to change
address/port as well as filenames for your device.

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/Net-OBEX>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/Net-OBEX/issues>

If you can't access GitHub, you can email your request
to C<bug-Net-OBEX at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut