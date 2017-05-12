# $Id: ControlPort.pm 266 2004-05-10 02:59:17Z sungo $
package POE::Component::ControlPort;

=pod

=head1 NAME

POE::Component::ControlPort - network control port for POE applications

=head1 SYNOPSIS

    use POE;
    use Getopt::Long;
    
    use POE::Component::ControlPort;
    use POE::Component::ControlPort::Command;

    my @commands = (
       {
           help_text    => 'My command',
           usage        => 'my_command [ arg1, arg2 ]',
           topic        => 'custom',
           name         => 'my_command',
           command      => sub {
              my %input = @_;
              
              local @ARGV = @{ $input{args} };
              GetOptions( ... ); 
           },
       } 
    );


    POE::Component::ControlPort->create(
        local_address   => '127.0.0.1',
        local_port      => '31337',
    
    # optional...
        hostname        => 'pie.pants.org',
        appname         => 'my perl app',

        commands        => \@commands,

        poe_debug       => 1,
    );

    # other poe sessions or whatever ...

    POE::Kernel->run();
    

=head1 DESCRIPTION

When building network applications, it is often helpful to have a
network accessible control and diagnostic interface. This module
provides such an interface for POE applications. By default, it provides
a fairly limited set of commands but is easily extended to provide
whatever command set you require. In addition, if
C<POE::Component::DebugShell> version 1.018 or above is installed, a set
of POE debug commands will be loaded.

=head1 GETTING STARTED

The utility of a network accessible controlport is limited only by the commands
you allow access to. A controlport with only a status command isn't very useful.
Defining commands is easy.

=head2 DEFINING COMMANDS

    my @commands = (
       {
           help_text    => 'My command',
           usage        => 'my_command [ arg1, arg2 ]',
           topic        => 'custom',
           name         => 'my_command',
           command      => sub {
              my %input = @_;
              
              local @ARGV = @{ $input{args} };
              GetOptions( ... ); 
           },
       } 
    );


A command is defined by a hash of metadata and a subroutine reference. The
metadata helps to group commands into functional units as well as display help
and usage information for the confused user.  The meat of a command, obviously,
is the subroutine reference which makes up the 'command' part of the metadata.

The subroutine reference is executed every time a user issues the command name
that is assigned for it.  Any text returned from the subroutine will be printed
out to the user in the control port. The subroutine's arguments are a hash of 
data about the command invocation.

=over 4

=item * args

This hash element is a list of arguments the user passed in to the command. It
is suggested that you assign this list to C< @ARGV > and use L<Getopt::Long> and
friends to parse the arguments.

=item * oob

This hash element contains a hash of out of band data about the transaction. It
is populated with hostname, appname, client_addr, and client_port.

=back

=head2 LAUNCHING THE PORT 

    POE::Component::ControlPort->create(
        local_address => '127.0.0.1',
        local_port => '31337',
    
    # optional...
        hostname => 'pie.pants.org',
        appname => 'my perl app',

        commands => \@commands,

        poe_debug => 1,
    )

The C<create()> method in the C<POE::Component::ControlPort> namespace is used
to create and launch the control port.  There are several parameters available
to C<create()>.

=over 4

=item * local_address

Mandatory. The address on which the control port should listen.

=item * local_port

Mandatory. The port on which the control port should listen.

=item * commands

Optional (but boring if not provided). An array of command hashes. See
L<DEFINING COMMANDS> above.

=item * hostname

Optional. Mostly for display in the control port itself. Will probably be used
for other things in the future.

=item * appname

Optional. The name of this application, defaulting to C<basename($0)>. This is 
used by TCPwrappers to determine if the connecting user is allowed to connect.
This is also used as the master alias for the control port session.

=item * poe_debug

Optional. Defaults to 0. If true, attempts to load commands from
L<POE::Component::DebugShell> if said module is available and of the appropriate
version.

=back

=head2 SHUTTING DOWN

The control port responds to a C<shutdown> event to the appname given during 
control port creation. This event will cause the immediate shutdown of all
connections and the termination of the listener.

=cut

# General setup {{{
use warnings;
use strict;

use Socket;
use POE qw(
    Wheel::SocketFactory
    Wheel::ReadWrite
);

use Sys::Hostname;
use File::Basename;

use Authen::Libwrap qw(hosts_ctl STRING_UNKNOWN);

use Params::Validate qw(validate);

use Carp;

use POE::Component::ControlPort::DefaultCommands;
use POE::Component::ControlPort::Command;

sub DEBUG () { 0 }

our $VERSION = '1.'.sprintf "%04d", (qw($Rev: 266 $))[1];

# }}}


sub create { #{{{
    my $class = shift;


# Validate arguments  {{{ 
    warn "Validating arguments" if DEBUG;

    my %args = validate( @_, {
        local_address => 1,
        local_port => 1,
        hostname => { optional => 1, default => hostname() },
        appname => { optional => 1, default => basename($0) },
        commands => { optional => 1, type => &Params::Validate::ARRAYREF },
        poe_debug => { optional => 1, default => 1 },
    } );
# }}}


# Register default commands #{{{
    warn "Registering default commands" if DEBUG;
    
    foreach my $cmd ( @POE::Component::ControlPort::DefaultCommands::COMMANDS ) {
        POE::Component::ControlPort::Command->register(%$cmd);
    }
# }}}

    
# if available, register poe debug commands #{{{
    if($args{poe_debug}) {
        POE::Component::ControlPort::DefaultCommands->_add_poe_debug_commands();
    }
# }}}


# Register user commands, if requested #{{{
    warn "Registering user commands" if DEBUG;

    if($args{commands}) {
        foreach my $cmd (@{ $args{commands} }) {
            if(ref $cmd eq 'HASH') {
                POE::Component::ControlPort::Command->register(%$cmd);
            } else {
                croak "Parameter 'commands' contains element which is not a hash ref";
            }
        }
    }
# }}}
    

# Set the whole ball rolling #{{{
    warn "Creating session" if DEBUG;
    
    my $self = POE::Session->create(
                inline_states => {
                    _start => \&start,
                    _stop => \&stop,

                    socket_connect => \&socket_connect,
                    socket_error => \&socket_error,

                    client_connect => \&client_connect,
                    client_error => \&client_error,
                    client_input => \&client_input,

                    'shutdown' => \&shutdown,

                },
                heap => {
                    address => $args{local_address},
                    port => $args{local_port},
                    hostname => $args{hostname},
                    appname => $args{appname},
                    prompt => $args{appname}." [".$args{hostname}."]: ",
                }
               );
    
        
    return $self;
# }}}
    
} #}}}

=begin devel

=head2 start

Get things rolling. Starts up a POE::Wheel::SocketFactory using the user
provided config info.

=cut

sub start { #{{{

    warn "Starting socketfactory" if DEBUG;

    $_[KERNEL]->alias_set($_[HEAP]->{appname});

    $_[HEAP]->{wheels}->{socketfactory} = 
        POE::Wheel::SocketFactory->new(
            BindAddress     => $_[HEAP]->{address},
            BindPort        => $_[HEAP]->{port},

            SuccessEvent    => 'socket_connect',
            FailureEvent    => 'socket_error',

            Reuse           => 'on',
        );

} #}}}


=head2 stop 

Mostly just a placeholder. 

=cut

sub stop { #{{{
    warn "Socketfactory stopping" if DEBUG;
} #}}}



=head2 shutdown

Forcibly shutdown the control port

=cut

sub shutdown { #{{{

    delete $_[HEAP]->{wheels}->{socketfactory};

    foreach my $wid (keys %{ $_[HEAP]->{wheels} }) {
        my $data = $_[HEAP]->{wheels}->{$wid};
        my $wheel = $data->{wheel};
        delete $_[HEAP]->{wheels}->{$wid};
        $wheel->shutdown_input();
        $wheel->shutdown_output();
    }
    $_[KERNEL]->alias_remove( $_[HEAP]->{appname} );
} #}}}




=head2 socket_connect

Well lookie here. Somebody wants to talk to us. Check their credentials
with Authen::Libwrap and if they're valid, set up the rest of the
connection with POE::Wheel::ReadWrite. Print out the welcome banner.

=cut


sub socket_connect { #{{{

    my $handle = $_[ARG0];
    my $client_addr = inet_ntoa($_[ARG1]);
    my $client_port = $_[ARG2];    

    if(hosts_ctl($_[HEAP]->{appname}, $handle)) {
        warn "Got socket connection from $client_addr : $client_port" if DEBUG;
    
        my $wheel = POE::Wheel::ReadWrite->new(
                        Handle => $handle,
    
                        InputEvent => 'client_input',
                        ErrorEvent => 'client_error',
                    );
    
        $_[HEAP]->{wheels}->{ $wheel->ID } = {
            wheel       => $wheel,
            client_addr => $client_addr,
            client_port => $client_port,
        };

        my $time = localtime(time);
        $wheel->put("Control port online: $time");

        $wheel->put($_[HEAP]->{prompt});

    } else {
        warn"Control port connection from $client_addr : $client_port disallowed by Authen::LibWrap" if DEBUG;;
    }
} #}}}



=head2 socket_error

Some problem happened while setting up the listener. carp about it and
try again in 2 seconds.

=cut

sub socket_error { #{{{
    my ($errop, $errnum, $errstr) = @_[ARG0..ARG2];

    carp "ERROR: $errop : $errnum - $errstr. Could not create listener. Attempting to restart in 2 seconds"; 

    delete $_[HEAP]->{wheels};
    $_[KERNEL]->delay('_start' => 2);

} #}}}


=head2 client_error

Error from a connected client. Probably just them logging out. Delete
their wheel and shut down the connection.

=cut

sub client_error { #{{{
    my $wid = $_[ARG3];
    my ($errop, $errnum, $errstr) = @_[ARG0 .. ARG2];
    
    my $data = $_[HEAP]->{wheels}->{$wid};
    
    if( ($errop eq 'read') && ($errnum eq '0') ) {
        warn "Client disconnection by $data->{client_addr} : $data->{client_port}" if DEBUG; 
    } else {
        warn "Client error from $data->{client_addr} : $data->{client_port}" if DEBUG; 
    }
    
    delete $_[HEAP]->{wheels}->{$wid};
} #}}}


=head2 client_input

The user said something to us. If they said something useful,
run the command they asked for. Then give them the output from the
command.

=cut

sub client_input { #{{{
    my $wid = $_[ARG1];
    my $input = $_[ARG0];

    my $data = $_[HEAP]->{wheels}->{$wid};
    my $wheel = $data->{wheel};

    my @args = split(/\s+/, $input);
    my $cmd = shift @args;
    my $txt;

    if($cmd) { 
        my $oob = { hostname => $_[HEAP]->{hostname},
                    appname => $_[HEAP]->{appname},
                    client_addr => $data->{client_addr},
                    client_port => $data->{client_port},
                  };
        
        warn "Got input from $data->{client_addr} : $data->{client_port}" if DEBUG; 
        my $txt = POE::Component::ControlPort::Command->run( 
                    command => $cmd, 
                    oob_data => $oob,
                    arguments => \@args,
                );

        if(defined $txt) {
            warn "Sending output to $data->{client_addr} : $data->{client_port}" if DEBUG; 
    
            $wheel->put($txt);
        }
    }
    $wheel->put("Done.");
    
} # }}}


1;

__END__

=pod

=end devel

=head1 REQUIREMENTS

The following perl modules are required for this module to work properly.

=over 4

=item * Authen::Libwrap

=item * Carp

=item * File::Basename

=item * POE

=item * Params::Validate

=item * Sys::Hostname

=back

=head1 AUTHOR

Matt Cashner (sungo@pobox.com)

=head1 REVISION

$Rev: 266 $

=head1 DATE

$Date: 2004-05-09 22:59:17 -0400 (Sun, 09 May 2004) $

=head1 LICENSE

Copyright (c) 2004, Matt Cashner

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

