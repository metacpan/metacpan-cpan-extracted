package Mobile::Location;

# Location.pm - the mobile agent environment location class.
#
# Author: Paul Barry, paul.barry@itcarlow.ie
# Create: March 2003.
# Update: April 2003  - changed to IO::Socket for agent receipt and processing 
#                       due to "fork" strangeness on regular sockets.
#         May 2003    - added support for authentication and encryption.
#                     - added the web-based monitoring service.
#
# Notes:  Version 1.x - unsafe, totally trusting Locations (never released).
#         Version 2.x - added support to the Location for executing mobile 
#                       agents within a restricted Opcode environment.
#         Version 3.x - adds support for authentication and encryption.  This
#                       code assumes that a functioning keyserver is running.
#         Version 4.x - embeds a web-server to allow for remote monitoring via
#                       the world-wide-web.

use strict;

use Crypt::RSA;       # Provides authentication and encryption services.
use IO::Socket;       # OO interface to Socket API.
use Socket;           # Procedural interface to Socket API.
use Sys::Hostname;    # Provides a means of determine name of current machine.
use HTTP::Daemon;     # Provides a basic HTTP server.
use HTTP::Status;     # Provides support for HTTP status messages.
use POSIX 'WNOHANG';  # Provides support for POSIX signals.

# Add a signal handler to process and deal with "zombies".

$SIG{CHLD} = sub { while ( waitpid( -1, WNOHANG ) > 0 ) { }; };

our $VERSION = 4.02;

use constant TRUE                => 1;
use constant FALSE               => 0;

use constant RUN_LOCATION_DIR    => "Location";
use constant KEY_SIZE            => 1024;

use constant RESPONDER_PPORT     => '30001';
use constant REGISTRATION_PPORT  => '30002';

use constant SCOOBY_CONFIG_FILE  => "$ENV{'HOME'}/.scoobyrc";

use constant HTML_DEFAULT_PAGE   => "index.html";
use constant HTTP_PORT           => 8080;

use constant LOGFILE             => 'location.log';

use constant VISIT_SCOOBY        => 'Visit the <a href="http://glasnost.itcarlow.ie/~scooby/">Scooby Website</a> at IT Carlow.<p>';

our $_PWD = ''; # This 'global' contains the current working directory
                # for the Location instance determined during construction.

##########################################################################
# The class constructor is in "new".
##########################################################################

sub new {

    # The Mobile::Location constructor.
    #
    # IN:   Receives a series of optional name/value pairings.
    #          Port  - Protocol port value to accept connections from.
    #                  Default value for Port is '2001'.
    #          Debug - set to 1 for STDERR status messages.
    #                  Default value for Debug is 0 (off).
    #          Log   - set to 1 to enable logging of agents to disk.
    #                  Default value for Log is 0 (off).
    #          Ops   - a set of Opcodes or Opcode tags, which are 
    #                  added to Scooby's ALLOWED ops when executing 
    #                  mobile agents.
    #          Web   - set to 1 to enable the logging mechanism and the
    #                  creation of a HTTP-based Monitoring Service.  The
    #                  default is 1 (i.e., ON).
    #
    # OUT:  Returns a blessed reference to a Mobile::Location object.

    my ( $class, %arguments ) = @_;

    my $self = bless {}, $class;

    $self->{ Port }  = $arguments{ Port }  || 2001;
    $self->{ Debug } = $arguments{ Debug } || FALSE;
    $self->{ Log }   = $arguments{ Log }   || FALSE;
    $self->{ Ops }   = $arguments{ Ops }   || ''; 
    $self->{ Web }   = $arguments{ Web }   || TRUE;

    # Untaint the PATH by setting it to something really limited.

    $ENV{'PATH'} = "/bin:/usr/bin";

    # This next line is part of the standard Perl technique.  See 'perlsec'.

    delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };
 
    $_PWD = `pwd`; # XXXXXX: Writing to global!  This is tainted.
    $_PWD =~ /^([-\@\/\w_.]+)$/; # So, we untaint it, using a regex.
    $_PWD = $1;

    # Disallow if running this Location as 'root'.

    die "Location running as ROOT. This is NOT secure (nor allowed)!" 
        unless $> and $^O ne 'VMS';

    # Work out and remember the IP address of the computer running this Location.

    my $host = gethostbyname( hostname ) or inet_aton( hostname );
    $self->{ Host } = inet_ntoa( $host );

    # Generate and remember a password to use with the PK- and PK+.

    $self->{ Password } = $0 . $$ . '_Location';

    # NOTE: A second server is spawned at this stage to handle any
    #       requests from an agent re: the availability of any
    #       required modules within the Perl system running this Location.
    #       See the _check_modules_on_remote subroutine from Devel::Scooby,
    #       as well as the _spawn_network_service and _check_for_modules 
    #       subroutines, below.

    _spawn_network_service( $self->{ Port }+1 );

    # Create the HTTP-based Monitoring Service.

    $self->_spawn_web_monitoring_service;

    return $self;
}


##########################################################################
# Methods and support subroutines.
##########################################################################

sub _logger {

    # This small routine quickly writes a message to the LOGFILE.  Note
    # that every line written to the LOGFILE is timestamped.  
    #
    # IN:  a message to log.
    #
    # OUT: nothing.

    my $self = shift;

    # Open the LOGFILE for append >>.

    open ML_LOGFILE, ">>" . LOGFILE
        or die "Mobile::Location: unable to append to LOGFILE.\n";

    print ML_LOGFILE scalar localtime, ": @_\n";

    close ML_LOGFILE;
}

sub _logger2 {

    # This small routine quickly writes a message to the LOGFILE.  Note
    # that every line written to the LOGFILE is timestamped.  This code is 
    # the same as "_logger", but for the fact that the location of the
    # LOGFILE is one-level-up in the directory hierarchy.
    #
    # IN:  a message to log.
    #
    # OUT: nothing.

    my $self = shift;

    # Open the LOGFILE (which is one-level-up) for append >>.

    open ML_LOGFILE, ">>../" . LOGFILE
        or die "Mobile::Location: unable to append to LOGFILE.\n";

    print ML_LOGFILE scalar localtime, ": @_\n";

    close ML_LOGFILE;
}

sub _build_index_dot_html {

    # Builds the INDEX.HTML file (used by _start_web_service).
    #
    # IN:  nothing.
    #
    # OUT: nothing (although "index.html" is created).

    my $self = shift;

    open HTMLFILE, ">index.html"
        or die "Mobile::Executive: index.html cannot be written to: $!.\n";

    print HTMLFILE<<end_html;

<HTML>
<HEAD>
<TITLE>Welcome to the Location Web-Based Monitoring Service.</TITLE>
</HEAD>
<BODY>
<h2>Welcome to the Location Web-Based Monitoring Service</h2>
end_html

    print HTMLFILE "Location executing on: <b>" . hostname . "</b>.<p>";
    print HTMLFILE "Location date/time: <b>" . localtime() . 
                       "</b>. Running on port: <b>" .
                           $self->{ Port } . "</b>.<p>";

    print HTMLFILE<<end_html;

Click <a href="clearlog.html">here</a> to reset the log.
<h2>Logging Details</h2>
<pre>
end_html

    open HTTP_LOGFILE, LOGFILE
        or die "Mobile::Location: the LOGFILE is missing - aborting.\n";

    while ( my $logline = <HTTP_LOGFILE> )
    {
        print HTMLFILE "$logline";
    }

    close HTTP_LOGFILE;

    print HTMLFILE<<end_html;

</pre>
end_html

    print HTMLFILE VISIT_SCOOBY;

    print HTMLFILE<<end_html;

</BODY>
</HTML>
end_html

    close HTMLFILE;
}

sub _build_clearlog_dot_html {

    # Builds the CLEARLOG.HTML file (used by _start_web_service).
    #
    # IN:  the name of the just-created backup file.
    #
    # OUT: nothing (although "clearlog.html" is created).

    my $self = shift;

    my $backup_log = shift;

    open CLEARLOG_HTML, ">clearlog.html"
        or die "Mobile::Executive: clearlog.html cannot be written to: $!.\n";

    print CLEARLOG_HTML<<end_html;

<HTML>
<HEAD>
<TITLE>Location Logfile Reset.</TITLE>
</HEAD>
<BODY>
<h2>Location Logfile Reset</h2>
The previous logfile has been archived as: <b>$backup_log</b><p>
Return to this Location's <a href="index.html">main page</a>.<p>
end_html

    print CLEARLOG_HTML VISIT_SCOOBY;

    print CLEARLOG_HTML<<end_html;

</BODY>
<HTML>
end_html

    close CLEARLOG_HTML;
}

sub _start_web_service {

    # Starts a small web server running on port HTTP_PORT.  Provides for some
    # simple monitoring of the Location.
    #
    # IN:  nothing.
    #
    # OUT: nothing.

    my $self = shift;

    my $httpd = HTTP::Daemon->new( LocalPort => HTTP_PORT,
                                   Reuse     => 1 )
        or die "Mobile::Location: could not create HTTP daemon on " .
                    HTTP_PORT . ".\n";

    $self->_logger( "Starting web service on port:", HTTP_PORT ) if $self->{ Web };

    while ( my $http_client = $httpd->accept )
    {
        if ( my $service = $http_client->get_request ) 
        {
            my $request = $service->uri->path;

            if ( $service->method eq 'GET' )
            {
                my $resource;
        
                if ( $request eq "/"  || $request eq "/index.html" )
                { 
                    $resource = HTML_DEFAULT_PAGE;

                    $self->_build_index_dot_html;

                    $http_client->send_file_response( $resource );
                }
                elsif ( $request eq "/clearlog.html" )
                {
                    # Create a name for the backup log.

                    my $backup_log = "Mobile::Location." . localtime() .
                                         "." . $$ . ".log";

                    # Make the backup, delete the LOGFILE, then recreate it.

                    system( "cp", LOGFILE, $backup_log );
                    unlink LOGFILE;

                    $self->_logger( "Mobile::Location: log reset." ) if $self->{ Web };

                    $self->_build_clearlog_dot_html( $backup_log );

                    $http_client->send_file_response( "clearlog.html" );
                }
                else
                {
                    $http_client->send_error( RC_NOT_FOUND );
                }
            }
            else
            {
                $http_client->send_error( RC_METHOD_NOT_ALLOWED );
            }
        }
    }
    continue
    {
        $http_client->close;
        undef( $http_client );
    }
}

sub _register_with_keyserver {

    # Create a PK+ and PK- for this server, storing the PK+ in the  
    # keyserver, and retaining the PK- in memory (as part of the objects
    # state).  Note: a new key-pair is generated with each invocation.
    #
    # IN:  nothing.  (Other than the object reference, of course).
    #
    # OUT: nothing.
    
    my $self = shift;

    # Generate the PK+ and PK-.  Store the PK- in the object's state.

    my $rsa = new Crypt::RSA;

    my $id = $self->{ Host } . ":" . $self->{ Port } . " Location";

    warn "This location is generating a PK+/PK- pairing.\n" if $self->{ Debug };

    my ( $public, $private ) = 
            $rsa->keygen(
                Identity  => $id,
                Size      => KEY_SIZE,
                Password  => $self->{ Password },
                Verbosity => FALSE
            ) or die $rsa->errstr, "\n";

    warn "Pairing Generated.\n" if $self->{ Debug };

    $self->_logger( "Location's PK+/PK- pairing generated." ) if $self->{ Web };

    # Remember the PK- in the object's state.

    $self->{ PrivateKey } = $private;

    # Write the PK+ to an appropriately named disk-file.

    my $pub_fn = $self->{ Host } . "." . $self->{ Port } . ".public";

    $self->_logger( "Writing PK+ to: $pub_fn." ) if $self->{ Web };

    $public->write( Filename => $pub_fn );

    # Determine the KEYSERVER address from the .scoobyrc file.

    open KEYFILE, SCOOBY_CONFIG_FILE
                or die "Mobile::Location: unable to access ~/.scoobyrc. Does it exist?\n";

    my $keyline = <KEYFILE>;

    close KEYFILE;

    # Note: format of 'rc' file is very strict.  No spaces!
    $keyline =~ /^KEYSERVER=(.+)/;

    $self->{ KeyServer } = $1;

    # Now that we know the address of the keyserver, we can register the PK+ of this
    # Location with the keyserver.  We read the PK+ from the just-created disk-file.

    $self->_logger( "Determined keyserver address as:", $self->{ KeyServer } ) if $self->{ Web };

    open KEYFILE, "$pub_fn"
        or die "Mobile::Location: KEYFILE does not exist: $!.\n";

    my @entire_keyfile = <KEYFILE>;

    close KEYFILE;

    my $keysock_obj = IO::Socket::INET->new( PeerAddr  => $self->{ KeyServer },
                                             PeerPort  => REGISTRATION_PPORT,
                                             Proto     => 'tcp' );

    if ( !defined( $keysock_obj ) )
    {
        die "Mobile::Location: could not create socket object to key server: $!.\n";
    }
    print $keysock_obj $self->{ Port }, "\n";
    print $keysock_obj @entire_keyfile;

    $keysock_obj->close;

    $self->_logger( "Location registered with keyserver." ) if $self->{ Web };
}

sub start_concurrent {

    # Start a passive server/location that executes concurrently.  For
    # each relocation request, a child process is spawned to process it.
    #
    # IN:  nothing.
    #
    # OUT: nothing.
    #
    # This method is never returned from.  Remember: servers are PERMANENT.
    
    my $self = shift;

    my $listening_socket = IO::Socket::INET->new( LocalPort => $self->{ Port },
                                                  Listen    => SOMAXCONN,
                                                  Proto     => 'tcp',
                                                  Reuse     => TRUE );

    if ( !defined( $listening_socket ) )
    {
        die "Mobile::Location: unable to bind to listening socket: $!.\n";
    }

    $self->_logger( "Location (concurrent) starting on port:", $self->{ Port } ) if $self->{ Web };

    warn "Location starting up on port: " . $self->{ Port } . ".\n" if $self->{ Debug };
    
    $self->_register_with_keyserver;   
 
    while ( TRUE )  # i.e., FOREVER, as servers are permanent.
    {
        next unless my $from_socket = $listening_socket->accept;

        next if my $child = fork;

        if ( $child == FALSE )
        {
            $self->_logger( "Servicing client from:", 
                                inet_ntoa( $from_socket->peeraddr ) ) if $self->{ Web };

            $listening_socket->close;
            $self->_service_client( $from_socket );
            exit FALSE;
        }

        $from_socket->close;
    }
}
    
sub start_sequential {

    # Start a passive server/location that executes sequentially.
    #
    # IN:  nothing.
    #
    # OUT: nothing.
    #
    # This method is never returned from.  Remember: servers are PERMANENT.

    my $self = shift;

    my $listening_socket = IO::Socket::INET->new( LocalPort => $self->{ Port },
                                                  Listen    => SOMAXCONN,
                                                  Proto     => 'tcp',
                                                  Reuse     => TRUE );

    if ( !defined( $listening_socket ) )
    {
        die "Mobile::Location: unable to bind to listening socket: $!.\n";
    }

    $self->_logger( "Location (sequential) starting on port:", $self->{ Port } ) if $self->{ Web };

    warn "Location starting up on port: " . $self->{ Port } . ".\n" if $self->{ Debug };
 
    $self->_register_with_keyserver;
   
    # Servers are PERMANENT.

    while ( TRUE )
    {
        next unless my $from_socket = $listening_socket->accept;

        $self->_logger( "Servicing client from:", 
                            inet_ntoa( $from_socket->peeraddr ) ) if $self->{ Web };

        $self->_service_client( $from_socket );
    } 
}

sub _service_client {

    # Service the receipt (and re-execution) of a mobile agent on 
    # this Location.
    #
    # IN:  A socket object to communicate with/on.
    #
    # OUT: nothing.

    my $self = shift;

    my $socket_object = shift;

    my $tmp_fn = <$socket_object>;  # The received filename.
    chomp( $tmp_fn ); 

    # We just want the name-part, so a little regex magic gives it to us.

    $tmp_fn = ( split /\//, $tmp_fn )[-1]; 

    my $tmp_linenum = <$socket_object>;  # The received line number.
    chomp( $tmp_linenum );

    my $data = '';

    # Receive the signature and mobile agent code.

    while ( my $chunk = <$socket_object> )
    {
        $data = $data . $chunk;
    }

    # We need to split out the signature from the $data so that we can verify it.

    ( my $agent_signature, $data ) = split /\n--end-sig--\n/, $data;

    # We need to verify the signature.  To do this, we need to retrieve
    # the appropriate PK+ from the keyserver.

    my $key_srv_sock = IO::Socket::INET->new(
                                              PeerAddr => $self->{ KeyServer },
                                              PeerPort => RESPONDER_PPORT,
                                              Proto    => 'tcp'
                                            );

    if ( !defined( $key_srv_sock ) )
    {
        $self->_logger( "Unable to create a verify socket." ) if $self->{ Web };
        
        die "Mobile::Location: unable to create a verify socket to keyserver: $!.\n";
    }

    my $agent_ip = $socket_object->peerhost;
    my $agent_port = $socket_object->peerport;

    print $key_srv_sock "$agent_ip\n";
    print $key_srv_sock $agent_port;

    $key_srv_sock->shutdown( 1 );

    my $verify_data = '';
    
    while ( my $verify_chunk = <$key_srv_sock> )
    {
        $verify_data = $verify_data . $verify_chunk;
    }
    
    $key_srv_sock->close;
   
    # This splits the signature and data on the SIGNATURE_DELIMITER 
    # pattern as used by the keyserver.

    ( my $verify_signature, $verify_data ) = split /\n--end-sig--\n/, $verify_data;

    if ( $verify_signature eq "NOSIG" )
    {
        $self->_logger( "WARNING: The keyserver returned NOSIG." ) if $self->{ Web };
        
        # We need to abort, as the keyserver does not have the requested
        # signature.  This is bad.

        $socket_object->close;

        exit 0;  # Short circuit.
    }

    open VERIFY_FILE, ">$agent_ip.$agent_port.public"
        or die "Mobile::Location: could not create verify key file: $!\n";

    print VERIFY_FILE $verify_data;

    close VERIFY_FILE;

    my $agent_pkplus = new Crypt::RSA::Key::Public(
                               Filename => "$agent_ip.$agent_port.public"
                           );

    my $rsa = new Crypt::RSA;

    my $verify = $rsa->verify( 
                                 Message    => $data,
                                 Signature  => $agent_signature,
                                 Key        => $agent_pkplus,
                                 Armour     => TRUE
                             );

    if ( !$verify )
    {
        $self->_logger( "WARNING: could not verify signature for:",
                            inet_ntoa( $socket_object->peeraddr ), 
                                "using $agent_ip/$agent_port." ) if $self->{ Web };

        die "Mobile::Location: could not verify signature of received mobile agent.  Aborting ... \n";    
    }

    $self->_logger( "Signature verified for $agent_ip/$agent_port." ) if $self->{ Web };

    # Remove the agents PK+ keyfile, as we no longer need it.

    unlink "$agent_ip.$agent_port.public";

    # At this stage, we have a mobile agent that is encrypted using the PK+
    # of this Location, and we have verified the signature to be correct.  
    # We use this Location's PK- to decrypt it.

    my $plaintext = $rsa->decrypt( 
                             Cyphertext => $data,
                             Key        => $self->{ PrivateKey },
                             Armour     => TRUE 
                          );

    if ( !defined( $plaintext ) )
    {
        $self->_logger( "WARNING: unable to decrypt Cyphertext for: $agent_ip/$agent_port." ) if $self->{ Web };

        die "Mobile::Location: decryption errors - aborting.\n";
    }

    # We have a plaintext representation of the mobile agent, which
    # we turn back into an array of lines.

    my @entire_thing = split /\n/, $plaintext;

    # Add a newline to each of the "lines" in @entire_thing.

    foreach my $line ( @entire_thing )
    {
        $line = $line . "\n";
    }

    # Ensure the Location is in the correct STARTUP directory.

    chdir $_PWD;

    # We enter the run-time directory if it exists.

    if ( -e RUN_LOCATION_DIR )
    {
        chdir( RUN_LOCATION_DIR );
    }
    else # Or, if it does NOT exist, we create it then change into it.
    {
        mkdir( RUN_LOCATION_DIR );
        chdir( RUN_LOCATION_DIR );
    }

    # As we are now in the run-time directory, we continue with the relocation.

    if ( $self->{ Log } )
    {
        my $logname = "last_agent_" . $$ . ".log";  # Note use of PID.
 
        # Put a copy of the mobile agent into the log file. 

        my $logOK = open AGENTLOGFILE, ">$logname"
            or warn "Mobile::Location: could not open log file: $!.\n";

        print AGENTLOGFILE @entire_thing if defined $logOK;

        close AGENTLOGFILE if defined $logOK;

        $self->_logger2( "Received agent logged to: $logname." ) if $self->{ Web };
    }

    # Untaint the filename received from Scooby, using a regex.

    $tmp_fn =~ /^([-\@\w_.]+)$/;
    $tmp_fn = $1;
  
    # Create the "mutated" agent on the local storage.

    open FILETOCHECK, ">$tmp_fn"
        or die "Location::Mobile: could not create agent disk-file: $!:";
    
    my $label = _generate_label( $tmp_fn, $tmp_linenum );
        
    # Start processing the agent one "line" at a time.

    my $chunk = shift @entire_thing;

    # Print the "magic" first line. 

    print FILETOCHECK $chunk;            

#    # Add the Opcode mask to the code.
#
#    print FILETOCHECK "\nuse ops qw( " . 
#
#        # Basic operation mask - relocating to a single Location.
#
#        'aassign add aelem av2arylen ' .
#        'backtick ' .
#        'caller chdir chomp chop closedir concat const ' .
#        'defined die ' .
#        'enter entereval enteriter entersub eq ' .
#        'ftdir fteexec ftewrite ' .
#        'gelem goto grepstart gv ' .
#        'helem ' .
#        'iter ' .
#        'join ' .
#        'last leaveeval leaveloop leavesub lstat ' .
#        'method method_named ' .
#        'ne negate next not null ' .
#        'open_dir ' .
#        'padany pop push pushmark ' .
#        'readdir refgen require return rv2av rv2cv rv2gv rv2hv rv2sv ' .
#        'sassign scalar seq shift sne split stat stringify stub substr ' .
#        'undef unshift unstack ' .
#
#        # Relocating to multiple Locations (requires more operations).
#        # Most of these are needed by Carp.pm, which is used by IO::Socket 
#        # (among other modules).
#
#        'anonhash anonlist ' .
#        'exists ' .
#        'keys ' .
#        'gt ' .
#        'length lt ' .
#        'mapstart ' .
#        'ord ' .
#        'postinc predec preinc ' .
#        'redo ref ' .
#        'sprintf subtract ' .
#        'wantarray ' .  
#
#        # Adding the ops required by Crypt::RSA and its support modules.
#
#        'anoncode ' . 
#        'bless bit_and bit_or bit_xor ' .
#        'chr close complement ' .
#        'divide delete dofile ' .
#        'each enterwrite eof ' .
#        'fcntl fileno flip flop formline fteread ftfile ftis ftsize ' .
#        'ge getc ' .
#        'hex ' 
#        'int index ioctl ' .
#        'lc le left_shift lslice '
#        'modulo multiply '
#        'oct open '
#        'pack padsv postdec pow print prtf '
#        'quotemeta ' .
#        'rand read readline repeat reverse regcreset ' . 
#        'select splice srand sysread syswrite '
#        'tell tie trans truncate '
#        'uc unpack '
#        'values vec '
#        'warn '
#        'xor ' 
#
#        $self->{ Ops } . " );\n\n";  # Forces safety.
#

    # Insert the GOTO label line.

    print FILETOCHECK "goto $label;\n";  

    # We re-initialize the line counter.

    my $line_counter = 2; 

    # Process the rest of the agent, one "line" at a time.

    while ( $chunk = shift @entire_thing )
    {
        if ( $line_counter == $tmp_linenum )  # We are at the 'next' line.
        {
            # Insert a 'label' statement before the next instruction.

            print FILETOCHECK "$label:\n1;\n";

            print FILETOCHECK "use Mobile::Executive;\n\n";
        }
        print FILETOCHECK $chunk;
        $line_counter++;
    }
    
    close FILETOCHECK;

    # Note: The agent now exists on the local run-time storage of this Location.
        
    $self->_logger2( "Received $tmp_fn from", $socket_object->peerhost, 
                 " next line: $tmp_linenum." ) if $self->{ Web };

    warn "Received $tmp_fn from ", 
             $socket_object->peerhost, 
                 "; next line: $tmp_linenum.\n" if $self->{ Debug };

    # Construct the command-line that will continue to execute the agent.

    my $cmd = "perl -d:Scooby " .  "$tmp_fn";
    
    # Close the socket as we are now finished with it.

    close $socket_object
        or warn "Mobile::Location: close failed: $!.\n";

    # Continue to execute the agent at this location.

    warn "Continuing to execute agent: $cmd.\n" if $self->{ Debug };
  
    $self->_logger2( "Continuing to execute mobile agent: $cmd." ) if $self->{ Web };

    my $results = qx( $cmd );
        
    print "$results" if $results ne '';  
}

sub _spawn_web_monitoring_service {

    # Creates a subprocess to run the web-based monitoring service.
    #
    # IN:  nothing.
    #
    # OUT: nothing.

    my $self = shift;

    my $child_pid = fork;  

    die "No spawned web-based monitoring service: $!.\n" unless defined( $child_pid );

    if ( $child_pid == FALSE )
    {
        # This is the CHILD code, which creates a server on "Port+1" and

        $self->_start_web_service if $self->{ Web };

        exit 0;
    }
}

##########################################################################
# These are not methods, they're support subroutines.
##########################################################################

sub _generate_label {

    # Generate a unique label string.
    #
    # IN:  A filename and a line number.
    #      Note: These values are combined with the time to produce a
    #      random (and hopefully unique) label.
    #
    # OUT: An appropriately formatted label.

    my $fn   = shift;
    my $ln   = shift;

    my $tm   = time;

    # Remove any unwanted characters from the filename.

    $fn =~ s/[^a-zA-Z0-9]//;

    return ( 'LABEL_' . $fn . $ln . $tm );
}

sub _check_for_modules {

    # Given a list of module classes, check to see if they exist within this
    # Location's Perl environment.
    #
    # IN:  A list of fully-qualified (one or more) module names.
    #      A "fully-qualified module name" is "Devel::Scooby", as 
    #      opposed to just "Scooby".
    #
    # OUT: A list of modules NOT found.  An empty list signals SUCCESS.

    my @mods_to_check = @_;       # Taken from IN.

    my @list_of_not_found = ();   # Will be used as OUT.

    foreach my $mod ( @mods_to_check )
    {
        # Untaint the $mod values prior to their use, using a regex.

        $mod =~ /^([\w\d:_]+)$/; 
        $mod = $1;

        eval "require $mod;";
        if ( $@ ) 
        { 

            # The module does not exist within this Perl!!

            push @list_of_not_found, $mod; 
        }
    }

    return @list_of_not_found;
}

sub _spawn_network_service {

    # Spawn a sub-process, running at protocol port number "$self->{ Port }+1" 
    # to respond to an agent's query re: required classes.
    #
    # IN:  The protocol port to start the service on.
    #
    # OUT: nothing.

    my $port = shift;

    # Untaint the value for $port, as it can be initialized from 
    # the command-line, and is therefore TAINTED.

    $port =~ /^(\d+)$/;
    $port = $1;

    my $child_pid = fork;  

    die "No spawned network service: $!.\n" unless defined( $child_pid );

    # This child code never ends, as servers are PERMANENT.

    if ( $child_pid == FALSE )
    {
        # This is the CHILD code, which creates a server on "Port+1" and
        # listens for requests from a remote mobile agent.

        my $trans_serv = getprotobyname( 'tcp' );
        my $local_addr = sockaddr_in( $port, INADDR_ANY );

        socket( TCP_SOCK, PF_INET, SOCK_STREAM, $trans_serv )
            or die "Mobile::Location: socket creation failed: $!.\n";
        setsockopt( TCP_SOCK, SOL_SOCKET, SO_REUSEADDR, 1 )
            or warn "Mobile::Location: could not set socket option: $!.\n";
        bind( TCP_SOCK, $local_addr )
            or die "Mobile::Location: bind to address failed: $!.\n";
        listen( TCP_SOCK, SOMAXCONN )
            or die "Mobile::Location: listen couldn't: $!.\n";

         my $from_who;

         while ( $from_who = accept( CHECK_MOD_SOCK, TCP_SOCK ) )
         {
             # Switch on AUTO-FLUSHING.

             my $previous = select CHECK_MOD_SOCK;
             $| = 1;
             select $previous;

             my $data = '';
    
             # Get the list of modules from the other Location.

             while ( my $chunk = <CHECK_MOD_SOCK> )
             {
                 $data = $data . $chunk;
             }

             my @modules = split / /, $data;

             my @list = _check_for_modules( @modules );

             if ( @list )
             {
                 print CHECK_MOD_SOCK "NOK: @list";
             }
             else
             {
                 print CHECK_MOD_SOCK "OK";
             }

             close CHECK_MOD_SOCK
                 or warn "Mobile::Location: close failed: $!.\n";
         }

         close TCP_SOCK;  # This code may never be reached.  It only
                          # executes if the call to "accept" fails.
    }

    # This is the parent process code.  That is, the value of 
    # $child_pid is defined and is greater than 0.
}

1;  # As it is required by Perl.

##########################################################################
# Documentation starts here.
##########################################################################

=pod

=head1 NAME

"Mobile::Location" - a class that provides for the creation of Scooby mobile agent environments (aka Location, Site or Place).

=head1 VERSION

4.0x (the v1.0x, v2.0x and v3.0x series were never released).

=head1 SYNOPSIS

use Mobile::Location;

my $location = Mobile::Location->new;

$location->start_sequential;

or 

$location->start_concurrent;


=head1 SOME IMPORTANT NOTES FOR LOCATION WRITERS

1. Never, ever run a Location as 'root'.  If you do, this module will die.  Running as 'root' is a serious security risk, as a mobile agent is foreign code that you are trusting to execute in a non-threatening way on your computer.  (Can you spell the word 'v', 'i', 'r', 'u', 's'?!?)

2. The B<Mobile::Location> class executes mobile agents within a restricted environment.  See the B<Ops> argument to the B<new> method, below, for more details.

3. Never, ever run a Location on the same machine that is acting as your keyserver (it's a really bad idea, so don't even think about it).

=head1 DESCRIPTION

Part of the Scooby mobile agent machinery, the B<Mobile::Location> class provides a convenient abstraction of a mobile agent environment.  Typical usage is as shown in the B<SYNOPSIS> section above.  This class allows for the creation of a passive, TCP-based mobile agent Location.

=head1 Overview

Simply create an object of type B<Mobile::Location> with the B<new> method.  To start a sequential server, use the B<start_sequential> method.  To start a concurrent server, use the B<start_concurrent> method.

=head1 Construction and initialization

Create a new instance of the B<Mobile::Location> object by calling the B<new> method:

=over 4

my $location = Mobile::Location->new;

=back

Optional named parameters (with default values) are:

=over 4

B<Debug (0)> - set to 1 to receive STDERR status messages from the object.

B<Port (2001)> - sets the protocol port number to accept connections on.

B<Log (0)> - set to 1 to instruct the Location to log the received mobile agent to disk prior to performing any mutation.  The name of the logged agent is "last_agent_PID.log", where PID is the process identifier of the Location.  On sequential Locations, the PID is always the same value for each received agent.  On concurrent Locations, the PID is the PID of the child process that services the relocation/re-execution, so it is always different for each received agent (so watch your disk space).  It is often useful to switch this option on (by setting Log to 1) when debugging.  Note that the received mobile agent persists on the Location's local disk storage.

B<Ops ('')> - add a list of Opcodes to the Opcode mask that is in effect when the mobile agent executes.  Study the standard B<Opcode> and B<Ops> modules for details on Opcodes and how they are set.  One way to secure your Location against attack is to ensure that the Opcodes in effect while a mobile agent executes are "safe".  This is NOT an easy task, as protecting the mobile agent environment from malicious mobile agents is never easy.  Note that the default set of Opcodes in effect are enough to allow the relocation mechanism to execute.  B<NOTE>: if the mobile agent uses a operation not allowed by the Opcode mask, it is killed and stops executing.  The Location continues to execute, and waits passively for the next mobile agent to arrive.  The default set of enabled Opcodes is restrictive.  Provide a space-delimited list of Opcodes to this argument to add to the list of allowed opcodes.  NOTE: this functionality is currently B<disabled> due to conflicts/incompatibilities with the current version of Crypt::RSA (version 1.50).

B<Web (1)> - turns on the HTTP-based Monitoring Service running on port 8080 (HTTP_PORT), thus enabling remote monitoring of the Locations current status.  It also logs interactions with this Location into 'location.log' (LOGFILE).  Set to 0 to disable this behaviour.

=back 

Note that any received mobile agent executes in a directory called "Location", which will be created (if needs be) in the directory that houses this Location.  Any "logs" are also created in the "Location" directory.

A constructor example is:

=over 4

my $place = Mobile::Location->new( Port => 5555, Debug => 1 );

=back

creates an object that will display all STDERR status messages, and use protocol port number 5555 for connections.  Logging of received agents to disk is off.  The standard Opcode mask is in effect.  And logging to disk is on, as is the HTTP server.

When the Location is constructed with B<new>, a second network service is created, running at protocol port number B<Port+1>.  In the example above, this second network service would run at protocol port number 5556.  When sent the names of a set of Perl classes (e.g., Data::Dumper, HTTP::Request, Net::SNMP and the like), this service checks to see if the classes are available to the locally installed Perl installation.  This allows B<Devel::Scooby> to determine whether or not relocation is worthwhile prior to an attempted relocation.  The B<Devel::Scooby> module tries to determines the list of classes used by any mobile agent and communicates with this second network service "in the background".  This all happens automatically, so the mobile agent programmer does not need to worry about it, as B<Devel::Scooby> only complains when a module does not exist on a remote Location.  That said, the administrator of the Location does need to be aware of this second network service.  To confirm that the Location and the second network service are up-and-running use the B<netstat -an> command-line utility (on Linux).  The two "listening" services should appear in netstat's output.

Note: If a Location crashes (or is killed), the second network service can sometimes keeps running.  After all, it is a separate process (albeit a child of the original).  Trying to restart the Location results in an "bind to address failed" error message.  Use the B<ps -aux> command to identify the Perl interpreter that is executing and kill it with B<kill -9 pid>, where B<pid> is the process ID of the child process's Perl interpreter.

=head1 Class and object methods

=over 4

=item B<start_concurrent> 

Start the location as a passive server, which operates concurrently.  Once connected to a client, the server forks another process to receive and continue executing a mobile agent.  This is the preferred method to use when there exists the potential to have an agent execute for a long period of time.

=item B<start_sequential>

Start the location as a passive server, which operates sequentially.  Once connected to a client, the server sequentially processes the receipt and continued executing of a mobile agent.  This is OK if the agent is quick and not processor intensive.  If the agent has the potential to execute for a long period of time, use the B<start_concurrent> method instead.  This may also be of use within environments that place a restriction on the use of B<fork>.

=back

=head1 Internal methods/subroutines

The following list of subroutines are used within the class to provide support services to the class methods.  These subroutines should not be invoked through the object (and in some cases, cannot be invoked through the object).

=over 4

=item B<_generate_label>

Takes a filename and line number, then combines them with the current time to produce a random, unique label.

=item B<_check_for_modules>

Given a list of module names, checks to see if the Location's Perl system has the module installed or not.

=item B<_spawn_network_service>

Used by the B<new> constructor to spawn the Port+1 network service which listens for a list of modules names from a mobile agent, then checks for their existence within the locally installed Perl system.

=item B<_service_client>

Given a socket object (and the instances init data), service the relocation of a Scooby mobile agent.

=item B<_register_with_keyserver> 

Creates a PK+ and PK- value for the server, storing the PK+ in the keyserver, and the PK- in the object's state.

=item B<_logger> and B<_logger2>

Logs a message to the LOGFILE.

=item B<_build_index_dot_html>

Builds the INDEX.HTML page for use by the HTTP-based Monitoring Service.

=item B<_build_clearlog_dot_html>

Builds the CLEARLOG.HTML page for use by the HTTP-based Monitoring Service.

=item B<_start_web_service>

Starts a small web server running at port 8080 (HTTP_PORT), and uses the two "_build_*" routines just described.

=item B<_spawn_web_monitoring_service>

Creates a subprocess and starts the web server.

=back

=head1 SEE ALSO

The B<Mobile::Executive> module (for creating mobile agents), as well as B<Devel::Scooby> (for running mobile agents).

The Scooby Website: B<http://glasnost.itcarlow.ie/~scooby/>.

=head1 AUTHOR

Paul Barry, Institute of Technology, Carlow in Ireland, B<paul.barry@itcarlow.ie>, B<http://glasnost.itcarlow.ie/~barrypi/>.

=head1 COPYRIGHT

Copyright (c) 2003, Paul Barry.  All Rights Reserved.

This module is free software.  It may be used, redistributed and/or modified under the same terms as Perl itself.

