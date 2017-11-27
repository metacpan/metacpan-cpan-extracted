# ABSTRACT: POE eris message dispatcher
package POE::Component::Server::eris;

use strict;
use warnings;

use POE qw(
    Component::Client::TCP
    Component::Server::TCP
);
use Sys::Hostname qw(hostname);

our $VERSION = '2.4';

my @_STREAM_NAMES = qw(subscribers match debug full regex);
my %_STREAM_ASSISTERS = (
    subscribers => 'programs',
    match       => 'words',
);
my %COMMANDS = (
    fullfeed    => { re => qr/^fullfeed/,              cb => \&fullfeed_client },
    nofullfeed  => { re => qr/^nofull(feed)?/,         cb => \&nofullfeed_client },
    subscribe   => { re => qr/^sub(?:scribe)? (.*)/,   cb => \&subscribe_client },
    unsubscribe => { re => qr/^unsub(?:scribe)? (.*)/, cb => \&unsubscribe_client },
    match       => { re => qr/^match (.*)/,            cb => \&match_client },
    nomatch     => { re => qr/^nomatch(?:\s+(.*))?/,   cb => \&nomatch_client },
    debug       => { re => qr/^debug/,                 cb => \&debug_client },
    nobug       => { re => qr/^(no(de)?bug)/,          cb => \&nobug_client },
    regex       => { re => qr/^re(?:gex)? (.*)/,       cb => \&regex_client },
    noregex     => { re => qr/^nore(gex)?/,            cb => \&noregex_client },
    status      => { re => qr/^status/,                cb => \&status_client },
    dump        => { re => qr/^dump (\S+)/,            cb => \&dump_client },
    help        => { re => qr/^help/,                  cb => \&help_client },
);
my $DISPATCH;


# Precompiled Regular Expressions
my %_PRE = (
    program => qr/(?>[0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}(?:\.[0-9]{3,})?(?:\+[0-9]{1,2}:[0-9]{1,2})?\s+\S+\s+([^:\s]+)(:|\s))/,
);

sub _benchmark_regex {
    eval {
        require Dumbbench;
    };
    if( $@ ) {
        warn "unable to load Dumbbench.pm: $@";
        return;
    }
    my @msgs = (
        q|<11>Jan  1 00:00:00 mainfw snort[32640]: [1:1893:4] SNMP missing community string attempt [Classification: Misc Attack] [Priority: 2]: {UDP} 1.2.3.4:23210 -> 5.6.7.8:161|,
        q|<11>Jan  1 00:00:00 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|,
        q|Jan  1 00:00:00 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|,
        q|<11>Jan  1 00:00:00 dev.example.com dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|,
        q|Jan  1 00:00:00 example syslogd 1.2.3: restart (remote reception).|,
        q|<163>Jun 7 18:39:00 hostname.domain.tld %ASA-3-313001: Denied ICMP type=5, code=1 from 1.2.3.4 on interface inside|,
        q|2016-11-29T06:30:01+01:00 ether CROND[15084]: (root) CMD (/usr/lib64/sa/sa1 1 1)|,
        q|<163>2016-11-29T06:30:01+01:00 ether CROND[15084]: (root) CMD (/usr/lib64/sa/sa1 1 1)|,
    );
    my %tests = ();
    my %misses = ();
    my $bench = Dumbbench->new(initial_runs => 10_000);

    foreach my $re (keys %_PRE) {
        $bench->add_instances(
            Dumbbench::Instance::PerlSub->new(
                name => $re,
                code => sub {
                        for (@msgs) {
                        if( $_ !~ /$_PRE{$re}/ ) {
                            $misses{"$re | $_"}=1;
                        }
                    }
                },
            ),
        );
    }
    $bench->run();
    print $bench->report();
    if( keys %misses ) {
        print "\nREGEX MISSES:\n\n";
        print "  $_\n" for sort keys %misses;
    }
}



sub spawn {
    my $type = shift;

    #
    # Param Setup
    my %args = (
        ListenAddress   => 'localhost',
        ListenPort      => 9514,
        GraphitePort    => 2003,
        GraphitePrefix  => 'eris.dispatcher',
        @_
    );

    # TCP Session Master
    my $tcp_sess = POE::Component::Server::TCP->new(
        Alias       => 'eris_client_server',
        Address     => $args{ListenAddress},
        Port        => $args{ListenPort},

        Error               => \&server_error,
        ClientConnected     => \&client_connect,
        ClientInput         => \&client_input,

        ClientDisconnected  => \&client_term,
        ClientError         => \&client_term,

        InlineStates        => {
            client_print => \&client_print,
        },
    );

    # Dispatcher Master Session
    $DISPATCH = POE::Session->create(
        inline_states => {
            _start                  => \&dispatcher_start,
            _stop                   => sub { print "SESSION ", $_[SESSION]->ID, " stopped.\n"; },
            server_shutdown         => \&server_shutdown,
            debug_message           => \&debug_message,
            dispatch_message        => \&dispatch_message,
            dispatch_messages       => \&dispatch_messages,
            broadcast               => \&broadcast,
            hangup_client           => \&hangup_client,
            register_client         => \&register_client,
            flush_client            => \&flush_client,
            graphite_connect        => \&graphite_connect,
            stats                   => \&flush_stats,
            # Client Commands
            map { sprintf("%s_client", $_) => $COMMANDS{$_}->{cb} } sort keys %COMMANDS,
        },
        heap => {
            config   => \%args,
            hostname => (split /\./, hostname)[0],
        },
    );

    #$DISPATCH->option( trace => 1 );

    return { alias => $args{Alias} ? $args{Alias} : undef, => ID => $DISPATCH->ID };
}


sub debug {
    my $msg = shift;
    chomp($msg);
    $poe_kernel->post( $DISPATCH => 'debug_message' => $msg );
    print "[debug] $msg\n";
}
#--------------------------------------------------------------------------#


sub dispatcher_start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    $kernel->alias_set( $heap->{config}{Alias} ) if $heap->{config}{Alias};
    $kernel->delay( flush_client => 0.1 );

    # Stream Storage
    foreach my $stream (@_STREAM_NAMES) {
        my %store;
        $heap->{$stream} = \%store;
    }
    # Assistance
    foreach my $assister (values %_STREAM_ASSISTERS) {
        my %store;
        $heap->{$assister} = \%store;
    }
    # Output buffering
    $heap->{buffers} = {};

    # Statistics Tracking
    $kernel->yield( 'graphite_connect' ) if exists $heap->{config}{GraphiteHost};
    $kernel->yield( 'stats' );
}
#--------------------------------------------------------------------------#


sub graphite_connect {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    # Build the Graphite Handler
    $heap->{_graphite} = POE::Component::Client::TCP->new(
        Alias          => 'graphite',
        RemoteAddress  => $heap->{config}{GraphiteHost},
        RemotePort     => $heap->{config}{GraphitePort},
        ConnectTimeout => 5,
        Connected      => sub {
            # let the parent know we're able to write
            $heap->{graphite} = 1;
        },
        ConnectError => sub {
            my ($op,$err_num,$err_str) = @_[ARG0..ARG2];
            delete $heap->{graphite} if exists $heap->{graphite};
            delete $heap->{_graphite};
            $heap->{stats}{graphite_errors} ||= 0;
            $heap->{stats}{graphite_errors}++;
            # Attempt to reconnect
            $kernel->delay( reconnect => 60 ) unless $heap->{_SHUTDOWN_};
        },
        Disconnected => sub {
            delete $heap->{graphite} if exists $heap->{graphite};
            delete $heap->{_graphite};
            $kernel->delay( reconnect => 60  ) unless $heap->{_SHUTDOWN_};
        },
        Filter => "POE::Filter::Line",
        InlineStates => {
            send => sub {
                $_[HEAP]->{server}->put($_[ARG0]);
            },
        },
        ServerInput => sub {
            # Shouldn't get any
            $heap->{stats}{graphite_feedback} ||= 0;
            $heap->{stats}{graphite_feedback}++;
        },
        ServerError => sub {
            $_[KERNEL]->yield( 'reconnect' ) unless $heap->{_SHUTDOWN_};
        },
    );
}

#--------------------------------------------------------------------------#


sub flush_stats {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    # Clear the event queue
    $kernel->delay('stats');

    if (exists $heap->{stats}) {
        my $stats = delete $heap->{stats};
        if( exists $heap->{graphite} && $heap->{graphite} ) {
            my $time = time();
            foreach my $stat (keys %{ $stats }) {
                my $metric = join('.', $heap->{config}{GraphitePrefix}, $heap->{hostname}, $stat);
                $kernel->post( graphite => send => join " ", $metric, $stats->{$stat}, $time);
            }
        }
        debug('STATS: ' . join(', ', map { "$_:$stats->{$_}" } sort keys %{ $stats } ) );
    }
    $heap->{stats} = {
        map { $_ => 0 } qw(received received_bytes dispatched dispatched_bytes)
    };

    $kernel->delay( stats => 60 ) unless $heap->{_SHUTDOWN_};
}

#--------------------------------------------------------------------------#


sub dispatch_message {
    my ($kernel,$heap,$msg) = @_[KERNEL,HEAP,ARG0];

    _dispatch_messages($kernel, $heap, [$msg]);
}


sub dispatch_messages {
    my ($kernel,$heap,$msgs) = @_[KERNEL,HEAP,ARG0];

    _dispatch_messages($kernel, $heap, [split /\n/, $msgs])
}

sub _dispatch_messages {
    my ($kernel,$heap,$msgs) = @_;

    my $dispatched = 0;
    my $bytes = 0;

    # Handle fullfeeds
    foreach my $sid ( keys %{ $heap->{full} } ) {
        push @{ $heap->{buffers}{$sid} }, @$msgs;
        $dispatched += @$msgs;
        $bytes += length $_ for @$msgs;
    }

    foreach my $msg ( @$msgs ) {
        # Grab statitics;
        $heap->{stats}{received}++;
        $heap->{stats}{received_bytes} += length $msg;

        # Program based subscriptions
        if( keys %{ $heap->{subscribers} } ) {
            if( my ($program) = map { lc } ($msg =~ /$_PRE{program}/o) ) {
                # remove the sub process and PID from the program
                $program =~ s/\(.*//;
                $program =~ s/\[.*//;

                if( exists $heap->{programs}{$program} && $heap->{programs}{$program} > 0 ) {
                    foreach my $sid (keys %{ $heap->{subscribers} }) {
                        next unless exists $heap->{subscribers}{$sid}{$program};
                        push @{ $heap->{buffers}{$sid} }, $msg;
                        $dispatched++;
                        $bytes += length $msg;
                    }
                }
            }
        }

        # Match based subscriptions
        if( keys %{ $heap->{words} } ) {
            foreach my $word (keys %{ $heap->{words} } ) {
                if( index( $msg, $word ) != -1 ) {
                    foreach my $sid ( keys %{ $heap->{match} } ) {
                        next unless exists $heap->{match}{$sid}{$word};
                        push @{ $heap->{buffers}{$sid} }, $msg;
                        $dispatched++;
                        $bytes += length $msg;
                    }
                }
            }
        }

        # Regex based subscriptions
        if( keys %{ $heap->{regex} } ) {
            my %hit = ();
            foreach my $sid (keys %{ $heap->{regex} } ) {
                foreach my $re ( keys %{ $heap->{regex}{$sid} } ) {
                    if( $hit{$re} || $msg =~ /$re/ ) {
                        $hit{$re} = 1;
                        push @{ $heap->{buffers}{$sid} }, $msg;
                        $dispatched++;
                        $bytes += length $msg;
                    }
                }
            }
        }
    }
    # Report statistics for dispatched messages
    if( $dispatched > 0 ) {
        $heap->{stats}{dispatched} += $dispatched;
        $heap->{stats}{dispatched_bytes} += $bytes;
    }
}

#--------------------------------------------------------------------------#


sub server_error {
    my ($syscall_name, $err_num, $err_str) = @_[ARG0..ARG2];
    debug( "SERVER ERROR: $syscall_name, $err_num, $err_str" );

    if( $err_num == 98 ) {
        # Address already in use, bail
        $poe_kernel->stop();
    }
}
#--------------------------------------------------------------------------#


sub register_client {
    my ($kernel,$heap,$sid) = @_[KERNEL,HEAP,ARG0];
    $heap->{buffers}{$sid} = [];
}
#--------------------------------------------------------------------------#


sub debug_client {
    my ($kernel,$heap,$sid) = @_[KERNEL,HEAP,ARG0];

    _remove_stream($heap,$sid,'full');

    $heap->{debug}{$sid} = 1;
    $kernel->post( $sid => 'client_print' => 'Debugging enabled.' );
}
#--------------------------------------------------------------------------#


sub nobug_client {
    my ($kernel,$heap,$sid) = @_[KERNEL,HEAP,ARG0];

    _remove_stream($heap,$sid,'debug');

    $kernel->post( $sid => 'client_print' => 'Debugging disabled.' );
}
#--------------------------------------------------------------------------#


sub fullfeed_client {
    my ($kernel,$heap,$sid) = @_[KERNEL,HEAP,ARG0];

    _remove_all_streams($heap,$sid);

    # Add to fullfeed:
    $heap->{full}{$sid} = 1;

    $kernel->post( $sid => 'client_print' => 'Full feed enabled, all other functions disabled.');
}
#--------------------------------------------------------------------------#


sub nofullfeed_client {
    my ($kernel,$heap,$sid) = @_[KERNEL,HEAP,ARG0];

    _remove_all_streams($heap,$sid);

    $kernel->post( $sid => 'client_print' => 'Full feed disabled.');
}
#--------------------------------------------------------------------------#


sub subscribe_client {
    my ($kernel,$heap,$sid,$argstr) = @_[KERNEL,HEAP,ARG0,ARG1];

    _remove_stream($heap,$sid,'full');

    my @progs = map { lc } split /[\s,]+/, $argstr;
    foreach my $prog (@progs) {
        $heap->{subscribers}{$sid}{$prog} = 1;
        $heap->{programs}{$prog}++;
    }

    $kernel->post( $sid => 'client_print' => 'Subscribed to : ' . join(', ', @progs ) );
}
#--------------------------------------------------------------------------#


sub unsubscribe_client {
    my ($kernel,$heap,$sid,$argstr) = @_[KERNEL,HEAP,ARG0,ARG1];

    my @progs = map { lc } split /[\s,]+/, $argstr;
    foreach my $prog (@progs) {
        delete $heap->{subscribers}{$sid}{$prog};
        $heap->{programs}{$prog}--;
        delete $heap->{programs}{$prog} unless $heap->{programs}{$prog} > 0;
    }

    $kernel->post( $sid => 'client_print' => 'Subscription removed for : ' . join(', ', @progs ) );
}
#--------------------------------------------------------------------------#


sub match_client {
    my ($kernel,$heap,$sid,$argstr) = @_[KERNEL,HEAP,ARG0,ARG1];

    _remove_stream($heap,$sid,'full') if exists $heap->{full}{$sid};

    my @words = map { lc } split /[\s,]+/, $argstr;
    foreach my $word (@words) {
        $heap->{words}{$word}++;
        $heap->{match}{$sid}{$word} = 1;
    }

    $kernel->post( $sid => 'client_print' => 'Receiving messages matching : ' . join(', ', @words ) );
}
#--------------------------------------------------------------------------#


sub flush_client {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    foreach my $sid ( keys %{ $heap->{buffers} } ) {
        my $msgs = $heap->{buffers}{$sid};
        next unless @$msgs > 0;

        $kernel->post( $sid => 'client_print' => join "\n", @$msgs );
        $heap->{buffers}{$sid} = [];
    }

    $kernel->delay( flush_client => 0.1 ) unless $heap->{_SHUTDOWN_};
}

#--------------------------------------------------------------------------#



sub nomatch_client {
    my ($kernel,$heap,$sid,$argstr) = @_[KERNEL,HEAP,ARG0,ARG1];

    # If we're a fullfeed client, ignore
    return if exists $heap->{full}{$sid};

    my @words = length $argstr ? map { lc } split /[\s,]+/, $argstr
              : exists $heap->{match}{$sid} ? keys %{ $heap->{match}{$sid} }
              : ();
    foreach my $word (@words) {
        delete $heap->{match}{$sid}{$word};
        # Remove the word from searching if this was the last client
        $heap->{words}{$word}--;
        delete $heap->{words}{$word} unless $heap->{words}{$word} > 0;
    }

    $kernel->post( $sid => 'client_print' => 'No longer receving messages matching : ' . join(', ', @words ) );
}
#--------------------------------------------------------------------------#


sub regex_client {
    my ($kernel,$heap,$sid,$argstr) = @_[KERNEL,HEAP,ARG0,ARG1];

    # Disable the fullfeed on this client
    _remove_stream($heap,$sid,'full') if exists $heap->{full}{$sid};

    my $regex = undef;
    eval {
        if (defined $argstr && length $argstr) {
            $regex = qr{$argstr};
        }
    };

    if( defined $regex ) {
        $heap->{regex}{$sid}{$regex} = 1;
        $kernel->post( $sid => 'client_print' => "Receiving messages matching regex : $argstr" );
    }
    else {
        $kernel->post( $sid => 'client_print' => "Invalid regular expression '$argstr', see perldoc perlre" );
    }
}
#--------------------------------------------------------------------------#



sub noregex_client {
    my ($kernel,$heap,$sid) = @_[KERNEL,HEAP,ARG0];

    _remove_stream($heap,$sid,'regex');

    $kernel->post( $sid => 'client_print' => 'No longer receving regex-based matches' );
}
#--------------------------------------------------------------------------#



sub status_client {
    my ($kernel,$heap,$sid) = @_[KERNEL,HEAP,ARG0];

    my $cnt = scalar( keys %{ $heap->{clients} } );

    my @details = ();
    foreach my $stream (@_STREAM_NAMES) {
        if ( exists $heap->{$stream} && ref $heap->{$stream} eq 'HASH' ) {
            my $cnt = keys %{ $heap->{$stream} };
            my $assist = 0;
            if( exists $_STREAM_ASSISTERS{$stream} ) {
                if( exists $heap->{$_STREAM_ASSISTERS{$stream}} && ref $heap->{$_STREAM_ASSISTERS{$stream}} eq 'HASH' ) {
                    $assist = scalar keys %{ $heap->{$_STREAM_ASSISTERS{$stream}} };
                }
            }
            next if $cnt <= 0 && $assist <= 0;
            my $det = "$stream=$cnt";
            $det .= ":$assist" if $assist > 0;
            push @details, $det;
        }
    }
    my $details = join(', ', @details);
    my $msg = "STATUS[0]: $cnt connections: $details";
    $kernel->post( $sid, 'client_print', $msg );
}


sub dump_client {
    my ($kernel,$heap,$sid,$type) = @_[KERNEL,HEAP,ARG0,ARG1];

    $heap->{dump_calls} ||= {
        assisters => sub {
            my @details = ();
            foreach my $asst (values %_STREAM_ASSISTERS) {
                if( exists $heap->{$asst} && ref $heap->{$asst} eq 'HASH') {
                    push @details, "$asst -> " . join(',', keys %{ $heap->{$asst} });
                }
            }
            return @details;
        },
        stats => sub {
            my @details = ();
            foreach my $stat (keys %{ $heap->{stats} }) {
                push @details, "$stat -> $heap->{stats}{$stat}";
            }
            return @details;
        },
        streams => sub {
            my @details = ();
            foreach my $str (@_STREAM_NAMES) {
                if( exists $heap->{$str} && ref $heap->{$str} eq 'HASH') {
                    my @sids = ();
                    foreach my $sid (keys %{$heap->{$str}}) {
                        if( ref $heap->{$str}{$sid} eq 'HASH' ) {
                            push @sids, "$sid:" . join(',', keys %{ $heap->{$str}{$sid} });
                        }
                        else {
                            push @sids, $sid;
                        }
                    }
                    push @details, "$str -> " . join( "; ", @sids);
                }
            }
            return @details;
        },
    };

    if( exists $heap->{dump_calls}{$type} ) {
        my @msgs = $heap->{dump_calls}{$type}->();
        $kernel->post( $sid => client_print => "DUMP[0]: $_" ) for @msgs;
    }
    else {
        $kernel->post( $sid => client_print => sprintf "DUMP[-1]: No comprende, please ask for: %s",
            join(',',sort keys %{ $heap->{dump_calls} } )
        );
    }
}




sub hangup_client {
    my ($kernel,$heap,$sid) = @_[KERNEL,HEAP,ARG0];

    delete $heap->{clients}{$sid};
    delete $heap->{buffers}{$sid};

    _remove_all_streams($heap,$sid);

    $kernel->post( $sid => 'shutdown' );
    debug("Client Termination Posted: $sid\n");

}

#--------------------------------------------------------------------------#
sub _remove_stream {
    my ($heap,$sid,$stream) = @_;

    debug("Removing '$stream' for $sid");

    my $ref = exists $heap->{$stream}{$sid} ? delete $heap->{$stream}{$sid} : undef;
    if(defined $ref) {
        if( exists $_STREAM_ASSISTERS{$stream} ) {
            my $assist = $_STREAM_ASSISTERS{$stream};
            foreach my $key (keys %{ $ref } ) {
                $heap->{$assist}{$key}--;
                delete $heap->{$assist}{$key} unless $heap->{$assist}{$key} > 0;
            }
        }
        undef $ref;
    }
}

sub _remove_all_streams {
    my ($heap,$sid) = @_;

    foreach my $stream (@_STREAM_NAMES) {
        _remove_stream($heap,$sid,$stream);
    }
}
#--------------------------------------------------------------------------#


sub server_shutdown {
    my ($kernel,$heap,$msg) = @_[KERNEL,HEAP,ARG0];

    # Set the shutdown
    $heap->{_SHUTDOWN_} = 1;

    # Remove our alias
    $kernel->alias_remove($heap->{config}{Alias}) if $heap->{config}{Alias};

    # Clear out the stats
    $kernel->yield( 'stats' );

    # Shutdown the graphite connection
    $kernel->call( graphite => 'shutdown' ) if $heap->{_graphite};

    # Let folks know the end is nye
    $kernel->call( $DISPATCH->ID => 'broadcast' => 'SERVER DISCONNECTING: ' . $msg );

    # Shutdown the engine
    $kernel->call( eris_client_server => 'shutdown' );

}
#--------------------------------------------------------------------------#


sub client_connect {
    my ($kernel,$heap,$ses) = @_[KERNEL,HEAP,SESSION];

    my $KID = $kernel->ID();
    my $CID = $heap->{client}->ID;
    my $SID = $ses->ID;

    # Register the client with the dispatcher
    $kernel->post( $DISPATCH => register_client => $SID );

    # Map client to session id
    $heap->{clients}{$SID} = $heap->{client};

    # Say hello to the client.
    $heap->{client}->put( "EHLO Streamer (KERNEL: $KID:$SID:$CID)" );
}

#--------------------------------------------------------------------------#


sub client_print {
    my ($kernel,$heap,$ses,$mesg) = @_[KERNEL,HEAP,SESSION,ARG0];
    $heap->{clients}{$ses->ID}->put($mesg);
}
#--------------------------------------------------------------------------#


sub broadcast {
    my ($kernel,$heap,$msg) = @_[KERNEL,HEAP,ARG0];
    foreach my $sid (keys %{ $heap->{clients} }) {
        $kernel->post( $sid => 'client_print' => $msg );
    }
}
#--------------------------------------------------------------------------#


sub debug_message {
    my ($kernel,$heap,$msg) = @_[KERNEL,HEAP,ARG0];
    foreach my $sid (keys %{ $heap->{debug} }) {
        $kernel->post( $sid => client_print => '[debug] ' . $msg );
    }
}
#--------------------------------------------------------------------------#


sub client_input {
    my ($kernel,$heap,$ses,$msg) = @_[KERNEL,HEAP,SESSION,ARG0];
    my $sid = $ses->ID;
    # Check for messages:
    my $handled = 0;
    foreach my $cmd ( keys %COMMANDS ) {
        if( $msg =~ /$COMMANDS{$cmd}->{re}/i ) {
            my $args = $1;
            my $evt = sprintf "%s_client", $cmd;
            $kernel->post( $DISPATCH => $evt, $sid => $args );
            $handled = 1;
            last;
        }
    }
    if( !$handled ) {
        $kernel->post( $sid => client_print => 'UNKNOWN COMMAND, Ignored. (see help)' );
    }
}
#--------------------------------------------------------------------------#


sub help_client {
    my ($kernel,$heap,$sid,$arg) = @_[KERNEL,HEAP,ARG0,ARG1];

    if( keys %COMMANDS ) {
        $kernel->post( $sid => client_print => sprintf "Available commands: %s",
            join(', ', sort keys %COMMANDS),
        );
    }
    else {
        $kernel->post( $sid => client_print => 'Something unsuccessfully happened.' );
    }
}


sub client_term {
    my ($kernel,$heap,$ses) = @_[KERNEL,HEAP,SESSION];
    my $sid = $ses->ID;

    delete $heap->{dispatch}{$sid};
    $kernel->post( $DISPATCH->ID => hangup_client =>  $sid );

    debug("SERVER, client $sid disconnected.\n");
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Server::eris - POE eris message dispatcher

=head1 VERSION

version 2.4

=head1 SYNOPSIS

POE session for integration with your central logging infrastructure
By itself, this module is useless.  It is designed to take an stream of data
from anything that can generate a POE Event.  Examples for syslog-ng and
rsyslog are included in the examples directory!

    use POE qw(
        Component::Server::TCP
        Component::Server::eris
    );

    # Message Dispatch Service
    my $SESSION = POE::Component::Server::eris->spawn(
            Alias               => 'eris_dispatch',     #optional
            ListenAddress       => 'localhost',         #default
            ListenPort          => '9514',              #default
            GraphiteHost        => undef,               #default
            GraphitePort        => 2003,                #default
            GraphitePrefix      => 'eris.dispatcher',   #default
    );

    # $SESSION = { alias => 'eris_dispatch', ID => POE::Session->ID };


    # Take Input from a TCP Socket
    my $input_log_session_id = POE::Component::Server::TCP->spawn(

        # An event will post incoming messages to:
        # $poe_kernel->post( eris_dispatch => dispatch_message => $msg );
        #        or
        # $poe_kernel->post( $SESSION->{alias} => dispatch_message => $msg );
        ...

    );

    POE::Kernel->run();

=head1 METHODS

=head2 spawn

Creates the POE::Session for the eris correlator.

Parameters:
    ListenAddress           => 'localhost',         #default
    ListenPort              => '9514',              #default

=head1 ACKNOWLEDGEMENTS

=over 4

=item Mattia Barbon

=back

=head1 AUTHOR

Brad Lhotsky <brad@divsionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=head1 EVENTS

=head2 debug

Controls Debugging Output to the controlling terminal

=head2 dispatcher_start

Sets the alias and creates in-memory storages

=head2 graphite_connect

Establish a connection to the graphite server

=head2 flush_stats

Send statistics to the graphite server and the debug clients

=head2 dispatch_message

Based on clients connected and their feed settings, distribute this message

=head2 dispatch_messages

Splits multiple messages by line feeds into many messages.

=head2 server_error

Handles errors related to the PoCo::TCP::Server

=head2 register_client

Client Registration for the dispatcher

=head2 debug_client

Enables debugging for the client requesting it

=head2 nobug_client

Disables debugging for a particular client

=head2 fullfeed_client

Adds requesting client to the list of full feed clients

=head2 nofullfeed_client

Disables the full feed from the requesting client.

=head2 subscribe_client

Handle program name subscription

=head2 unsubscribe_client

Handle unsubscribe requests from clients

=head2 match_client

Handle requests for string matching from clients

=head2 flush_client

Flushes the outstanding buffer to the client.

=head2 nomatch_client

Remove a match based feed from a client

=head2 regex_client

Handle requests for string regexes from clients

=head2 noregex_client

Remove a match based feed from a client

=head2 status_client

Send current server statistics to client

=head2 dump_client

Dump something interesting to the client

=head2 hangup_client

This handles cleaning up from a client disconnect

=head2 server_shutdown

Announce server shutdown, shut off PoCo::Server::TCP Session

=head2 client_connect

PoCo::Server::TCP Client Establishment Code

=head2 client_print

PoCo::Server::TCP Write to Client

=head2 broadcast

PoCo::Server::TCP Broadcast Messages

=head2 debug_message

Send debug message to DEBUG clients

=head2 client_input

Parse the Client Input for eris::dispatcher commands and enact those commands

=head2 help_client

Display the help message

=head2 client_term

PoCo::Server::TCP Client Termination

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/POE-Component-Server-eris>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=POE-Component-Server-eris>

=back

=head2 Source Code

This module's source code is available by visiting:
L<https://github.com/reyjrar/POE-Component-Server-eris>

=cut
