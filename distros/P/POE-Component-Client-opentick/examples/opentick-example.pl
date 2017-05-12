#!/usr/bin/perl
#
#   Demonstration program for POE::Component::Client::opentick
#
#   infi/2008
#
#   NOTE: You MUST set the Username and Password parameters to spawn(),
#         or the OPENTICK_USER and OPENTICK_PASS envvars before using
#         this script.
#

use strict;
use warnings;
use Data::Dumper;
use Time::HiRes qw( time );
use POE qw( Component::Client::opentick );
$|=1;

###
### Variables
###

my $alias    = 'exampleclient';
my %requests = ();

########################################################################
###   MAIN                                                           ###
########################################################################

# Create the OT session object, and set it up to spawn in POE.
# See 'perldoc POE::Component::Client::opentick' for extended option details
my $opentick = POE::Component::Client::opentick->spawn(
        # REQUIRED: YOUR opentick username (or set envvar OPENTICK_USER)
#        Username    => 'YOURUSERNAME',
        # REQUIRED: YOUR opentick password (or set envvar OPENTICK_PASS)
#        Password    => 'YOURPASSWORD',
        # REQUIRED: set to your session's alias to receive events
        Notifyee    => $alias,      # Tell the component our alias
        # REQUIRED: register to listen for these events.
        Events      => [ qw/ ot_on_login    ot_on_error     ot_on_logout
                             ot_on_data     ot_request_complete / ],
        # This would work, also.
#        Events      => [ qw/ all / ],
        # Pass an arrayref of hostnames if you wish to override the defaults
#        Servers     => [ qw( feed1.opentick.com feed2.opentick.com ) ],
        # Set to a TRUE value if you wish to enable realtime quoting
#        Realtime    => 1,
        # Set to a TRUE value if you wish to see component debugging output.
#        Debug       => 1,
        # Set to a TRUE value if you wish to have ALL messages silenced.
#        Quiet       => 1,
        # Set to a TRUE value to skip ::Record object creation and receive
        #   ONLY arrayref responses.
#        RawData     => 1,
);

#print Dumper $opentick;

# Create our own session, and register our event handlers with POE
POE::Session->create(
        inline_states   => {
            _start              => \&on_poe_start,
            ot_on_login         => \&on_login,
            ot_on_logout        => \&on_logout,
            ot_on_error         => \&on_error,
            ot_on_data          => \&on_data,
            ot_request_complete => \&on_request_complete,
            stats               => \&get_stats,
#            _default            => \&default_handler,
        },
);

# Run the POE kernel event loop.
$poe_kernel->run();     # $poe_kernel is exported by POE.pm

# This only happens after the POE kernel exits.
print "Client: POE kernel's run method quit.  Bye!\n";

# Exit politely.
exit(0);


########################################################################
####  Event handlers                                                 ###
########################################################################

# This handler is called upon successful login to the opentick server.
# You can start querying symbols, etc. from this point.
sub on_login
{
    print "Client: Logged in.\n";

    # Now we issue a request to the OT component.
#    my $req_id = $opentick->call( requestDividends => Q => MSFT =>
#                                  1000000000, 1111111111 );
#    my $req_id = $opentick->call( requestSplits => N => KO =>
#                                  0, 1222222222 );
#    my $req_id = $opentick->call( requestOptionInit => AO => MSFT =>
#                                  12, 2006, 24, 25, 2 );
#    my $req_id = $opentick->call( requestHistData => Q => MSFT =>
#                                  1111000000, 1111000020, 1, 1 );
#    my $req_id = $opentick->call( requestHistTicks => Q => MSFT =>
#                                  1111000000, 1111000020, 4 );
#    my $req_id = $opentick->call( requestTickStream => Q => 'GOOG' );
#    my $req_id = $opentick->call( requestTickStreamEx => Q => 'GOOG' =>
#                                  4 );
    my $req_id = $opentick->call( requestTickSnapshot => '@' => 'MSFT' =>
                                  4 );
#    my $req_id = $opentick->call( requestOptionChain => AO => MSFT =>
#                                  3, 2008 );
#    my $req_id = $opentick->call( requestOptionChainEx => AO => MSFT =>
#                                  3, 2008, 15 );
#    my $req_id = $opentick->call( requestOptionChainU => AO => MSFT =>
#                                  4, 2008, 15, 24, 25, 1 );
#    my $req_id = $opentick->call( requestOptionChainSnapshot => AO => MSFT =>
#                                  4, 2008, 15, 20, 25, 1 );
#    my $req_id = $opentick->call( requestEqInit => Q => 'MSFT' );
#    my $req_id = $opentick->call( requestBookStream => bt => 'MSFT' );
#    my $req_id = $opentick->call( requestBookStreamEx => is => 'MSFT' =>
#                                  4080 );
#    my $req_id = $opentick->call( requestHistBooks => is => 'MSFT' =>
#                                  1162389600, 1162476000, 4080 );
#    my $req_id = $opentick->call( requestListSymbols => 'Q' ); 
#    my $req_id = $opentick->call( requestListSymbolsEx => 'Q' => 'MS' =>
#                                  131072+1 ); 
#    my $req_id = $opentick->call( 'requestListExchanges' );

    # We should keep track of the Request ID for later.
    if( $req_id )
    {
        print "Client: Issued command; req_id = $req_id\n";
        $requests{$req_id} = time;          # let's store something useful.
    }

    # Let's also set a timer to get some OT component statistics 2 seconds
    # from now (after we have had time to run a query and receive results).
    $poe_kernel->delay( 'stats', 2 );

    return;
}

# This handler is called upon receiving an error from the component.
# Do something sane here.
sub on_error
{
    # The default arguments, then an PoCo::Client::opentick::Error object.
    # See the corresponding documentation for more features.
    my( $request_id, $command_id, $error ) = @_[ARG0..ARG2];

    # The $error object's stringify() method is overloaded.  Just use it.
    print "Client: Error received:\n";
    print "$error\n";

    # Return nothing, so anyone call()ing us won't be affected.
    return;
}

# This handler is called once for each packet of request response data
# received from the opentick server.  It is passed a request ID along
# with the arguments, so you can match up your requests with the response
# data.
sub on_data
{
    # The default arguments, and then the Record object
    # See the opentick.com documentation for details.
    my( $request_id, $command_id, $record ) = @_[ARG0..$#_];

    # Dump the received data.  We'll just do something simple.
    print "Client: Data received: ", join( ' ', $record->get_data() ), "\n";

    # Return nothing, so anyone call()ing us won't be affected.
    return;
}

# This handler is called when a request has been completed.  It should
# remove the $request_id from whatever data structure you have set up,
# and any other cleanup you may need to do (commit transactions, etc).
sub on_request_complete
{
    # This is called with default OT client arguments.
    my( $request_id, $command_id ) = @_[ARG0,ARG1];

    print "Client: ReqID #$request_id has completed.\n";

    # Since we kept the time, let's do something with it.
    printf "Client: ReqID #%d time elapsed: %.3f seconds.\n",
           $request_id, time - $requests{$request_id};

    # Remove the request from our request list.
    delete( $requests{$request_id} );

    # Return nothing, so anyone call()ing us won't be affected.
    return;
}

# This handler is REQUIRED by POE, and is called as soon as our session
# is instantiated within POE.  You need to set your alias here, to 
# keep your session alive and properly receive events from the opentick
# component.
sub on_poe_start
{
    # This is called from POE::Kernel, and so the argument list is from there.
    my( $session ) = $_[SESSION];
    my $session_id = $session->ID();

    print "Client: Session started (ID=$session_id)\n";

    # Set our alias within POE, so it keeps our session alive.
    $poe_kernel->alias_set( $alias );

    # Return nothing, so anyone call()ing us won't be affected.
    return;
}

# Grab and dump some statistics on the opentick object.
# Called after the delay specified within on_login()
sub get_stats
{
    # We don't need to use any arguments for this.

    # Get statistics on the $opentick object.
#    my @stats = $opentick->statistics();
    # This also works fine for statistics(), but only with ->call()
    #my @stats = $opentick->call( 'statistics' );

    # Print the statistics
#    print "OT component statistics:\n";
#    printf "packets sent  = %d\npackets recv  = %d\nbytes sent    = %d\n" .
#           "bytes recv    = %d\nmessages sent = %d\nmessages recv = %d\n" .
#           "records recv  = %d\nerrors recv   = %d\n" .
#           "uptime        = %d secs\nconnect time  = %d secs\n",
#           @stats;

    # Try cancelling the request
#    my $req_id = $opentick->call( cancelTickStream => 2 );

    # Now we'll shut down.
    print "Client: Logging out.\n";
    $opentick->yield( 'shutdown' );

    # Return nothing, so anyone call()ing us won't be affected.
    return;
}

# Do something useful, like cleanup and exit.
# Called upon logout.
sub on_logout
{
    print "Client: Logged out.\n";

    # Try to shut down gracefully.
    undef $opentick;
    $poe_kernel->alias_remove( $alias );

    # Will that do it?
}

sub default_handler {
    print "Client: Got something!\nArgs:\n";
    print Dumper @_[ARG0..$#_];
}

# That's all she wrote, batman.

__END__

