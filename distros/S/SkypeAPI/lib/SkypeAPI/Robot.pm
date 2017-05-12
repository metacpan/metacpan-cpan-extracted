package SkypeAPI::Robot;

use strict;
use warnings;

use SkypeAPI;
use SkypeAPI::Command;
use XiaoI;
use Data::Dumper;
our $VERSION = '0.04';


sub new {
    my $class = shift;
    my $opt = shift;
    
    my $instance = {opt => $opt};
    bless $instance, $class;
    $instance->{robot_list} = {};
    $instance->{message_list} = {};

    return $instance;
}

sub handler {
    my ($skype, $message) = @_;
    print "[robot]I received message\n";
    if ($message =~ m{^MESSAGE\s+(\d+) STATUS (RECEIVED|READ)}) {
        my $message_id = $1;
        my $status = $2;
        print "[robot]I received message $message_id\n";
        return  1 if $skype->{robot_manager}->{message_list}->{$message_id};
        $skype->{robot_manager}->{message_list}->{$message_id} = 1;
        my $CHATNAME  = $skype->send_command( $skype->create_command( { string => "GET CHATMESSAGE $message_id CHATNAME" } ) );
        $CHATNAME =~ s{.*?(CHATNAME)\s+}{}s;
        print "CHATNAME :$CHATNAME \n";

        if (not exists $skype->{robot_manager}->{robot_list}->{ $CHATNAME }) {
            print "CREAET NEW ROBOT FOR THE CHAT\n";
            my $robot = XiaoI->new;
            $skype->{robot_manager}->{robot_list}->{$CHATNAME} = $robot;
        }
        
        my $body  = $skype->send_command( $skype->create_command( { string => "GET CHATMESSAGE $message_id BODY" } ) );
        $body =~ s{.*?(BODY)\s+}{}s;
        print "body :$body \n";
        
        my $robot = $skype->{robot_manager}->{robot_list}->{$CHATNAME};
        my $text = $robot->get_robot_text($body);
        $skype->send_command( $skype->create_command( { string => "CHATMESSAGE $CHATNAME $text" } ) );
    }        
    return 1;
}



sub run {
    my $self = shift;   
    
    my $skype = SkypeAPI->new();
    $skype->{robot_manager} = $self;
    $skype->register_handler(\&handler);
        
    print "wait_available = " . $skype->attach , "\n";
    $skype->listen();
}


1;
