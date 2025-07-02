package Net::EPP::Server;
# ABSTRACT: A simple EPP server implementation.
use Carp;
use Crypt::OpenSSL::Random;
use Cwd qw(abs_path);
use DateTime;
use Digest::SHA qw(sha512_hex);
use File::Path qw(make_path);
use File::Spec;
use File::Slurp qw(write_file);
use IO::Socket::SSL;
use List::Util qw(any none);
use Mozilla::CA;
use Net::EPP 0.27;
use Net::EPP::Frame;
use Net::EPP::Protocol;
use Net::EPP::ResponseCodes;
use No::Worries::DN qw(dn_parse);
use Socket;
use Socket6;
use Sys::Hostname;
use Time::HiRes qw(ualarm);
use XML::LibXML;
use base qw(Net::Server::PreFork);
use bytes;
use utf8;
use open qw(:encoding(utf8));
use feature qw(say state);
use vars qw($VERSION %MESSAGES $HELLO);
use strict;
use warnings;

our $VERSION = '0.10';

our %MESSAGES = (
    1000 => 'Command completed successfully.',
    1001 => 'Command completed successfully; action pending.',
    1300 => 'Command completed successfully; no messages.',
    1301 => 'Command completed successfully; ack to dequeue.',
    1500 => 'Command completed successfully; ending session.',
    2000 => 'Unknown command.',
    2001 => 'Command syntax error.',
    2002 => 'Command use error.',
    2003 => 'Required parameter missing.',
    2004 => 'Parameter value range error.',
    2005 => 'Parameter value syntax error.',
    2100 => 'Unimplemented protocol version.',
    2101 => 'Unimplemented command.',
    2102 => 'Unimplemented option.',
    2103 => 'Unimplemented extension.',
    2104 => 'Billing failure.',
    2105 => 'Object is not eligible for renewal.',
    2106 => 'Object is not eligible for transfer.',
    2200 => 'Authentication error.',
    2201 => 'Authorization error.',
    2202 => 'Invalid authorization information.',
    2300 => 'Object pending transfer.',
    2301 => 'Object not pending transfer.',
    2302 => 'Object exists.',
    2303 => 'Object does not exist.',
    2304 => 'Object status prohibits operation.',
    2305 => 'Object association prohibits operation.',
    2306 => 'Parameter value policy error.',
    2307 => 'Unimplemented object service.',
    2308 => 'Data management policy violation.',
    2400 => 'Command failed.',
    2500 => 'Command failed; server closing connection.',
    2501 => 'Authentication error; server closing connection.',
    2502 => 'Session limit exceeded; server closing connection.',
);

$HELLO = XML::LibXML::Document->new;
$HELLO->setDocumentElement($HELLO->createElementNS($Net::EPP::Frame::EPP_URN, 'epp'));
$HELLO->documentElement->appendChild($HELLO->createElement('hello'));


sub new {
    my $package = shift;

    return bless($package->SUPER::new, $package);
}


sub run {
    my ($self, %args) = @_;

    $args{'host'}   ||= 'localhost';
    $args{'port'}   ||= 7000;
    $args{'proto'}  ||= 'ssl';

    $self->{'epp'} = {
        'handlers'          => delete($args{'handlers'}) || {},
        'timeout'           => delete($args{'timeout'})  || 30,
        'client_ca_file'    => delete($args{'client_ca_file'}),
        'xsd_file'          => delete($args{'xsd_file'}),
        'log_dir'           => delete($args{'log_dir'}),
    };

    if ($self->{'epp'}->{'client_ca_file'}) {
        $args{'SSL_verify_mode'}    = SSL_VERIFY_FAIL_IF_NO_PEER_CERT;
        $args{'SSL_client_ca_file'} = $self->{'epp'}->{'client_ca_file'};
    }

    return $self->SUPER::run(%args);
}

#
# This method is called when a new connection is received. It sends the
# <greeting> to the client, then enters the main loop.
#
sub process_request {
    my ($self, $socket) = @_;

    $self->send_frame($socket, $self->generate_greeting);

    $self->main_loop($socket);

    $socket->flush;
    $socket->close;
}

#
# This method initialises the session, and calls main_loop_iteration() in a
# loop. That method returns the result code, and the loop will terminate if the
# code indicates that it should.
#
sub main_loop {
    my ($self, $socket) = @_;

    my $session = $self->init_session($socket);

    while (1) {
        my $code = $self->main_loop_iteration($socket, $session);

        last if (OK_BYE == $code || $code >= COMMAND_FAILED_BYE);
    }
}

#
# This method initialises a new session
#
sub init_session {
    my ($self, $socket) = @_;

    my $session =  {
        'session_id'    => $self->generate_svTRID,
        'remote_addr'   => inet_ntop(4 == length($socket->peeraddr) ? AF_INET : AF_INET6, $socket->peeraddr),
        'remote_port'   => $socket->peerport,
        'counter'       => 0,
    };

    if ($socket->peer_certificate) {
        $session->{'client_cert'} = {
            'issuer'        => dn_to_hashref($socket->peer_certificate('issuer')),
            'subject'       => dn_to_hashref($socket->peer_certificate('subject')),
            'common_name'   => $socket->peer_certificate('commonName'),
        };
    };

    return $session;
}

#
# this function wraps No::Worries::DN::dn_parse() and returns a hashref instead
# of an array
#
sub dn_to_hashref {
    my $ref = {};

    foreach (@{dn_parse(shift)}) {
        my ($k, $v) = split(/=/, $_, 2);
        $ref->{$k} = $v;
    }

    return $ref;
}

#
# This method reads a frame from the client, passes it to process_frame(),
# sends the response back to the client, and returns the result code back to
# main_loop().
#
sub main_loop_iteration {
    my ($self, $socket, $session) = @_;

    my $xml = $self->get_frame($socket);

    return COMMAND_FAILED_BYE if (!$xml);

    my $response = $self->process_frame($xml, $session);

    $self->send_frame($socket, $response);

    $session->{'counter'}++;

    $self->write_log($session, $xml, $response);

    if ('greeting' eq $response->documentElement->firstChild->localName) {
        return OK;

    } else {
        return $response->getElementsByTagName('result')->item(0)->getAttribute('code');

    }
}

#
# write the command and response to the log
#
sub write_log {
    my ($self, $session, $command, $response) = @_;

    return unless exists($self->{'epp'}->{'log_dir'});

    my $dir = File::Spec->catdir(
        abs_path($self->{'epp'}->{'log_dir'}),
        $session->{'session_id'}
    );

    make_path($dir, { mode => 0700});

    write_file(File::Spec->catfile($dir, sprintf('%016u-command.xml', $session->{'counter'})), $command);
    write_file(File::Spec->catfile($dir, sprintf('%016u-response.xml', $session->{'counter'})), $response);
}

#
# This method is a wrapper around Net::EPP::Protocol->get_frame() which
# implements a timeout and exception handler.
#
sub get_frame {
    my ($self, $socket) = @_;

    my $xml;

    eval {
        local $SIG{ALRM} = sub { die("ALARM\n") };

        ualarm(1000 * 1000 * ($self->{'epp'}->{'timeout'}));

        $xml = Net::EPP::Protocol->get_frame($socket);

        ualarm(0);
    };

    return ($@ ? undef : $xml);
}


#
# This method processes an XML frame received from a client and returns a
# response frame. It manages session state, to ensure that clients that haven't
# authenticated yet can't do anything except login.
#
sub process_frame {
    my ($self, $xml, $session) = @_;

    my $svTRID = $self->generate_svTRID;

    my $frame = $self->parse_frame($xml);

    if (!$frame->isa('XML::LibXML::Document')) {
        return $self->generate_error(
            code    => SYNTAX_ERROR,
            msg     => 'XML parse error.',
            svTRID  => $svTRID,
        );
    }

    my ($code, $msg) = $self->validate_frame($frame);

    if (OK != $code) {
        return $self->generate_error(
            code    => $code,
            msg     => $msg,
            svTRID  => $svTRID,
        );
    }

    eval { $self->run_callback(
        event   => 'frame_received',
        frame   => $frame
    ) };

    my $fcname = $frame->getElementsByTagName('epp')->item(0)->firstChild->localName;

    if ('hello' eq $fcname) {
        return $self->generate_greeting;
    }

    my $clTRID = $frame->getElementsByTagName('clTRID')->item(0);
    $clTRID = $clTRID->textContent if ($clTRID);

    my $command;

    if ('command' eq $fcname) {
        $command = $frame->documentElement->firstChild->firstChild->localName;

    } elsif ('extension' eq $fcname) {
        $command = 'other';

    }

    if (!$command) {
        return $self->generate_error(
            code    => SYNTAX_ERROR,
            msg     => 'First child element of <epp> is not <command> or <extension>.',
            clTRID  => $clTRID,
            svTRID  => $svTRID,
        );
    }

    if (!defined($session->{'clid'}) && 'login' ne $command) {
        return $self->generate_error(
            code    => AUTHENTICATION_ERROR,
            msg     => 'You are not logged in.',
            clTRID  => $clTRID,
            svTRID  => $svTRID,
        );
    }

    if ('login' eq $command) {
        if (defined($session->{'clid'})) {
            return $self->generate_error(
                code    => AUTHENTICATION_ERROR,
                msg     => 'You are already logged in.',
                clTRID  => $clTRID,
                svTRID  => $svTRID,
            );
        }

        my $meta = $self->run_callback(event => 'hello', frame => $HELLO);

        foreach my $uri (map { $_->textContent } $frame->getElementsByTagName('objURI')) {
            if (none { $_ eq $uri } @{$meta->{objects}}) {
                return $self->generate_error(
                    code    => UNIMPLEMENTED_OBJECT_SERVICE,
                    msg     => sprintf("This server does not support '%s' objects.", $uri),
                    clTRID  => $clTRID,
                    svTRID  => $svTRID,
                );
            }
        }

        foreach my $uri (map { $_->textContent } $frame->getElementsByTagName('extURI')) {
            if (none { $_ eq $uri } @{$meta->{extensions}}) {
                return $self->generate_error(
                    code    => UNIMPLEMENTED_EXTENSION,
                    msg     => sprintf("This server does not support the '%s' extension.", $uri),
                    clTRID  => $clTRID,
                    svTRID  => $svTRID,
                );
            }
        }
    }

    if ('logout' eq $command) {
        eval { $self->run_callback(event => 'session_closed', session => $session) };

        return $self->generate_response(
            code    => OK_BYE,
            msg     => 'Command completed successfully; ending session.',
            clTRID  => $clTRID,
            svTRID  => $svTRID,
        );
    }

    my $response = $self->handle_command(
        command => $command,
        frame   => $frame,
        session => $session,
        clTRID  => $clTRID,
        svTRID  => $svTRID,
    );

    if ('login' eq $command && $response->getElementsByTagName('result')->item(0)->getAttribute('code') < UNKNOWN_COMMAND) {
        $session->{'clid'}          = $frame->getElementsByTagName('clID')->item(0)->textContent;
        $session->{'lang'}          = $frame->getElementsByTagName('lang')->item(0)->textContent;
        $session->{'objects'}       = [ map { $_->textContent } $frame->getElementsByTagName('objURI') ];
        $session->{'extensions'}    = [ map { $_->textContent } $frame->getElementsByTagName('extURI') ];
    }

    eval { $self->run_callback(
        event       => 'response_prepared',
        frame       => $frame,
        response    => $response
    ) };

    return $response;
}

#
# This method invokes the event handler for a given event/command, and passes
# back the response, returning an error if the command references an
# unimplemented command, object service or extension.
#
sub handle_command {
    my $self    = shift;
    my %args    = @_;
    my $command = $args{'command'};
    my $frame   = $args{'frame'};
    my $session = $args{'session'};
    my $clTRID  = $args{'clTRID'};
    my $svTRID  = $args{'svTRID'};

    my $response;

    #
    # check for an unimplemented command
    #
    if (!defined($self->{'epp'}->{'handlers'}->{$command})) {
        return $self->generate_error(
            code    => UNIMPLEMENTED_COMMAND,
            msg     => sprintf('This server does not implement the <%s> command.', $command),
            clTRID  => $clTRID,
            svTRID  => $svTRID,
        );
    }

    if ('login' ne $command) {
        #
        # check for an unimplemented object
        #
        if (any { $command eq $_ } qw(check info create delete renew transfer update)) {
            my $type = $frame->getElementsByTagName('epp')->item(0)->firstChild->firstChild->firstChild->namespaceURI;

            if (none { $type eq $_ } @{$session->{'objects'}}) {
                return $self->generate_error(
                    code    => UNIMPLEMENTED_OBJECT_SERVICE,
                    msg     => sprintf('This server does not support %s objects.', $type),
                    clTRID  => $clTRID,
                    svTRID  => $svTRID,
                );
            }
        }

        #
        # check for an unimplemented extension
        #
        my $extn = $frame->getElementsByTagName('extension')->item(0);
        if ($extn) {
            foreach my $el ($extn->childNodes) {
                if (none { $el->namespaceURI eq $_ } @{$session->{'extensions'}}) {
                    return $self->generate_error(
                        code    => UNIMPLEMENTED_EXTENSION,
                        msg     => sprintf('This server does not support the %s extension.', $el->namespaceURI),
                        clTRID  => $clTRID,
                        svTRID  => $svTRID,
                    );
                }
            }
        }
    }

    return $self->run_command(%args);
}


sub generate_greeting {
    my $self = shift;

    state $frame;

    if (!$frame) {
        my $data = $self->run_callback(event => 'hello', frame => $HELLO);

        $frame = XML::LibXML::Document->new;

        $frame->setDocumentElement($frame->createElementNS($Net::EPP::Frame::EPP_URN, 'epp'));
        my $greeting = $frame->documentElement->appendChild($frame->createElement('greeting'));

        $greeting->appendChild($frame->createElement('svID'))->appendText($data->{'svID'} || lc(hostname));

        # the <svDate> element is populated dynamically
        $greeting->appendChild($frame->createElement('svDate'))->appendChild($frame->createTextNode(''));

        my $svcMenu = $greeting->appendChild($frame->createElement('svcMenu'));
        $svcMenu->appendChild($frame->createElement('version'))->appendText('1.0');

        foreach my $lang (@{$data->{'lang'} || [qw(en)]}) {
            $svcMenu->appendChild($frame->createElement('lang'))->appendText($lang);
        }

        foreach my $objURI (@{$data->{'objects'}}) {
            $svcMenu->appendChild($frame->createElement('objURI'))->appendText($objURI);
        }

        if (scalar(@{$data->{'extensions'}}) > 0) {
            my $svcExtension = $svcMenu->appendChild($frame->createElement('svcExtension'));

            foreach my $extURI (@{$data->{'extensions'}}) {
                $svcExtension->appendChild($frame->createElement('extURI'))->appendText($extURI);
            }
        }

        my $dcp = $greeting->appendChild($frame->createElement('dcp'));
        $dcp->appendChild($frame->createElement('access'))->appendChild($frame->createElement('all'));

        my $statement = $dcp->appendChild($frame->createElement('statement'));
        $statement->appendChild($frame->createElement('purpose'))->appendChild($frame->createElement('prov'));
        $statement->appendChild($frame->createElement('recipient'))->appendChild($frame->createElement('public'));
        $statement->appendChild($frame->createElement('retention'))->appendChild($frame->createElement('legal'));
    }

    $frame->getElementsByTagName('svDate')->item(0)->firstChild->setData(DateTime->now->strftime('%FT%T.0Z'));

    return $frame;
}


sub run_command {
    my $self    = shift;
    my %args    = @_;
    my $command = $args{'command'};
    my $frame   = $args{'frame'};
    my $session = $args{'session'};
    my $clTRID  = $args{'clTRID'};
    my $svTRID  = $args{'svTRID'};

    my @result = eval { $self->run_callback(
        event   => $command,
        frame   => $frame,
        session => $session,
        clTRID  => $clTRID,
        svTRID  => $svTRID,
    ) };

    if ($@) {
        carp($@);

        return $self->generate_error(
            code    => COMMAND_FAILED,
            clTRID  => $clTRID,
            svTRID  => $svTRID,
        );
    }

    #
    # the command handler returned nothing
    #
    if (0 == scalar(@result)) {
        carp(sprintf('<%s> command handler returned nothing', $command));

        return $self->generate_error(
            code    => COMMAND_FAILED,
            clTRID  => $clTRID,
            svTRID  => $svTRID,
        );
    }

    #
    # single return value
    #
    if (1 == scalar(@result)) {
        my $result = shift(@result);

        if ($result->isa('XML::LibXML::Document')) {
            return $result;
        }

        if (is_result_code($result)) {
            return $self->generate_response(
                code    => $result,
                clTRID  => $clTRID,
                svTRID  => $svTRID,
            );
        }

        carp(sprintf('<%s> command handler did not return a result code or an XML document', $command));

        return $self->generate_error(
            code    => COMMAND_FAILED,
            clTRID  => $clTRID,
            svTRID  => $svTRID,
        );
    }

    if (!is_result_code($result[0])) {
        carp(sprintf('<%s> command handler returned something that is not a result code', $command));

        return $self->generate_error(
            code    => COMMAND_FAILED,
            clTRID  => $clTRID,
            svTRID  => $svTRID,
        );
    }

    my $code = shift(@result);

    if (!ref($result[0])) {
        #
        # assume that the next member is a string containing a message
        #
        return $self->generate_response(
            code    => $code,
            msg     => $result[0],
            clTRID  => $clTRID,
            svTRID  => $svTRID,
        );
    }

    #
    # generate a basic response that we will then insert elements into
    #
    my $response = $self->generate_response(
        code    => $code,
        clTRID  => $clTRID,
        svTRID  => $svTRID,
    );

    my %els;
    foreach my $el (@result) {
        #
        # anything that isn't an element is ignored
        #
        if ($el->isa('XML::LibXML::Element')) {
            #
            # if multiple elements with the same local name are present,
            # the last will clobber any previous elements.
            #
            $els{$el->localName} = $el;
        }
    }

    my $response_el = $response->getElementsByTagName('response')->item(0);

    #
    # now append elements in the correct order, if provided
    #
    foreach my $name (grep { exists($els{$_}) } qw(resData msgQ extension)) {
        $response_el->appendChild($response->importNode($els{$name}));
    }

    return $response;
}


sub generate_response {
    my $self    = shift;
    my %args    = @_;

    my $clTRID  = $args{'clTRID'};
    my $svTRID  = $args{'svTRID'};

    my $code    = $args{'code'} || OK;
    my $msg     = $args{'msg'} || $MESSAGES{$code} || ($code < UNKNOWN_COMMAND ? $MESSAGES{OK} : $MESSAGES{COMMAND_FAILED});

    my $frame = XML::LibXML::Document->new;

    $frame->setDocumentElement($frame->createElementNS($Net::EPP::Frame::EPP_URN, 'epp'));
    my $response = $frame->documentElement->appendChild($frame->createElement('response'));

    my $result = $response->appendChild($frame->createElement('result'));

    $result->setAttribute('code', $code);
    $result->appendChild($frame->createElement('msg'))->appendText($msg);

    if ($args{'resData'}) {
        $response->appendChild($frame->createElement('resData'));
    }

    if ($clTRID || $svTRID) {
        my $trID = $response->appendChild($frame->createElement('trID'));
        $trID->appendChild($frame->createElement('clTRID'))->appendText($clTRID) if ($clTRID);
        $trID->appendChild($frame->createElement('svTRID'))->appendText($svTRID) if ($svTRID);
    }

    return $frame;
}


sub generate_error {
    my ($self, %args) = @_;
    $args{'code'} ||= COMMAND_FAILED;
    $args{'msg'} = $args{'msg'} || $MESSAGES{$args{'code'}} || 'An internal error occurred. Please try again later.';
    return $self->generate_response(%args);
}


sub generate_svTRID {
    state $counter = time();

    return substr(sha512_hex(
        pack('Q', ++$counter)
        .chr(0)
        .Crypt::OpenSSL::Random::random_pseudo_bytes(32)
    ), 0, 64);
}


sub parse_frame {
    my ($self, $xml) = @_;

    return XML::LibXML->load_xml(
        string      => $xml,
        no_blanks   => 1,
        no_cdata    => 1,
    );
}


sub validate_frame {
    my ($self, $frame) = @_;

    if ($self->{'epp'}->{'xsd_file'}) {
        state $xsd = XML::LibXML::Schema->new(location => $self->{'epp'}->{'xsd_file'});

        eval { $xsd->validate($frame) };

        return (SYNTAX_ERROR, $@) if ($@);
    }

    return OK;
}

#
# This method finds the callback for the given event, and if found, runs it and
# passes back its return value(s).
#
sub run_callback {
    my $self = shift;
    my %args = @_;

    $args{'server'} ||= $self;

    my $ref = $self->{'epp'}->{'handlers'}->{$args{'event'}};

    return &{$ref}(%args) if ($ref);
}


sub is_result_code {
    my $value = shift;
    return (int($value) >= OK && int($value) <= 2502);
}

#
# This method is a wrapper around Net::EPP::Protocol->send_frame() which
# validates the response and reports any errors
#
sub send_frame {
    my ($self, $socket, $frame) = @_;

    #
    # note: we need to do a round-trip here otherwise we get namespace issues
    #
    $frame = XML::LibXML->load_xml(string => $frame->toString);

    my ($code, $msg) = $self->validate_frame($frame);
    if (OK != $code) {
        carp($msg);
    }

    Net::EPP::Protocol->send_frame($socket, $frame->toString);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::EPP::Server - A simple EPP server implementation.

=head1 VERSION

version 0.10

=head1 SYNOPSIS

    use Net::EPP::Server;
    use Net::EPP::ResponseCodes;

    #
    # these are the objects we want to support
    #
    my @OBJECTS = qw(domain host contact);

    #
    # these are the extensions we want to support
    #
    my @EXTENSIONS = qw(secDNS rgp loginSec allocationToken launch);

    #
    # You can pass any arguments supported by Net::Server::Proto::SSL, but
    # by default the server will listen on localhost port 7000 using a
    # self-signed certificate.
    #
    Net::EPP::Server->new->run(

        #
        # this defines callbacks that will be invoked when an EPP frame is
        # received
        #
        handlers => {
            hello   => \&hello_handler,
            login   => \&login_handler,
            check   => \&check_handler,
            info    => \&info_handler,
            create  => \&create_handler,

            # add more here
        }
    );

    #
    # The <hello> handler is special and just needs
    # to return a hashref containing server metadata.
    #
    sub hello_handler {
        return {
            # this is the server ID and is optional, if not provided the system
            # hostname will be used
            svID => 'epp.example.com',

            # this is optional
            lang => [ qw(en fr de) ],

            # these are arrayrefs of namespace URIs
            objects => [
                map { Net::EPP::Frame::ObjectSpec->xmlns($_) } @OBJECTS
            ],

            extensions => [
                map { Net::EPP::Frame::ObjectSpec->xmlns($_) } @EXTENSIONS
            ],
        };
    }

    #
    # All other handlers work the same. They are passed a hash of arguments and
    # can return a simple result code, a result code and message, a
    # XML::LibXML::Document object, or a result code and an array of
    # XML::LibXML::Element objects.
    #
    sub login_handler {
        my %args = @_;

        my $frame = $args{'frame'};

        my $clid = $frame->getElementsByTagName('clid')->item(0)->textContent;
        my $pw = $frame->getElementsByTagName('pw')->item(0)->textContent;

        if (!validate_credentials($clid, $pw)) {
            return AUTHENTICATION_FAILED;

        } else {
            return OK;

        }
    }

=head1 INTRODUCTION

C<Net::EPP::Server> provides a high-level framework for developing L<Extensible
Provisioning Protocol (EPP)|https://www.rfc-editor.org/info/std69> servers.

It implements the TLS/TCP transport described in L<RFC 5734|https://www.rfc-editor.org/info/rfc5734>,
and the L<EPP Server State Machine|https://www.rfc-editor.org/rfc/rfc5730.html#:~:text=Figure%201:%20EPP%20Server%20State%20Machine>
described in L<Section 2 of RFC 5730|https://www.rfc-editor.org/rfc/rfc5730.html#section-2>.

=head1 SERVER CONFIGURATION

C<Net::EPP::Server> inherits from L<Net::Server> I<(specifically
L<Net::Server::PreFork>)>, and so the C<run()> method accepts all the parameters
supported by that module, plus the following:

=over

=item * C<handlers>, which is a hashref which maps events (including EPP
commands) to callback functions. See below for details.

=item * C<timeout> (optional), which is how long (in seconds) to wait for a
client to send a command before dropping the connection. This parameter may be a
decimal (e.g. C<3.14>) or an integer (e.g. C<42>). The default timeout is 30
seconds.

=item * C<client_ca_file> (optional), which is the location on disk of a file
which can be use to validate client certificates. If this parameter is not
provided, clients will not be required to use a certificate.

=item * C<xsd_file> (optional), which is the location on disk of an XSD file
which should be used to validate all frames received from clients. This XSD
file can include other XSD files using C<E<lt>importE<gt>>.

item * C<log_dir> (optional), which is the location on disk where log files
will be written.

=back

=head1 EVENT HANDLERS

You implement the business logic of your EPP server by specifying callbacks that
are invoked for certain events. These come in two flavours: I<events> and
I<commands>.

All event handlers receive a hash containing one or more arguments that are
described below.

=head2 C<frame_received>

Called when a frame has been successfully parsed and validated, but before it
has been processed. The input frame will be passed as the C<frame> argument.

=head2 C<response_prepared>

Called when a response has been generated, but before it has been sent back to
the client. The response will be passed as the C<response> argument, while the
input frame will be passed as the C<frame> argument. It is B<not> called for
C<E<lt>helloE<gt>> and C<E<lt>logoutE<gt>>commands.

=head2 C<session_closed>

C<Net::EPP::Server> takes care of handling session management, but this event
handler will be called once a C<E<lt>logoutE<gt>> command has been successfully
processed, and before the client connection has been closed. The C<session>
argument will contain a hashref of the session (see below).

=head2 C<hello>

The C<hello> event handler is called when a new client connects, or a
C<E<lt>helloE<gt>> frame is received.

Unlike the other event handlers, this handler B<MUST> respond with a hashref
which contains the following entries:

=over

=item * C<svID> (OPTIONAL) - the server ID. If not provided, the system hostname
will be used.

=item * C<lang> (OPTIONAL) - an arrayref containing language codes. It not
provided, C<en> will be used as the only supported language.

=item * C<objects> (REQUIRED) - an arrayref of namespace URIs for

=back

=head2 COMMAND HANDLERS

The standard EPP command repertoire is:

=over

=item * C<login>

=item * C<logout>

=item * C<poll>

=item * C<check>

=item * C<info>

=item * C<create>

=item * C<delete>

=item * C<renew>

=item * C<transfer>

=item * C<delete>

=back

A command handler may be specified for all of these commands except C<logout>,
since C<Net::EPP::Server> handles this itself.

Since EPP allows the command repertoire to be extended (by omitting the
C<E<lt>commandE<gt>> element and using the C<E<lt>extensionE<gt>> element only),
C<Net::EPP::Server> also supports the C<other> event which will be called when
processing such frames.

All command handlers receive a hash containing the following arguments:

=over

=item * C<server> - the server.

=item * C<event> - the name of the command.

=item * C<frame> - an L<XML::LibXML::Document> object representing the frame
received from the client.

=item * C<session> - a hashref containing the session information.

=item * C<clTRID> - the value of the C<E<lt>clTRIDE<gt>> element taken from the
frame received from the client.

=item * C<svTRID> - a value suitable for inclusion in the C<E<lt>clTRIDE<gt>>
element of the response.

=back

=head3 SESSION PARAMETERS

As mentioned above, the C<session> parameter is a hashref which contains
information about the session. It contains the following values:

=over

=item * C<session_id> - a unique session ID.

=item * C<remote_addr> - the client's remote IP address (IPv4 or IPv6).

=item * C<remote_port> - the client's remote port.

=item * C<clid> - the client ID used to log in.

=item * C<lang> - the language specified at login.

=item * C<objects> - an arrayref of the object URI(s) specified at login.

=item * C<extensions> - an arrayref of the extension URI(s) specified at login.

=item * C<client_cert> - a hashref containing information about the client
certificate (if any), which looks something like this:

    {
      'issuer' => $dnref,
      'common_name' => 'example.com',
      'subject' => $dnref,
    }

C<$dnref> is a hashref representing the Distinguished Name of the issuer or
subject and looks like this:

    {
        'O' => 'Example Inc.',
        'OU' => 'Registry Services',
        'emailAddress' => 'registry@example.com',
        'CN' => 'EPP Server Private CA',
    }

Other members, such as C<C> (country), C<ST> (state/province), and C<L> (city)
may also be present.

=back

=head3 RETURN VALUES

Command handlers can return result information in four different ways that are
explained below.

=head4 1. SIMPLE RESULT CODE

Command handlers can signal the result of a command by simply passing a single
integer value. L<Net::EPP::ResponseCodes> may be used to avoid literal integers.

Example:

    sub delete_handler {
        my %args = @_;

        # business logic here

        if ($success) {
            return OK;

        } else {
            return COMMAND_FAILED;

        }
    }

C<Net::EPP::Server> will construct a standard EPP response frame using the
result code and send it to the client.

=head4 2. RESULT CODE + MESSAGE

If the command handler returns two values, and the first is a valid result code,
then the second can be a message. Example:

    sub delete_handler {
        my %args = @_;

        # business logic here

        if ($success) {
            return (OK, 'object deleted');

        } else {
            return (COMMAND_FAILED, 'object not deleted');

        }
    }

C<Net::EPP::Server> will construct a standard EPP response frame using the
result code and message, and send it to the client.

=head4 3. RESULT CODE + XML ELEMENTS

The command handler may return a result code followed by an array of between
one and three L<XML::LibXML::Element> objects, in any order, representing the
C<E<lt>resDataE<gt>>, C<E<lt>msgQE<gt>> and C<E<lt>extensionE<gt>> elements.
Example:

    sub delete_handler {
        my %args = @_;

        # business logic here

        return (
            OK,
            $resData_element,
            $msgQ_element,
            $extension_element,
        );
    }

C<Net::EPP::Server> will construct a standard EPP response frame using the
result code and supplied elements which will be imported and inserted into the
appropriate positions, and send it to the client.

=head4 4. L<XML::LibXML::Document> OBJECT

A return value that is a single L<XML::LibXML::Document> object will be sent
back to the client verbatim.

=head3 EXCEPTIONS

C<Net::EPP::Server> will catch any exceptions thrown by the command handler,
will C<carp($@)>, and then send a C<2400> result code back to the client.

=head1 UTILITY METHODS

=head2 C<generate_response(%args)>

This method returns a L<XML::LibXML::Document> object representing the response
described by C<%args>, which should contain the following:

=over

=item * C<code> (OPTIONAL) - the result code. See L<Net::EPP::ResponseCodes>.
If not provided, C<1000> will be used.

=item * C<msg> - a human-readable error message. If not provided, the string
C<"Command completed successfully."> will be used if C<code> is less than
C<2000>, and C<"Command failed."> if C<code> is C<2000> or higher.

=item * C<resData> (OPTIONAL) - if defined, an empty C<E<lt>resDataE<gt>>
element will be added to the frame.

=item * C<clTRID> (OPTIONAL) - the client transaction ID.

=item * C<svTRID> (OPTIONAL) - the server's transaction ID.

=back

Once created, it is straightforward to modify the object to add, remove or
change its contents as needed.

=head2 C<generate_error(%args)>

This method is identical to C<generate_response()> except the default value
for the C<code> parameter is C<2400>, indicating that the command failed for
unspecified reasons.

=head2 C<generate_svTRID()>

This method returns a unique string suitable for use in the C<E<lt>svTRIDE<gt>>
and similar elements.

=head2 C<parse_frame($xml)>

Attempts to parse C<$xml> and returns a L<XML::LibXML::Document> if successful.

=head2 C<is_valid($frame)>

Returns a result code and optionally a message if C<$frame> cannot be validated
against the XSD file provided in the C<xsd_file> parameter.

=head2 C<is_result_code($value)>

Returns true if C<$value> is a recognised EPP result code.

=head1 AUTHOR

Gavin Brown <gavin.brown@icann.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Internet Corporation for Assigned Names and Number (ICANN).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
