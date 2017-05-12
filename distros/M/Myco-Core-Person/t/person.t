# $Id: person.t,v 1.1.1.1 2006/02/28 22:15:51 sommerb Exp $

use strict;
use warnings;
use lib 'lib';
use Myco::Core::Person;
use Test::More;
BEGIN { plan tests => 23 };

# Requires: Lingua::Strfname

##############################################################################
# In-Memory Tests.
##############################################################################

sub test_first {
    # Test first name.
    my $p =_sample_person();
    ok($p->get_first eq 'Larry', 'First name Larry');
    $p->set_first('Damian');
    ok($p->get_first eq 'Damian', 'First name Damian');
}

sub test_last {
    # Test last name.
    my $p =_sample_person();
    ok($p->get_last eq 'Wall', 'Last name Wall');
    $p->set_last('Conway');
    ok($p->get_last eq 'Conway', 'Last name Conway');
}

sub test_middle {
    # Test middle name.
    my $p =_sample_person();
    ok($p->get_middle eq 'Albert', 'Middle name Albert');
    $p->set_middle('Terrence');
    ok($p->get_middle eq 'Terrence', 'Middle name Terrence');
}

sub test_prefix {
    # Test prefix.
    my $p =_sample_person();
    ok($p->get_prefix eq 'Mr.', 'Prefix Mr.');
    $p->set_prefix('Dr.');
    ok($p->get_prefix eq 'Dr.', 'Prefix Dr.');
}

sub test_suffix {
    # Test suffix.
    my $p =_sample_person();
    ok($p->get_suffix eq 'Ph.D.', 'Suffix Ph.D.');
    $p->set_suffix('Jr.');
    ok($p->get_suffix eq 'Jr.', 'Suffix Jr.');
}

sub test_nick {
    # Test nick name.
    my $p =_sample_person();
    ok(! defined $p->get_nick, 'Nick name is undef');
    $p->set_nick('PerlGuy');
    ok($p->get_nick eq 'PerlGuy', 'Nick name PerlGuy');
}

sub test_strfname {
    # Test strfname formatting.
    my $p =_sample_person();
    $p->set_nick('TIMTOWTDI');
    my %tests = ( "%f% m% l" => 'Larry Albert Wall',
		  "%p% f% M% l%, s" => 'Mr. Larry A. Wall, Ph.D.',
		  "%l,% F%M" => 'Wall, L.A.',
		  '%l%, f% m' => 'Wall, Larry Albert',
		  '%l%, f% M' => 'Wall, Larry A.',
		  '%l%, f' => 'Wall, Larry',
		  '%l%, F% m' => 'Wall, L. Albert',
		  '%f% l' => 'Larry Wall',
		  '%f% M% l' => 'Larry A. Wall',
		  '%F%M% l' => 'L.A. Wall',
		  '%F% m% l' => 'L. Albert Wall',
    );

    while (my ($k, $v) = each %tests) {
	ok($p->strfname($k) eq $v, "$k => $v");
    }
}

##############################################################################
# Utility methods.
##############################################################################
sub _sample_person {
  return Myco::Core::Person->new( last   => 'Wall',
				  first  => 'Larry',
				  middle => 'Albert',
				  prefix => 'Mr.',
				  suffix => 'Ph.D.',
				);
}


###############################################################################
# Run the tests
###############################################################################

&test_first;
&test_last;
&test_middle;
&test_prefix;
&test_suffix;
&test_nick;
&test_strfname;

1;
