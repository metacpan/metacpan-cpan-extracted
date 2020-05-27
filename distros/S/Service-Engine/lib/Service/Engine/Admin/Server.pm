package Service::Engine::Admin::Server;

use 5.010;
use strict;
use warnings;
use Carp;
use Service::Engine;
use Service::Engine::Admin;
use base qw(Net::Server::Multiplex);
use Data::Dumper;

# IO::Multiplex callback hook
sub mux_connection {
    
    my $self = shift;
    my $mux  = shift;
    my $fh   = shift;
    my $peer = $self->{peeraddr};
    
    # pull in some Service::Engine globals
    $self->{'Config'} = $Service::Engine::Config;
    $self->{'Log'} = $Service::Engine::Log;
    $self->{'Admin'} = $Service::Engine::Admin;
    $self->{'EngineName'} = $Service::Engine::EngineName;
        
    my $password = $self->{'Config'}->get_config('admin')->{'password'};
    my $timeout = $self->{'Config'}->get_config('admin')->{'timeout'};
    my $command_list = $self->{'Admin'}->command_list();
    
    # Net::Server stores a connection counter in the {requests} field.
    $self->{id} = $self->{net_server}->{server}->{requests};
    # Keep some values that I might need while the {server}
    # property hash still contains the current client info
    # and stash them in my own object hash.
    $self->{peerport} = $self->{net_server}->{server}->{peerport};
    
    $self->{'Log'}->log({msg=>"Client [$peer] (id $self->{id}) just connected...",level=>3});
    
    # Notify everyone that the client arrived
    # $self->broadcast($mux,"JOIN: (#$self->{id}) from $peer\r\n");

    # Try out the timeout feature of IO::Multiplex
    $mux->set_timeout($fh, undef);
    $mux->set_timeout($fh, $timeout);
    
    # $fh->write(`clear`);
    
    if ($password) {
        $fh->write("password: ");
        $self->{'password_prompted'} = 1;
    } else {
        $fh->write("Welcome to \033[1m" . $self->{'EngineName'} . "\033[0m!\n");
        $fh->write("Enter '?' at any prompt for help.\n");
        $fh->write("Select an option: \n$command_list\n> ");
    }
    
}

sub mux_input {
    
    my $self = shift;
    my $mux  = shift;
    my $fh   = shift;
    my $in_ref = shift;  # Scalar reference to the input
    my $peer = $self->{peeraddr};
    my $id   = $self->{id};
    
    my $command_list = $self->{'Admin'}->command_list();
    
    my $password = $self->{'Config'}->get_config('admin')->{'password'};
     
    # Process each line in the input
    while ($$in_ref =~ s/^(.*?)\r?\n//) {
    
        if (!$1) {
            $fh->write("> ");
            next;
        }
        
        if ($self->{'password_prompted'}) {
            
            if ($password eq $1) {
                # $fh->write(`clear`);
                $fh->write("Welcome to \033[1m" . $self->{'EngineName'} . "\033[0m!\n");
                $fh->write("Select an option: \n$command_list\n> ");
                $self->{'password_prompted'} = 0;
            } else {
                $mux->close($fh);
            }

        } else {
                    
            $self->{'Log'}->log({msg=>"Processing $1",level=>3});
            $self->_process_input($1,$mux,$fh);
            
        }

    }

}


sub _process_input {

    my $self = shift;
    my $input = shift;
    my $mux  = shift;
    my $fh   = shift;
        
    # $fh->write(`clear`);
     
    my $command_list = $self->{'Admin'}->command_list();
    
    if ($input eq '?') {
        
        my $help = qq[
Commands
quit,close - close the program

Options
You can type the first letter of any option to select it.
Available options are:
$command_list
> ];    
        $fh->write($help);
    } elsif ($input eq 'close' || $input eq 'quit' || $input eq '!q') {
        $mux->close($fh);
    } else {
        my $module = $self->{'Admin'}->$input();
        if (ref($module) eq 'HASH') { # this is a command
            my $package = $module->{'module'};
            my $method = $module->{'method'};
            $package->$method($fh);
            $fh->write("\n> ");
        } else {
            if ($module) { # this is a method
                $module->run($fh);       
                $fh->write("\n> ");
            }
        }
        
    }
    
}

# This callback will happen when the mux->set_timeout expires.
sub mux_timeout {
    my $self = shift;
    my $mux  = shift;
    my $fh   = shift;
    $fh->write("If you don't want to talk then you should leave. *BYE*\r\n");
    close(STDOUT);
    $mux->set_timeout($fh, undef);
    $mux->set_timeout($fh, 40);
}
 
# Routine to send a message to all clients in a mux.
sub broadcast {
    my $self = shift;
    my $mux  = shift;
    my $msg  = shift;
    foreach my $fh ($mux->handles) {
        # NOTE: All the client unique objects can be found at
        # $mux->{_fhs}->{$fh}->{object}
        # In this example, the {id} would be
        #   $mux->{_fhs}->{$fh}->{object}->{id}
        print $fh $msg;
    }
}

1;