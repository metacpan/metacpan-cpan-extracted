#!perl

# $Id: Lexer.t,v 1.4 2013/07/27 00:34:39 Paulo Exp $

use 5.010;
use strict;
use warnings;

use Test::More;

use_ok 'Parse::FSM::Error', 'error', 'warning';

#------------------------------------------------------------------------------
my $warn; 
$SIG{__WARN__} = sub {$warn = shift};

sub t_error { 
	my($args, $expected_message) = @_;
	my $test_name = "[line ".((caller)[2])."]";

	(my $expected_error   = $expected_message) =~ s/XXX/Error/;
	(my $expected_warning = $expected_message) =~ s/XXX/Warning/;
	
	eval {	error(@$args) };
	is		$@, $expected_error, "$test_name die()";
	
			$warn = "";
			warning(@$args);
	is 		$warn, $expected_warning, "$test_name warning()";
	$warn = undef;
}
#------------------------------------------------------------------------------

t_error([], 						"XXX\n");
t_error([""], 						"XXX\n");
t_error([0], 						"XXX : 0\n");

t_error(["test error"], 			"XXX : test error\n");
t_error(["test error\n"], 			"XXX : test error\n");

t_error(["test error",   undef, 0], "XXX : test error\n");
t_error(["test error\n", undef, 0], "XXX : test error\n");

t_error(["test error",   undef, 1], "XXX at line 1 : test error\n");
t_error(["test error\n", undef, 1], "XXX at line 1 : test error\n");

t_error(["test error",   undef, 11],"XXX at line 11 : test error\n");
t_error(["test error\n", undef, 11],"XXX at line 11 : test error\n");

t_error(["test error",   "f1"], 	"XXX at file 'f1' : test error\n");
t_error(["test error\n", "f1"], 	"XXX at file 'f1' : test error\n");

t_error(["test error",   "f1", 0], 	"XXX at file 'f1' : test error\n");
t_error(["test error\n", "f1", 0], 	"XXX at file 'f1' : test error\n");

t_error(["test error",   "f1", 10],	"XXX at file 'f1', line 10 : test error\n");
t_error(["test error\n", "f1", 10],	"XXX at file 'f1', line 10 : test error\n");

done_testing();
