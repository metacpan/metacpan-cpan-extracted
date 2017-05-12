# $Id: DefaultCommands.pm 230 2004-04-25 15:49:02Z sungo $

=pod

=head1 NAME

POE::Component::ControlPort::DefaultCommands - Set of default commands available to the control port

=cut

package POE::Component::ControlPort::DefaultCommands;

use warnings;
use strict;

use Getopt::Long;
use POE::Component::ControlPort::Command;

our $VERSION = '1.'.sprintf "%04d", (qw($Rev: 230 $))[1];

our @COMMANDS = ( #{{{
    {
        help_text => 'Display general port status',
        usage => 'status',
        topic => 'general',
        name => 'status',
        command => \&status,
    },

    {
        help_text => 'Display help about available commands',
        usage => 'help [ topic || command ]',
        topic => 'general',
        name => 'help',
        command => \&help,
    },

); #}}}

our $START_TIME = time;


sub status {
    my %args = @_;
    
    my $time = localtime($START_TIME);

    return qq|
Control port online since $time.
Application $args{oob}{appname} on host $args{oob}{hostname}
Client is $args{oob}{client_addr} port $args{oob}{client_port} 
|;

}

sub help {
    my %args = @_;

    my @args = @{$args{args}};

    if(scalar @args > 1) {
        return "ERROR: Can only provide help on one thing at a time. ";
    }

    my $help = shift @args;

    my $txt;
    if(defined $help) {  
        if(defined $POE::Component::ControlPort::Command::TOPICS{$help}) {
            $txt = "Commands available in topic '$help':\n";
            
            foreach my $cmd (sort @{ $POE::Component::ControlPort::Command::TOPICS{$help} }) {
                $txt .= "\t* $cmd\n";
            }
            
        } elsif (defined $POE::Component::ControlPort::Command::REGISTERED_COMMANDS{$help}) {
            my $data = $POE::Component::ControlPort::Command::REGISTERED_COMMANDS{$help};
            
            $txt = "Help for command '$help'\n";
            $txt .= "Usage: ".$data->{usage}."\n";
            $txt .= $data->{help_text}."\n";


        } else {
            $txt = "'$help' is an unknown command or help topic\n";
        }
    } else {
        $txt = "The following help topics are available:\n";
        
        foreach my $topic ( sort keys %POE::Component::ControlPort::Command::TOPICS ) {
            $txt .= "\t * $topic\n";
        }
    }

    return $txt;
}


sub _add_poe_debug_commands {
    eval "use POE::Component::DebugShell; use POE::API::Peek";
    unless($@) {
        if($POE::Component::DebugShell::VERSION >= '1.017') {
            my $cmds = POE::Component::DebugShell->_raw_commands();

            foreach my $cmd_name (keys %$cmds) {
                my $cmd_data = $cmds->{$cmd_name};
                
                next if $cmd_name eq 'status';
                next if $cmd_name eq 'help';
                next if $cmd_name eq 'exit';
                next if $cmd_name eq 'reload';
                
                my $api = POE::API::Peek->new(); 
                POE::Component::ControlPort::Command->register(
                    name => $cmd_name,
                    usage => $cmd_name,
                    help_text => $cmd_data->{help},
                    topic => 'poe_debug',
                    command => sub { 
                        my %args = @_;
                        return $cmd_data->{cmd}->(
                            api => $api,
                            args => $args{args}
                        );
                    },
                );
            }
        }
    }
}


1;
__END__

=pod 

=head1 AUTHOR

Matt Cashner (cpan@eekeek.org)

=head1 REVISION

$Revision: 1.2 $

=head1 DATE

$Date: 2004-04-25 11:49:02 -0400 (Sun, 25 Apr 2004) $

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

