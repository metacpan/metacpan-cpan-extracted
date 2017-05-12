package SkypeAPI;

use 5.008005;
use strict;
use warnings;

require Exporter;
use Class::Accessor::Fast;
our @ISA = qw(Exporter Class::Accessor::Fast);

our $VERSION = '0.08';


# Preloaded methods go here.
use SkypeAPI::Win;
use Time::HiRes qw( sleep );
use threads::shared;
use Digest::MD5;
use Data::Dumper;
use SkypeAPI::Command;
$| = 1;

__PACKAGE__->mk_accessors(
  qw/api handler_list stop_listen/
);

our $command_lock : shared;
our %command_list : shared;
our @message_list : shared;

sub attach {
    my $self = shift;
    print "[skype]I am attaching\n";    
    
    $self->api(SkypeAPI::Win->new);
    $self->api->init($self->handler_list);
    $self->wait_available;
}

sub is_available {
    my $self = shift;
    return $self->api->is_available();
}

sub wait_available {
    my $self = shift;
    my ($times, $interval) = @_;
    $times ||= 100;
    $interval ||= 0.1;
    for (1..$times) {
        return 1 if $self->api->is_available();
        sleep $interval;
    }
    return 0;
}

sub send_command {
    my $self = shift;
    my $command = shift;
    my $try_times = shift || 10;
    
    {
        lock(%command_list);
        $command_list{$command->id} = $command;
    }
    
    
    my $command_string = sprintf("#%s %s", $command->id, $command->string);
    printf("[send]$command_string\n");
    my $send_ok = 0;
    for (1..$try_times) {
        if ( $self->api->send_message($command_string) ) {
            $send_ok = 1;
            last;
        }
    }
    return undef if not $send_ok;
    
    
    if ($command->blocking) {
        {
            my $start = time;
            WAIT:
            while (1) {
                {
                    lock $SkypeAPI::command_lock;
                    if (defined $command->reply) {
                        last WAIT;
                    }
                }                
                
                if (time - $start > $command->timeout) {
                    print "[skype]wait command timeout\n";
                    last;
                }
                sleep 0.01;
            }           
            
        }
    }
    return $command->reply();
}

sub create_command {
    my $self = shift;
    my $opt = shift;
    my $command;
    share($command);
    $command = &share({});
    bless $command, 'SkypeAPI::Command';
    $command->timeout($opt->{timeout} || 10);
    $command->blocking($opt->{blocking} || 1);
    $command->id($opt->{id} || substr(Digest::MD5::md5_hex(time . int(rand(10000))), 0, 16));
    $command->string($opt->{string} || '');
    return $command;
}

sub register_handler {
    my $self = shift;
    my $ref_sub = shift;
    $self->handler_list({}) if not defined $self->handler_list;
    my $id = keys %{$self->handler_list};
    $self->handler_list->{$id + 1} = $ref_sub;    
}

sub listen {
    my $self = shift;

    $self->stop_listen(0);
    while (!$self->stop_listen) {
        my $message;
        {
            lock @message_list;
            $message = shift @message_list;
        }
        if (not defined $message) {
            sleep 0.01;             
            next;
        }
        for my $id (sort keys %{$self->handler_list}) {
            $self->handler_list->{$id}->($self, $message);
        }
    }
}



1;
__END__

=head1 NAME

SkypeAPI - Skype API simple implementation, only support windows platform now.

=head1 VERSION

0.06

=head1 SYNOPSIS

    use SkypeAPI;
    my $skype = SkypeAPI->new();
    print " skype available=", $skype->attach , "\n";
    my $command = $skype->create_command( { string => "GET USERSTATUS"}  );
    print  $skype->send_command($command) , "\n";
    $command = $skype->create_command( { string => "SEARCH CHATS"}  );
    print $skype->send_command($command) , "\n";

=head1 FUNCTIONS

=head2 SkypeAPI->new( )

Returns a SkypeAPI object. 

    my $skype = SkypeAPI->new();

=head2 SkypeAPI->attach( )

Attach to skype, return 1 if attached ok.

=head2 SkypeAPI->send_command( $command_object, [$try_times] )

Send command to skype, return the reponse of skype

It sometimes failed when sending message to skype, so we have to retry sending message. $try_times default is 10.

=head2 SkypeAPI->create_command( $opt )

Create command. $opt is a hashref. You can defind the command string, timeout in it.

timeout default is 10 seconds.

    my $command = $skype->create_command( { string => "SEARCH CHATS", timeout => 5}  );


=head2 SkypeAPI->register_handler( $ref_callback )

Add listener to the chain of message handler. 

    $skype->register_handler(\&handler);
    $skype->attach();
    sub handler {
        my $skype = shift;
        my $msg = shift;
        my $command = $skype->create_command( { string => "GET USERSTATUS"}  );
        print $skype->send_command($command) , "\n";
    }

=head2 SkypeAPI->listen( )

After you register handlers, call $skype->listen to enter the message loop;

    $skype->listen();

=head2 SkypeAPI->stop_listen( )

Call stop_listen in your handler to exit the message loop

    sub handler {
        my $skype = shift;
        my $msg = shift;
        $skype->stop_listen();
    }



=head1 DESCRIPTION

A Perl simple implementation of the Skype API, working off of the canonical Java and Python implementations.
It is a encapsulation of Windows message communication between Skype and client applications.
 This version of SkypeAPI only implement some commands of SKYPE API, you can implement the others using  SkypAPI->send_command

=head2 EXPORT

None by default.

=head1 ROBOT DEMO

You can find the robot.pl in the lib/../t/robot.pl, run it and your skype will become a xiaoi robot :)

the robot needs the module XiaoI, please install it first, See L<http://code.google.com/p/xiaoi/>


=head1 SEE ALSO

For more command information, See L<https://developer.skype.com/Docs/ApiDoc/src>

The svn source of this project, See L<http://code.google.com/p/skype4perl/>


=head1 AUTHOR

laomoi ( I<laomoi@gmail.com> )

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by laomoi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itinstance, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
