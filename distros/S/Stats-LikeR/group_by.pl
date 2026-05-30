#!/usr/bin/env perl

require 5.010;
use feature 'say';
use warnings FATAL => 'all';
use autodie ':default';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
use Stats::LikeR;

sub group_by_pp {
	my ($data, $target_key, $group_key) = @_;
	my %result;
	if (ref($data) eq 'ARRAY') { # Array of Hashes
	  for my $row (@$data) {
		   next unless ref($row) eq 'HASH' && exists $row->{$group_key};
		   my $t_val = $row->{$target_key};
		   if (defined $t_val) {
		       my $g_val = $row->{$group_key};
		       $result{$g_val} //= [];
		       push @{ $result{$g_val} }, $t_val;
		   }
	  }
	} elsif (ref($data) eq 'HASH') {# Hash of Arrays
	  
	  if (ref($data->{$group_key}) eq 'ARRAY' && ref($data->{$target_key}) eq 'ARRAY') {
		   my $g_arr = $data->{$group_key};
		   my $t_arr = $data->{$target_key};
		   
		   my $len = @$g_arr < @$t_arr ? @$g_arr : @$t_arr;
		   for my $i (0 .. $len - 1) {
		       my $t_val = $t_arr->[$i];
		       if (defined $t_val) {
		           my $g_val = $g_arr->[$i];
		           $result{$g_val} //= [];
		           push @{ $result{$g_val} }, $t_val;
		       }
		   }
	  } else {# Hash of Hashes
		   for my $row_key (keys %$data) {
		       my $row = $data->{$row_key};
		       next unless ref($row) eq 'HASH' && exists $row->{$group_key};
		       
		       my $t_val = $row->{$target_key};
		       if (defined $t_val) {
		           my $g_val = $row->{$group_key};
		           $result{$g_val} //= [];
		           push @{ $result{$g_val} }, $t_val;
		       }
		   }
	  }
	}
	return \%result;
}
my $aoh_data = [
	{ 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 20.5 },
	{ 'Gender' => 'Female', 'Testosterone, total (nmol/L)' => 1.8 },
	{ 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 18.2 },
	{ 'Gender' => 'Female' } # Intentional missing target value
];
my $gb = group_by($aoh_data, 'Testosterone, total (nmol/L)', 'Gender');
p $gb;
my $hoa_data = {
	'Gender'                       => ['Male', 'Female', 'Male', 'Female'],
	'Testosterone, total (nmol/L)' => [22.1,   2.5,      19.4,   undef   ]
};

$gb = group_by($hoa_data, 'Testosterone, total (nmol/L)', 'Gender');

if (scalar keys %$gb == 2) {
	say('group_by (HoA): correct number of group keys created');
} else {
	say('group_by (HoA): incorrect number of group keys');
}

if (scalar @{ $gb->{'Male'} } == 2 && $gb->{'Male'}[0] == 22.1 && $gb->{'Male'}[1] == 19.4) {
	say('group_by (HoA): Male target values grouped correctly');
} else {
	say('group_by (HoA): Male target values NOT grouped correctly');
}

if (!defined $gb->{'Female'}[1]) {
	say('group_by (HoA): gracefully handled undefined target arrays element');
} else {
	say('group_by (HoA): failed to handle undefined target array element');
}
# ==========================================
# TEST SET 3: Hash of Hashes (HoH)
# ==========================================
my $hoh_data = {
	'Patient_A' => { 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 20.5 },
	'Patient_B' => { 'Gender' => 'Female', 'Testosterone, total (nmol/L)' => 1.8 },
	'Patient_C' => { 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 18.2 },
	'Patient_D' => { 'Gender' => 'Female' }, # Intentional missing target value
	'Patient_E' => { 'Gender' => 'Female', 'Testosterone, total (nmol/L)' => undef } # Explicit undef
};
p $hoh_data;
my $res3 = Stats::LikeR::group_by($hoh_data, 'Testosterone, total (nmol/L)', 'Gender');
p $res3;
if (scalar keys %$res3 == 2) {
	say('group_by (HoH): correct number of group keys created');
} else {
	say('group_by (HoH): incorrect number of group keys');
}

# Sort the array to protect the test against randomized hash iteration order
my @males = sort { $a <=> $b } @{ $res3->{'Male'} };

if (scalar @males == 2 && $males[0] == 18.2 && $males[1] == 20.5) {
	say('group_by (HoH): Male target values grouped correctly');
} else {
	say('group_by (HoH): Male target values NOT grouped correctly');
}

my @females = @{ $res3->{'Female'} };

if (scalar @females == 1 && $females[0] == 1.8) {
	say('group_by (HoH): Female target correctly handled missing and undef values');
} else {
	say('group_by (HoH): Female target improperly included undefined/missing values');
}
