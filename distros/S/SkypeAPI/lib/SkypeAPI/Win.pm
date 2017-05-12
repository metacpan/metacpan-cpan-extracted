package SkypeAPI::Win;

use 5.008005;
use strict;
use warnings;

require Exporter;
use Class::Accessor::Fast;

our @ISA = qw(Exporter Class::Accessor::Fast);

our $VERSION = '0.08';

require XSLoader;
XSLoader::load('SkypeAPI::Win', $VERSION);

# Preloaded methods go here.
use threads;
use threads::shared;
use Data::Dumper;

__PACKAGE__->mk_accessors(
  qw/thread   is_running/
);


sub init {
    my $self = shift;
    my $handler_list = shift;
    my $thread = new threads(\&run, $self, $handler_list);
    $self->thread($thread);
}

sub run {
    my $self = shift;
    $self->attach( { copy_data => \&handler } );
}

sub handler {
    my $message = shift;
    print "[api]$message\n";
    if (defined $message and $message =~ m{^#(\w+)\s+(.*)}) {
        my ($id, $reply) = ($1, $2);
        if ($SkypeAPI::command_list{$id}) {
            my $command;
            {
                lock %SkypeAPI::command_list;
                $command = delete $SkypeAPI::command_list{$id};
                
            }
            
            {
                lock $SkypeAPI::command_lock;
                
                $command->reply($reply); 
               
            }
            
        }  
    } else {
        lock @SkypeAPI::message_list;
        push @SkypeAPI::message_list, $message;
    }

    #print Dumper(\%SkypeAPI::command_list);
}



sub DESTROY {
    my $self = shift;
    if ($self->thread) {
        $self->quit();
        $self->thread->join;
        $self->thread(undef);
    }
}




1;
__END__
