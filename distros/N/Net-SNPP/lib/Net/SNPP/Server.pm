package Net::SNPP::Server;
use strict;
use warnings;
use Socket;
use IO::Handle;
use Net::Cmd;
use Fcntl qw(:flock);
use Carp;
use vars qw( @ISA $counter );
@ISA = qw( IO::Handle Net::Cmd );
$counter = 0;

=head1 NAME

Net::SNPP::Server

=head1 DESCRIPTION

An object interface for creating SNPP servers.  Almost everything you
need to create your very own SNPP server is here in this module.
There is a callback() method that can replace default function with
your own.
them.  Any SNPP command can be overridden or new/custom ones can be 
created using custom_command().  To disable commands you just don't
want to deal with, use disable_command().

=head1 SYNOPSIS

There may be a synopsis here someday ...

=head1 METHODS

=over 4

=item new()

Create a Net::SNPP::Server object listening on a port.  By default, it only
listens on the localhost (127.0.0.1) - specify MultiHomed to listen on all
addresses or LocalAddr to listen on only one.

 my $svr = Net::SNPP::Server->new(
    Port       => port to listen on
    BindTo     => interface address to bind to
    MultiHomed => listen on all interfaces if true (and BindTo is unset)
    Listen     => how many simultaneous connections to handle (SOMAXCONN)
    # the following two options are only used by handle_client()
    MaxErrors  => maximum number of errors before disconnecting client
    Timeout    => timeout while waiting for data (uses SIGARLM)
 );

=cut

sub new {
    my( $class, %args ) = @_;
    my $self = {};

    # set defaults for basic parameters
    if ( !exists($args{Listen})    ) { $args{Listen} = SOMAXCONN }
    if ( !exists($args{Port})      ) { $args{Port} = 444 }

    # choose either a unix domain socket or an inet socket
    if ( !exists($args{UnixSocket}) ) { $args{Domain}    = AF_INET }
    else { $args{Domain} = PF_UNIX }

    # by default, bind only to the loopback interface
    # i.e. MultiHomed and BindTo were not specified
    if ( !exists($args{MultiHomed}) && !exists($args{BindTo}) ) {
        $args{BindTo} = INADDR_LOOPBACK;
    }
    # if a bind address is passed in, bind to it
    elsif ( exists($args{BindTo}) ) {
        $args{BindTo} = inet_aton( $args{BindTo} );
    }
    # bind to all interfaces if MultiHomed is defined
    # and BindTo is not
    else {
        $args{BindTo} = INADDR_ANY;
    }

    # these two values are only used by the handle_client method
    $self->{'MaxErrors'} = delete($args{MaxErrors});
    $self->{'Timeout'}   = delete($args{Timeout});

    # create the socket by hand instead of IO::Socket::INET to
    # make manipulation a little easier within this module
    $self->{sock} = IO::Handle->new();
    socket( $self->{sock}, $args{Domain}, SOCK_STREAM, getprotobyname('tcp') )
        || croak "couldn't create socket: $!";
    setsockopt( $self->{sock}, SOL_SOCKET, SO_REUSEADDR, 1 );

    if ( $args{Domain} == PF_UNIX ) {
        if ( -e $args{UnixSocket} ) { unlink( $args{UnixSocket} ) }
        $self->{sockaddr} = sockaddr_un( $args{UnixSocket} )
            || croak "couldn't get socket address: $!";
    }
    else {
        $self->{sockaddr} = sockaddr_in( $args{Port}, $args{BindTo} )
            || croak "couldn't get socket address: $!";
    }

    bind( $self->{sock}, $self->{sockaddr} )
        || croak "could not bind socket: $!";

    listen( $self->{sock}, $args{Listen} )
        || croak "could not listen on socket: $!";

    # set default callbacks
    $self->{CB} = {
        process_page => sub {
            my( $pgr, $page, $results ) = @_;
            push( @$results, [ $pgr, $page ] );
        },
        validate_pager_id => sub {
            return undef if ( $_[0] =~ /\D/ || length($_[0]) < 7 );
            return $_[0];
        },
        validate_pager_pin => sub { $_[1] || 1 },
        write_log => sub { print STDERR "@_\n" },
        create_id_and_pin => sub {
            srand(); # re-seed the pseudrandom number generator
            return( time().$counter, int(rand(1000000000)) );
        }
    };

    # initialize disabled and custom commands hashrefs
    $self->{disabled} = {};
    $self->{custom}   = {};
    
    return bless( $self, $class );
}

=item client()

Calls accept() for you and returns a client handle.  This method
will block if there is no waiting client.  The handle returned
is a subclass of IO::Handle, so all IO::Handle methods should work.
 my $client = $server->client();

=cut

sub client {
    my $handle = IO::Handle->new();
    accept( $handle, $_[0]->{sock} );
    return bless($handle, ref($_[0]));
}

=item ip()

Return the IP address associated with a client handle.
 printf "connection from %s", $client->ip();

=cut

sub ip {
    my $remote_client = getpeername($_[0]);
    return 'xxx.xxx.xxx.xxx' if ( !defined($remote_client) );
    my($port,$iaddr) = unpack_sockaddr_in($remote_client);
    return inet_ntoa($iaddr);
}

=item socket()

Returns the raw socket handle.  This mainly exists for use with select() or
IO::Select.
 my $select = IO::Select->new();
 $select->add( $server->socket() );

=cut

sub socket { $_[0]->{sock}; }

=item connected()

For use with a client handle.  True if server socket is still alive.

=cut

sub connected { $_[0]->opened() && getpeername($_[0]) }

=item shutdown()

Shuts down the server socket.
 $server->shutdown(2);

=cut

sub shutdown { shutdown($_[0],$_[1] || 2) }

=item callback()

Insert a callback into Server.pm.
 $server->callback( 'process_page', \&my_function );
 $server->callback( 'validate_pager_id', \&my_function );
 $server->callback( 'validate_pager_pin', \&my_function );
 $server->callback( 'write_log',    \&my_function );
 $server->callback( 'create_id_and_pin', \&my_function );

=over 2

=item process_page( $PAGER_ID, \%PAGE, \@RESULTS )

$PAGER_ID = [
   0 => retval of validate_pager_id
   1 => retval of validate_pager_pin
]
$PAGE = {
   mess => $,
   responses => [],
}

=item validate_pager_id( PAGER_ID )

The return value of this callback will be saved as the pager id
that is passed to the process_page callback as the first list
element of the first argument.

=item validate_pager_pin( VALIDATED_PAGER_ID, PIN )

The value returned by this callback will be saved as the second
list element in the first argument to process_page.  
The PAGER_ID input to this callback is the output from the
validate_pager_id callback.

NOTE: If you really care about the PIN, you must use this callback.  The default callback will return 1 if the pin is not set.

=item write_log

First argument is a Unix syslog level, such as "warning" or "info."
The rest of the arguments are the message.  Return value is ignored.

=item create_id_and_pin

Create an ID and PIN for a 2way message.

=back

=cut

sub callback ($ $ $) {
    croak "first argument callback() to must be one of: ", join(', ', keys(%{$_[0]->{CB}}))
        if ( !exists($_[0]->{CB}{$_[1]}) );
    croak "second argument callback() to must be a CODE ref"
        if ( ref($_[2]) ne 'CODE' );
    $_[0]->{CB}{$_[1]} = $_[2];
}

=item custom_command()

Create a custom command or override a default command in handle_client().
The command name must be 4 letters or numbers.  The second argument is a coderef
that should return a text command, i.e. "250 OK" and some "defined" value to continue the
client loop.  +++If no value is set, the client will be disconnected after
executing your command.+++ If you need MSTA or KTAG, this
is the hook you need to implement them.

The subroutine will be passed the command arguments, split on whitespace.

 sub my_MSTA_sub {
    my( $id, $password ) = @_;
    # ...
    return "250 OK", 1;
 }
 $server->custom_command( "MSTA", \&my_MSTA_sub );

=cut

sub custom_command ($ $ $) {
    croak "first argument to custom_command must be exactly 4 characters"
        if ( length($_[1]) != 4 );
    croak "second argument to custom_command must be a coderef"
        if ( ref($_[2]) ne 'CODE' );
    $_[0]->{custom}{uc($_[1])} = $_[2];
}

=item disable_command()

Specify a command to disable in the server.  This is useful, for instance,
if you don't want to support level 3 commands.
 $server->disable_command( "2WAY", "550 2WAY not supported here" );

The second argument is an optional custom error message.  The default is:
 "500 Command Not Implemented, Try Again"

=cut

sub disable_command {
    # shorten & uppercase it so it matches in handle_client
    my $cmd = unpack('A4',uc($_[1]));

    if ( defined($_[2]) ) {
        $_[0]->{disabled}{$cmd} = $_[2];
    }
    else {
        $_[0]->{disabled}{$cmd} = "500 Command Not Implemented, Try Again";
    }
}

=item handle_client()

Takes the result of $server->client() and takes care of parsing
the user input.   This should be quite close to being rfc1861
compliant.  If you specified Timeout to be something other
than 0 in new(), SIGARLM will be used to set a timeout.  If you
use this, make sure to take signals into account when writing your
code.  fork()'ing before calling handle_client is a good way
to avoid interrupting code that shouldn't be interrupted.

=cut

sub handle_client ($ $) {
    my( $self, $client )  = @_;
    my $page = {};    # store the stuff the user gives us in this hash
    my @pgrs = ();    # store the list of pagers
                      # each pager is an array ref [ $pager_id, $pin ]
    my @retvals = (); # build up a list of return values
    my $errors  = 0;  # count the errors for maximum errors
    my $timeout = 0;
    local(%SIG);

    # enable timeouts if user requested passed Timeout to new()
    if ( $self->{'Timeout'} ) {
        $SIG{ALRM} = sub {
            $self->{CB}{write_log}->( 'debug', "client timeout" );
            $client->command( "421 Timeout, Goodbye" );
            $client->shutdown(2);
            $timeout = 1;
        };
        alarm( $self->{'Timeout'} );
    }

    # let the client know we're ready for them
    $client->command( "220 SNPP Gateway Ready" );

    $self->{CB}{write_log}->( 'debug', "client connected" );

    # loop until timeout or client quits
    while ( $timeout == 0 && (my $input = $client->getline()) ) {
        # clean \n\r's out of input, then split it up by whitespace
        $input =~ s/[\r\n]+//gs;
        my @cmd = split( /\s+/, $input );

        # uppercase and truncate the command shifted from @cmd to 4 characters
        my $user_cmd = unpack('A4',uc(shift(@cmd)));
        if ( length($user_cmd) != 4 ) {
            # FIXME: put in correct full text from RFC document
            $client->command( "550 Error, Invalid Command" );
        }

        $self->{CB}{write_log}->( 'debug', "processing command '$user_cmd @cmd'" );
        
        # //////////////////////////////////////////////////////////////////// #
        #                       BEGIN COMMANDS PARSING                         #
        # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ #

        ########################################################################
        # user disabled commands --------------------------------------------- #
        if ( exists($self->{disabled}{$user_cmd}) ) {
            $errors++;
            $client->command( $self->{disabled}{$user_cmd} );
        }
        ########################################################################
        # user custom commands ----------------------------------------------- #
        elsif ( exists($self->{custom}{$user_cmd}) ) {
            my ($cmdtxt,$cont) = $self->{custom}{$user_cmd}->( @cmd );
            $client->command( $cmdtxt );
            last if ( !$cont );
        }
        ########################################################################
        # 4.3 Level 1 Commands #################################################
        ########################################################################
        # 4.3.1 PAGEr <Pager ID> --------------------------------------------- #
        # 4.5.2 PAGEr <PagerID> [Password/PIN] ------------------------------- #
        elsif ( $user_cmd eq 'PAGE' ) {
            my $valid_pgr_id = $self->{CB}{validate_pager_id}->($cmd[0]);
            my $valid_pin    = $self->{CB}{validate_pager_pin}->($valid_pgr_id,$cmd[1]);
            if ( $valid_pgr_id && $valid_pin ) {
                    push( @pgrs, [$valid_pgr_id,$valid_pin] );
                    $client->command( "250 Pager ID Accepted" );
            }
            else {
                $errors++;
                $client->command( "550 Error, Invalid Pager ID" );
            }
        }

        ########################################################################
        # 4.3.2 MESSage <Alpha or Numeric Message> --------------------------- #
        # 4.5.8 SUBJect <MessageSubject> ------------------------------------- #
        elsif ( $user_cmd =~ /(MESS|SUBJ)/ ) {
            my $key = $1;
            if ( $key && $key eq 'MESS' && defined($page->{mess}) ) {
                $errors++;
                $client->command( "503 ERROR, Message Already Entered" );
                next;
            }
            if ( !defined($cmd[0]) || $cmd[0] eq '' ) {
                $errors++;
                $client->command( "550 ERROR, Invalid Message" );
                next;
            }
            $page->{lc($key)} = join(' ', @cmd);
            $client->command( "250 Message OK" );
        }

        ########################################################################
        # 4.3.3 RESEt -------------------------------------------------------- #
        elsif ( $user_cmd eq 'RESE' ) {
            $page = {};
            @pgrs = ();
            $client->command( "250 RESET OK" );
        }

        ########################################################################
        # 4.3.4 SEND --------------------------------------------------------- #
        elsif ( $user_cmd eq 'SEND' ) {
            if ( @pgrs == 0 ) {
                $errors++;
                $client->command( "503 Error, Pager ID needed" );
                next;
            }
            if ( !exists($page->{mess}) ) {
                $errors++;
                $client->command( "503 Error, Pager ID or Message Incomplete" );
                next;
            }

            my $res  = undef;
            for ( my $i=0; $i<@pgrs; $i++ ) {
                if ( !exists($page->{alert}) ) { $page->{alert} = 0 }
                if ( !exists($page->{hold})  ) { $page->{hold}  = 0 }

                # call the callback subroutine with the data
                # the default callback just pushes the data onto @retvals
                $res = $self->{CB}{process_page}->( $pgrs[$i], $page, \@retvals );
            }
            if ( $res && exists($page->{twoway}) ) {
                # this callback generates the two numbers for identifying a page
                my @tags = $self->{CB}{create_id_and_pin}->( \@pgrs, $page );
                $client->command( "960 @tags OK, Message QUEUED for Delivery" );
            }
            elsif ( $res ) {
                $client->command( "250 Message Sent Successfully" );
            }
            else {
                $client->command( "554 Error, failed" );
                next;
            }
            # RESEt
            @pgrs = ();
            $page = {};
        }

        ########################################################################
        elsif ( $user_cmd eq 'QUIT' ) {
            $client->command( "221 OK, Goodbye" );
            last;
        }

        ########################################################################
        # 4.3.6 HELP (optional) ---------------------------------------------- #
        elsif ( $user_cmd eq 'HELP' ) {
            {
                no warnings; # so we can use <DATA>
                while (<DATA>) { $client->command( $_ ) }
                $client->command( "250 End of Help Information" );
            }
        }

        ########################################################################
        ## 4.4 Level 2 - Minimum Extensions ####################################
        ########################################################################
        # 4.4.1 DATA --------------------------------------------------------- #
        elsif ( $user_cmd eq 'DATA' ) {
            $client->command( "354 Begin Input; End with <CRLF>'.'<CRLF>" );
            my $buffer = join( '', @{ $client->read_until_dot() } );
            if ( !defined($buffer) || !length($buffer) ) {
                $errors++;
                $client->command( "550 Error, Blank Message" );
            }
            else {
                $buffer =~ s/[\r\n]+/\n/gs;
                $page->{mess} = $buffer;
                $client->command( "250 Message OK" );
            }
        }

        ########################################################################
        ## 4.5 Level 2 - Optional Extensions ###################################
        ########################################################################
        # 4.5.4 ALERt <AlertOverride> ---------------------------------------- #
        elsif ( $user_cmd eq 'ALER' ) {
            if ( defined($cmd[0]) && ($cmd[0] == 1 || $cmd[0] == 0) ) {
                $page->{alert} = $cmd[0];
                $client->command( "250 OK, Alert Override Accepted" );
            }
            else {
                $errors++;
                $client->command( "550 Error, Invalid Alert Parameter" );
            }
        }

        ########################################################################
        # 4.5.6 HOLDuntil <YYMMDDHHMMSS> [+/-GMTdifference] ------------------ #
        # non-rfc <YYYYMMDDMMSS> to accept 4-digit years is also accepted ---- #
        elsif ( $user_cmd eq 'HOLD' ) {
            if ( defined($cmd[0]) && $cmd[0] !~ /[^0-9]/
                  && (length($cmd[0]) == 12 || length($cmd[0]) == 14) ) {
                $page->{hold} = $cmd[0];
                if ( $cmd[1] =~ /([+-]\d+)/ ) { $page->{hold_gmt_diff} = $1; }
                $client->command( "250 Delayed Messaging Selected" );
            }
            else {
                $errors++;
                $client->command( "550 Error, Invalid Delivery Date/Time" );
            }
        }

        ########################################################################
        ## 4.6 Level 3 - Two-Way Extensions ####################################
        ########################################################################
        # 4.6.1 2WAY --------------------------------------------------------- #
        elsif ( $user_cmd eq '2WAY' ) {
            if ( exists($page->{mess}) || @pgrs > 0 ) {
                $errors++;
                $client->command( "550 Error, Standard Transaction Already Underway, use RESEt" );
                next;
            }
            $page->{twoway} = 1;
            $client->command( "250 OK, Beginning 2-Way Transaction" );
        }

        ########################################################################
        # 4.6.2 PING <PagerID | Alias> --------------------------------------- #
        # FIXME: what the heck should this do by default?
        elsif ( $user_cmd eq 'PING' ) {
            $client->command( "250 OK, Cannot access device status" );
        }

        ########################################################################
        # 4.6.7 MCREsponse <2-byte_Code> Response_Text (not implemented) ----- #
        elsif ( $user_cmd eq 'MCRE' ) {
            if ( !exists($page->{twoway}) ) {
                $errors++;
                $client->command( "550 MCResponses Not Enabled" );
            }
            elsif ( $cmd[0] !~ /[^0-9]/ && length($cmd[0]) < 3 &&
                 length($cmd[1]) >= 1 && length($cmd[1]) < 16 ) {
                    if ( exists($page->{responses}{$cmd[0]}) ) {
                        $client->command( "502 Error! Would Duplicate Previously Entered MCResponse" );
                        next;
                    }
                    $page->{responses}{shift @cmd} = join(' ',@cmd);
                    $client->command( "250 Response Added to Transaction" );
            }
            else {
                $errors++;
                $client->command( "554 Error, failed" );
            }
        }
        ########################################################################
        # UNKNOWN/UNDEFINED COMMANDS ----------------------------------------- #
        # -------------------------------------------------------------------- #
        # 4.5.1 LOGIn <loginid> [password] (not implemented) ----------------- #
        # 4.5.3 LEVEl <ServiceLevel>       (not implemented) ----------------- #
        # 4.5.5 COVErage <AlternateArea>   (not implemented) ----------------- #
        # 4.5.7 CALLerid <CallerID>        (not implemented) ----------------- #
        # 4.6.3 EXPTag <hours>             (not implemented) ----------------- #
        # 4.6.5 ACKRead <0|1>              (not implemented) ----------------- #
        # 4.6.6 RTYPe <Reply_Type_Code>    (not implemented) ----------------- #
        # MSTA --------------------------------------------------------------- #
        # KTAG <Message_Tag> <Pass_Code>   (not implemented) ----------------- #
        ########################################################################
        else {
            $errors++;
            $client->command( "500 Command Not Implemented, Try Again" );
        }
        # //////////////////////////////////////////////////////////////////// #
        #                         END COMMANDS PARSING                         #
        # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ #

        # check the number of errors
        if ( $self->{MaxErrors} && $errors >= $self->{MaxErrors} ) {
            $client->command( "421 Too Many Errors, Goodbye (terminate connection)" );
            last;
        }
        # reset the alarm on input
        if ( $self->{Timeout} ) { alarm(0); alarm( $self->{Timeout} ); }
    } # while()

    # turn off the alarm
    if ( $self->{Timeout} ) { alarm(0); }

    # disconnect if we're still connected
    if ( $client->connected() ) { $client->shutdown(2) }

    return @retvals;
}

=item forked_server()

Creates a server in a forked process.  The return value is
an array (or arrayref depending on context) containing a read-only pipe and
the pid of the new process.  Pages completed will be written to the pipe as
a semicolon delimited array.
 my($pipe,$pid) = $server->forked_server();
 my $line = $pipe->getline();
 chomp( $line );
 my( $pgr, $pgr, %pagedata ) = split( /;/, $line );

=cut

# when testing, pass in an integer argument to limit the number of clients
# the server will process before exiting
sub forked_server {
    my( $self, $count_arg ) = @_;
    my $count = -1;
    if ( $count_arg ) { $count = $count_arg }
    my @pids = (); # pids to merge before exit

	# create a pipe for communication from child back to this process
	our( $rp, $wp ) = ( IO::Handle->new(), IO::Handle->new() );
	pipe( $rp, $wp )
	    || die "could not create READ/WRITE pipes";
    $wp->autoflush(1);

    # declare our callback subroutine for process_page 
    # has it's own ugly serialization that should probably be replaced
    # with Storable or Dumper
    sub write_to_pipe {
        my( $pgr, $page, $results ) = @_;
        my( @parts, @resps ) = ();
        if ( my $href = delete($page->{responses}) ) {
            while ( my($k,$v) = each(%$href) ) {
                $v =~ s/;/\%semicolon%/g;
                $k = "responses[$k]";
                push( @resps, $k, $v );
            }
        }
        while ( my($k,$v) = each(%$page) ) {
            if ( !defined($v) ) { $v = '' }
            push( @parts, $k, $v );
        }
        if ( !defined($pgr->[1]) ) { $pgr->[1] = '1' }
        my $out = join( ';', @$pgr, @parts, @resps );
        $out =~ s/[\r\n]+//gs; # make sure there aren't any unexpected newlines

        # send the page semicolon delimited down the pipe
        flock( $wp, LOCK_EX );
        $wp->print( "$out\n" );
        flock( $wp, LOCK_UN );
    }

	# fork a child process to act as a server
	my $pid = fork();
	if ( $pid ) {
	    $wp->close();
        return wantarray ? ($rp,$pid) : [$rp,$pid];
	}
	else {
	    $rp->close();
        # replace the page callback with our own subroutine
        $self->callback( 'process_page', \&write_to_pipe );
        while ( !$count_arg || $count > 0 ) {

            # attempt reap child processes on every loop
            for ( my $i=0; $i<@pids; $i++ ) {
                my $pid = waitpid( $pids[$i], 0 );
                if ( $pid < 1 ) { splice( @pids, $i, 1 ); }
            }

            # get a client socket handle
	        my $client = $self->client();

            $count--;

            # fork again so we can handle simultaneous connections
            my $pid = fork();

            # parent process goes back to top of loop
            if ( $pid ) {
                push( @pids, $pid );
                next;
            }
            
            $self->handle_client( $client );
            exit 0;
	    }
        $wp->close();
	    exit 0;
	}
}

=back

=head1 AUTHOR

Al Tobey <tobeya@tobert.org>

Some ideas from Sendpage::SNPPServer
 Kees Cook <cook@cpoint.net> http://outflux.net/

=head1 TODO

Add more hooks for callbacks

Implement the following level 2 and level 3 commands

 4.5.1 LOGIn <loginid> [password]
 4.5.3 LEVEl <ServiceLevel>
 4.5.5 COVErage <AlternateArea>
 4.5.7 CALLerid <CallerID>
 4.6.3 EXPTag <hours>
 4.6.5 ACKRead <0|1>
 4.6.6 RTYPe <Reply_Type_Code>

=head1 SEE ALSO

Net::Cmd Socket

=cut

1;

# FIXME: update this from the RFC
__DATA__
214
214 Level 1 commands:
214
214     PAGEr <pager ID>
214     MESSage <alphanumeric message>
214     RESEt
214     SEND
214     QUIT
214     HELPinfo
214
214 Level 2 commands:
214
214     DATA
214     LOGIn <userid> <password>
214     ALERt <alert override:<0|1>>
214     HOLDuntil <YYMMDDHHMMSS> [+/-GMTdifference]
214     CALLerid <CallerID>
214     SUBJect <message subject>
214
214 Level 3 commands:
214
214     2WAY
214     ACKRead <0|1>
214     RType <NONE|YESNO|SIMREPLY|MULTICHOICE|TEXT>
214     MCREsponse <2-byte_code> <response text>
214     MSTAtus <messagetag> <passcode>
214
