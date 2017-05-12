# -*- perl -*-

use Test::More qw(no_plan);
use Set::Object qw(set refaddr);
use strict;

my $set = set();

{ package MyClass;
  our $c;
  sub new { $c++; my $pkg = shift;
	    my $self = bless {@_}, $pkg;
	    #print STDERR "# NEW - $self\n";
	    $self;
	}
  sub DESTROY {
      my $self = shift;
      #print STDERR "# FREE - $self\n";
      $c-- }
}

use Devel::Peek;

{
    my $item = MyClass->new;
    $set->insert($item);
    is($set->size, 1, "sanity check 1");
    isa_ok($set, "Set::Object", "it's a Set::Object");
    ok(!$set->isa("Set::Object::Weak"), "but not weak");
    #diag(Dump($item));
    $set->weaken;
    #diag(Dump($item));
    is($set->size, 1, "weaken not too eager");
    isa_ok($set, "Set::Object::Weak", "it's now a Set::Object::Weak");
}

is($MyClass::c, 0, "weaken makes refcnt lower");
is($set->size, 0, "Set knows that the object expired");
diag($_) for $set->members;

$set->insert(MyClass->new);
is($set->size, 0, "weakened sets can't hold temporary objects");

my $structure = MyClass->new
    (
     bob => [ "Hi, I'm bob" ],
     who => set(),
    );

$structure->{who}->insert($structure->{bob});
$structure->{who}->weaken;

#diag("now cloning");

SKIP:{
unless (eval { require Storable; 1 }) {
   skip "Storable not installed", 5;
}
my $clone = Storable::dclone $structure;

isnt(refaddr($structure->{bob}), refaddr($clone->{bob}), "sanity check 2");
isnt(${$structure->{who}}, ${$clone->{who}}, "sanity check 3");

is($clone->{who}->size, 1, "Set has size");
is(($clone->{who}->members)[0], $clone->{bob}, "Set contents preserved");

delete $clone->{bob};

is($clone->{who}->size, 0, "weaken preserved over dclone()");
}

# test strengthen, too
{
    $set->clear();
    $set->weaken();
    my $ref = {};
    {
	my $ref2 = {};
	$set->insert($ref, $ref2);
	is($set->size, 2, "sanity check 4");
    }
    is($set->size, 1, "sanity check 5");
    isa_ok($set, "Set::Object::Weak", "starts as a Set::Object::Weak");
    $set->strengthen;
}

isa_ok($set, "Set::Object", "it's a Set::Object");
ok(!$set->isa("Set::Object::Weak"), "but not weak");
is($set->size, 1, "->strengthen()");

# test that weak sets can expire before their referants
{
    my $referant = [ "hello, world" ];
    {
	my $set = set();
	$set->weaken;
	$set->insert($referant);
	my $magic = Set::Object::get_magic($referant);
	is_deeply($magic, [$$set], "Magic detected");
    }
    my $magic = Set::Object::get_magic($referant);
    #diag("magic is $magic, length ".@$magic);
    #Dump($magic);
    #diag("got that?  :)");
    is_deeply($magic, undef, "Magic removed");
}

# test that dispel works with tied refs
{
    my %object;
    tie %object, 'Tie::Scalar::Null' => \%object;

    $object{x} = "Hello";
    is($object{x}, "Hello, world", "sanity check 6");

    {
	my $set = set(\%object);
	$object{x} = "I'd like to buy you a coke";
	my ($member) = $set->members;
	is($member->{x},
	   "I'd like to buy you a coke, world", "sanity check 7");
	$set->weaken;
	$object{x} = "You're the one";
	is($object{x}, "You're the one, world",
	   "weak_set magic doesn't interfere with tie magic");
	is_deeply(Set::Object::get_magic(\%object), [$$set], "Magic detected");
    }
    is($object{x}, "You're the one, world",
       "hash not ruined by _dispel_magic");

    is_deeply(Set::Object::get_magic(\%object), undef, "Magic removed");
    $object{y} = "Catch the light";
    is($object{y}, "Catch the light, world",
       "tie magic not interefered with by _dispel_magic");
}

# now do it the other way around...
{
    my %object;

    {
	my $set = set(\%object);
	$set->weaken;

	tie %object, 'Tie::Scalar::Null' => \%object;

	my ($member) = $set->members;
	$member->{x} = "I'm almost over XS for one day";
	is($member->{x},
	   "I'm almost over XS for one day, world", "sanity check 8");
	is_deeply(Set::Object::get_magic(\%object), [$$set],
		  "Magic detected");
    }
    is_deeply(Set::Object::get_magic(\%object), undef, "Magic removed");
    $object{y} = "Yep, that's enough";
    #Dump(\%object);
    is($object{y}, "Yep, that's enough, world",
       "tie magic not interefered with by _dispel_magic [reverse]");
}

require Set::Object::Weak;
no strict 'subs';
Set::Object::Weak->import(weak_set);
my $s = Set::Object::Weak->new([]);
is($s->size, 0, "Set::Object::Weak->new()");
$s = weak_set([]);
is($s->size, 0, "weak_set()");

# ok, may as well put it there too
my $ws = Set::Object::weak_set(["ø"]);
is($ws->size, 0, "Set::Object::weak_set");

# test example in the SYNOPSIS
$ws = Set::Object::Weak->new( 0, "", {}, [], (bless {}, "Object") );
is($ws->size, 2, "made a weak set");

$ws = Set::Object::Weak::set("one");
is($ws->size, 1, "Set::Object::Weak::set() inserts its arguments");

{package Tie::Scalar::Null;
 sub TIEHASH {
     my ($class) = @_;
     return bless {}, $class;
 }
 sub FETCH {
     $DB::single = 1;
     $_[0]->{$_[1]};
 }
 sub STORE {
     $DB::single = 1;
     $_[0]->{$_[1]} = "$_[2], world";
 }
 sub FIRSTKEY {
     each %{$_[0]};
 }
 sub NEXTKEY {
     each %{$_[0]};
 }
}

$set = Set::Object::weak_set(["ø"]) + Set::Object::weak_set(["þ"]);
is($set->size(), 2, "computations on sets don't care that they're weak");
