#!/usr/bin/perl

# Copyright (c) 2011 Timothe Litt <litt at acm dot org>
#
# May be used on the same terms as Perl.

# Sleep hook demo, showing how it enables a background thread
# to provide a simple command interface to a daemon.

=head1 custom_sleep - Demo for a custom 'sleep' function

This example demonstrates the usage of the 'sleep' option
for L<Schedule::Cron> with a custom sleep method which can 
dynamically modify the crontab even inbetween to cron events.
It provides a cron daemon which listens on a TCP port for commands. 

Please note that this is an example only and should obviously not
used for production !

When started, this script will listen on port 65331 and will first
ask for a password. Use 'Purfect' here. Then the following commands
are available:

   status                  -- Print internal job queue
   add id "cron spec" name -- Add a sample jon which will bring "id: name" 
                              each time "cron spec" fires
   load /path/to/crontab   -- Load a crontab as with Schedule::Cron->load_crontab 
   delete id               -- Delete job entry
   quit                    -- Disconect

A sample session looks like:

First start the server:

  ./custom_sleep.pl
  Please wait while initialization is scheduled
  Schedule::Cron - Starting job 0
  Ready, my port is localhost::65331
  Schedule::Cron - Finished job 0
  Schedule::Cron - Starting job 5
  Now: Periodic
  Schedule::Cron - Finished job 5

And then a client:

  $ telnet localhost 65331
  Trying 127.0.0.1...
  Connected to localhost.localdomain (127.0.0.1).
  Escape character is '^]'.
  Password: Purfect
  Password accepted

  status
  Job 0 0 0 1 1 * Next: Sun Jan 1 00:00:00 2012 - NewYear( )
  End of job queue

  load cron.tab
  Loaded cron.tab

  status
  Job 1 34 2 * * Mon Next: Mon Jun 6 02:34:00 2011 - "make_stats"( )
  Job 2 43 8 * * Wed Next: Wed Jun 8 08:43:00 2011 - "Make Peace"( )
  Job 0 0 0 1 1 * Next: Sun Jan 1 00:00:00 2012 - NewYear( )
  End of job queue

  add Halloween "30 18 31 10 *" Pumpkin time
  Added 30 18 31 10 *

  add Today "11 15 * * *" Something to do
  Added 11 15 * * *
 
  add Now "*/2 * * * * 30" Periodic
  Added */2 * * * * 30

  status
  Job 5 */2 * * * * 30 Next: Thu Jun 2 13:40:30 2011 - Now( Periodic )
  Job 4 11 15 * * * Next: Thu Jun 2 15:11:00 2011 - Today( Something to do )
  Job 1 34 2 * * Mon Next: Mon Jun 6 02:34:00 2011 - "make_stats"( )
  Job 2 43 8 * * Wed Next: Wed Jun 8 08:43:00 2011 - "Make Peace"( )
  Job 3 30 18 31 10 * Next: Mon Oct 31 18:30:00 2011 - Halloween( Pumpkin time )
  Job 0 0 0 1 1 * Next: Sun Jan 1 00:00:00 2012 - NewYear( )
  End of job queue
 
  delete Today
  Deleted Today
  
  status
  Job 4 */2 * * * * 30 Next: Thu Jun 2 13:42:30 2011 - Now( Periodic )
  Job 1 34 2 * * Mon Next: Mon Jun 6 02:34:00 2011 - "make_stats"( )
  Job 2 43 8 * * Wed Next: Wed Jun 8 08:43:00 2011 - "Make Peace"( )
  Job 3 30 18 31 10 * Next: Mon Oct 31 18:30:00 2011 - Halloween( Pumpkin time )
  Job 0 0 0 1 1 * Next: Sun Jan 1 00:00:00 2012 - NewYear( )
  End of job queue

  q
  Connection closed by foreign host.

=cut

use strict;
use warnings;

use Schedule::Cron;
use Socket ':crlf';
use IO::Socket::INET;

my $port = 65331;
our $password = 'Purfect';

our( $lsock, $rin, $win, $maxfd, %servers );

my $cron = new Schedule::Cron( sub { print 'Loaded entry: ', join('', @_ ), "\n"; }, {
                                        nofork => 1,
                                        loglevel => 0,
                                        log => sub { print $_[1], "\n"; },
                                        sleep => \&idler
                                       } );

$cron->add_entry( "* * * * * *", \&init, 'Init', $cron );
$cron->add_entry( "0 0 1 1 *", sub { print "Happy New Year\n"; }, "NewYear" );

print "Please wait while initialization is scheduled\n";
print help();

$cron->run( { detach => 0 } );

exit;


sub idler {
    my( $time ) = @_;

    my( $rout, $wout );

    my( $nfound, $ttg ) = select( $rout=$rin, $wout=$win, undef, $time );
    if( $nfound ) {
        if( $nfound == -1 ) {
            die "select() error: $!\n"; # This will be an internal error, such as a stale fd.
        }
        for( my $n = 0; $n <= $maxfd; $n++ ) {
            if( vec( $rout, $n, 1 ) ) {
                my $s = $servers{$n};
                $s->{rsub}->( );
            }
        }
        for( my $n = 0; $n <= $maxfd; $n++ ) {
            if( vec( $wout, $n, 1 ) ) {
                my $s = $servers{$n};
                $s->{wsub}->( );
            }
        }
    }
}

# First task run initializes (usually in daemon, after forking closed open files)
# I suppose this could be a postfork callback, but there isn't one...

sub init {
    my( $name, $cron ) = @_;

    $cron->delete_entry( 'Init' );

    $rin = '';
    $win = '';

    $lsock = IO::Socket::INET->new(
                                   LocalAddr => "localhost:$port",
                                   Proto => 'tcp',
                                   Type => SOCK_STREAM,
                                   Listen => 5,
                                   ReuseAddr => 1,
                                   Blocking => 0,
                                  ),
                                    or die "Unable to open status port $port $!\n";
    vec( $rin, ($maxfd = $lsock->fileno()), 1 ) = 1;
    $servers{$maxfd} = { rsub=>sub { newConn( $lsock, $cron ); } };

    print "Ready, my port is localhost:$port\nTo connect:\n    telnet localhost $port\n";

    return;
}

sub newConn {
    my( $lsock, $cron ) = @_;

    my $sock = $lsock->accept();

    $sock->blocking(0);
    my $cx = {
              rbuf => '',
              wbuf => 'Password: ',
              };
    my $fd = $sock->fileno();
    $maxfd = $fd if( $maxfd < $fd );

    vec( $rin, $fd, 1 ) = 1;
    vec( $win, $fd, 1 ) = 1;
    $servers{$fd} = { rsub=>sub { serverRd( $sock, $cx, $fd ); },
                      wsub=>sub { serverWr( $sock, $cx, $fd ); },
                      cron=>$cron,
                    };
}

sub serverRd {
    my( $sock, $cx, $fd ) = @_;

    # Read whatever is available.  1000 is arbitrary, 1 will work (with lots of overhead).
    # Huge will prevent any other thread from running.

    my $rn= $sock->sysread( $cx ->{rbuf}, 1000, length $cx->{rbuf} );
    unless( defined $rn ) {
        print "Read error: $!\n";
    }
    unless( $rn ) { # Connection closed by client
        vec( $rin, $fd, 1 ) = 0;
        vec( $win, $fd, 1 ) = 0;
        $sock->close();
        undef $cx;
        return;
    }

    # Assemble reads to form whole lines
    # Decode each line as a command.

    while( $cx->{rbuf} =~ /$LF/sm ) {
        $cx->{rbuf} =~ s/$CR//g;
        my( $line, $rest );
        ($line, $rest) = split( /$LF/, $cx->{rbuf}, 2 );
        $rest = '' unless( defined $rest );
        $cx->{rbuf} = $rest;

        # This is not secure, but one has to do something.
        # Demos always get used for more than they should..
        # Please do better...like user/account validation
        # using the system services.

        unless( $cx->{authenticated} ){
            if( $line eq $password ) {
                $cx->{authenticated} = 1;
                $cx->{wbuf} .= "Password accepted$CR$LF";
            } else {
                $cx->{wbuf} .= "Password refused.$CR${LF}Password: ";
            }
            next;
        }

        if( $line =~ /^STAT(?:US)?(?: (\w+))?$/i ) {
            $cx->{wbuf} .= status( $cron, ($1 || 'normal') );
        } elsif( $line =~ /^ADD\s+(\w+)\s+"(.*?)"\s+(.*)$/i ) {
            my( $name, $sched ) = ($1, $2);
            $cron->add_entry( $sched, \&announce, $1, $3 );
            $cx->{wbuf} .= "Added $name '$sched'$CR$LF";
        } elsif( $line =~ /^DEL(?:ETE)?\s+(["\w]+)$/i ) {
            my $name = $1;
            my $idx = $cron->check_entry( $name );
            if( defined $idx ) {
                $cron->delete_entry( $idx );
                $cx->{wbuf} .= "Deleted $name$CR$LF";
            } else {
                $cx->{wbuf} .= "$name not found$CR$LF";
            }
        } elsif( $line =~ /^HELP$/i ) {
            $cx->{wbuf} .= help();
        } elsif( $line =~ /^LOAD\s([\w\._-]+)$/i ) {
            my $cfg = $1; # Danger: File permissions of server are used here.
              eval {
                  $cron->load_crontab( $cfg );
              };
            my $emsg = $@;
            $emsg =~ s/\n/$CR$LF/gms;
            $cx->{wbuf} .= $emsg || "Loaded $cfg$CR$LF";
        } elsif( $line =~ /^Q(?:uit)?$/i ) {
            $cx->{wbuf} .= "Bye$CR$LF";
            $cx->{wend} = 1;
        } else {
            $cx->{wbuf} .= "Unrecognized command: $line$CR$LF";
        }
    }
    serverWr( $sock, $cx, $fd );
}

# Server write process
#
# Output as much as possible from our buffer.
# If more remains, keep select mask active
# If done, clear select mask.  If last write, close socket.

sub serverWr {
    my( $sock, $cx, $fd ) = @_;

    if( length $cx->{wbuf} ) {
        my $written = $sock->syswrite( $cx->{wbuf} );

        $cx->{wbuf} = substr( $cx->{wbuf}, $written );
    }
    if( length $cx->{wbuf} ) {
        vec( $win, $fd, 1 ) = 1;
        return;
    } else {
        vec( $win, $fd, 1 ) = 0;
        if( $cx->{wend} ) {
            vec( $rin, $fd, 1 ) = 0;
            $sock->close();
            return;
        }
    }
}

sub announce {
    my( $id, $msg ) = @_;

    print "$id: $msg\n";
    return;
}

sub status {
    my $cron = shift;
    my $level = shift;

    my $maxtwid = 0;
    my @entries = map { $_->[0] } sort { $a->[1] <=> $b->[1] }
                                           map { 
                                                 my $time = $_->{time};
                                                 $maxtwid = length $time if( $maxtwid < length $time );
                                                 [ $_, 
                                                   $cron->get_next_execution_time( $time ),
                                                 ]
                                               } $cron->list_entries();
    my $msg = "Job queue\n";
    foreach my $qe ( @entries ) {
        my $job = $cron->check_entry( $qe->{args}->[0] );
        next unless( defined $job ); #??
        $msg .= sprintf( "Job %-4s %-*s Next: %s - %s", 
                         $job, $maxtwid, $qe->{time},
                         (scalar localtime( $cron->get_next_execution_time( $qe->{time}, 0 ) )),
                         $qe->{args}->[0] ||  '<Unnamed>', # Task name
                       );
        if( $level =~ /^debug$/i ) {
            $msg .= '( ';
            my @uargs = @{$qe->{args}};
            $msg .= join( ', ', @uargs[1..$#uargs] ) . ' )';
        }
        $msg .= "\n";
    }
    $msg .= "End of job queue\n";
    $msg =~ s/\n/$CR$LF/mgs;

    return $msg;
}

use Cwd 'getcwd';
sub help {
    my $wd = getcwd();
   my $msg = <<"HELP";
CAUTION: Not production code.  NOT secure.
Do NOT run from privileged account.

Commands:
    status
       Shows queue

    status debug
       With argument lists

    add name "schedule" A string to be printed when executed
       Adds a new task on specified schedule

    delete name
       Deletes a task (by name)

    help
      This message.

    load file
        Loads a crontab file from $wd
        CAUTION, this is with server permissions.  If 
        the server can read /etc/passwd (or anything else), 
        it will display it in the error messages.  
        As I said, NOT production...

    quit
        Exits.

HELP

   $msg =~ s/\n/$CRLF/gms;

   return $msg;
}
