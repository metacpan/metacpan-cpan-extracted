# Perl
#
# MyValidation.pm
#
# declare validation rules here
#
# Ralf Peine, Sat Aug 30 14:39:05 2014

package MyValidation;

use DateTime;

use Scalar::Validation qw(:all);

#------------------------------------------------------------------------------
#
#  Rules
#
#------------------------------------------------------------------------------

sub create_birth_date_rule {          # as sub for testing!
    my $time = shift || time;

    my ($current_mday,$current_month,$current_year) = get_current_date($time);
    # print "$current_year-$current_month-$current_mday\n";

    my $birth_date_rule_name = 'BirthDate';
    delete_rule $birth_date_rule_name if rule_known $birth_date_rule_name;

    declare_rule (
	$birth_date_rule_name =>
        -as      => IsoDate =>
	-where   => sub {
	    my ($year, $month, $day) = split (/\-/, $_);
	    return 1 if $year  < $current_year;
	    return 0 if $year  > $current_year;
	    return 1 if $month < $current_month;
	    return 0 if $month > $current_month;
	    return 0 if $day   > $current_mday;
	    return 1;
	},
        -owner   => MyValidation =>
	-message => sub { "value $_ is not an ISO birth date, or it is in the future!" },
	-description => 'This rule checks if $_ is an ISO birth date and in the past'
	);
}

{ # make month_days private
    my @month_days = (
	0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
	);
    
    declare_rule (
	IsoDate =>
	-as     => Filled =>    # a filled string
	-where  => sub {
	    my ($year, $month, $day) = /^(\d{4})-([01]\d)-([0123]\d)$/;
	    return 0 unless defined ($year);
	    return 0 if $month == 0 || $month > 12;
	    return 0 if $day   == 0 || $day   > $month_days[$month];
	    return 1 if     $month !=  2;
	    return 1 if     $day   <= 28;
	    return 0 if     $year  %   4;
	    return 1 unless $year  % 400;
	    return 0 unless $year  % 100;
	    return 1;
	},
        -owner       => MyValidation =>
	-message     => sub { "value $_ is not an ISO 8601 date like 2014-08-30" },
	-description => 'This rule checks if $_ is an ISO 8601 date like 2014-08-30'
	);
}

sub get_current_date {
    my $time = shift;
    my  ($d1,$d2,$d3,$current_mday,$current_month,$current_year) =
	localtime($time);
    $current_year += 1900;
    $current_month++;
    return ($current_mday,$current_month,$current_year);
}

create_birth_date_rule();

declare_rule (
    LivingBirthDate => 
    -as             => BirthDate =>
    -where          => sub {
	my ($year, $month, $day) = split (/-/);
	return 0 if $year  < 1850; # get from now() in real code
	return 1;
    },
    -owner   => MyValidation =>
    -message => sub { "value $_ is not an ISO birth date or its more than 150 years ago!" },
    -description => 'This rule checks if $_ is an ISO birth date of a living person'
    );

1;
