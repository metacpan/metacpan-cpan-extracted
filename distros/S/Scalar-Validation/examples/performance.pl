# Perl
#
# Performance Tests of Validation
#
# Sun Jul  6 10:19:58 2014

$| = 1;

use strict;
use warnings;

use Scalar::Validation qw (:all);

use Time::HiRes qw(time);

declare_rule (
    Any => -where   => sub { 1; },
    -message => sub { "No problem!!"}
    );

# my $max_loops = 1000000;
my $max_loops = 100000;
# my $max_loops = 10000;
# my $max_loops = 1000;

my $run = 0;

# --- content, called by both loops ---
my $sub_content;                                                              
# my $sub_content = sub { my $v = shift; return ++$v; };                        
# my $sub_content = sub { my $v = shift; my @arr = map { $_ * $v } (0..20); };  
# my $sub_content = sub { my @arr = map { $_ } (0..shift); }; # max 10000 loops 

# --- first get time needed without validation ---

my $max_empty_loops_per_second = 0;
while ($run < 3) {
    my $loops = 1000;

    my $rules_ref = [Any => Any => 0];
    
    while ($loops <= $max_loops ) {
	my $start_time = time;
	
	foreach my $i (1..$loops) {
	    my $variable = -1 + $i;
	    $sub_content->($variable) if $sub_content;
	}
	my $duration = time - $start_time;
	my $loops_per_second = $loops / $duration;
	$max_empty_loops_per_second = $loops_per_second if $max_empty_loops_per_second < $loops_per_second;
	
	print "## empty $loops, time $duration s, validations/second: $loops_per_second\n";
	
	$loops *= 10;
    }
    $run++;
}

# --- now get time needed with validation ---
($Scalar::Validation::fail_action, $Scalar::Validation::off)   = prepare_validation_mode(off => 1);

my $max_loops_per_second = 0;

$run = 0;
while ($run < 3) {
    my $loops = 1000;

    my $rules_ref = [Any => Any => 0];
    
    while ($loops <= $max_loops ) {
	my $start_time = time;
	
	foreach my $i (1..$loops) {
	    # my $variable = validate(Performance => Any => $i);
	    # my $variable = is_valid(Performance => Any => $i);
	    # my $variable = validate(Performance => [Any => 'Any'] => $i);
	    # my $variable = validate(Performance => -And => [Any => Any => 0] => $i);
	    # my $variable = validate(Performance => $rules_ref => $i);
	    # my $variable = validate(Performance => Int => $i);
	    my $variable = validate(Performance => Float => $i);
	    # my $variable = validate(Performance => -Optional => Int => undef);
	    # my $variable = validate(Performance => -Optional => Int => '');  # => dies
	    # my $variable = validate(Performance => -Optional => Int => $i);
	    # my $variable = validate(Performance => -Optional => Float => $i);
	    # };

	    $sub_content->($variable-1) if $sub_content;
	}
	
	my $duration = time - $start_time;
	my $loops_per_second = $loops / $duration;
	$max_loops_per_second = $loops_per_second if $max_loops_per_second < $loops_per_second;
	
	print "## validations $loops, time $duration s, validations/second: $loops_per_second\n";
	
	$loops *= 10;
    }
    $run++;
}

my $factor = $max_loops_per_second / $max_empty_loops_per_second * 100.0;
print "\n## max loops per second = $max_loops_per_second\n";
print "## factor               = $factor %\n";

# Statistics on quad core CPU 3.3 GHz, 8 GB RAM, Windows 7 Home, 64 Bit, Service Pack 1

#------------------------------------------------------------------------------------
# no sub call     => Off   => 21.5% => Win7x64
# no sub call     => Int   =>  2.6% => Win7x64
# no sub call     => Float =>  2.3% => Win7x64
# shift           => Off   => 36.8% => Win7x64
# shift           => Int   =>  6.5% => Win7x64
# shift           => Float =>  5.7% => Win7x64
# array[21]       => Off   => 85.2% => Win7x64
# array[21]       => Int   => 40.0% => Win7x64
# array[21]       => Float => 38.7% => Win7x64
# array[0..$loop] => Off   => 98.1% => Win7x64
# array[0..$loop] => Int   => 91.7% => Win7x64
# array[0..$loop] => Float => 91.9% => Win7x64
