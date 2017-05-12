# perl
#
# Demo to start examples for PORF Perl Open Report Framework
#
# Ralf Peine, Wed May 14 10:39:11 2014
#
#------------------------------------------------------------------------------

use warnings;
use strict;

$|=1;

use lib '../../..';

use Time::HiRes;
use Report::Porf::examples::Person;

#------------------------------------------------------------------------------
#
#  Defaults
#
#------------------------------------------------------------------------------

our $CountMax     = 1000;
our $CountDefault = 13;

#------------------------------------------------------------------------------
#
#  Methods
#
#------------------------------------------------------------------------------

# --- check count for lists ---------------------------------------------------
sub inspect_count {
	my $count = shift;

	$count = $CountDefault unless $count;
	$count = $CountMax     if $count > $CountMax;

	return $count;
}

# --- create Test Data As List Of $data_type --------------------------------------
sub create_data_list {
	my $data_type  = shift;
	my $count = inspect_count(shift);

	if ( lc($data_type) eq 'array' ) {
		return create_persons_as_array($count);
	}
	elsif ( lc($data_type) eq 'hash' ) {
		return create_persons_as_hash($count);
	}
	elsif ( lc($data_type) eq 'object' ) {
		return create_persons_as_object($count);
	}

	die "Cannot create test data in format '$data_type'";
}

#------------------------------------------------------------------------------
#
#  create Test Data as Array
#
#------------------------------------------------------------------------------

sub create_persons_as_array {
	my $max_entries = shift;

	my $start_time = hires_actual_time();
	my @rows;
	
	foreach my $l (1..$max_entries) {
		my $time = hires_diff_time($start_time, hires_actual_time());
		my @data = (
			$l,
			"Vorname $l",
			"Name $l",
			($l/$max_entries)*100,
			$time,
		);

		push (@rows, \@data);	
	}

	return \@rows;
}

#--------------------------------------------------------------------------------
#
#  create Test Data as Hash
#
#--------------------------------------------------------------------------------

sub create_persons_as_hash {
	my $max_entries = shift;

	my $start_time = hires_actual_time();
	my @rows;
	
	foreach my $l (1..$max_entries) {
		my $time = hires_diff_time($start_time, hires_actual_time());
		my %data = (
			Count   => $l,
			Prename => "Vorname $l",
			Surname => "Name $l",
			Age     => ($l/$max_entries)*100,
			Time    => $time,
		);

		push (@rows, \%data);	
	}

	return \@rows;
}

#--------------------------------------------------------------------------------
#
#  create Test Data as Object
#
#--------------------------------------------------------------------------------

sub create_persons_as_object {
	my $max_entries = shift;

	my $start_time = hires_actual_time();
	my @rows;
	
	foreach my $l (1..$max_entries) {
		my $time = hires_diff_time($start_time, hires_actual_time());
		my $person = Report::Porf::examples::Person->new();
		$person->set_count  ($l);
		$person->set_prename("Vorname $l");
		$person->set_surname("Name $l");
		$person->set_age    (($l/$max_entries)*100);
		$person->set_time   ($time);

		push (@rows, $person);	
	}

	return \@rows;
}

#--------------------------------------------------------------------------------
#
#  Helper subs
#
#--------------------------------------------------------------------------------

# --- get hiresolution time, uses Time::HiRes ---
sub hires_actual_time {
	return [Time::HiRes::gettimeofday];
}

# --- get difference from now to $start_time in hiresolution time, uses Time::HiRes ---
sub hires_diff_time {
	my $start_time = shift;
	my $end_time   = shift; # actual time, if omitted
	return Time::HiRes::tv_interval ($start_time, $end_time); 
}

#--------------------------------------------------------------------------------
#
#  Main Example
#
#--------------------------------------------------------------------------------

my $max_lines  = shift;
my $format     = shift;
my $data_type  = shift;
my $example    = shift;

$format    = 'text'                  unless $format;
$data_type = 'array'                 unless $data_type;
$data_type = lc($data_type);
$example   = "minimal_$data_type.pl" unless $example;

require $example;

$max_lines = $CountDefault unless $max_lines;

# --- measure time --------------------------------------
my $start_time = hires_actual_time();

#--------------------------------------------------------------------------------
#
#  Run Example
#
#--------------------------------------------------------------------------------

my $row_count = run_example(create_data_list($data_type, $max_lines), $format);

# --- measure time --------------------------------------

my $end_time = hires_actual_time();

my $time_needed = "Time needed for export of $row_count lines ($data_type) by example script '$example': ".
	hires_diff_time($start_time, $end_time)." sec\n";
print "# $time_needed";
warn "$time_needed";
