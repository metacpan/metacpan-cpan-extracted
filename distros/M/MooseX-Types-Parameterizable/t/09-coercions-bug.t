package Person;

use Test::More;

use Moose;
use MooseX::Types::Parameterizable qw(Parameterizable);
use MooseX::Types::Moose qw(Int Str HashRef ArrayRef);
use MooseX::Types -declare=>[qw(
    Varchar InfoHash OlderThanAge
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
#  die $str;
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


my $olderthan = OlderThanAge[older_than=>2];
my $varchar = Varchar[5];

has age=>(is=>'rw', isa=>$olderthan, coerce=>1);
has name=>(is=>'rw', isa=>$varchar,coerce=>1);

ok my $person = Person->new,
  'Created a testable object';

ok $person->name('john'), 'john is less than 5 chars';
is $person->name([qw/j o h n/]), 'john', 'j o h n is john';

ok $person->age(3),
  '3 is older than 2';
is $person->age([1..10]), 55,
  'Coerce ArrayRef works';
is $person->age({a=>5,b=>6,c=>7,d=>8}), 4,
  'Coerce HashRef works';

done_testing;
