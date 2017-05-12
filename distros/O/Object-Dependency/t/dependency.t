#!/usr/bin/perl 


use strict;
use warnings;
use Test::More qw(no_plan);
use Object::Dependency;
use Data::Dumper;

my $finished = 0;

END { ok($finished, 'finished') }

{
	package Object::Dependency;
	use strict;
	use warnings;

	sub check_invariants
	{
		my ($self) = @_;
		undef $@;
		eval { $self->check_invariants_wrapped() };
		if ($@) {
			*Object::Dependency::lock_keys = sub {};   # doesn't work with Dumper()
			confess "$@\n " . Dumper($self) . "\n" . $self->dump_graph_string();
		}
	}

	sub check_invariants_wrapped
	{
		my ($self) = @_;
		for my $addr (sort keys %{$self->{addrmap}}) {
			die "item in addrmap and stuck"
				if $self->{stuck}{$addr};
		}
		for my $addr (sort (keys %{$self->{addrmap}}, keys %{$self->{stuck}})) {
			my $node = $self->{addrmap}{$addr} || $self->{stuck}{$addr};
			die "node inconsistent $addr vs $node->{dg_addr} ($node)" unless $addr == $node->{dg_addr};
			$self->validate_addr_map($node, 'dg_blocks');
			$self->validate_addr_map($node, 'dg_depends');
			$self->validate_relationships($addr, $node, 'dg_blocks', 'dg_depends');
			$self->validate_relationships($addr, $node, 'dg_depends', 'dg_blocks');
		}
		$self->validate_addr_map($self, 'addrmap');
		$self->validate_addr_map($self, 'stuck');
	}

	sub validate_addr_map
	{
		my ($self, $node, $key) = @_;
		confess unless ref($node);
		confess unless ref($node->{$key});
		for my $i (keys %{$node->{$key}}) {
			my $o = $node->{$key}{$i}{dg_item};
			my $a = refaddr($o) || $o;
			die "bad mapping for $key: $i v. $a" if $i != $a;
		}
		return 1;
	}

	sub validate_relationships
	{
		my ($self, $addr, $node, $rel, $inverse) = @_;
		for my $a (keys %{$node->{$rel}}) {
			my $rnode = $node->{$rel}{$a};
			die "$rel/$inverse doesn't hold for $addr/$a" unless $rnode->{$inverse}{$addr} == $node;
		}
		return 1;
	}
}

my $dg = new Object::Dependency;

my $zero	= [ 0 ];
my $one		= [ 1 ];
my $two		= [ 2 ];
my $three	= [ 3 ];
my $four	= 4;
my $five	= [ 5 ];
my $six		= [ 6 ];
my $seven	= [ 7 ];
my $eight	= [ 8 ];
my $nine	= [ 9 ];

sub setup
{
	$dg->add($one, $zero);
	$dg->add($two, $one);
	$dg->add($three, $zero, $one);
	$dg->add($four, $two);
	$dg->add($five, $zero, $two);
	$dg->add($six, $one, $two);
	$dg->add($seven);
	$dg->add($seven, $zero);
	$dg->add($seven, $one);
	$dg->add($seven, $two);
	$dg->add($seven, $two);
	$dg->add($eight, $three);
	$dg->add($nine, $zero, $three);
}

my @i;

sub check
{
	$dg->check_invariants();
	my @i = $dg->independent(@_);
	$dg->check_invariants();
	return join(' ', sort map { $_ eq '4' ? '4' : $_->[0] } @i);
}

setup();

is(check(), "0");

$dg->remove_dependency($zero);

is(check(), "1");

$dg->remove_dependency($one);

is(check(), "2 3");

$dg->remove_dependency($three);

is(check(), "2 8 9");

$dg->remove_dependency($two, $eight);

is(check(), "4 5 6 7 9");

$dg->remove_dependency($four, $seven);

is(check(), "5 6 9");

$dg->remove_dependency($five, $six, $nine);

is(check(), "");

is($dg->alldone(), 1, 'alldone');

# ---------------------------------------------------------------------

$dg = new Object::Dependency;

my $ten         = [ 10 ];

setup();
$dg->add($ten, $one, $nine);

is(check(), "0");

$dg->remove_dependency($zero);

is(check(), "1");

$dg->remove_dependency($one);

is(check(), "2 3");

$dg->remove_dependency($three);

is(check(), "2 8 9");

$dg->remove_dependency($two, $eight);

is(check(), "4 5 6 7 9");

$dg->remove_dependency($four, $seven);

is(check(), "5 6 9");

$dg->remove_dependency($five, $six);

is(check(), "9");

is($dg->alldone(), 0, 'not done');

$dg->stuck_dependency($nine);

is($dg->alldone(), 1, 'done but stuck');

is(check(), "");

my $eleven = [ 11 ];
my $twelve = [ 12 ];

$dg->add($eleven, $nine);
$dg->add($nine, $twelve);

is(check(), "12");

is($dg->alldone(), 0, 'not done');

$dg->remove_dependency($twelve);

is($dg->alldone(), 1, 'done but stuck');
is(check(), "");


# ---------------------------------------------------------------------

$dg = new Object::Dependency;

setup();

is(check(), "0");
is(check(), "0", "active objects are returned");

is(check(active => 1), "", "... unless we say otherwise");

is(check(lock => 1), "0");
is(check(), "", "locked object are not returned");
is(check(lock => 1), "", "ditto");

$dg->unlock($zero);
is(check(), "0", "unlocked are returned");

is(check(), "0");

$dg->stuck_dependency($three);

is(check(), "0");
is(check(stuck => 1), "3 8 9", "can ask for stuck dependencies");
is(check(stuck => 1), "3 8 9");


$finished = 1;
