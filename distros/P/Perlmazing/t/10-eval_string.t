use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 5;
use Perlmazing;

{
	my $r = eval_string 'hello world';
	my $e = $@;
	is $r, undef, 'eval_string fails with invalid code';
	isnt $e, undef, 'error in $@ is set after failed eval';
	undef $@;
}
{
	local $@;
	my $r = eval_string 'hello world';
	my $e = $@;
	isnt $e, undef, 'error in localized $@ is set after failed eval';
	my $true = ($e =~ /...called in eval_string at .*?10\-eval_string\.t line 18\.$/);
	is $true, 1, 'error includes the right file name and number for the error';
}
{
	my $r = eval_string '1 + 4';
	is $r, 5, 'eval_string returns value correctly';
}