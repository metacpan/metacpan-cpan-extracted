#!/usr/bin/perl
# ==================================================================
#   term.perl
#   Author  : Scott Beck
#   $Id: term.perl,v 1.6 2002/02/22 10:18:00 bline Exp $
# ==================================================================
#
# Description: Provides a terminal interface to a POP3 mailbox
#

use strict;
use warnings;

sub POE::Component::Client::POP3::DEBUG () { 1 }
#sub POE::Kernel::TRACE_EVENTS           () { 1 }
#sub POE::Kernel::ASSERT_RETURNS         () { 1 }
sub DEBUG () { 1 }

use Symbol qw(gensym);
use POE qw/Wheel::ReadLine Component::Client::POP3/;
use Term::ReadKey;

sub PROMPT       () { '> ' }
sub NOOP_DELAY   () { 10 }
sub STATE_USER   () { 0 }
sub STATE_PASS   () { 1 }
sub STATE_CONN   () { 3 }
sub STATE_NOCONN () { 4 }

my %USAGE = (
    help     => [ "help [command]   - Give a help message. command is optional" ],
    '?'      => [ "See help" ],
    quit     => [ "quit             - Given in connection stage when you want to",
                  "                   disconnect" ],
    close    => [ "See quit" ],
    exit     => [ "exit             - To exit the program" ],
    list     => [ "list [number]    - List the size and number of each message. If",
                  "                   number is omited, lists all messages" ],
    ls       => [ "See list" ],
    get      => [ "get number       - Get a message. You may optionaly > to a file",
                  "                   or | to a program the email. For example:",
                  "                      get 1 > /tmp/msg1",
                  "                   This would write message one to /tmp/msg1" ],
    view     => [ "view number      - Retrieves message number into a temp file and executes",
                  "                   an editor on the file. The editor is taken from the",
                  "                   environment variable EDITOR, if EDITOR is not set vim is",
                  "                   used."],
    reset    => [ "reset            - Undeletes any message that were deleted" ],
    open     => [ "open host[:port] - Connect to host on port. port defaults to 110" ],
    connect  => [ "See open" ],
    retr     => [ "See get" ],
    retrieve => [ "See get" ]
);

# Output does not look nice or readable on raw terminals
open STDERR, ">debug.txt" if DEBUG;

sub handler_start {
# ----------------------------------------------------------------------------
    my ( $kernel, $heap ) = @_[KERNEL, HEAP];

    $heap->{wheel} = POE::Wheel::ReadLine->new( InputEvent => 'term_input' );
    $heap->{wheel}->put( "Type ? for help" );
    $heap->{wheel}->get( PROMPT );
    $kernel->alias_set( 'me' );
    $heap->{alias} = 'me';
}

sub handler_stop {
# ----------------------------------------------------------------------------
    my ( $kernel, $heap, $in ) = @_[KERNEL, HEAP, ARG0];
    
    delete $heap->{wheel};
    ReadMode 'normal';
    print "Good Bye\n";
    $kernel->alarm_remove_all;
}

sub handler_default {
# ----------------------------------------------------------------------------
    my ( $heap, $caught_event ) = @_[HEAP, ARG0];
    if ( $caught_event =~ /^comm_/ ) {
        $heap->{wheel}->put( "Command not understood" );
        $heap->{wheel}->get( $heap->{prompt} );
    }
    return 0;
}

sub handler_noop {
# ----------------------------------------------------------------------------
    my ( $kernel, $heap ) = @_[KERNEL, HEAP];
    if ( $heap->{state} == STATE_CONN ) {
        $kernel->post( 'pop_conn', 'noop' );
    }
    $kernel->delay( 'noop', NOOP_DELAY );
}

sub handler_term_input {
# ----------------------------------------------------------------------------
    my ( $kernel, $heap, $input, $error ) = @_[KERNEL, HEAP, ARG0, ARG1];
    
    if ( !defined $input ) {
        return;
    }
    elsif ( $heap->{state} == STATE_USER ) {
        warn "$heap->{alias}: in term_input with state_user" if DEBUG;
        $kernel->yield( 'user', $input );
    }
    elsif ( $heap->{state} == STATE_PASS ) {
        warn "$heap->{alias}: in term_input with state_pass" if DEBUG;
        $kernel->yield( 'pass', $input );
    }
    elsif ( length $input ) {
        if ( DEBUG ) {
            warn "$heap->{alias}: in term_input with state_noconn" if $heap->{state} == STATE_NOCONN;
            warn "$heap->{alias}: in term_input with state_conn" if $heap->{state} == STATE_CONN;
        }
        $heap->{wheel}->addhistory( $input );
        my ( $comm, $args ) = $input =~ /^\s*((?:\S+\b)|\?)\s*(.*)/;
        $kernel->yield( "comm_$comm", $args, $comm );
    }
    else {
        $heap->{wheel}->get( $heap->{prompt} );
    }
}

sub handler_pop_connect {
    my ( $kernel, $heap ) = @_[KERNEL, HEAP];
    warn "$heap->{alias}: Spawning pop3 client" if DEBUG;
    POE::Component::Client::POP3->spawn(
        Alias      => 'pop_conn',
        RemoteAddr => $heap->{host},
        RemotePort => $heap->{port},
        Events => [{
            authenticated => 'pop_auth',
            error         => 'pop_fatal_error',
            trans_error   => 'pop_trans_error',
            disconnected  => 'pop_disconnected',
            list          => 'pop_list',
            retr          => 'pop_retr',
            uidl          => 'pop_uidl',
            top           => 'pop_top',
            rset          => 'pop_rset',
            connected     => 'pop_connected'
        }]
    );
}

sub handler_user {
# ----------------------------------------------------------------------------
    my ( $kernel, $heap, $input ) = @_[KERNEL, HEAP, ARG0];
    $heap->{user} = $input;
    unless ( defined $heap->{user} and length $heap->{user} ) {
        $heap->{wheel}->put( "Username required" );
        $heap->{wheel}->get( 'Username: ' );
        return;
    }
    warn "$heap->{alias}: Changing state to state_pass" if DEBUG;
    $heap->{state} = STATE_PASS;
    if ( $heap->{wheel}->can( 'get_noecho' ) ) {
        $heap->{wheel}->get_noecho( 'Password: ' );
    }
    else {
        $heap->{wheel}->get( 'Password: ' );
    }
}

sub handler_pass {
# ----------------------------------------------------------------------------
    my ( $kernel, $heap, $input ) = @_[KERNEL, HEAP, ARG0];
    $heap->{pass} = $input;
    unless ( defined $heap->{pass} and length $heap->{pass} ) {
        $heap->{wheel}->put( "Password Required" );
        $heap->{wheel}->get( 'Password: ' );
        return;
    }
    $kernel->post( 'pop_conn', 'login', $heap->{user}, $heap->{pass} );
    delete $heap->{user};
    delete $heap->{pass};
}

sub handler_comm_list {
# ----------------------------------------------------------------------------
    my ( $kernel, $heap, $args ) = @_[KERNEL, HEAP, ARG0];
    unless ( $heap->{state} == STATE_CONN ) {
        $heap->{wheel}->put( "Not connected" );
        $heap->{wheel}->get( PROMPT );
        return;
    }
    if ( defined $args and $args =~ /(\d+)/ ) {
        $kernel->post( 'pop_conn', 'list', $1 );
    }
    else {
        $kernel->post( 'pop_conn', 'list' );
    }
}

sub handler_comm_get {
# ----------------------------------------------------------------------------
    my ( $kernel, $heap, $args, $comm ) = @_[KERNEL, HEAP, ARG0, ARG1];
    unless ( $heap->{state} == STATE_CONN ) {
        $heap->{wheel}->put( "Not connected" );
        $heap->{wheel}->get( PROMPT );
        return;
    }
    my $num = $1 if $args =~ s/^\s*(\d+)//;
    unless ( defined $num ) {
        $heap->{wheel}->put( "Must specify a number to $comm" );
        $heap->{wheel}->get( $heap->{prompt} );
        return;
    }
    if ( $comm eq 'view' ) {
        $heap->{view} = "/tmp/$num." . time . ".eml";
        my $fh = gensym;
        open $fh, ">$heap->{view}"
            or die "Could not open $heap->{view}; Reason: $!";
        $kernel->post( 'pop_conn', 'retr', $num, $fh );
    }
    elsif ( $args =~ /^\s*([>\|])\s*(.+)\s*$/ ) {
        my ( $meth, $file ) = ( $1, $2 );
        if ( $meth eq '>' ) {
            my $fh = gensym;
            if ( open $fh, ">$file" ) {
                $heap->{retr_file} = $file;
                $kernel->post( 'pop_conn', 'retr', $num, $fh );
            }
            else {
                $heap->{wheel}->put( "Could not open $file; Reason: $!" );
                $kernel->post( 'pop_conn', 'retr', $num );
            }
        }
        else {
            $heap->{retr_file} = "/tmp/$num." . time . ".eml";
            my $fh = gensym;
            open $fh, ">$heap->{retr_file}"
                or die "Could not open $heap->{retr_file}; Reason: $!";
            $heap->{retr_pipe} = $file;
            $kernel->post( 'pop_conn', 'retr', $num, $fh );
        }
    }
    else {
        $kernel->post( 'pop_conn', 'retr', $num );
    }
}

sub handler_comm_quit {
# ----------------------------------------------------------------------------
    my ( $kernel, $heap ) = @_[KERNEL, HEAP];
    unless ( $heap->{state} == STATE_CONN ) {
        $heap->{wheel}->put( "Not connected" );
        $heap->{wheel}->get( PROMPT );
        return;
    }
    $kernel->post( 'pop_conn', 'quit' );
}

sub handler_comm_help {
# ----------------------------------------------------------------------------
    my ( $kernel, $heap, $args ) = @_[KERNEL, HEAP, ARG0];
    $args ||= '';
    $args =~ s/^\s+//;
    $args =~ s/\s+$//;
    usage( $args );
    $heap->{wheel}->get( $heap->{prompt} );
}

sub handler_comm_open {
# ----------------------------------------------------------------------------
    my ( $kernel, $heap, $args ) = @_[KERNEL, HEAP, ARG0];
    $kernel->post( 'pop_conn', 'quit' ) if $heap->{state} == STATE_CONN;
    $args =~ /^\s*([^: ]*)(?::(\d+))?/;
    my ( $host, $port ) = ( $1, $2 );
    $port = 110 unless defined $port;
    unless ( defined $host and length $host ) {
        $heap->{wheel}->put( "Hostname required, type ? for help" );
        $heap->{wheel}->get( $heap->{prompt} );
        return;
    }
    $heap->{host} = $host;
    $heap->{port} = $port;
    if ( $heap->{state} == STATE_CONN ) {
        $kernel->state( pop_disconnected => sub {
            $kernel->yield( 'pop_connect' );
            $kernel->state( pop_disconnected => \&handler_pop_disconnected );
        } );
    }
    else {
        $kernel->yield( 'pop_connect' );
    }
}

sub handler_comm_reset {
# ----------------------------------------------------------------------------
    my ( $kernel, $heap ) = @_[KERNEL, HEAP];
    unless ( $heap->{state} == STATE_CONN ) {
        $heap->{wheel}->put( "Not connected" );
        $heap->{wheel}->get( PROMPT );
        return;
    }
    $kernel->post( 'pop_conn', 'rset' );
}

sub handler_pop_connected {
# ----------------------------------------------------------------------------
    my $heap = $_[HEAP];
    warn "$heap->{alias}: Changing state to state_user" if DEBUG;
    $heap->{state} = STATE_USER;
    $heap->{wheel}->get( 'Username: ' );
}

sub handler_pop_rset {
# ----------------------------------------------------------------------------
    my $heap = $_[HEAP];
    $heap->{wheel}->get( $heap->{prompt} );
}

sub handler_comm_exit {
# ----------------------------------------------------------------------------
    my ( $kernel, $heap ) = @_[KERNEL, HEAP];
    $kernel->post( 'pop_conn', 'quit' ) if $heap->{state} == STATE_CONN;
    delete $heap->{wheel};
    $kernel->alias_remove( 'me' );
    $kernel->alarm_remove_all;
}

sub handler_pop_trans_error {
# ----------------------------------------------------------------------------
    my ( $kernel, $heap, $state, $command, $input ) = @_[KERNEL, HEAP, ARG0 .. ARG2];
    warn "$heap->{alias}: Error in $state state with command $command, server said: $input"
        if DEBUG;
    $heap->{wheel}->put( "Error: $input" );

    # Servers usually disconnect you when your login is wrong
    if ( $heap->{state} == STATE_PASS ) {
        $heap->{state} = STATE_NOCONN;
        $kernel->post( 'pop_conn', 'quit' );
        $kernel->state( pop_disconnected => sub {
            $heap->{wheel}->get( $heap->{prompt} );
        } );
    }
    else {
        $heap->{wheel}->get( $heap->{prompt} );
    }
}

sub handler_pop_fatal_error {
# ----------------------------------------------------------------------------
    my ( $kernel, $heap, $command, $op, $errnum, $errstr ) =
        @_[KERNEL, HEAP, ARG0 .. ARG3];
    warn "$heap->{alias}: IO error for $op $errstr ($errnum)" if DEBUG;
    warn "$heap->{alias}: Changing state to state_noconn" if DEBUG;
    $heap->{wheel}->put( "Error for $op: $errstr" );
    $heap->{state} = STATE_NOCONN;
    $heap->{prompt} = PROMPT;
    $heap->{wheel}->get( $heap->{prompt} );
}

sub handler_pop_retr {
# ----------------------------------------------------------------------------
    my ( $kernel, $heap, $email, $number ) = @_[KERNEL, HEAP, ARG0, ARG1];
    
    my $file;
    if ( $file = delete $heap->{view} ) {
        my $editor = $ENV{EDITOR} || 'vim';
        $editor .= " -c 'set syn=mail'" if $editor eq 'vim';
        system "$editor $file";
        unlink $file;
    }
    elsif ( my $exe = delete $heap->{retr_pipe} ) {
        system "cat $heap->{retr_file} | $exe";
        unlink $heap->{retr_file};
    }
    elsif ( $file = delete $heap->{retr_file} ) {
        $heap->{wheel}->put( "Message $number downloaded to $file" );
    }
    else {
        $heap->{wheel}->put( "Message number $number" );
        $heap->{wheel}->put( @$email );
    }
    $heap->{wheel}->get( $heap->{prompt} );
}

sub handler_pop_list {
# ----------------------------------------------------------------------------
    my ( $kernel, $heap, $list ) = @_[KERNEL, HEAP, ARG0];
    
    $heap->{wheel}->put( "List:" );
    for ( sort keys %$list ) {
        $heap->{wheel}->put( "\tMessage: $_ Size: $list->{$_}" );
    }
    $heap->{wheel}->get( $heap->{prompt} );
}

sub handler_pop_auth {
# ----------------------------------------------------------------------------
    my ( $kernel, $heap, $in ) = @_[KERNEL, HEAP, ARG0];
    $kernel->delay( 'noop', NOOP_DELAY );
    $heap->{wheel}->put( "Authentication succeded" );
    warn "$heap->{alias}: changing state to state_conn" if DEBUG;
    $heap->{state} = STATE_CONN;
    $heap->{prompt} = $heap->{host} . ' ' . PROMPT;
    $heap->{wheel}->get( $heap->{prompt} );
    delete $heap->{user};
    delete $heap->{pass};
}

sub handler_pop_disconnected {
# ----------------------------------------------------------------------------
    my ( $kernel, $heap, $input ) = @_[KERNEL, HEAP, ARG0];
    
    warn "$heap->{alias}: Disconnected" if DEBUG;
    if ( defined $heap->{wheel} ) {
        my $msg = '';
        $msg = "Server said $input" if defined $input;
        $heap->{wheel}->put( "Disconnected", $msg );
        $heap->{wheel}->get( PROMPT );
    }
    $heap->{prompt} = PROMPT;
    if ( $heap->{state} == STATE_CONN ) {
        warn "$heap->{alias}: changing state to state_noconn" if DEBUG;
        $heap->{state} = STATE_NOCONN;
    }
    $kernel->alarm_remove_all;
}

sub usage {
# ----------------------------------------------------------------------------
    my ( $command ) = @_;
    my $heap = $poe_kernel->get_active_session()->get_heap();
    if ( exists $USAGE{$command} ) {
        $heap->{wheel}->put( @{$USAGE{$command}} );
    }
    elsif ( defined $command and length $command ) {
        $heap->{wheel}->put( "Command not found. See help" );
    }
    else {

        $heap->{wheel}->put(
            (
                map @{$USAGE{$_}},
                grep { $USAGE{$_}[0] !~ /^See / }
                sort keys %USAGE
            ),
            "",
            "The following commands are synonymous:",
            "       help ?",
            "       retr retrieve get",
            "       quit close",
            "       open connect",
            "       list ls",
            ""
        );
    }
}

POE::Session->create(
    inline_states => {
        _start           => \&handler_start,
        _stop            => \&handler_stop,
        _default         => \&handler_default,
        term_input       => \&handler_term_input,
        noop             => \&handler_noop,
        user             => \&handler_user,
        pass             => \&handler_pass,
        pop_connect      => \&handler_pop_connect,
        pop_connected    => \&handler_pop_connected,
        pop_trans_error  => \&handler_pop_trans_error,
        pop_fatal_error  => \&handler_pop_fatal_error,
        pop_retr         => \&handler_pop_retr,
        pop_list         => \&handler_pop_list,
        pop_auth         => \&handler_pop_auth,
        pop_rset         => \&handler_pop_rset,
        pop_disconnected => \&handler_pop_disconnected,
        comm_list        => \&handler_comm_list,
        comm_help        => \&handler_comm_help,
        'comm_?'         => \&handler_comm_help,
        comm_quit        => \&handler_comm_quit,
        comm_close       => \&handler_comm_quit,
        comm_exit        => \&handler_comm_exit,
        comm_list        => \&handler_comm_list,
        comm_ls          => \&handler_comm_list,
        comm_reset       => \&handler_comm_reset,
        comm_view        => \&handler_comm_get,
        comm_get         => \&handler_comm_get,
        comm_retr        => \&handler_comm_get,
        comm_retrieve    => \&handler_comm_get,
        comm_open        => \&handler_comm_open,
        comm_connect     => \&handler_comm_open
    },
    heap => {
        state  => STATE_NOCONN,
        prompt => PROMPT
    }
);

$poe_kernel->run;


