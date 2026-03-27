use Test::More;
use Rope;

# ============================================================
# Class definitions – exercise every scope-closure path
# ============================================================

{
	package Scope::Counter;

	use Rope;
	use Rope::Autoload;

	property count => (
		value => 0,
		configurable => 1,
		enumerable => 1,
	);

	property label => (
		initable => 1,
		writeable => 1,
		enumerable => 1,
		predicate => 1,
		clearer   => 1,
		trigger   => sub {
			my ($self, $value) = @_;
			$self->{count}++;
			return $value;
		},
	);

	function increment => sub {
		my ($self, $n) = @_;
		$self->count = $self->count + (defined $n ? $n : 1);
		return $self->count;
	};

	function identity => sub {
		my ($self) = @_;
		return $self;
	};

	1;
}

{
	package Scope::Role;

	use Rope::Role;

	property role_val => (
		value => 'from_role',
		writeable => 1,
		enumerable => 1,
	);

	function role_greet => sub {
		my ($self) = @_;
		return 'hello:' . $self->{role_val};
	};

	1;
}

{
	package Scope::WithRole;

	use Rope;
	use Rope::Autoload;

	with 'Scope::Role';

	property local_val => (
		value => 0,
		configurable => 1,
		enumerable => 1,
	);

	function combined => sub {
		my ($self) = @_;
		return $self->{role_val} . ':' . $self->{local_val};
	};

	1;
}

{
	package Scope::Parent;

	use Rope;
	use Rope::Autoload;

	property base => (
		value => 'parent',
		writeable => 1,
		enumerable => 1,
	);

	function whoami => sub {
		my ($self) = @_;
		return $self->{base};
	};

	1;
}

{
	package Scope::Child;

	use Rope;
	use Rope::Autoload;

	extends 'Scope::Parent';

	before base => sub {
		my ($self, $val) = @_;
		return 'child:' . $val;
	};

	after whoami => sub {
		my ($self, @r) = @_;
		return $r[0] . ':after';
	};

	1;
}

{
	package Scope::Around;

	use Rope;
	use Rope::Autoload;

	extends 'Scope::Parent';

	around whoami => sub {
		my ($self, $cb, @args) = @_;
		my $r = $cb->(@args);
		return 'around(' . $r . ')';
	};

	1;
}

# ============================================================
# 1. Basic scope isolation – many instances of the same class
# ============================================================

subtest 'scope isolation across instances' => sub {
	my @objects;
	for my $i (1 .. 20) {
		my $obj = Scope::Counter->new(label => "obj_$i");
		push @objects, $obj;
	}

	# Each object should have its own scope
	for my $i (0 .. $#objects) {
		my $n = $i + 1;
		is($objects[$i]->label, "obj_$n", "instance $n has correct label");
		is($objects[$i]->count, 1, "instance $n trigger fired once (from init)");
	}

	# Mutate one – others must not be affected
	$objects[0]->label = 'changed';
	is($objects[0]->label, 'changed', 'first object mutated');
	is($objects[0]->count, 2, 'first object trigger count bumped');
	is($objects[1]->label, 'obj_2', 'second object unaffected');
	is($objects[1]->count, 1, 'second object count unaffected');

	# identity() should return the correct $self each time
	for my $i (0 .. $#objects) {
		my $self_ref = $objects[$i]->{identity}->();
		is($self_ref->{label}, $objects[$i]->{label},
			"identity returns correct self for instance " . ($i + 1));
	}
};

# ============================================================
# 2. Create / destroy / recreate loop
# ============================================================

subtest 'create-destroy-recreate cycle' => sub {
	for my $round (1 .. 15) {
		my $obj = Scope::Counter->new(label => "round_$round");
		is($obj->label, "round_$round", "round $round: label correct");
		is($obj->count, 1, "round $round: trigger count correct");

		$obj->increment(5);
		is($obj->count, 6, "round $round: increment works");

		# predicate & clearer
		is($obj->has_label, 1, "round $round: predicate true");
		$obj->clear_label;
		is($obj->has_label, '', "round $round: clearer works");

		$obj->destroy();
	}
};

# ============================================================
# 3. Interleaved create / destroy – stale identifier detection
# ============================================================

subtest 'interleaved create-destroy' => sub {
	my @live;
	for my $i (1 .. 10) {
		push @live, Scope::Counter->new(label => "live_$i");
	}

	# Destroy odd-indexed, keep even
	for (my $i = 0; $i < @live; $i += 2) {
		$live[$i]->destroy();
		$live[$i] = undef;
	}

	# Create new objects – they should get fresh scope
	for (my $i = 0; $i < @live; $i += 2) {
		$live[$i] = Scope::Counter->new(label => "replaced_$i");
	}

	# Verify all objects have correct isolated scope
	for my $i (0 .. $#live) {
		next unless $live[$i];
		my $expected = $i % 2 == 0 ? "replaced_$i" : 'live_' . ($i + 1);
		is($live[$i]->label, $expected, "slot $i has correct label: $expected");

		# Mutate and check isolation
		$live[$i]->increment(100);
		is($live[$i]->count, 101, "slot $i count after increment");
	}

	# Cross-check no bleed
	for my $i (0 .. $#live) {
		next unless $live[$i];
		is($live[$i]->count, 101, "slot $i count stable after other mutations");
	}

	$_->destroy() for grep { defined } @live;
};

# ============================================================
# 4. Role composition – scope per instance
# ============================================================

subtest 'role scope isolation' => sub {
	my @objects;
	for my $i (1 .. 10) {
		push @objects, Scope::WithRole->new();
	}

	# Mutate role_val on each uniquely
	for my $i (0 .. $#objects) {
		$objects[$i]->role_val = "val_$i";
		$objects[$i]->local_val = $i * 10;
	}

	# Verify isolation
	for my $i (0 .. $#objects) {
		is($objects[$i]->role_val, "val_$i", "role prop isolated for instance $i");
		is($objects[$i]->local_val, $i * 10, "local prop isolated for instance $i");
		is($objects[$i]->{role_greet}->(), "hello:val_$i",
			"role function uses correct self for instance $i");
		is($objects[$i]->{combined}->(), "val_$i:" . ($i * 10),
			"combined function correct for instance $i");
	}

	$_->destroy() for @objects;
};

# ============================================================
# 5. Inheritance with before/after – scope per instance
# ============================================================

subtest 'inheritance before/after scope' => sub {
	my @children;
	for my $i (1 .. 10) {
		push @children, Scope::Child->new();
	}

	for my $i (0 .. $#children) {
		$children[$i]->base = "v$i";
	}

	for my $i (0 .. $#children) {
		is($children[$i]->base, "child:v$i",
			"before hook applied correctly for child $i");
		is($children[$i]->{whoami}->(), "child:v$i:after",
			"after hook applied correctly for child $i");
	}

	$_->destroy() for @children;
};

# ============================================================
# 6. Around modifier scope isolation
# ============================================================

subtest 'around modifier scope' => sub {
	my @objects;
	for my $i (1 .. 10) {
		push @objects, Scope::Around->new();
	}

	for my $i (0 .. $#objects) {
		$objects[$i]->base = "a$i";
	}

	for my $i (0 .. $#objects) {
		is($objects[$i]->base, "a$i", "base correct for around instance $i");
		is($objects[$i]->{whoami}->(), "around(a$i)",
			"around hook scoped correctly for instance $i");
	}

	$_->destroy() for @objects;
};

# ============================================================
# 7. Mixed class rapid cycling
# ============================================================

subtest 'mixed class rapid cycling' => sub {
	for my $round (1 .. 10) {
		my $counter = Scope::Counter->new(label => "c$round");
		my $roled   = Scope::WithRole->new();
		my $child   = Scope::Child->new();
		my $around  = Scope::Around->new();

		$counter->increment(10);
		$roled->role_val = "r$round";
		$child->base = "ch$round";
		$around->base = "ar$round";

		is($counter->count, 11, "round $round: counter scope ok");
		is($roled->{role_greet}->(), "hello:r$round",
			"round $round: role scope ok");
		is($child->{whoami}->(), "child:ch$round:after",
			"round $round: child scope ok");
		is($around->{whoami}->(), "around(ar$round)",
			"round $round: around scope ok");

		# identity check – the self inside the closure is the right object
		my $self_ref = $counter->{identity}->();
		is($self_ref->{label}, "c$round",
			"round $round: identity self correct");

		$counter->destroy();
		$roled->destroy();
		$child->destroy();
		$around->destroy();
	}
};

# ============================================================
# 8. Trigger chain – scope doesn't leak across trigger calls
# ============================================================

subtest 'trigger does not leak across instances' => sub {
	my $a = Scope::Counter->new(label => 'a');
	my $b = Scope::Counter->new(label => 'b');

	is($a->count, 1, 'a: initial trigger count');
	is($b->count, 1, 'b: initial trigger count');

	# Rapid alternating mutations
	for my $i (1 .. 20) {
		$a->label = "a_$i";
		$b->label = "b_$i";
	}

	is($a->count, 21, 'a: trigger count after 20 mutations');
	is($b->count, 21, 'b: trigger count after 20 mutations');
	is($a->label, 'a_20', 'a: final label');
	is($b->label, 'b_20', 'b: final label');

	$a->destroy();
	$b->destroy();
};

# ============================================================
# 9. Simultaneous instances – large batch
# ============================================================

subtest 'large batch simultaneous instances' => sub {
	my @batch;
	my $n = 50;

	for my $i (1 .. $n) {
		push @batch, Scope::Counter->new(label => "batch_$i");
	}

	# Mutate all
	for my $i (0 .. $#batch) {
		$batch[$i]->increment($i);
	}

	# Verify
	for my $i (0 .. $#batch) {
		is($batch[$i]->count, 1 + $i,
			"batch instance $i: count correct");
		is($batch[$i]->label, "batch_" . ($i + 1),
			"batch instance $i: label untouched");
	}

	$_->destroy() for @batch;
};

# ============================================================
# 10. Self-referential property – clone must not infinite loop
# ============================================================

subtest 'self-referential property value' => sub {
	my $obj = Scope::Counter->new(label => 'self_ref');
	# Store a hash that references itself as a property value
	my $circular = { name => 'loop' };
	$circular->{self} = $circular;
	$obj->label = $circular;
	is(ref($obj->label), 'HASH', 'circular hash stored as property');
	is($obj->label->{name}, 'loop', 'can read into circular hash');

	# Creating a new object should clone META without hitting deep recursion
	# (clone only affects META, not instance data, but this exercises the path)
	my $obj2 = Scope::Counter->new(label => 'after_circular');
	is($obj2->label, 'after_circular', 'new object after circular ref works');

	$obj->destroy();
	$obj2->destroy();
};

# ============================================================
# 11. Builder that references another property via self
# ============================================================

{
	package Scope::Builder;

	use Rope;
	use Rope::Autoload;

	property base_val => (
		value => 10,
		initable => 1,
		writeable => 1,
		enumerable => 1,
	);

	property derived => (
		enumerable => 1,
		writeable => 1,
		builder => sub {
			return 'built';
		},
	);

	function compute => sub {
		my ($self) = @_;
		return $self->{base_val} . ':' . $self->{derived};
	};

	1;
}

subtest 'builder scope across many instances' => sub {
	my @objs;
	for my $i (1 .. 20) {
		push @objs, Scope::Builder->new(base_val => $i);
	}

	for my $i (0 .. $#objs) {
		is($objs[$i]->base_val, $i + 1, "builder instance $i: base_val correct");
		is($objs[$i]->derived, 'built', "builder instance $i: derived built");
		is($objs[$i]->{compute}->(), ($i + 1) . ':built',
			"builder instance $i: compute correct");
	}

	$_->destroy() for @objs;
};

# ============================================================
# 12. Deep inheritance chain – scope through multiple extends
# ============================================================

{
	package Scope::Gen0;

	use Rope;
	use Rope::Autoload;

	property gen => (
		value => 0,
		writeable => 1,
		enumerable => 1,
	);

	function lineage => sub {
		my ($self) = @_;
		return 'gen0:' . $self->{gen};
	};

	1;
}

{
	package Scope::Gen1;

	use Rope;
	extends 'Scope::Gen0';

	before gen => sub {
		my ($self, $val) = @_;
		return $val + 100;
	};

	1;
}

{
	package Scope::Gen2;

	use Rope;
	extends 'Scope::Gen1';

	before gen => sub {
		my ($self, $val) = @_;
		return $val + 1000;
	};

	1;
}

subtest 'deep inheritance chain scope' => sub {
	my @g0;
	my @g1;
	my @g2;
	for my $i (1 .. 5) {
		push @g0, Scope::Gen0->new();
		push @g1, Scope::Gen1->new();
		push @g2, Scope::Gen2->new();
	}

	# Mutate gen0 instances
	for my $i (0 .. $#g0) {
		$g0[$i]->gen = $i;
		is($g0[$i]->gen, $i, "gen0 instance $i: gen set directly");
	}

	# Mutate gen1 instances – before adds 100
	for my $i (0 .. $#g1) {
		$g1[$i]->gen = $i;
		is($g1[$i]->gen, $i + 100, "gen1 instance $i: before hook adds 100");
	}

	# Mutate gen2 instances – before chain adds 1000 then 100
	for my $i (0 .. $#g2) {
		$g2[$i]->gen = $i;
		is($g2[$i]->gen, $i + 1100, "gen2 instance $i: chained before hooks add 1100");
	}

	# Cross-check no scope bleed between generations
	for my $i (0 .. $#g0) {
		is($g0[$i]->gen, $i, "gen0 instance $i: still correct after gen1/gen2 mutations");
	}

	$_->destroy() for (@g0, @g1, @g2);
};

# ============================================================
# 13. Role + inheritance combined – complex scope chain
# ============================================================

{
	package Scope::MixedRole;

	use Rope::Role;

	property mixin => (
		value => 'role_default',
		writeable => 1,
		enumerable => 1,
		predicate => 1,
		clearer => 1,
	);

	function greet_mixin => sub {
		my ($self) = @_;
		return 'mixin:' . $self->{mixin};
	};

	1;
}

{
	package Scope::MixedParent;

	use Rope;
	use Rope::Autoload;

	with 'Scope::MixedRole';

	property own_val => (
		value => 'parent',
		writeable => 1,
		enumerable => 1,
	);

	function combined_val => sub {
		my ($self) = @_;
		return $self->{own_val} . '+' . $self->{mixin};
	};

	1;
}

{
	package Scope::MixedChild;

	use Rope;
	use Rope::Autoload;

	extends 'Scope::MixedParent';

	around greet_mixin => sub {
		my ($self, $cb, @args) = @_;
		return 'child_wrap(' . $cb->(@args) . ')';
	};

	1;
}

subtest 'role + inheritance combined scope' => sub {
	my @parents;
	my @children;
	for my $i (1 .. 10) {
		push @parents, Scope::MixedParent->new();
		push @children, Scope::MixedChild->new();
	}

	for my $i (0 .. $#parents) {
		$parents[$i]->mixin = "p$i";
		$parents[$i]->own_val = "pown$i";
		$children[$i]->mixin = "c$i";
		$children[$i]->own_val = "cown$i";
	}

	for my $i (0 .. $#parents) {
		is($parents[$i]->{greet_mixin}->(), "mixin:p$i",
			"parent $i: role function scoped correctly");
		is($parents[$i]->{combined_val}->(), "pown$i+p$i",
			"parent $i: combined val correct");
		is($parents[$i]->has_mixin, 1,
			"parent $i: predicate works");

		is($children[$i]->{greet_mixin}->(), "child_wrap(mixin:c$i)",
			"child $i: around hook on role function scoped correctly");
		is($children[$i]->{combined_val}->(), "cown$i+c$i",
			"child $i: inherited combined val correct");
	}

	# Destroy parents, children should still work
	$_->destroy() for @parents;

	for my $i (0 .. $#children) {
		is($children[$i]->{greet_mixin}->(), "child_wrap(mixin:c$i)",
			"child $i: still works after parent destroy");
	}

	# Clear mixin via clearer, verify predicate
	for my $i (0 .. $#children) {
		$children[$i]->clear_mixin;
		is($children[$i]->has_mixin, '',
			"child $i: clearer works after parent destroy");
	}

	$_->destroy() for @children;
};

# ============================================================
# 14. Rapid destroy-then-access (use-after-destroy guard)
# ============================================================

subtest 'scope after destroy' => sub {
	my $obj = Scope::Counter->new(label => 'doomed');
	is($obj->label, 'doomed', 'object works before destroy');

	$obj->destroy();

	# After destroy, the object is removed from META{initialised}
	# Creating a new one should work cleanly
	my $obj2 = Scope::Counter->new(label => 'phoenix');
	is($obj2->label, 'phoenix', 'new object after destroy has clean scope');
	$obj2->increment(5);
	is($obj2->count, 6, 'new object increments correctly');
	$obj2->destroy();
};

# ============================================================
# 15. While loop – 1000 iterations setting/getting nested Rope objects
# ============================================================

{
	package Nested::Address;

	use Rope;
	use Rope::Autoload;

	property street => (
		initable => 1,
		writeable => 1,
		enumerable => 1,
	);

	property city => (
		initable => 1,
		writeable => 1,
		enumerable => 1,
	);

	function summary => sub {
		my ($self) = @_;
		return $self->{street} . ', ' . $self->{city};
	};

	1;
}

{
	package Nested::Person;

	use Rope;
	use Rope::Autoload;

	property name => (
		initable => 1,
		writeable => 1,
		enumerable => 1,
		predicate => 1,
		trigger => sub {
			my ($self, $value) = @_;
			$self->{name_changes}++;
			return $value;
		},
	);

	property name_changes => (
		value => 0,
		configurable => 1,
		enumerable => 1,
	);

	property address => (
		initable => 1,
		writeable => 1,
		enumerable => 1,
	);

	property tags => (
		initable => 1,
		writeable => 1,
		enumerable => 1,
	);

	function full_info => sub {
		my ($self) = @_;
		my $addr = $self->{address};
		return $self->{name} . ' @ ' . $addr->{summary}->();
	};

	1;
}

{
	package Nested::Team;

	use Rope;
	use Rope::Autoload;

	property team_name => (
		initable => 1,
		writeable => 1,
		enumerable => 1,
	);

	property leader => (
		initable => 1,
		writeable => 1,
		enumerable => 1,
	);

	property member => (
		initable => 1,
		writeable => 1,
		enumerable => 1,
	);

	function describe => sub {
		my ($self) = @_;
		my $l = $self->{leader};
		my $m = $self->{member};
		return $self->{team_name} . ': ' . $l->{name} . ' + ' . $m->{name};
	};

	1;
}

subtest 'while loop 1000 iterations with nested Rope objects' => sub {
	my $i = 0;
	while ($i < 1000) {
		# Build nested Rope objects: Team -> Person -> Address
		my $addr1 = Nested::Address->new(
			street => "Street $i",
			city   => "City $i",
		);
		my $addr2 = Nested::Address->new(
			street => "Ave $i",
			city   => "Town $i",
		);

		my $person1 = Nested::Person->new(
			name    => "Alice_$i",
			address => $addr1,
			tags    => [ "tag_a_$i", "tag_b_$i" ],
		);
		my $person2 = Nested::Person->new(
			name    => "Bob_$i",
			address => $addr2,
			tags    => [ "tag_c_$i" ],
		);

		my $team = Nested::Team->new(
			team_name => "Team_$i",
			leader    => $person1,
			member    => $person2,
		);

		# GET nested attributes – read through multiple Rope layers
		is($team->team_name, "Team_$i", "iter $i: team name")
			if $i % 100 == 0;
		is($team->{describe}->(), "Team_$i: Alice_$i + Bob_$i", "iter $i: describe")
			if $i % 100 == 0;
		is($person1->{full_info}->(), "Alice_$i @ Street $i, City $i", "iter $i: person1 full_info")
			if $i % 100 == 0;
		is($person2->{full_info}->(), "Bob_$i @ Ave $i, Town $i", "iter $i: person2 full_info")
			if $i % 100 == 0;

		# SET nested attributes – mutate through Rope scope
		$addr1->street = "NewStreet $i";
		$addr1->city   = "NewCity $i";
		$person1->name = "Alice_${i}_v2";
		$person2->name = "Bob_${i}_v2";
		$team->team_name = "Team_${i}_v2";

		# Re-read after mutation
		is($addr1->{summary}->(), "NewStreet $i, NewCity $i", "iter $i: addr1 after mutate")
			if $i % 100 == 0;
		is($person1->{full_info}->(), "Alice_${i}_v2 @ NewStreet $i, NewCity $i", "iter $i: person1 after mutate")
			if $i % 100 == 0;
		is($team->{describe}->(), "Team_${i}_v2: Alice_${i}_v2 + Bob_${i}_v2", "iter $i: team after mutate")
			if $i % 100 == 0;

		# Verify trigger counted both init + mutation
		is($person1->name_changes, 2, "iter $i: person1 trigger count")
			if $i % 100 == 0;
		is($person2->name_changes, 2, "iter $i: person2 trigger count")
			if $i % 100 == 0;

		# Predicate on nested
		is($person1->has_name, 1, "iter $i: predicate on nested")
			if $i % 100 == 0;

		# Swap nested objects between parents
		$team->leader = $person2;
		$team->member = $person1;
		is($team->{describe}->(), "Team_${i}_v2: Bob_${i}_v2 + Alice_${i}_v2", "iter $i: after swap")
			if $i % 100 == 0;

		# Replace address on person mid-loop
		my $addr3 = Nested::Address->new(
			street => "Replaced $i",
			city   => "Swapped $i",
		);
		$person1->address = $addr3;
		is($person1->{full_info}->(), "Alice_${i}_v2 @ Replaced $i, Swapped $i", "iter $i: replaced nested addr")
			if $i % 100 == 0;

		# Destroy inner objects, create fresh ones in same iteration
		$addr1->destroy();
		$addr2->destroy();
		$addr3->destroy();
		$person1->destroy();
		$person2->destroy();
		$team->destroy();

		$i++;
	}

	is($i, 1000, 'completed 1000 iterations');
};

ok(1, 'scope stress test complete');
done_testing();
