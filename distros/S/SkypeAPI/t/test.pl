#!perl

use strict;

use lib './lib';

use SkypeAPI;
use Data::Dumper;
use SkypeAPI::Command;


my $skype = SkypeAPI->new();

$skype->register_handler(\&handler);

print "wait_available = " . $skype->attach , "\n";

print "i am empty\n";

my $command = $skype->create_command( { string => "GET USERSTATUS"}  );
print "[script]", $skype->send_command($command) , "\n";
$command = $skype->create_command( { string => "SEARCH CHATS"}  );
print "[script]", $skype->send_command($command) , "\n";




sub handler {
    my $self = shift;
    my $msg = shift;
    print ".......test:$msg\n";
    my $command = $self->create_command( { string => "GET USERSTATUS"}  );
print "[script]", $self->send_command($command) , "\n";

}


$skype->listen();
