#!/usr/bin/perl -ws
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'


######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use lib "t";
use Data::Dumper;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval );



use constant list_of_rules_in_progress => 0;
use constant line_number=> 1;
use constant current_line => 2;
use constant handle => 3;
use constant lexical_boneyard => 4;
use constant filename => 5;



#use Profiler;

$Profiler::do_not_instrument_this_sub{main::Parse::Nibbler::DieOnFatalError}=1;
$Profiler::do_not_instrument_this_sub{DieOnFatalError}=1;


use VerilogGrammar;
package Parse::Nibbler;

my $filename = 't/verilog.v';

$filename = shift(@ARGV) if(scalar(@ARGV));


my $start_time = [gettimeofday];


Parse::Nibbler::new($filename);

eval
{
Parse::Nibbler::SourceText();
};


print Parse::Nibbler::dumper();



print $@;

my $end_time = [gettimeofday];
my $delay_time = tv_interval( $start_time, $end_time);


print "delay_time is $delay_time seconds \n";

my $line = $line_number;

print "total number of lines is $line \n";

my $rate = $line / $delay_time;

print "lines per second = $rate \n";


print Dumper \%Parse::Nibbler::timer_information;

print Dumper \%Parse::Nibbler::caller_counter;

print "ok 2\n";
