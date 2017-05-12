#!/usr/bin/perl -w

use strict;
use lib "..";
use OpenPlugin();

my $CONFIG_FILE = '/usr/local/etc/OpenPlugin.conf';

my $OP = OpenPlugin->new( config => { src => $CONFIG_FILE } );

eval { $OP->exception->throw("This is a test exception\n"); };

if( $@ ) {
    print "Error: $@";
}

print "\nOpenPlugin Stack Trace:\n";
my @errors = $OP->exception->get_stack;
foreach my $e ( @errors ) {
   print "Error: ", $e->creation_location, "\n";
}

print "\nStack Trace using Devel::Stacktrace:\n";
print $@->state->{trace}->as_string;
