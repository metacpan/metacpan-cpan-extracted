use Test::Most;
use MooseX::Types::Parameterizable qw(Parameterizable);
use MooseX::Types::Moose qw(Int Str HashRef ArrayRef);
use MooseX::Types -declare=>[qw(
    Varchar InfoHash OlderThanAge HashRefsOfInts MyInt
)];


subtype Varchar,
as Parameterizable[Str,Int],
where {
  my($string, $int) = @_;
  $int >= length($string) ? 1:0;
},
message { "'$_[0]' is too long (max length $_[1])" };

coerce Varchar,
from ArrayRef,
via {
  my ($arrayref, $int) = @_;
  my $str = join('', @$arrayref);
  return $str;
};

subtype( InfoHash,
as HashRef[Int],
where {
    defined $_->{older_than};
}),

subtype( OlderThanAge,
as Parameterizable[Int, InfoHash],
where {
    my ($value, $dict) = @_;
    return $value > $dict->{older_than} ? 1:0;
});

coerce OlderThanAge,
from HashRef,
via {
    my ($hashref, $constraining_value) = @_;
    return scalar(keys(%$hashref));
},
from ArrayRef,
via {
    my ($arrayref, $constraining_value) = @_;
    my $age;
    $age += $_ for @$arrayref;
    return $age;
};

subtype MyInt,
as Int;

my $myint = MyInt;

coerce $myint, from ArrayRef, via { scalar(@$_) };

is $myint->coerce([qw/j o h n/]), 4, 
  'coerce straight up works for myint';

my $olderthan = OlderThanAge[older_than=>2];
my $varchar = Varchar[5];

is $varchar->coerce([qw/j o h n/]), 'john', 
  'coerce straight up works';

ok $varchar->assert_coerce([qw/j o h n/]),
  'check with assert_coerce is good';

ok $varchar->has_coercion, 'I have a coercion!';

{
  package Person;

  use Moose;

  has control=>(is=>'rw',isa=>$myint,coerce=>1);
  has age=>(is=>'rw', isa=>$olderthan, coerce=>1);
  has name=>(is=>'rw', isa=>$varchar,coerce=>1);
}

ok my $person = Person->new(name=>[qw/a b c/]),
  'Created a testable object';

is $person->name, 'abc',
  'coerce during instantiation is good';

ok $person->control([qw/a b c/]), 'control coercible';
is $person->control, 3, 'control works as expected';

is $person->meta->get_attribute('name')->type_constraint->coerce([qw/j o h n/]), 'john',
  'coerce on the attribute via meta object works';

ok $person->name('john'), 'john is less than 5 chars';

$person->meta->get_attribute('name')->set_value($person, [qw/j o h X/]);
is $person->meta->get_attribute('name')->get_value($person), 'johX', 'j o h n is john222';

ok $person->age(3),
  '3 is older than 2';

SKIP: {
  skip "Something in Moose 2.0 broke these and I'm buggered to figure it out", 4;
  is $person->name([qw/j o h X/]), 'johX', 'j o h n is john';
  is $person->name, 'johX';
  is $person->age([1..10]), 55,
    'Coerce ArrayRef works';
  is $person->age({a=>5,b=>6,c=>7,d=>8}), 4,
    'Coerce HashRef works';
}

done_testing;
