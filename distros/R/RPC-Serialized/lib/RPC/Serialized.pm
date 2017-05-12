package RPC::Serialized;
{
  $RPC::Serialized::VERSION = '1.123630';
}

use strict;
use warnings FATAL => 'all';

use base 'Class::Accessor::Fast::Contained';

use Readonly;
use Data::Serializer;
use RPC::Serialized::Config;
use RPC::Serialized::Exceptions;

__PACKAGE__->mk_ro_accessors(qw/
    debug
/);
__PACKAGE__->mk_accessors(qw/
    ds
    ifh ofh
/);

# this is the record separator in our data stream,
# used if debug is enabled
Readonly my $TERMINATOR => '...';

sub new {
    my $class  = shift;
    my $params = RPC::Serialized::Config->parse(@_);

    throw_app 'Missing or invalid input handle'
        if exists $params->me->{ifh}
        and ! _is_valid_input_handle( $params->me->{ifh} );

    throw_app 'Missing or invalid output handle'
        if exists $params->me->{ofh}
        and ! _is_valid_output_handle( $params->me->{ofh} );

    $params->me->{ofh}->autoflush(1) if exists $params->me->{ofh};
    $params->me->{ds} = Data::Serializer->new($params->data_serializer);

    return $class->SUPER::new({ $params->me });
}

sub _is_valid_handle {
    my $h = shift;
    return 1
        if defined $h
        and ref $h
        and $h->can('error');
    return 0;
}

sub _is_valid_input_handle {
    my $h = shift;
    return 1
        if _is_valid_handle($h)
        and $h->can('getline')
        and $h->can('eof');
    return 0;
}

sub _is_valid_output_handle {
    my $h = shift;
    return 1
        if _is_valid_handle($h)
        and $h->can('print')
        and $h->can('autoflush')
        and $h->can('error');
    return 0;
}

sub send {
    my $self = shift;
    my $data = shift;

    throw_proto 'Data not a hash reference'
        unless ref($data) eq 'HASH';

    my $io = $self->ofh;

    if ($self->debug) {
        my $send_data = $self->ds->raw_serialize($data);
        $io->print( $send_data .
                ($send_data =~ m/\n$/ ? '' : "\n") . "$TERMINATOR\n" )
            and not $io->error
            or throw_system "Failed to send data: $!";
    }
    else {
        $io->print( $self->ds->serialize($data) . "\n" )
            and not $io->error
            or throw_system "Failed to send data: $!";
    }
}

sub recv {
    my $self = shift;
    my $data = '';
    my $io   = $self->ifh;

    if ($self->debug) {
        while ( $_ = $io->getline and not $io->error ) {
            last if /^\Q$TERMINATOR\E$/o;
            $data .= $_;
        }
    }
    else {
        $data = $io->getline;
    }

    throw_system "Failed to read data: $!"
        if $io->error;

    chomp $data if defined $data;
    return unless defined($data) && length($data);

    my @token = ();
    eval {
        if ($self->debug) {
            $data = $self->ds->raw_deserialize($data);
        }
        else {
            my $token = $self->ds->_get_token($data);
            @token = $self->ds->_extract_token($token) if defined $token;

            $data = $self->ds->deserialize($data);
        }
    };
    throw_proto "Data::Serializer error: $@"
        if $@;

    throw_proto 'Serializer parse error'
        if !defined $data or $data == 1;

    throw_proto 'Data not a hash reference'
        if ref($data) ne 'HASH';

    return (wantarray
        ? ($data, @token)
        : $data);
}

sub DESTROY {
    my $self = shift;
    $self->ifh->close if $self->ifh;
    $self->ofh->close if $self->ofh;
}

1;

# ABSTRACT: Subroutine calls over the network using common serialization


# Here are some of the less common error messages. When more time is available
# these will be futher documented:
# 
# =over 4
# 
# =item C<Permission denied> in an C<X::Authorization>
# 
# The authorization scheme loaded has refused to permit the current subject to
# make the current call.
# 
# =item C<TCPREMOTEINFO not set> in an C<X::Authorization>
# 
# The C<UCSPI/TCP> server will look for the C<TCPREMOTEINFO> environment
# variable, if authorization is enabled. See the C<ucspi-tcp> documentation for
# details if you don't know how to enable this.
# 
# =item C<IPCREMOTEEUID not set> in an C<X::Authorization>
# 
# The C<UCSPI/IPC> server will look for the C<IPCREMOTEINFO> environment
# variable, if authorization is enabled. See the <ucspi-ipc> documentation for
# details if you don't know how to enable this.
# 
# =item C<getpwuid $uid failed> in an C<X::Authorization>
# 
# The C<UCSPI/IPC> server failed to get the username for the calling user. Only
# happens if authorization has been enabled.
# 
# =item C<Not a RPC::Serialized::AuthzHandler> in an C<X::Application>
# 
# Server authorization is enabled but the specified handler does not inherit
# from L<RPC::Serialized::AuthzHandler>.
# 
# =item C<Failed to open GDBM file...> in an C<X::System>
# 
# =item C<Missing or invalid URI> in an C<X::Application>
# 
# =item C<Can't determine path from URI ...> in an C<X::Application>
# 
# =item C<Failed to open ...> in an C<X::System>
# 
# =item C<Target name not specified> in an C<X::Application>
# 
# =item C<Failed to parse scheme from URI ...> in an C<X::Application>
# 
# =item C<Unsupported URI scheme ...> in an C<X::Application>
# 
# =item C<Failed to load ...> in an C<X::System>
# 
# =item C<Subject name not specified> in an C<X::Application>
# 
# =item C<Operation name not specified> in an C<X::Application>
# 
# =item C<Open $acl_path failed: ...> in an C<X::System>
# 
# =item C<Failed to parse ACLs at ...> in an C<X::Application>
# 
# =item C<ACL path not specified> in an C<X::Application>
# 
# =back


__END__
=pod

=head1 NAME

RPC::Serialized - Subroutine calls over the network using common serialization

=head1 VERSION

version 1.123630

=head1 SYNOPSIS

 # for the RPC server...
 
 # choose one of the supplied server types (NetServer is Net::Server)
 use RPC::Serialized::Server::NetServer;
 
 my $s = RPC::Serialized::Server::NetServer->new;
 $s->run;
     # server process is now looping and waiting for RPC (like Apache prefork)
     # the default port number for Net::Server is 20203
 
 # and so for the RPC client...
 
 use RPC::Serialized::Client::INET;
 
 my $c = RPC::Serialized::Client::INET->new({
     io_socket_inet => {PeerPort => 20203},
 });
  
 my $result = $c->remote_sub_name(qw/ some data /);
     # remote_sub_name gets mapped to an invocation on the RPC server
     # it's best to wrap this in an eval{} block

=head1 DESCRIPTION

This module allows you to call a Perl subroutine in another process, possibly
on another machine, using a very simple and extensible interface which ties
together the features of other good modules from the CPAN.

There are lots of uses for RPC (remote procedure calls), so here are a couple
of examples just to give you an idea:

=over 4

=item Priveledge separation

If you have a web interface which is used to control a critical backend
system, perhaps a key database or the settings on a firewall, you can use RPC
to prevent security flaws on the web service from affecting the backend
service. Only procedure calls which are permitted will be accepted from the
web host, and it also offers a nice interface separation for your systems.

=item File or data access

To avoid sharing of filesystems over the network (SAMBA, NFS, etc), you can
provide a restricted interface using RPC. For example a web service to search
log files could send an RPC request with the search string to the log server,
and display the results. There would be no need to run a network filesystem.

=back

What makes this module different from another RPC implementation?

=over 4

=item Data Serialization

This module uses L<Data::Serializer> to construct its "on the wire" protocol.
This means any Perl data structure can be sent or received, even Perl code
itself in the case of some of the serialization modules (e.g. YAML supports
this). You can also encrypt and compress data; all options to Data::Serializer
are easily available through the configuration of this module.

=item Simple deployment

Each remote procedure is simply a perl subroutine in a module which is loaded
by the server. You can let the server autoload everything as it is called, or
specify each "handler" subroutine individually (or combine both!). Adding and
modifying the available handlers is simple, meaning you think less about the
RPC subsystem and more about your code and service provision.

=item Flexible configuration

All the modules used by C<RPC::Serialized> can be fully configured as you
wish, from one configuration file, or via options to C<new()>. You saw an
example of this in the L</SYNOPSIS> section, above, for the
L<IO::Socket::INET> module.

=back

The following sections take you through setting up an RPC server and client.

=head1 GENERAL CONFIGURATION

Both the client and server parts of this module share the same configuration
system. There is a file, L<RPC::Serialized::Config>, which contains the basic
defaults suitable for most situations. Then, you can also specify the name of
a configuration file as a parameter to any call to C<new()>. Finally, a
hash reference of options can be supplied directly to any call to C<new()>.
Let's go through these cases by example:

 # this is for a server, but the example applies equally to a client
 use RPC::Serialized::Server::NetServer;
 
 # no configuration at all - use the built in defaults
 $s = RPC::Serialized::Server::NetServer->new;

If you are happy with the settings in the source code of
L<RPC::Serialized::Config>, then no options are required. In the case of some
types of server and client this is enough to get you going.

 # load a configuration file, using Config::Any  
 $s = RPC::Serialized::Server::NetServer->new('/path/to/config/file');

Alternatively, specify a file with configuration. We use L<Config::Any> to
load the file, and so it should contain a data structure in one of the
formats supported by that module. I<Tip>: make sure there is a filename
suffix, e.g. C<.yml>, to help C<Config::Any> load the data. For details of the
required structure of that data, read on...

 # pass some options directly
 $s = RPC::Serialized::Server::NetServer->new({
      net_server => {log_file => undef, port => 5233},
      rpc_serialized => {handler_namespaces => 'RPC::Serialized::Handler'},
 });

You can pass a hash reference to C<new()>. Each key in this hash is the name
of a module to configure. The module names are converted to lowercase, and the
C<::> separator is replaced by an underscore. In the example above we are
providing some options to L<Net::Server> and this module, L<RPC::Serialized>.

The value of each key is another anonymous hash, this time with any options as
specified by that module's own manual page. Of course, this only works for
modules which use key/value options themselves, but thankfully that is the
case for each module used by C<RPC::Serialized>.

Remember, in all of the examples in this manual page which show passing
configuration settings to C<new()>, you can also achieve the same thing using
a configuration file by passing its name to C<new()> instead.

As a final note on this topic, you can provide both a configuration filename,
and an hash reference of options to the C<new()> call. In fact, whatever and
however many of these you provide, they will be read in with the later ones
taking prescedent.

=head1 SETTING UP A SERVER

You do not have to know too much about internet servers to use this module. As
well as providing a standard TCP and UDP server, there are also UNIX socket
and Standard Input/Output servers that you might use for communicating with
clients on the same host system.

In the main, we are dealing with a UNIX world here, so most of the description
will make assumptions about that. If you get this module running on Windows,
please let the author know!

A small perl script which starts the server running is all you need. This can
be copied verbatim from the L</SYNOPSIS> section above. For guidance on
providing configuration to the server, see L</GENERAL CONFIGURATION>, above.

When running a server process, it can either stay in the foreground, or detach
from your shell. The default is to stay in the foreground, for two reasons.
First, when you are developing you probably want to start the server and see
what is happening on C<STDERR>. Second, many people use Dan Bernstein's
C<daemontools> package to manage persistent servers, and this requires a
process which does not detach from its parent process. If you are using the
C<NetServer> server, then it is easy to make it detach:

 $s = RPC::Serialized::Server::NetServer->new({
      net_server => { background => 1, setsid => 1 },
 });

To stop the server you will then have to issue a kill to the detached process.

There is a handful of alternative servers shipped with this module. For more
details, please see the manual pages for each of them:

=over 4

=item L<RPC::Serialized::Server::NetServer>

This is a full-blown pre-forking internet server, with many many good
features. You will have to install the L<Net::Server> Perl module and
dependencies to use this server. It supports TCP and UDP INET sockets, as well
as UNIX domain sockets.

=item L<RPC::Serialized::Server::STDIO>

This is a very simple server which processes one request at a time, accepting
data on Standard Input and sending responses to Standard Output.

=item L<RPC::Serialized::Server::UCSPI::TCP>

If you use Dan Bernstein's C<tcpserver> (a.k.a. C<ucspi-tcp>) then this is the
option for you. It is based upon the C<STDIO> server, above, and is designed
to be fired up by C<tcpserver> whenever an incoming connection is handled.
There is an example script for this in the Perl distribution for this module.

=item L<RPC::Serialized::Server::UCSPI::IPC>

This is similar to the option above, but for UNIX (i.e. local filesystem)
sockets rather than INET sockets. It is designed for C<ucspi-ipc>, producted
by I<SuperScript Technology, Inc.>, and you can find more details by searching
on I<Google>.

=back

=head2 How the server works

Each RPC message which comes in "over the wire" is really just a Perl data
structure, a hash. There is a "CALL" key, which has the name of the RPC method
to invoke, and some "ARGS" to pass to it as arguments.

The server looks at the CALL and tries to load and execute the handler which
maps to that CALL. If it fails it raises an Exception, and fires that back to
the client. If the invocation is successful, then the RESPONSE is sent back to
the client, again in a Perl data structure. It is all quite elegant and simple
(i.e. not my design, see L</AUTHOR> below for the acknowledgement!).

On the wire, if we switch off most of the L<Data::Serializer> magic and set
the Serializer to YAML, then it looks like this:

 ---
 CALL: localtime
 ARGS: []
 ...
 --- 
 RESPONSE: Sun Jul  8 21:57:28 2007
 ...

Note that C<...> is the record separator which tells the server when it can
process the incoming request. In this example, the CALL was for a method
called C<localtime>, and there were no arguments so I passed an empty list.
The RESPONSE was just the scalar output of Perl's C<localtime> function.

You might find it interesting to note that, inside of C<RPC::Serialized>, the
methods used to send and receive data at the client and server I<are
identical>. In the example above, I entered the YAML document and trailing
C<...> to make the method call, and the server responded with another YAML
document and C<...> record terminator. Using one of the
C<RPC::Serialized::Client> family, it would look just the same.

=head2 How to write RPC Handlers

First, know that there are three example handlers included in this
distribution, so you can just go and look at them if you prefer reading code
to documentation! See the modules under C<RPC::Serialized::Handler::>.

So you might have guessed that the first step is to choose your package name
for the handler. Each package contains one handler, or put another way, each
handler lives in its own package. You can either have the handler's name be
derived from the package's name, or set it manually. Using the C<localtime>
example from above, this is what the handler looks like:

 package RPC::Serialized::Handler::Localtime;
 
 use strict;
 use warnings FATAL => 'all';
 
 use base 'RPC::Serialized::Handler';
 
 sub invoke {
     my $self = shift;
     my $time = shift;
 
     $time = time unless defined $time;
     return scalar localtime($time);
 }
 
 1;

There is a "magic" method in the package, called C<invoke()>, and it is this
which is called by the RPC server to handle the incoming request.

By default all the servers will take the name of the requested method CALL,
convert underscores to C<::> separators, convert initial letters to uppercase,
and try to load a module in the C<RPC::Serialized::Handler::> namespace. For
example, if I called the C<< $c->frobnits_goo >> handler from a client, the
server would try to load a package called
C<RPC::Serialized::Handler::Frobnits::Goo> and then call the <invoke()> method
within that.

Alternatively you can see the L</OPTIONS FOR THIS MODULE> section below to
change that default namespace, or have your own mappings between client calls
and loaded handler packages (or a mixture of both).

You should expect all arguments passed to your C<invoke()> method to be in a
plain perl list (i.e. C<@_>); items in the list may be references to complex
data structures. You should return a single scalar value from that method, and
nothing else. The scalar value can, however, be a reference to an arbitrarily
complex data structure.

=head1 SETTING UP A CLIENT

As with the server, you don't need to know a lot about how networked services
operate in order to set up the client. However you probably do need to know
where your server is listening, to make contact with it!

Therefore, you will need to use the client which corresponds to your server.
Please read the manual page for the appropriate module:

=over 4

=item L<RPC::Serialized::Client::INET>

Use this client package to communicate with either a C<NetServer> server, or
the C<UCSPI/TCP> server.

=item L<RPC::Serialized::Client::UNIX>

This client will make UNIX domain socket (i.e. local filesystem) connections
to the C<NetServer> or C<UCSPI/IPC> servers.

=item L<RPC::Serialized::Client::STDIO>

For testing purposes you can use this client, which communicates on Standard
Input and Standard Output. Alternatively, use this package as a base to
implement a new kind of client.

=back

The basis of the client set-up is given in L</SYNOPSIS>, above, but we will
show another example here for completeness:

 #!/usr/bin/perl
 
 use strict;
 use warnings FATAL => 'all';
 
 use Readonly;
 use RPC::Serialized::Client::UNIX;
 
 Readonly my $SOCKET => '/var/run/rpc-serialized-example.socket';
 
 my $c = RPC::Serialized::Client::UNIX->new({
     io_socket_unix => { Peer => $SOCKET }
 });
 
 eval {
     my $response = $c->echo(qw/ a b c d /);
     print "echo: " . join( ":", @$res ) . "\n";
 };
 warn "$@\n" if $@;
 
 eval {
     my $now = $c->localtime;
     print "Localtime on the server is: $now\n";
 };
 warn "$@\n" if $@;

The above code uses the UNIX domain socket client to contact a server which is
listening on the file mentioned in C<$SOCKET>. Once the client object is set
up, we can make a call to any method we wish on the remote server, just by
specifying its name. Here, we call the C<echo> and the C<localtime> handlers.

For each call, you should specify the arguments as a plain perl list, although
that list can include references to complex data structures. There is a single
(scalar) return value from each call you make, although again this may be a
reference to a data structure if you wish.

This example also shows how you should use C<eval{}> constructs around the RPC
calls. This is good practice for most network programming, as all kinds of
things can go wrong. See the section L</ERROR HANDLING> below for more
information.

=head2 Timeouts

You should be aware that C<RPC::Serialized> operates timeouts on all handler
calls. By default, you get 30 seconds to make your request (i.e. make the call
and pass any data to the server), another 30 seconds for the server to handle
the call, and 30 seconds to transfer the response back to your client.

If any of this fails or times out, an exception will be raised and passed back
to you if possible. Exceptions can be passed through RPC, but you don't need
to know about how that works, only that you should be prepared to handle
C<die> using C<eval>.

To alter the timeout setting, see the next section L</OPTIONS FOR THIS
MODULE>. To see examples of the C<eval> construct see L</ERROR HANDLING>,
below.

=head1 OPTIONS FOR THIS MODULE

There is actually only a small number of options for this module, as most of
the heavy lifting within is done by other modules on the CPAN. In particular,
we use L<Data::Serializer>, and there is a section below which explains how to
customize your serializer set-up.

Options are passed to the C<new()> method in a hash reference. To see how this
is done, take a look at the L</GENERAL CONFIGURATION> or L</SYNOPSIS> sections
above, although here is a quick example:

 my $s = RPC::Serialized::Server::NetServer->new({
     rpc_serialized => { timeout => 15, trace => 1 },
 });

=over 4

=item C<handler_namespaces>

As explained above in L</How the server works>, the server will try to
auto-load the handler for a call, based on some naming conventions. This value
sets the Perl package namespaces which are searched. You can set this either
to a scalar string, the name of a single namespace, or an array reference
containing a list of such namespaces. The default setting is
C<RPC::Serialized::Handler>, into which we supply the C<echo>, C<localtime>,
and C<sleep> handlers as examples. Setting this value to an array reference
containing an empty list will disable auto-loading.

=item C<handlers>

An alternative to C<handler_namespaces>, this value allows you to map
individual CALLs to a given package name. In this way you can alias or alter
the "published" name of handlers, or restrict calls. It can be used in
addition to C<handler_namespaces>, but will take priority where both can be
used to invoke an RPC handler. Set this value to an anonymous hash, where keys
are calls made by the client (e.g. C<echo>) and values are package names
containing the handler (e.g. C<RPC::Serialized::Handler::Echo>). No handlers
are specified by default.

=item C<timeout>

This is a scalar value which sets how long C<RPC::Serializer> servers wait
before timing out their connections. As explained above, it is used when
receiving an RPC call, when dispatching to the handler of that call, and when
replying to the client. Each phase is given the C<timeout> in seconds to do
its work. The default value is 30 seconds.

=item C<trace>

This is a boolean (scalar) which sets whether logging of the content of RPC
traffic is made using UNIX syslog. For more details see the section L</SERVER
LOGGING>, below. If set to a true value, logging will be enabled. The default
value is false.

=item C<debug>

This is a boolean (scalar) which disables the C<RPC::Serializer> magic,
meaning just the raw serialized data structures are sent between client and
server. Normally, C<RPC::Serializer> will perform compression, encryption,
ASCII-armoring and hashing of the data it sends, if so configured. If set to a
true value, C<debug> prevents this. It can be very useful when combined with
the C<STDIO> client and server, to test operations, as you can type CALLs in
by hand at the console. The default value is false.

=item C<callbacks>

Hash reference with key value pairs of the callback names and the
corresponding code reference. Currently only callback
C<pre_handler_argument_filter> is working. It will be called B<after> the
arguments were encoded from the RPC call and B<before> your RPC method will
called. When the callback is called, its input parameters are:

=over 4

=item Hash Reference

The contains just one parameter: C<server> and that is the C<Net::Server::*>
.object

=item List of Original RPC Parameters

This is the normal list of parameters for you to filter.

=back

Returned values are the new RPC parameters. In the callback you can modify,
add and/or remove parameters. The call is protected by an C<eval/throw_app>
construct so the code can die if needed. For example:

 my $c = RPC::Serialized::Client::INET->new({
    ... OTHER OPTIONS ...
    callbacks => {
        pre_handler_argument_filter => sub {
            my $opt = shift;
            #   Net::Server::* object:
            #   $opt->{server}
            #   The normal arguments:
            my @arguments = @_;
            #   Return the reversed list of arguments 
            return reverse @arguments;
        },
    }
 });

=back

=head1 CONFIGURING Data::Serializer

The defaults for L<Data::Serializer>, which is used to encode and decode your
method calls and responses, are quite sane so you can safely leave this alone.

However you might prefer to override this and use a particular serialization
format, or enable encryption, and this is quite straightforward to do. Passing
a hash of options within the call to C<new()> at either the client or server
will do this, like so:

 my $c = RPC::Serialized::Client::STDIO->new({
     data_serializer => { serializer => 'YAML::Syck', encoding => 'b64' },
 });

The only option which you cannot alter is C<portable>, and this is forced to
true, meaning that C<Data::Serializer> will ASCII-armor the a data structure
(i.e. encode it in hexadecimal or base64). Of course, if you have enabled the
C<debug> option to C<RPC::Serialized> then C<portable> is ignored.

In most cases, the C<Data::Serializer> module at the RPC server will
auto-detect the settings used, and reply with a packet with the same settings.
Where this might not work is in two cases: First make sure that the serializer
used on the client is installed on the server. Second, make sure any keys and
modules used for encryption on the client are available on the server. With a
standard install of C<RPC::Serialized> there should be no concern here, as it
uses only core Perl modules, and encryption is not enabled.

For further details please see the L<Data::Serializer> manual page.

=head1 CONFIGURING Net::Server

The L<Net::Server> binding shipped with this module has some defaults set,
although none are enforced so you can override all options to that module.

The chosen I<personality> is C<PreFork>, and a C<Single> personality is also
available. If you want to use something else just copy the bundled binding
module (C<RPC::Serialized::Server::NetServer>) and modify as appropriate.
Default settings which differ from those in the native C<Net::Server> are as
follows:

=over 4

=item C<log_level> is set to C<4>

=item C<syslog_facility> is set to C<local1>

=item C<background> is set to C<undef>

=item C<setsid> is set to C<undef>

=back

This means that logging goes to STDERR from the parent server, but to send it
to Syslog instead just do the following (after reading the L<Net::Server>
manual page):

 my $s = RPC::Serialized::Server::NetServer->new({
     net_server => { log_file => 'Sys::Syslog' },
 });

In addition the server does not fork or detach from the shell and go into the
background. For further details please see the L<Net::Server> manual page.

=head1 AUTHORIZATION

The system from which C<RPC::Serialized> derives supports user-based
authorization based on a calling username, the called handler, and the
arguments passed to that handler.

In addition, C<Net::Server> supports IP-based access control lists.

Both of these systems are available although by default disabled. Looking in
the examples folder with this distribution you should find some sample ACLs
for C<RPC::Serialized>. You can also consult the L<Net::Server> manual page
for its options.

For the time being the authorization is not documented here, but it is hoped
this will be remedied before too long! If you want help with authorization
configuration, feel free to email the module author.

=head1 SERVER LOGGING

If you have enabled RPC server logging, using the C<trace> option to C<new()>,
then output is sent via UNIX Syslog. The server will write out a serialized
dump of the data sent and received, using whichever serializer you have set
the server to use. This might not be the same serializer used in the
transaction, however, as explained in the section L</CONFIGURING
Data::Serializer>, above. You will see the CALL, ARGS, RESPONSE and any
EXCEPTIONs raised, in the log.

Logging uses the excellent L<Log::Dispatch> module from CPAN, with its
C<Syslog> personality. The default settings are as follows:

=over 4

=item C<name> is set to C<rpc-serialized>

=item C<min_level> is set to C<info>

=item C<facility> is set to C<local0>

=item C<callbacks> is set to add a newline to each log message

=back

You can override these settings in the configuration file, or the call to
C<new()>, like this:

 my $s = RPC::Serialized::Server::STDIO->new({
     log_dispatch_syslog => { facility => 'local7' },
 });

Log messages will be dispatched to your syslog subsystem at the level set in
C<min_level>. Note that the hash key used is C<log_dispatch_syslog>, as above.

=head2 Suppressing Sensitive Data

If you transmit sensitive data in the arguments to handler calls, but also
wish to log a trace of the handler call+args, then the C<args_suppress_log>
configuration parameter will help.

This parameter takes a Hash reference where they keys are the names of
handlers and the values are Array references of sensitive argument names.
Naturally, this assumes treating of the C<args> list as a Hash of keys/values
by the handler and you would only be able to use this parameter in that
situation. For example:

 $s = RPC::Serialized::Server::NetServer->new({
     rpc_serialized => { args_suppress_log => {
         login => [qw/ password /],
     }},
 });

Using the above configuration, the C<login> handler when called would not log
the value of the C<password> named argument in its C<args>. The text
C<[suppressed]> is output to the log in place of the named argument's value.

=head1 ERROR HANDLING

This module makes use of L<Exception::Class> when it needs to raise a critical
error, but don't fret if this makes no sense to you. The essential concept is
that calls to this module might die, and you need to be able to deal with
that.

The usual way is to wrap calls in an C<eval{}> block to trap errors, like so:

 eval {
     my $now = $c->localtime;
     print "Localtime on the server is: $now\n";
 };
 warn "Remote procedure call failed: $@\n" if $@;

A nifty part of this module (courtesy of the original authors of the code) is
that an exception can be raised in the server and delivered to the client. The
exceptions are C<RPC::Serialized::X> objects, derived from
C<Class::Exception>, of the following types:

=over 4

=item C<RPC::Serialized::X::Protocol> is for an RPC protocol error

=item C<RPC::Serialized::X::Parse> is for a Data::Serializer parser failure

=item C<RPC::Serialized::X::Validation> is for a data validation error

=item C<RPC::Serialized::X::System> is for any system error

=item C<RPC::Serialized::X::Application> is for application programming errors

=item C<RPC::Serialized::X::Authorization> is for an authorization failure

=back

Typically you want to check if it was C<RPC::Serialized> having a problem, or
some other issue:

 eval {
     my $num = $c->cabbages;
     print "Number of cabbages is: $num\n";
 };
 if ($@ and $@->isa('RPC::Serialized::X')) {
     print $@->message, "\n"; # "no handler for cabbages"
 }
 else { die $@ } # rethrow the exception

For further details please see the L<Class::Exception> manual page.

=head1 DIAGNOSTICS

Here is a list of the common error messages and exception types raised by this
module, and probable causes:

=over 4

=item C<Failed to create socket: ...> in an C<X::System>

The C<INET> or C<UNIX> client has failed to set up an L<IO::Socket::INET> or
L<IO::Socket::UNIX> socket respectively.

=item C<Invalid or missing CALL> in an C<X::Protocol>

After de-serializing the incoming data message from the client, there appears
to be no CALL parameter.

=item C<Invalid or missing ARGS> in an C<X::Protocol>

After de-serializing the incoming data message from the client, there appears
to be no ARGS list.

=item C<Failed to load ...> in an C<X::System>

The server has attempted to load the handler specified for the current call,
but failed. Did you specify the correct handler?

=item C<No handler for ...> in an C<X::Application>

After searching any manual handler mappings, or the auto-load namespaces, no
suitable handler package was found for the current call.

=item C<... not a RPC::Serialized::Handler> in an C<X::Application>

Having found a package to load for the current call from the handler
specification, it does not inherit from C<RPC::Serialized::Handler>.

=item C<Cannot search for invalid name: ...> in an C<X::Application>

You are attempting to auto-load a handler whose package name would not be
valid in perl. It must be letters, digits and underscores only.

=item C<Invalid or missing CLASS> in an C<X::Protocol>

An Exception class rasied by the server is not known to the client, so this
exception is raised instead.

=item C<Object method called on class> in an C<X::Application>

You are attempting to invoke a call on the client module directly, rather than
instantiating a new client object from it and then making the call on that.

=item C<Missing or invalid input handle> in an C<X::Application>

The server has not been passed a valid C<IO::Handle> upon which to read data.
The handle is passed in the call to C<new()> or via the C<ifh> accessor method
on the server object.

=item C<Missing or invalid output handle> in an C<X::Application>

The server has not been passed a valid C<IO::Handle> upon which to write data.
The handle is passed in the call to C<new()> or via the C<ofh> accessor method
on the server object.

=item C<Failed to load Log::Dispatch but trace is on: ...> in an C<X::Application>

You have enabled server logging using the C<trace> option, but the
L<Log::Dispatch> or L<Log::Dispatch::Syslog> module has failed to load.

=item C<Data not a hash reference> in an C<X::Protocol>

After de-serializing some data (from the client or server), the data structure
appears not to be a hash reference.

=item C<Failed to send data: ...> in an C<X::System>

A system error has ocurred when sending data through the handle to the client
or server.

=item C<Failed to read data: ...> in an C<X::System>

A system error has ocurred when reading data from the handle to the client or
server.

=item C<Data::Serializer error: ...> in an C<X::Protocol>

An error has been thrown by the L<Data::Serializer> module when initializing.

=item C<Serializer parse error> in an C<X::Protocol>

An error has been thrown by the C<Data::Serializer> module when attempting to
serialize or de-serialize data to or from the client or server.

=back

=head1 DEPENDENCIES

In addition to the contents of the standard Perl C<5.8.4> distribution, this
module requires the following:

=over 4

=item L<Data::Serializer>

=item L<Exception::Class>

=item L<Module::MultiConf>

=item L<Readonly>

=item L<Class::Accessor::Fast::Contained>

=back

To use some optional features, you may require the following:

=over 4

=item L<Net::Server>

=item L<Log::Dispatch>

=item L<GDBM_File>

=back

=head1 THANKS

This module is a derivative of C<YAML::RPC>, written by C<pod> and Ray Miller,
at the University of Oxford Computing Services. Without their brilliant
creation this system would not exist.

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by University of Oxford.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

