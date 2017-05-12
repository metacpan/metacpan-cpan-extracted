package POE::Component::DebugShell;

use warnings;
use strict;

use 5.006;

use Carp;

use POE;
use POE::Wheel::ReadLine;
use POE::API::Peek;

our $VERSION = '1.412';
our $RUNNING = 0;
our %COMMANDS;
our $SPAWN_TIME;

sub spawn { #{{{
    my $class = shift;

    # Singleton check {{{
    if($RUNNING) {
        carp "A ".__PACKAGE__." session is already running. Will not start a second.";
        return undef;
    } else {
        $RUNNING = 1;
    }
    # }}}

    my $api = POE::API::Peek->new() or croak "Unable to create POE::API::Peek object";


    # Session creation {{{
    my $sess = POE::Session->create(
        inline_states => {
            _start      => \&_start,
            _stop       => \&_stop,

            term_input  => \&term_input,
        },
        heap => {
            api         => $api,
        },
    );
    # }}}

    if($sess) {
        $SPAWN_TIME = time();
        return $sess;
    } else {
        return undef;
    }
} #}}}



sub _start { #{{{
    $_[KERNEL]->alias_set(__PACKAGE__." controller");

    $_[HEAP]->{rl} = POE::Wheel::ReadLine->new( InputEvent => 'term_input' );
    $_[HEAP]->{prompt} = 'debug> ';

    tie *STDOUT, "POE::Component::DebugShell::Output", 'stdout', \&_output;
    tie *STDERR, "POE::Component::DebugShell::Output", 'stderr', \&_output;

    $_[HEAP]->{rl}->clear();
    _output("Welcome to POE Debug Shell v$VERSION");

    $_[HEAP]->{rl}->get($_[HEAP]->{prompt});

} #}}}



sub _stop { #{{{
    # Shut things down
    $_[HEAP]->{vt} && $_[HEAP]->{vt}->delete_window($_[HEAP]->{main_window});
} #}}}



sub term_input { #{{{
    my ($input, $exception) = @_[ARG0, ARG1];

    unless (defined $input) {
        croak("Received exception from UI: $exception");
    }

    $_[HEAP]->{rl}->addhistory($input);

    if($input =~ /^help (.*?)$/) {
        my $cmd = $1;
        if($COMMANDS{$cmd}) {
            if($COMMANDS{$cmd}{help}) {
                _output("Help for $cmd:");
                _output($COMMANDS{$cmd}{help});
            } else {
                _output("Error: '$cmd' has no help.");
            }
        } else {
            _output("Error: '$cmd' is not a known command");
        }
    } elsif ( ($input eq 'help') or ($input eq '?') ) {
        my $text;
        _output(' ');
        _output("General help for POE::Component::DebugShell v$VERSION");
        _output("The following commands are available:");
        foreach my $cmd (sort keys %COMMANDS) {
            no warnings;
            my $short_help = $COMMANDS{$cmd}{short_help} || '[ No short help provided ]';
            _output("\t* $cmd - $short_help");
        }
        _output(' ');

    } else  {
        my ($cmd, @args);
        if($input =~ /^(.+?)\s+(.*)$/) {
            $cmd = $1;
            my $args = $2;
            @args = split('\s+',$args) if $args;
        } else {
            $cmd = $input;
        }

        if($COMMANDS{$cmd}) {
            my $txt = eval { $COMMANDS{$cmd}{cmd}->( api => $_[HEAP]->{api}, args => \@args); };
            if($@) {
                _output("Error running $cmd: $@");
            } else {
                my @lines = split(/\n/, $txt);
                _output($_) for @lines;
            }
        } else {
            _output("Error: '$cmd' is not a known command");
        }
    }

    $_[HEAP]->{rl}->get($_[HEAP]->{prompt});

} #}}}



sub _output { #{{{
    my $msg = shift || ' ';
    my $heap = $poe_kernel->alias_resolve(__PACKAGE__." controller")->get_heap(); 
    $heap->{rl}->put($msg);
} #}}}

sub _raw_commands { #{{{
    return \%COMMANDS;
} #}}}

#   ____                                          _     
#  / ___|___  _ __ ___  _ __ ___   __ _ _ __   __| |___ 
# | |   / _ \| '_ ` _ \| '_ ` _ \ / _` | '_ \ / _` / __|
# | |__| (_) | | | | | | | | | | | (_| | | | | (_| \__ \
#  \____\___/|_| |_| |_|_| |_| |_|\__,_|_| |_|\__,_|___/
#                                                       
# {{{

%COMMANDS = ( #{{{

    'reload' => {
        help => "Reload the shell to catch updates.",
        short_help => "Reload the shell to catch updates.",
        cmd => \&cmd_reload,
    },

    show_sessions => {
        help => 'Show a list of all sessions in the system. The output format is in the form of loggable session ids.',
        short_help => 'Show a list of all sessions',
        cmd => \&cmd_show_sessions,
    },

    'list_aliases' => {
        help => 'List aliases for a given session id. Provide one session id as a parameter.',
        short_help => 'List aliases for a given session id.',
        cmd => \&cmd_list_aliases,
    },

    'session_stats' => {
        help => 'Display various statistics for a given session id. Provide one session id as a parameter.',
        short_help => 'Display various statistics for a given session id.',
        cmd => \&cmd_session_stats,
    },

    'queue_dump' => {
        help => 'Dump the contents of the event queue.',
        short_help => 'Dump the contents of the event queue.',
        cmd => \&cmd_queue_dump,
    },

    'status' => {
        help => 'General shell status.',
        short_help => 'General shell status.',
        cmd => \&cmd_status,
    },
); #}}}

###############

sub cmd_reload { #{{{
    my $ret;
    $ret .= "Reloading....\n";
    eval q|
        no warnings qw(redefine);
        $SIG{__WARN__} = sub { };

        foreach my $key (keys %INC) {
            if($key =~ m#POE/Component/DebugShell#) {
                delete $INC{$key};
            } elsif ($key =~ m#POE/API/Peek#) {
                delete $INC{$key};
            }
        }
        require POE::Component::DebugShell;
    |;
    $ret .= "Error: $@\n" if $@;

    return $ret;
} #}}}

sub cmd_show_sessions { #{{{
    my %args = @_;
    my $api = $args{api};

    my $ret;
    $ret .= "Session List:\n";
    my @sessions = $api->session_list;
    foreach my $sess (@sessions) {
        my $id = $sess->ID. " [ ".$api->session_id_loggable($sess)." ]";
        $ret .= "\t* $id\n";
    }

    return $ret;
} #}}}

sub cmd_list_aliases { #{{{
    my %args = @_;
    my $user_args = $args{args};
    my $api = $args{api};

    my $ret;

    if(my $id = shift @$user_args) {
        if(my $sess = $api->resolve_session_to_ref($id)) {
            my @aliases = $api->session_alias_list($sess);
            if(@aliases) {
                $ret .= "Alias list for session $id\n";
                foreach my $alias (sort @aliases) {
                    $ret .= "\t* $alias\n";
                }
            } else {
                $ret .= "No aliases found for session $id\n";
            }
        } else {
            $ret .= "** Error: ID $id does not resolve to a session. Sorry.\n";
        }

    } else {
        $ret .= "** Error: Please provide a session id\n";
    }
    return $ret;
}

# }}}

sub cmd_session_stats { #{{{
    my %args = @_;
    my $user_args = $args{args};
    my $api = $args{api};

    my $ret;

    if(my $id = shift @$user_args) {
        if(my $sess = $api->resolve_session_to_ref($id)) {
            my $to = $api->event_count_to($sess);
            my $from = $api->event_count_from($sess);
            $ret .= "Statistics for Session $id\n";
            $ret .= "\tEvents coming from: $from\n";
            $ret .= "\tEvents going to: $to\n";

        } else {
            $ret .= "** Error: ID $id does not resolve to a session. Sorry.\n";
        }


    } else {
        $ret .= "** Error: Please provide a session id\n";
    }

    return $ret;
} #}}}

sub cmd_queue_dump { #{{{
    my %args = @_;
    my $api = $args{api};
    my $verbose;

    my $ret;

    if($args{args} && defined $args{args}) {
        if(ref $args{args} eq 'ARRAY') {
            if(@{$args{args}}[0] eq '-v') {
                $verbose = 1;
            }
        }
    }

    my @queue = $api->event_queue_dump();

    $ret .= "Event Queue:\n";

    foreach my $item (@queue) {
        $ret .= "\t* ID: ". $item->{ID}." - Index: ".$item->{index}."\n";
        $ret .= "\t\tPriority: ".$item->{priority}."\n";
        $ret .= "\t\tEvent: ".$item->{event}."\n";

        if($verbose) {
            $ret .= "\t\tSource: ".
                    $api->session_id_loggable($item->{source}).
                    "\n";
            $ret .= "\t\tDestination: ".
                    $api->session_id_loggable($item->{destination}).
                    "\n";
            $ret .= "\t\tType: ".$item->{type}."\n";
            $ret .= "\n";
        }
    }
    return $ret;
} #}}}

sub cmd_status { #{{{
    my %args = @_;
    my $api = $args{api};
    my $sess_count = $api->session_count;
    my $ret = "\n";
    $ret .= "This is ".__PACKAGE__." v".$VERSION."\n";
    $ret .= "running inside $0."."\n";
    $ret .= "This console was spawned at ".localtime($SPAWN_TIME).".\n";
    $ret .= "There are $sess_count known sessions (including the kernel).\n";
    $ret .= "\n";
    return $ret;
} # }}}

# }}}

1;

package POE::Component::DebugShell::Output;

use strict;
#use warnings FATAL => "all";

sub PRINT { 
    my $self = shift;

    my $txt = join('',@_);
    $txt =~ s/\r?\n$//;
    $self->{print}->($self->{type}."> $txt");
}

sub TIEHANDLE {
    my $class = shift;
    bless({
        type => shift,
        print => shift,
    }, $class);
}

1;
__END__

=pod

=head1 NAME

POE::Component::DebugShell - Component to allow interactive peeking into a 
running POE application

=head1 SYNOPSIS

    use POE::Component::DebugShell;

    POE::Component::DebugShell->spawn();

=head1 DESCRIPTION

This component allows for interactive peeking into a running POE
application.

C<spawn()> creates a ReadLine enabled shell equipped with various debug
commands. The following commands are available.

=head1 COMMANDS

=head2 show_sessions

 debug> show_sessions
    * 3 [ session 3 (POE::Component::DebugShell controller) ]
    * 2 [ session 2 (PIE, PIE2) ]

Show a list of all sessions in the system. The output format is in the
form of loggable session ids.

=head2 session_stats

 debug> session_stats 2
    Statistics for Session 2
        Events coming from: 1
        Events going to: 1

Display various statistics for a given session. Provide one session id
as a parameter.

=head2 list_aliases

 debug> list_aliases 2
    Alias list for session 2
        * PIE
        * PIE2

List aliases for a given session id. Provide one session id as a
parameter.

=head2 queue_dump

 debug> queue_dump
    Event Queue:
        * ID: 738 - Index: 0
            Priority: 1078459009.06715
            Event: _sigchld_poll
        * ID: 704 - Index: 1
            Priority: 1078459012.42691
            Event: ping

Dump the contents of the event queue. Add a C<-v> parameter to get
verbose output.

=head2 help

 debug> help
    The following commands are available:
        ...

Display help about available commands.

=head2 status

 debug> status
    This is POE::Component::DebugShell v1.14
    running inside examples/foo.perl.
    This console spawned at Thu Mar 4 22:51:51 2004.
    There are 3 known sessions (including the kernel).

General shell status.

=head2 reload

 debug> reload
 Reloading...

Reload the shell

=head2 exit

 debug> exit
 Exiting...

Exit the shell

=head1 DEVELOPERS

For you wacky developers, I've provided access to the raw command data
via the C<_raw_commands> method. The underbar at the beginning should 
let you know that this is an experimental interface for developers only. 

C<_raw_commands> returns a hash reference. The keys of this hash are the
command names. The values are a hash of data about the command. This
hash contains the following data:

=over 4

=item * short_help

Short help text

=item * help

Long help text

=item * cmd

Code reference for the command. This command requires that a hash be
passed to it containing an C<api> parameter, which is a 
C<POE::API::Peek> object, and an C<args> parameter, which is an array
reference of arguments (think C<@ARGV>).

=back

=head1 AUTHOR

Matt Cashner (sungo@pobox.com)

=head1 LICENSE

Copyright (c) 2003-2004, Matt Cashner

Permission is hereby granted, free of charge, to any person obtaining 
a copy of this software and associated documentation files (the 
"Software"), to deal in the Software without restriction, including 
without limitation the rights to use, copy, modify, merge, publish, 
distribute, sublicense, and/or sell copies of the Software, and to 
permit persons to whom the Software is furnished to do so, subject 
to the following conditions:

The above copyright notice and this permission notice shall be included 
in all copies or substantial portions of the Software.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

# sungo // vim: ts=4 sw=4 expandtab
