# ==================================================================
#   POE::Component::Client::POP3
#   Author  : Scott Beck
#   $Id: POP3.pm,v 1.6 2002/03/15 19:14:45 bline Exp $
# ==================================================================
#
# Description: Impliment a POP3 client for POE
#

package POE::Component::Client::POP3;
# ==================================================================

use strict;
use vars qw($VERSION);

use Carp;

use Socket;
use POE qw( Wheel::SocketFactory Wheel::ReadWrite );

BEGIN { eval 'sub DEBUG () { 0 };' unless defined &DEBUG }

sub EOL         () { "\015\012" }
sub STATE_AUTH  () { 0 }
sub STATE_TRANS () { 1 }

$VERSION = 0.02;

# Start things off

sub spawn {
    my $class = shift;
    my $sender = $poe_kernel->get_active_session;

    croak "$class->spawn requires an event number of argument" if @_ & 1;
    
    my %params = @_;

    my $alias = delete $params{Alias};
    croak "$class->spawn requires an alias to start" unless defined $alias;

    my $user = delete $params{Username};
    my $pass = delete $params{Password};
    my $auth = delete $params{AuthMethod};
    $auth = 'PASS' unless defined $auth;

    my $remote_addr = delete $params{RemoteAddr};
    croak "$class->spawn requires a RemoteAddr parameter"
        unless defined $remote_addr;

    my $remote_port = delete $params{RemotePort};
    $remote_port = 110 unless defined $remote_port;
    
    my $bind_addr = delete $params{BindAddr};
    my $bind_port = delete $params{BindPort};

    my $events = delete $params{Events};
    $events = [] unless defined $events and ref( $events ) eq 'ARRAY';
    my %register;
    for my $opt ( @$events ) {
        if ( ref $opt eq 'HASH' ) {
            @register{keys %$opt} = values %$opt;
        }
        else {
            $register{$opt} = $opt;
        }
    }
    POE::Session->create(
        inline_states => {
            _start        => \&handler_start,
            input         => \&handler_input,
            login         => \&handler_login,
            connected     => \&handler_connected,
            connect_error => \&handler_connect_error,
            ioerror       => \&handler_ioerror,
            retr          => \&handler_retr,
            list          => \&handler_list,
            uidl          => \&handler_uidl,
            top           => \&handler_top,
            dele          => \&handler_dele,
            noop          => \&handler_noop,
            rset          => \&handler_rset,
            quit          => \&handler_quit,
            stat          => \&handler_stat
        },
        heap => {
            alias       => $alias,
            user        => $user,
            pass        => $pass,
            auth        => $auth,
            remote_addr => $remote_addr,
            remote_port => $remote_port,
            bind_addr   => $bind_addr,
            bind_port   => $bind_port,
            state       => STATE_AUTH,
            stack       => [ [ 'init' ] ],
            events      => { $sender => \%register }
        }
    );
}

# Setup our socket connection

sub handler_start {
    my ( $kernel, $heap ) = @_[KERNEL, HEAP];
    
    $heap->{sock_wheel} = POE::Wheel::SocketFactory->new(
        SocketDomain   => AF_INET,
        SocketType     => SOCK_STREAM,
        SocketProtocol => 'tcp',
        BindAddress    => $heap->{bind_addr},
        BindPort       => $heap->{bind_port},
        RemotePort     => $heap->{remote_port},
        RemoteAddress  => $heap->{remote_addr},
        SuccessEvent   => 'connected',
        FailureEvent   => 'connect_error'
    );

    warn "$heap->{alias}: Setting up alias $heap->{alias}" if DEBUG;
    $kernel->alias_set( $heap->{alias} );
}

# After connection we start getting input events with Wheel::ReadWrite

sub handler_connected {
    my ( $kernel, $heap, $socket ) = @_[KERNEL, HEAP, ARG0];

    warn "$heap->{alias}: Connected with $socket" if DEBUG;
    $heap->{rw_wheel} = POE::Wheel::ReadWrite->new(
        Handle     => $socket,
        Filter     => POE::Filter::Line->new( Literal => EOL ),
        InputEvent => 'input',
        ErrorEvent => 'ioerror'
    );
}

# read/write errors

sub handler_ioerror {
    my ( $kernel, $heap, $op, $errnum, $errstr, $wheel_id) =
        @_[KERNEL, HEAP, ARG0..ARG3];

    if ( $errnum == 0 ) {
        send_event( 'disconnected' );
    }
    else {
        warn "$heap->{alias}: IO error for $op $errstr ($errnum) from $wheel_id" if DEBUG;
        send_event( 'error', $heap->{current_action}, $op, $errnum, $errstr );
    }
    stop();
}

# connection errors

sub handler_connect_error {
    my ( $kernel, $heap, $op, $errnum, $errstr, $wheel_id) =
        @_[KERNEL, HEAP, ARG0..ARG3];

    warn "$heap->{alias}: Connect error for $op $errstr ($errnum) from $wheel_id" if DEBUG;
    send_event( 'error', 'connect', $op, $errnum, $errstr );
    stop();
}

# The switch on input

sub handler_input {
    my ( $kernel, $heap, $input ) = @_[KERNEL, HEAP, ARG0];


    my $event = pop( @{$heap->{stack}} ) || ['none', {}];
    my ( $action, $args ) = @$event;
    $action = lc $action;
    $heap->{current_action} = $action;
    warn "$heap->{alias}: Input from $action: ($input)" if DEBUG;

    if ( defined &{"comm_$action"} ) {
        $POE::Component::Client::POP3::{"comm_$action"}->(
            $action,
            $input,
            $args
        );
    }
    else {
        send_trans_event( $action, $input );
    }
}

# When we havn't send any request (before auth)

sub comm_init {
    my ( $action, $input, $args ) = @_;
    my $heap = $poe_kernel->get_active_session()->get_heap();

    $heap->{apop_id} = $1 if $input =~ /<([^>]+)>/;
    send_trans_event( 'connected', $input );

    if ( defined $heap->{user} and defined $heap->{pass} ) {
        $poe_kernel->yield( 'login' );
    }
}

# responce to APOP

sub comm_apop {
    my ( $action, $input, $args ) = @_;
    my $heap = $poe_kernel->get_active_session()->get_heap();

    if ( trans_error( $input ) ) {
        send_trans_error( 'auth', $action, $input );
        return;
    }
    send_trans_event( 'authenticated' );
    $heap->{state} = STATE_TRANS;
}

# responce to USER

sub comm_user {
    my ( $action, $input, $args ) = @_;
    my $heap = $poe_kernel->get_active_session()->get_heap();

    if ( trans_error( $input ) ) {
        send_trans_error( 'auth', $action, $input );
        return;
    }
    # We send the password
    command( [ 'PASS', $heap->{pass} ] );
    # delete it!
    delete $heap->{pass};
}

# responce to PASS

sub comm_pass {
    my ( $action, $input, $args ) = @_;
    my $heap = $poe_kernel->get_active_session()->get_heap();

    if ( trans_error( $input ) ) {
        send_trans_error( 'auth', $action, $input );
        return;
    }
    send_trans_event( 'authenticated' );
    $heap->{state} = STATE_TRANS;
}

# responce to STAT

sub comm_stat {
    my ( $action, $input, $args ) = @_;

    if ( trans_error( $input ) ) {
        send_trans_error( 'trans', $action, $input );
        return;
    }
    send_event( $action, ( split( ' ', $input ) )[1, 2] );
}

# responce to LIST or UIDL

*comm_uidl = \&comm_list;
sub comm_list {
    my ( $action, $input, $args ) = @_;
    my $heap = $poe_kernel->get_active_session()->get_heap();

    if (
        $args->{listing_one} or
        !$args->{got_first_line}
    )
    {
        if ( trans_error( $input ) ) {
            send_trans_error( 'trans', $action, $input );
            return;
        }
    }
    if ( delete $args->{listing_one} ) {
        send_event( $action, { ( split( ' ', $input ) )[1, 2] } );
    }
    else {
        if ( !$args->{got_first_line} ) {
            $args->{got_first_line} = 1;
            push @{$heap->{stack}}, [ $action, $args ];
        }
        elsif ( $input eq '.' ) {
            $args->{lines} ||= {};
            send_event( $action, $args->{lines} );
        }
        else {
            my ( $num, $data ) = ( split( ' ', $input ) )[0, 1];
            $args->{lines}{$num} = $data;
            push @{$heap->{stack}}, [ $action, $args ];
        }
    }
}

# responce to either RETR or TOP

*comm_top = \&comm_retr;
sub comm_retr {
    my ( $action, $input, $args ) = @_;
    my $heap = $poe_kernel->get_active_session()->get_heap();

    if ( !$args->{got_first_line} ) {
        if ( trans_error( $input ) ) {
            send_trans_error( 'trans', $action, $input );
            return;
        }
        $args->{got_first_line} = 1;
        push @{$heap->{stack}}, [ $action, $args ];
    }
    elsif ( $input eq '.' ) {
        if ( defined $args->{handle} ) {
            send_event(
                $action,
                $args->{handle},
                $args->{number}
            );
        }
        else {
            $args->{lines} ||= {};
            send_event(
                $action,
                $args->{lines},
                $args->{number}
            );
        }
    }
    else {

        # Expecting more lines
        push @{$heap->{stack}}, [ $action, $args ];
        if ( defined $args->{handle} ) {
            print {$args->{handle}} $input . EOL;
        }
        else {
            push @{$args->{lines}}, $input;
        }
    }
}

# responce to DELE, NOOP, or RSET

*comm_noop = \&comm_dele;
*comm_rset = \&comm_dele;
sub comm_dele {
    my ( $action, $input, $args ) = @_;

    if ( trans_error( $input ) ) {
        send_trans_error( 'trans', $action, $input );
        return;
    }
    send_trans_event( $action, $input, values %$args );
}

# responce to QUIT

sub comm_quit {
    my ( $action, $input, $args ) = @_;

    send_trans_event( $action, $input, values %$args );
    send_event( 'disconnected', $input );
    stop();
}

# Authenticate, public event

sub handler_login {
    my ( $kernel, $heap, $user, $pass, $type ) =
        @_[KERNEL, HEAP, ARG0 .. ARG2];

    warn "$heap->{alias}: login event called from ".
         "$_[CALLER_FILE] on line $_[CALLER_LINE]\n" if DEBUG;

    assert_auth();

    $heap->{auth} = $type if defined $type;
    $heap->{auth} = 'PASS' unless defined $heap->{auth};

    $heap->{user} = $user unless defined $heap->{user};
    croak "No username defined in login" unless defined $heap->{user};
    $heap->{pass} = $pass unless defined $heap->{pass};
    croak "No password defined in login" unless defined $heap->{pass};

    if ( $heap->{auth} eq 'APOP' ) {
        if (!defined $heap->{apop_id} ) {
            send_event(
                'trans_error',
                'auth',
                'apop',
                "Server does not support APOP authentication"
            );
            return;
        }
        eval {
            require Digest::MD5;
        };
        croak "Unable to do APOP authentication; Digest::MD5 not installed"
            if $@;
        my $hex = Digest::MD5::md5_hex( "<$heap->{apop_id}>$heap->{pass}" );
        command( [ 'APOP', $heap->{user}, $hex ] );
        delete $heap->{pass};
        delete $heap->{user};
    }
    elsif ( $heap->{auth} eq 'PASS' ) {
        command( [ 'USER', $heap->{user} ] );
        delete $heap->{user};
    }
    else {
        croak "Unknown authentication method: $heap->{auth}";
    }
}

# Get the status of all messages

sub handler_stat {
    my ( $kernel, $heap ) = @_[KERNEL, HEAP];

    warn "$heap->{alias}: stat event called from ".
         "$_[CALLER_FILE] on line $_[CALLER_LINE]\n" if DEBUG;

    assert_trans();
    
    command( 'STAT' );
}

# List one or more message

sub handler_list {
    my ( $kernel, $heap, $num ) = @_[KERNEL, HEAP, ARG0];

    warn "$heap->{alias}: list event called from ".
         "$_[CALLER_FILE] on line $_[CALLER_LINE]\n" if DEBUG;

    assert_trans();

    if ( $num ) {
        command( [ 'LIST', $num ], { listing_one => 1 } );
    }
    else {
        command( 'LIST' );
    }
}

# Retrieve a message

sub handler_retr {
    my ( $kernel, $heap, $num, $handle ) = @_[KERNEL, HEAP, ARG0, ARG1];

    warn "$heap->{alias}: retr event called from ".
         "$_[CALLER_FILE] on line $_[CALLER_LINE]\n" if DEBUG;

    croak "Must specify a number for retr"
        unless defined $num;

    assert_trans();

    command( [ 'RETR', $num ], {
        number => $num,
        handle => $handle
    } );
}

# Delete a message

sub handler_dele {
    my ( $kernel, $heap, $num ) = @_[KERNEL, HEAP, ARG0];

    warn "$heap->{alias}: dele event called from ".
         "$_[CALLER_FILE] on line $_[CALLER_LINE]\n" if DEBUG;

    croak "Must specify a number for dele"
        unless defined $num;

    assert_trans();

    command( [ 'DELE', $num ], {
        number => $num
    } );
}

# Keep us from idling

sub handler_noop {
    my ( $kernel, $heap ) = @_[KERNEL, HEAP];

    warn "$heap->{alias}: noop event called from ".
         "$_[CALLER_FILE] on line $_[CALLER_LINE]\n" if DEBUG;

    assert_trans();

    command( 'NOOP' );
}

# Reset status of deletes

sub handler_rset {
    my ( $kernel, $heap ) = @_[KERNEL, HEAP];

    warn "$heap->{alias}: rset event called from ".
         "$_[CALLER_FILE] on line $_[CALLER_LINE]\n" if DEBUG;

    assert_trans();

    command( 'RSET' );
}

# End the session

sub handler_quit {
    my ( $kernel, $heap ) = @_[KERNEL, HEAP, ARG0];

    warn "$heap->{alias}: quit event called from ".
         "$_[CALLER_FILE] on line $_[CALLER_LINE]\n" if DEBUG;

    command( 'QUIT' );
}

# Get the header and n lines from the body

sub handler_top {
    my ( $kernel, $heap, $msg_num, $lines, $handle ) = 
        @_[KERNEL, HEAP, ARG0 .. ARG2];

    croak "Must specify a number for top"
        unless defined $msg_num;

    warn "$heap->{alias}: top event called from ".
         "$_[CALLER_FILE] on line $_[CALLER_LINE]\n" if DEBUG;

    assert_trans();

    if ( defined $lines ) {
        command( [ 'TOP', $msg_num, $lines ], {
            number => $msg_num,
            handle => $handle
        } );
    }
    else {
        command( [ 'TOP', $msg_num ], {
            number => $msg_num,
            handle => $handle
        } );
    }
}

# Get a list of uidls

sub handler_uidl {
    my ( $kernel, $heap, $num ) = @_[KERNEL, HEAP, ARG0];

    warn "$heap->{alias}: uidl event called from ".
         "$_[CALLER_FILE] on line $_[CALLER_LINE]\n" if DEBUG;

    assert_trans();

    if ( $num ) {
        command( [ 'UIDL', $num ], {
            listing_one => 1
        } );
    }
    else {
        command( 'UIDL' );
    }
}

# Register an event to start recieveing

sub handler_register {
    my ( $heap, $sender, @params ) = @_[HEAP, SENDER, ARG0 .. $#_];

    warn "$heap->{alias}: register event called from ".
         "$_[CALLER_FILE] on line $_[CALLER_LINE]\n" if DEBUG;

    my %register;
    for my $opt ( @params ) {
        if ( ref $opt eq 'HASH' ) {
            @register{keys %$opt} = values %$opt;
        }
        else {
            $register{$opt} = $opt;
        }
    }
    for ( keys %register ) {
        $heap->{events}{$sender}{$_} = $register{$_};
    }
}

# Unregister events

sub handler_unregister {
    my ( $heap, $sender, @params ) = @_[HEAP, SENDER, ARG0 .. $#_];

    warn "$heap->{alias}: unregister event called from ".
         "$_[CALLER_FILE] on line $_[CALLER_LINE]\n" if DEBUG;

    my %register;
    for ( @params ) {
        delete $heap->{events}{$sender}{$_};
    }
    delete $heap->{events}{$sender} if !keys %{$heap->{events}{$sender}};
}

# Make assertions

sub assert_trans {
    my $heap = $poe_kernel->get_active_session()->get_heap();

    if ( $heap->{state} != STATE_TRANS ) {
        (my $trans = (caller(1))[3]) =~ s/^.+handler_//;
        croak "Must be in transaction state to call '$trans'";
    }
}

sub assert_auth {
    my $heap = $poe_kernel->get_active_session()->get_heap();

    if ( $heap->{state} != STATE_AUTH ) {
        (my $trans = (caller(1))[3]) =~ s/^.+handler_//;
        croak "Must be in authentication state to call '$trans'";
    }
}

sub trans_error {
    return( index( $_[0], '-ERR' ) == 0 );
}

# Send a command and push the return onto the stack

sub command {
    my ( $cmd_args, $state ) = @_;

    my $heap = $poe_kernel->get_active_session()->get_heap();
    return unless defined $heap->{rw_wheel};
    
    $cmd_args = [$cmd_args] unless ref( $cmd_args ) eq 'ARRAY';
    my $command = uc shift( @$cmd_args );
    $state = {} unless defined $state;
    unshift @{$heap->{stack}}, [$command, $state];
    warn "$heap->{alias}: Output: ", join( ' ', $command, @$cmd_args ) if DEBUG;
    $heap->{rw_wheel}->put( join ' ', $command, @$cmd_args );
}

# Send events to interested sessions

sub send_event {
    my ( $event, @args ) = @_;
    my $heap = $poe_kernel->get_active_session()->get_heap();

    for my $session ( keys %{$heap->{events}} ) {
        if (
            exists $heap->{events}{$session}{$event} or
            exists $heap->{events}{$session}{all}
        )
        {
            $poe_kernel->post(
                $session,
                ( $heap->{events}{$session}{$event} || $event ),
                @args
            );
        }
    }
}

# Format input for a trans_error event and send it

sub send_trans_error {
    my ( $state, $command, $input ) = @_;
    $input =~ s/^-ERR\s*//i if $input;
    send_event( 'trans_error', $state, $command, $input );
}

# Format input for a normal trans event and send it

sub send_trans_event {
    my ( $event, $input, @args ) = @_;
    $input =~ s/^\+OK\s*//i if $input;
    send_event( $event, $input, @args );
}

# Stop everything so we get GCed

sub stop {
    my $heap = $poe_kernel->get_active_session()->get_heap();
    $poe_kernel->alias_remove( $heap->{alias} );
    delete $heap->{rw_wheel};
    delete $heap->{sock_wheel};
}

1;

=head1 NAME

POE::Component::Client::POP3 - Impliment a POP3 client POE component

=head1 SYNOPSIS

    use POE::Component::Client::POP3;

    POE::Component::Client::POP3->spawn(
        Alias      => 'pop_client',
        Username   => 'bob',
        Password   => 'my password',
        AuthMethod => 'APOP',       # Other possible is PASS
        RemoteAddr => '192.168.1.101',
        RemotePort => 110,          # Default
        BindPort   => 1000,         # Default 0
        BindAddr   => INADDR_ANY,   # Default
        Events => [
            'connected',     # when we get connected
            'authenticated', # after authentication happens
            'error',         # write/read error happens
            'trans_error',   # The server returned an -ERR for a transaction
            'disconnected',  # we are disconnected
            'list',          # a list is retrieved
            'retr'           # a message is retrieved
        ]
    );

    # We are connected
    sub connected {
        my $msg = $_[ARG0];
        print "Connection message: $msg\n";
    }

    # We were disconnected
    sub disconnected {
        my $msg = $_[ARG0];
        print "Diconnected\n";
        print "Messgae: $msg\n" if defined $msg;
    }

    # We are authenticated
    sub authenticated {
        my $msg = $_[ARG0];
        print "Authenticated with message $msg\n";
    }

    # Catch errors
    sub error {
        my ( $state, $operation, $errnum, $errstr ) = @_[ARG0..ARG3];
        print "In state $state operation $operation".
              "error $errnum: $errstr\n";
        $poe_kernel->post( 'pop_client', 'quit' );
    }
    sub trans_error {
        my ( $state, $command, $input ) = @_[ARG0..ARG2];
        print "In state $state command $command we got input $input\n";
    }

    # Get a list of messages
    $poe_kernel->post( 
        'pop_client',  # The session we are posting to
        'list'         # Post to our list state
    );
    sub list {
        my $list = $_[ARG0]; # An hash ref

        for ( sort keys %$list ) {
            print "Message number $_ is $list->{$_} bytes\n";
        }
    }

    # Retrieve message 1
    $poe_kernel->post(
        'pop_client', # The session to post to
        'retr',       # retr state
        1,            # message 1
    );
    sub retr {
        # array ref of lines and message number
        my ( $msg, $msg_num ) = @_[ARG0, ARG1];

        print "Message number $msg_num is:\n", join( "\n", @$msg ), "\n";
    }

    # Retrieve the header and the first 10 lines of the
    # body of message 2
    $poe_kernel->post(
        'pop_client', # The session
        'top',        # The state
        2,            # message 2
        10            # header and 10 lines of the body
    );
    sub top {
        my ( $lines, $msg_num ) = @_[ARG0, ARG1];

        print "Message number $msg_num is:\n", join( "\n", @$msg ), "\n";
    }

    # Retrieve message 2 and write it to a file
    open my $handle, "/tmp/msg2" or die "Could not open /tmp/msg2; Reason: $!";
    $poe_kernel->post(
        'pop_client', # The session
        'retr',       # The state
        2,            # Message 2
        $handle       # The file handle to write it to
    );
    sub retr {
        my ( $handle, $msg_num ) = @_[ARG0, ARG1];

        print "Message $msg_num written to fileno ", fileno( $handle ), "\n";
        close $handle; @ Not really needed, it will go out of scope after this
    }

=head1 DESCRIPTION

POE::Component::Client::POP3 is a POE component for interacting with a POP3
server. This means it is an event driven way to communicate with a server that
impliments Post Office Protocol Version 3 see rfc 1939 for details on the
protocol.

=head1 CAVEATS

You should have a full understanding of POE, and atleast a familiarity with
POP3 in order to grok this document.

Throughout this document POE::Component::Client::POP3 will be refered to as
Client::POP3 for obvious reasons.

=head1 METHODS

Client::POP3 only has one public method. All other actions are performed by
posting events back to the session that was created. This is similar to
POE::Component::IRC and many other POE components

=head2 spawn

This method's arguments look like a hash but are really a list. You will call
this method to get everything going, it is similar to most modules new()
method but it does not return an object but creats a session for you to post
events to.

The following is a list of the arguments it takes.

=over

=item Alias

Name of the kernel alias Client::POP3 will make for it's session. You must
supply this. This is what you will be posting events to.

=item Events

An array reference of the events you wish posted back to you when certain
things happen. See L<"register"> elsewhere in the document for a description
of what the array reference should contain.

=item Username

This is the username to login as once we get connected. If you do not specify
this no attempt to login will be made once we connect.

=item Password

The password to use for authentication. If not specified no attempt will be
made to authenticate once we are connected. You will need to catch the
connection event and do the authentication yourself by posting a login
event with the proper username and password see L<"login"> elsewhere in
this document.

=item AuthMethod

This is the type of authentication we will attempt on the remote server. There
are two type APOP and PASS. PASS method use the USER and PASS command to send
the username and password in the clear. The APOP method used the APOP command
to send the username and password. The password is md5 encoded with a string
from the server before it is sent. The remote server must support APOP in
order for this to work, see RFC1932 page 15 for further description of how this
works. This method requires Digest::MD5 be installed.

=item RemoteAddr

This is the hostname or ip address of the remote POP3 server we are connecting
to, it is required.

=item RemotePort

This is the port on the remote machine we are connecting to. It will default
to 110 if not defined.

=item BindAddr

This supplies the address where the socket will be bound to. BindAddr may
contain a string or a packed Internet address. The string form should hold
either an ip address or a hostname. This defaults to INADDR_ANY.

=item BindPort

This contains a port on the BindAddr to bind to. It defaults to zero. BindPort
may be either a port number or a named service. See perldoc -f bind for more 
information.

=back

=head1 INPUT

Client::POP3 receives events from the session or sessions that want it to
perform actions. These events are posted to the Alias you specified when you
called spawn(). For example:

    $poe_kernel->post( 'alias_i_set', 'list' );

Assuming you set Alias to 'alias_i_set', this will tell Client::POP3 to send
a LIST command to the server, when the data is received Client::POP3 will then
send you a 'list' event or whatever you aliased the 'list' event to.

This is a list of all the events you should post to the Client::POP3 session.

=over

=item register

In order to tell Client::POP3 what events you would like and would not like
you need to regester them or unregister them. The event register takes a list
of arguments. If an argument is a hash, the key will be the event Client::POP3
has to post and the value will be the event you would like posted in to your
session. If the argument is a scalar it will register that event to post to
your session by it's own name. For example:

    $kernel->post(
        'pop_client',
        'register'
        'list',
        { error => 'oops' }
    );

Will tell Client::POP3 to post 'list' to you when that event happens and to
post 'oops' to you when the error event happens. The order of the arguments
does not matter.

=item unregister

To unregister an event (Client::POP3 stops posting it to you) simply post an
event unregister with the list of event you no longer care about and they
will not be sent to you any longer. For example:

    $poe_kernel->post( 'pop_client', 'unregister', 'error', 'list' );

Would unregister the events 'error' and 'list'.

=item login

This is the event that causes Client::POP3 to attempt to login to the remote
server. This event should only be posted after the connection is established.
Arguments to this event are username, password, auth type. In that order. Here
is an example

    $poe_kernel->post(
        'pop_client',
        'login',
        "bob",
        "bob's password",
        "PASS"
    );

This will tell Client::POP3 to login as USER 'bob' with PASS 'bob's password'
using the PASS method. The third argument is not manditory and if omited will
default to PASS.

You will generally not need to send this event unless an error happens during
login and you wish to resubmit a different username and password to the
server, as this event is fired automaticly when you specify the Username and
Password parameters to spawn().


=item stat

Send a STAT command to the server. This gets the size and number of messages
on the remote server. A 'stat' event is posted back to you when the
information is retrieved. This event takes no arguments.

    $poe_kernel->post( 'pop_client', 'stat' );


=item list

Send a LIST command to the server. This event can take either one or no
arguments. In the no argument for a list of all the messages on the remote
server is posted back to you, with there sizes. If a single argument is
given it is expected to be the number of the message you wish to list,
in this case just that messages size and number is posted back to you.

    $poe_kernel->post( 'pop_client', 'list' );
    -or-
    $poe_kernel->post( 'pop_client', 'list', $message_number );


=item uidl

This event is very similar to 'list' in what it does and takes. You can
post this event with no arguments to get a list of all the messages and
there uidl (unique id) or you can send an argument that is expected to
be the message number you with the uidl for.

    $poe_kernel->post( 'pop_client', 'uidl' );
    -or-
    $poe_kernel->post( 'pop_client', 'uidl', $msg_number );


=item retr

This events is to get an email off the remote server. The arguments are
the message number to get and an optional filehandle to write the message
to. If no filehandle is given, when the message is retrieved, the 'retr'
event will be posted to you with an array reference of all the lines in the
email. If given with a filehandle, after the message is written to the handle,
the 'retr' event posted to you will contain the filehandle that it was written
to instead of the lines in an array.

    $poe_kernel->post( 'pop_client', 'retr', $msg_number );
    -or-
    $poe_kernel->post( 'pop_client', 'retr', $msg_number, \*FH );


=item top


This event acts the same as the 'retr' however there is one additional
argument, the number of lines from the body to retrieve. If the number
of lines if not defined the entire body is retrieved.

    $poe_kernel->post( 'pop_client', 'top', $msg_number, $num_lines );
    -or-
    $poe_kernel->post( 'pop_client', 'top', $msg_number, $num_lines, \*FH );


=item dele

This is how you delete messages from the remote server. The messages are
not actually deleted until you post a 'quit' event. The only argument to this
event is the number message to delete. You would get this message number from
a 'list' event.

    $poe_kernel->post( 'pop_client', 'dele', $msg_number );


=item noop

This event tells Client::POP3 to send a NOOP command to the server, this is good
for servers that have a timeout on connection in that it usually resets the
timeout. This event takes no arguments.

    $poe_kernel->post( 'pop_client', 'noop' );


=item rset

This event tells Client::POP3 to send a RSET command to the server. This tells
the server to reset all delete flags. This event takes no arguments.

    $poe_kernel->post( 'pop_client', 'rset' );


=item quit

This event causes Client::POP3 to call quit on the remote server and to
disconnect. This event takes no arguments.

    $poe_kernel->post( 'pop_client', 'quit' );

=back

=head1 OUTPUT

These are events that you may request to be posted to your session. You do
this by specifing them when you call spawn() with the 'Events' argument or by
posting the event 'register'.

=over

=item trans_error

This event is posted when the server send us an error reply to a command.
e.i. -ERR Command not implimented. The -ERR part of the message is stripped
off before it is sent to you. The arguments to the event handler are state,
command, and server input. State will be one of auth or trans. auth means we
were not authenticated yet and trans means we were.

    sub trans_error {
        my ( $state, $command, $server_input ) = @_[ARG0..ARG2];
        ...
    }


=item error

This event is fired when Wheel::ReadWrite sends us an error, usually either a
read or write error. Four arguments are passed to this event handler. The
first one is the state we were in, 'connect', 'auth' or 'trans'. 'auth'
meaning were are in the authentication state, 'trans' meaning we were in
the transaction state and 'connect' meaning we have yet to connect. The second
argument is the operation that failed, probably 'read' or 'write', the third
argument is the error number, this corresponds to Errno, see L<Errno> for
details on what this number means. The last argument is the error string, e.g.
"Socket is not connected".

    sub error {
        my ( $state, $operation, $errnum, $errstr ) = @_[ARG0..ARG3];
        ...
    }


=item connected

This event is fired after the socket has been connected but before
authentication. If you didn't specify the 'Username' and 'Password' parameters
you would want to post a 'login' event to Clinet::POP3 now.

    sub connected {
        my $server_input = $_[ARG0];
        ...
    }


=item disconnected

This event is fired when the socket is disconnected. You will not get this
event if the socket was diconnected with an error, you will get the 'error'
event instead. You should also expect this event after you post a 'quit'
event. One argument is posted to this event's handler, and that is what the
server said, if the server closes the connection without saying goodbye :(
the argument will be undefined.

    sub disconnected {
        my $server_input = defined( $_[ARG0] ) ? $_[ARG0] : 'None';
        ...
    }


=item authenticated

This event is fired after athentication succeeds. You will want to catch this
event in order to start performing operations like listing messages and
whatnot. No arguments are passed to this events handler.

    sub authenticated {
        ...
    }


=item stat

This event is fired when we receive the return of a stat request done on the
server. The arguments to this events handler is the number of messages and
the total size of all messages.

    sub stat {
        my ( $num_msgs, $size_msgs ) = @_[ARG0, ARG1];
        ...
    }


=item list

Fired when we receive the output from a list command. The only argument is
a hash reference, the keys are the message numbers and the values are the
sizes of the messages.

    sub list {
        my $list_href = $_[ARG0];
        ...
    }


=item uidl

Fired when we receive the output from a uidl command. The only argument is
a hahs reference, the keys are the message numbers and the values are the
unique uidl's.

    sub uidl {
        my $uidl_href = $_[ARG0];
        ...
    }


=item retr

This event is fired when we finish receiving a an email requested by a retr
command. If you requested the message be written to a filehandle then the
first argument is the filehandle else the first argument is an array reference
of the lines of the message with no EOL character on them. The second argument
is the message number retrieved.

    sub retr {
        my ( $msg_aref, $msg_num ) = @_[ARG0, ARG1];
        ...
    }
    -or-
    sub retr {
        my ( $msg_fh, $msg_num ) = @_[ARG0, ARG1];
        ...
    }


=item top


This event is fired when we have finished getting the output from a top
command. If you requesed to have the output written to a filehandle, the
first argument to this event's handler is the filehandle it was written to
else the first argument is an array of lines without an EOL. The second
argument if the message number retrieved.

    sub top {
        my ( $msg_aref, $msg_num ) = @_[ARG0, ARG1];
        ...
    }
    -or-
    sub top {
        my ( $msg_fh, $msg_num ) = @_[ARG0, ARG1];
        ...
    }


=item dele

Fired when the responce to a dele command is returned. The event's handler
receives two arguments. The first is the response from the server without
the +OK at the beginning. The second is the message number marked for
deletion.

    sub dele {
        my ( $server_input, $msg_num ) = @_[ARG0, ARG1];
        ...
    }


=item noop

Fired when the responce from a noop command is returned. The only argument is
the responce from the server without the +OK at the start of it.

    sub noop {
        my $server_input = $_[ARG0];
        ...
    }


=item rset

Fired when the responce from a rset command is returned. The only argument is
the responce from the server without the +OK at the start of it.

    sub rset {
        my $server_input = $_[ARG0];
        ...
    }


=item quit

Fired when the responce from a quit command is returned. The only argument is
the responce from the server without the +OK at the start of it. NOTE: You may
never get this event when you quit, many servers do not send a responce to a
quit command.

    sub quit {
        my $server_input = $_[ARG0];
        ...
    }

=back

=head1 SEE ALSO

L<POE>, L<perl>, RFC1939, RFC1957, RFC1725

=head1 BUGS

Plenty I'm sure.

=head1 AUTHORS & COPYRIGHTS

Except where otherwise noted, POE::Component::Client::POP3 is Copyright
2002-2003 Scott Beck <scott@gossamer-threads.com>. All rights reserved.
POE::Component::Client::POP3 is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.


