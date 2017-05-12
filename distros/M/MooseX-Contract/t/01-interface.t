package MyEvenClass;

use MooseX::Contract;
use Moose::Util::TypeConstraints;

my $even_int = subtype 'Int', where { $_ % 2 == 0};

has value => (
	is => 'rw',
	isa => $even_int,
	required => 1,
	default => 0
);

invariant assert { shift->{value} % 2 == 0 } 'self->{value} must be an even value';

contract incr => accepts [$even_int];
sub incr {
	my $self = shift;
	my $incr = shift;
	$self->{value} += $incr;
	return;
}
contract incr_by_two => accepts void, returns void;
sub incr_by_two {
	shift->{value} += 2;
	return;
}
contract bad_return => returns void;
sub bad_return {
	my $self = shift;
	return "Hiya!";
}

sub bad_method {
	shift->{value}++;
}

contract 'get_multiple'
	=> accepts ['Int'],
	=> returns [$even_int];
sub get_multiple {
	return shift->{value} * shift;
}

contract 'get_multiple_bad'
	=> accepts ['Int'],
	=> returns [$even_int];
sub get_multiple_bad {
	return (shift->{value} * shift) + 1;
}

no MooseX::Contract;

__PACKAGE__->meta->make_immutable;


package main;

use strict;
use warnings;
use Test::More tests => 11;

BEGIN { require_ok('MooseX::Contract') };

my $o = MyEvenClass->new;
is($o->value, 0, 'initialized properly');
$o->incr(2);
is($o->value, 2, 'incremented properly');
eval { $o->incr(1) };
ok($@, "accepts error expected");
eval { my $foo = $o->bad_return };
ok($@, "returns error expected");
eval { $o->bad_return };
ok(!$@, "no returns error in void context") || diag $@;
eval { $o->bad_method };
ok($@, "invariant causes error on bad_method");
$o->value(2);
$o->incr_by_two;
is($o->value, 4, 'incr_by_two');
eval { $o->incr_by_two(1) };
ok($@, 'incr_by_two with extra args fails as expected');

is($o->get_multiple(3), $o->{value} * 3, 'get_multiple');
eval { my $multiple = $o->get_multiple_bad(3) };
ok($@, 'returns assertion fails') || diag $@;
