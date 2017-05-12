#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Term::ReadKey;
use Time::HiRes qw(sleep);
use NETIOM;

my $logging = 0;

GetOptions ("log" => \$logging) or die;

ReadMode('raw'); # Turn off controls keys
END {
    ReadMode('restore'); # Reset tty mode before exiting
}

my @unit;
foreach my $unit ('netiom01', 'netiom02') {
    push @unit, NETIOM->new($unit);
}

system 'clear';

my $unit_index = 0;
my $key_input  = 0;
my $output_key_indicator = ' <-- i or o toggles';
my $input_key_indicator = '';
my $active_key_string = 'output';

my $state_log;

while ( 1 ) {

    # my $key;
    while ( defined ( my $key = ReadKey(-1) ) ) {
        if ( $key eq 'q' or $key eq 'Q') {
            exit 0;
        }
        elsif ( $key =~ m/[0-9a-f]/i ) {
            
            if ( ! $key ) {
                $key = 10;
            }
            elsif ( $key =~ m/[a-f]/i ){
                $key = ord(uc($key))-54;
            }
            
            if ($key_input && $unit[$unit_index]->can('set_input_bit') ) {
                $unit[$unit_index]->set_input_bit($key, $unit[$unit_index]->get_input_bit($key) ? 0 : 1);
            }
            else {
                $unit[$unit_index]->set_output_bit($key, $unit[$unit_index]->get_output_bit($key) ? 0 : 1);
            }
        }
        elsif ( $key =~ m/[l]/i ) {
            $state_log = '';
            foreach ( @unit ) { $_->{logged} = 0 };
        }        
        elsif ( $key =~ m/u/i ) {
            $unit_index = ($unit_index) ? 0 : 1;
        }
        elsif ( $key =~ m/[io]/i && $unit[$unit_index]->can('set_input_bit')) {
            $key_input  = ($key_input) ? 0 : 1;
            
            my $t_i = $input_key_indicator;
            $input_key_indicator = $output_key_indicator;
            $output_key_indicator = $t_i;
            
            if ($key_input) {
                $active_key_string = 'input';
            }
            else {
                $active_key_string = 'output';
            }
        }
    }
    
    my $out;
    
    if ( $unit[0]->{mock} ) {
        $out .= "Mocking: dbfile = " . $unit[0]->{dbfile} . ", " . ($ENV{NET_IOM_DB_PATH} ? "NET_IOM_DB_PATH = $ENV{NET_IOM_DB_PATH}" : '') . "\n\n";        
    }
    
    foreach my $unit (@unit) {
        
        my $prev_input_state = $unit->get_unit_name() . '    ' . (join '  ', $unit->get_input());
        $unit->update_state();
        my $curr_input_state = $unit->get_unit_name() . '    ' . (join '  ', $unit->get_input());
        
        if ( ! $unit->{logged} ) {
            
            $state_log = $prev_input_state . ' ' . localtime(time())  . "\n" . $state_log;
            $unit->{logged} = 1;
        }
        
        if ( $prev_input_state ne $curr_input_state ) {
            $state_log = $curr_input_state . ' ' . localtime(time())  . "\n" . $state_log;
        }
        
        if ( $unit eq $unit[$unit_index] ) {
            $out .= $unit[$unit_index]->get_unit_name() . " <-- Active unit, press u to toggle.\n";
            $out .= "Press   1  2  3  4  5  6  7  8  9  0  A  B  C  D  E  F to toggle $active_key_string.\n";
            $out .= "       01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16\n";
        }
        else {
            $out .= $unit->get_unit_name ."\n\n";
            $out .= "       01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16\n";
        }
        $out .= "Input   " . (join "  ", $unit->get_input()) . (($unit eq $unit[$unit_index]) && $unit[$unit_index]->can('set_input_bit') ? $input_key_indicator : '') . "\n";
        $out .= "Output  " . (join "  ", $unit->get_output()). (($unit eq $unit[$unit_index]) ? $output_key_indicator : '') . "\n\n";
    }
    $out .= "Press q to quit.\n";
    system 'clear';
    print $out;
    print "\nInput log: 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 time\n$state_log" if $logging;
    sleep .15;
}
