package Statistics::R::IO::Rserve;
# ABSTRACT: Supply object methods for Rserve communication
$Statistics::R::IO::Rserve::VERSION = '1.0001';
use 5.010;

use Class::Tiny::Antlers;

use Statistics::R::IO::REXPFactory;
use Statistics::R::IO::QapEncoding;

use Socket;
use IO::Socket::INET ();
use Scalar::Util qw(blessed looks_like_number openhandle);
use Carp;

use namespace::clean;


has fh => (
    is => 'ro',
    default => sub {
        my $self = shift;
        my $fh;
        if ($self->_usesocket) {
            socket($fh, PF_INET, SOCK_STREAM, getprotobyname('tcp')) ||
                croak "socket: $!";
            connect($fh, sockaddr_in($self->port, inet_aton($self->server))) ||
                croak "connect: $!";
            bless $fh, 'IO::Handle'
        }
        else {
            $fh = IO::Socket::INET->new(PeerAddr => $self->server,
                                        PeerPort => $self->port) or
                                            croak $!
        }
        $self->_set_autoclose(1) unless defined($self->_autoclose);
        my ($response, $rc) = '';
        while ($rc = $fh->read($response, 32 - length $response,
                               length $response)) {}
        croak $! unless defined $rc;

        croak "Unrecognized server ID" unless
            substr($response, 0, 12) eq 'Rsrv0103QAP1';
        $fh
    },
);

has server => (
    is => 'ro',
    default => 'localhost',
);

has port => (
    is => 'ro',
    default => 6311,
);


has _autoclose => (
    is => 'ro',
);


has _autoflush => (
    is => 'ro',
    default => sub {
        my $self = shift;
        $self->_usesocket ? 1 : 0
    },
);

has _usesocket => (
    is => 'ro',
    default => 0
);


use constant {
    CMD_login => 0x001, # "name\npwd" : -
    CMD_voidEval => 0x002, # string : -
    CMD_eval => 0x003, # string | encoded SEXP : encoded SEXP
    CMD_shutdown => 0x004, # [admin-pwd] : -

    # security/encryption - all since 1.7-0
    CMD_switch => 0x005, # string (protocol) : -
    CMD_keyReq => 0x006, # string (request) : bytestream (key)
    CMD_secLogin => 0x007, # bytestream (encrypted auth) : -
    CMD_OCcall => 0x00f, # SEXP : SEXP -- it is the only command
                         # supported in object-capability mode and it
                         # requires that the SEXP is a language
                         # construct with OC reference in the first
                         # position
    CMD_OCinit => 0x434f7352, # SEXP -- 'RsOC' - command sent from the
                              # server in OC mode with the packet of
                              # initial capabilities. file I/O
                              # routines. server may answe
    CMD_openFile => 0x010, # fn : -
    CMD_createFile => 0x011, # fn : -
    CMD_closeFile => 0x012, # - : -
    CMD_readFile => 0x013, # [int size] : data... ; if size not
                           # present, server is free to choose any
                           # value - usually it uses the size of its
                           # static buffer
    CMD_writeFile => 0x014, # data : -
    CMD_removeFile => 0x015, # fn : -

    # object manipulation
    CMD_setSEXP => 0x020, # string(name), REXP : -
    CMD_assignSEXP => 0x021, # string(name), REXP : - ; same as
                             # setSEXP except that the name is parsed

    # session management (since 0.4-0)
    CMD_detachSession => 0x030, # : session key
    CMD_detachedVoidEval => 0x031, # string : session key; doesn't
    CMD_attachSession => 0x032, # session key : -

    # control commands (since 0.6-0) - passed on to the master process */
    # Note: currently all control commands are asychronous, i.e. RESP_OK
    # indicates that the command was enqueued in the master pipe, but there
    # is no guarantee that it will be processed. Moreover non-forked
    # connections (e.g. the default debug setup) don't process any
    # control commands until the current client connection is closed so
    # the connection issuing the control command will never see its
    # result.
    CMD_ctrl => 0x40, # -- not a command - just a constant --
    CMD_ctrlEval => 0x42, # string : -
    CMD_ctrlSource => 0x45, # string : -
    CMD_ctrlShutdown => 0x44, # - : -

    # 'internal' commands (since 0.1-9)
    CMD_setBufferSize => 0x081, # [int sendBufSize] this commad allow
                                # clients to request bigger buffer
                                # sizes if large data is to be
                                # transported from Rserve to the
                                # client. (incoming buffer is resized
                                # automatically)
    CMD_setEncoding => 0x082, # string (one of "native","latin1","utf8") : -; since 0.5-3

    # special commands - the payload of packages with this mask does not contain defined parameters
    CMD_SPECIAL_MASK => 0xf0,
    CMD_serEval => 0xf5, # serialized eval - the packets are raw
                         # serialized data without data header
    CMD_serAssign => 0xf6, # serialized assign - serialized list with
                           # [[1]]=name, [[2]]=value
    CMD_serEEval => 0xf7, # serialized expression eval - like serEval
                          # with one additional evaluation round
};


sub BUILDARGS {
    my $class = shift;
    
    if ( scalar @_ == 0 ) {
        return { }
    } elsif ( scalar @_ == 1 ) {
        if ( ref $_[0] eq 'HASH' ) {
            my $args = { %{ $_[0] } };
            if (my $fh = $args->{fh}) {
                ($args->{server}, $args->{port}) = _fh_host_port($fh);
            }
            return $args
        } elsif (ref $_[0] eq '') {
            my $server = shift;
            return { server => $server }
        } else {
            my $fh = shift;
            my ($server, $port) = _fh_host_port($fh);
            return { fh => $fh,
                     server => $server,
                     port => $port,
                     _autoclose => 0,
                     _autoflush => ref($fh) eq 'GLOB' }
        }
    }
    elsif ( @_ % 2 ) {
        die "The new() method for $class expects a hash reference or a key/value list."
                . " You passed an odd number of arguments\n";
    }
    else {
        my $args = { @_ };
        if (my $fh = $args->{fh}) {
            ($args->{server}, $args->{port}) = _fh_host_port($fh);
        }
        return $args
    }
}


sub BUILD {
    my ($self, $args) = @_;

    # Required attribute types
    die "Attribute 'fh' must be an instance of IO::Handle or an open filehandle" if
        defined($args->{fh}) &&
        !((ref($args->{fh}) eq "GLOB" && Scalar::Util::openhandle($args->{fh})) ||
         (blessed($args->{fh}) && $args->{fh}->isa("IO::Handle")));
    die "Attribute 'server' must be scalar value" if
        exists($args->{server}) && (!defined($args->{server}) || ref($args->{server}));
    die "Attribute 'port' must be an integer" unless
        looks_like_number($self->port) && (int($self->port) == $self->port);
}


## Extracts host address and port from the given socket handle (either
## as an object or a "classic" socket)
sub _fh_host_port {
    my $fh = shift or return;
    if (ref($fh) eq 'GLOB') {
        my ($port, $host) = unpack_sockaddr_in(getpeername($fh)) or return;
        my $name = gethostbyaddr($host, AF_INET);
        return ($name // inet_ntoa($host), $port)
    } elsif (blessed($fh) && $fh->isa('IO::Socket')){
        return ($fh->peerhost, $fh->peerport)
    }
    return undef
}


## Private setter for autoclose used in the default handler of 'fh'
sub _set_autoclose {
    my $self = shift;
    $self->{_autoclose} = shift
}


sub eval {
    my ($self, $expr) = (shift, shift);

    # Encode $expr as DT_STRING
    my $parameter = pack('VZ*',
                         ((length($expr)+1) << 8) + 4,
                         $expr);

    my $data = $self->_send_command(CMD_eval, $parameter);

    my ($value, $state) = @{Statistics::R::IO::QapEncoding::decode($data)};
    croak 'Could not parse Rserve value' unless $state;
    croak 'Unread data remaining in the Rserve response' unless $state->eof;
    $value
}


sub ser_eval {
    my ($self, $rexp) = (shift, shift);
    
    ## simulate the request parameter as constructed by:
    ## > serialize(quote(parse(text="{$rexp}")[[1]]), NULL)
    my $parameter =
        "\x58\x0a\0\0\0\2\0\3\0\3\0\2\3\0\0\0\0\6\0\0\0\1\0\4\0" .
        "\x09\0\0\0\2\x5b\x5b\0\0\0\2\0\0\0\6\0\0\0\1\0\4\0\x09\0\0" .
        "\0\5\x70\x61\x72\x73\x65\0\0\4\2\0\0\0\1\0\4\0\x09\0\0\0\4\x74\x65" .
        "\x78\x74\0\0\0\x10\0\0\0\1\0\4\0\x09" .
        pack('N', length($rexp)+2) .
        "\x7b" . $rexp . "\x7d" .
        "\0\0\0\xfe\0\0\0\2\0\0\0\x0e\0\0\0\1\x3f\xf0\0\0\0\0\0\0" .
        "\0\0\0\xfe";
    ## request is:
    ## - command (0xf5, CMD_serEval,
    ##       means raw serialized data without data header)
    my $data = $self->_send_command(CMD_serEval, $parameter);
    
    my ($value, $state) = @{Statistics::R::IO::REXPFactory::unserialize($data)};
    croak 'Could not parse Rserve value' unless $state;
    croak 'Unread data remaining in the Rserve response' unless $state->eof;
    $value
}


sub get_file {
    my ($self, $remote, $local) = (shift, shift, shift);

    my $data = pack 'C*', @{$self->eval("readBin('$remote', what='raw', n=file.info('$remote')[['size']])")->to_pl};

    if ($local) {
        open my $local_file, '>:raw', $local or
            croak "Cannot open $!";
        
        print $local_file $data;
        
        close $local_file;
    }
    
    $data
}


use constant {
    CMD_RESP => 0x10000, # all responses have this flag set
    CMD_OOB => 0x20000, # out-of-band data - i.e. unsolicited messages
};

use constant {
    RESP_OK => (CMD_RESP|0x0001), # command succeeded; returned
                                  # parameters depend on the command
                                  # issued
    RESP_ERR => (CMD_RESP|0x0002), # command failed, check stats code
                                   # attached string may describe the
                                   # error
    OOB_SEND => (CMD_OOB | 0x1000), # OOB send - unsolicited SEXP sent
                                    # from the R instance to the
                                    # client. 12 LSB are reserved for
                                    # application-specific code
    OOB_MSG => (CMD_OOB | 0x2000), # OOB message - unsolicited message
                                   # sent from the R instance to the
                                   # client requiring a response. 12
                                   # LSB are reserved for
                                   # application-specific code
};


## Sends a request to Rserve and receives the response, checking for
## any errors.
## 
## Returns the data portion of the server response
sub _send_command {
    my ($self, $command, $parameters) = (shift, shift, shift || '');
    
    ## request is (byte order is low-endian):
    ## - command (4 bytes)
    ## - length of the message (low 32 bits)
    ## - offset of the data part (normally 0)
    ## - high 32 bits of the length of the message (0 if < 4GB)
    $self->fh->print(pack('V4', $command, length($parameters), 0, 0) .
                     $parameters);
    $self->fh->flush if $self->_autoflush;
    
    my $response = $self->_receive_response(16);
    ## Of the next four long-ints:
    ## - the first one is status and should be 65537 (bytes \1, \0, \1, \0)
    ## - the second one is length
    ## - the third and fourth are ??
    my ($status, $length) = unpack VV => substr($response, 0, 8);
    if ($status & CMD_RESP) {
        unless ($status == RESP_OK) {
            croak 'R server returned an error: ' . sprintf("0x%X", $status)
        }
    }
    elsif ($status & CMD_OOB) {
        croak 'OOB messages are not supported yet'
    }
    else {
        croak 'Unrecognized response type: ' . $status
    }
    
    $self->_receive_response($length)
}


sub _receive_response {
    my ($self, $length) = (shift, shift);
    
    my ($response, $offset, $rc) = ('', 0);
    while ($rc = $self->fh->read($response, $length - $offset, $offset)) {
        $offset += $rc;
        last if $length == $offset;
    }
    croak $! unless defined $rc;
    $response
}


sub close {
    my $self = shift;
    $self->fh->close
}


sub DEMOLISH {
    my $self = shift;
    $self->close if $self->_autoclose
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statistics::R::IO::Rserve - Supply object methods for Rserve communication

=head1 VERSION

version 1.0001

=head1 SYNOPSIS

    use Statistics::R::IO::Rserve;
    
    my $rserve = Statistics::R::IO::RDS->new('someserver');
    my $var = $rserve->eval('1+1');
    print $var->to_pl;
    $rserve->close;

=head1 DESCRIPTION

C<Statistics::R::IO::Rserve> provides an object-oriented interface to
communicate with the L<Rserve|http://www.rforge.net/Rserve/> binary R
server.

This allows Perl programs to access all facilities of R without the
need to have a local install of R or link to an R library.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new $server

The single-argument constructor can be invoked with a scalar
containing the host name of the Rserve server. The method will
immediately open a connection to the server using L<IO::Socket::INET>
and perform the initial steps prescribed by the protocol. The method
will raise an exception if the connection cannot be established or if
the remote host does not appear to run the correct version of Rserve.

=item new $handle

The single-argument constructor can be invoked with an instance of
L<IO::Handle> containing the connection to the Rserve server, which
becomes the 'fh' attribute. The caller is responsible for ensuring
that the connection is established and ready for submitting client
requests.

=item new ATTRIBUTE_HASH_OR_HASH_REF

The constructor's arguments can also be given as a hash or hash
reference, specifying values of the object attributes. The caller
passing the handle is responsible for ensuring that the connection is
established and ready for submitting client requests.

=item new

The no-argument constructor uses the default server name 'localhost'
and port 6311 and immediately opens a connection to the server using
L<IO::Socket::INET>, performing the initial steps prescribed by the
protocol. The method will raise an exception if the connection cannot
be established or if the remote host does not appear to run the
correct version of Rserve.

=back

=head2 ACCESSORS

=over

=item server

Name of the Rserve server.

=item port

Port of the Rserve server.

=item fh

A connection handle (stored as a reference to the L<IO::Handle>) to
the Rserve server.

=back

=head2 METHODS

=over

=item eval EXPR

Evaluates an R expression, given as text string in REXPR, on an
L<Rserve|http://www.rforge.net/Rserve/> server and returns its result
as a L<Statistics::R::REXP> object.

=item ser_eval EXPR

Evaluates an R expression, given as text string in REXPR, on an
L<Rserve|http://www.rforge.net/Rserve/> server and returns its result
as a L<Statistics::R::REXP> object. This method uses the CMD_serEval
Rserve command (code 0xf5), which is designated as "internal/special"
and "should not be used by clients". Consequently, it is not
recommended to use this method in a production environment, but only
to help debug cases where C<eval> isn't working as desired.

=item get_file REMOTE_NAME [, LOCAL_NAME]

Transfers a file named REMOTE_NAME from the Rserve server to the local
machine, copying it to LOCAL_NAME if it is specified. The file is
transferred in binary mode. Returns the contents of the file as a
scalar.

=item close

Closes the object's filehandle. This method is automatically invoked
when the object is destroyed if the connection was opened by the
constructor, but not if it was passed in as a pre-opened handle.

=back

=head1 BUGS AND LIMITATIONS

Instances of this class are intended to be immutable. Please do not
try to change their value or attributes.

There are no known bugs in this module. Please see
L<Statistics::R::IO> for bug reporting.

=head1 SUPPORT

See L<Statistics::R::IO> for support and contact information.

=for Pod::Coverage BUILDARGS BUILD DEMOLISH
=for Pod::Coverage CMD_OCcall CMD_OCinit CMD_OOB CMD_RESP CMD_SPECIAL_MASK CMD_assignSEXP
CMD_attachSession CMD_closeFile CMD_createFile CMD_ctrl CMD_ctrlEval
CMD_ctrlShutdown CMD_ctrlSource CMD_detachSession CMD_detachedVoidEval
CMD_eval CMD_keyReq CMD_login CMD_openFile CMD_readFile CMD_removeFile
CMD_secLogin CMD_serAssign CMD_serEEval CMD_serEval CMD_setBufferSize
CMD_setEncoding CMD_setSEXP CMD_shutdown CMD_switch CMD_voidEval
CMD_writeFile

=for Pod::Coverage OOB_MSG OOB_SEND
=for Pod::Coverage RESP_ERR RESP_OK

=head1 AUTHOR

Davor Cubranic <cubranic@stat.ubc.ca>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by University of British Columbia.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
