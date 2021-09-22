use Test2::V0;

use Sub::Meta;

sub display { my @args = @_; return Sub::Meta->new(@args)->display }

is display(), 'sub(*) => *';
is display(is_method => 1), 'method(*) => *';
is display(subname => 'hello'), 'sub hello(*) => *';
is display(subname => 'hello', is_method => 1), 'method hello(*) => *';
is display(subname => 'hello', args => []), 'sub hello() => *';
is display(subname => 'hello', args => ['Str']), 'sub hello(Str) => *';
is display(subname => 'hello', args => ['Str', 'Int']), 'sub hello(Str, Int) => *';
is display(
    subname => 'hello',
    args => [{ type => 'Str', name => '$a' }]
   ), 'sub hello(Str $a) => *';

is display(
    subname => 'hello',
    args => [{ type => 'Str', name => '$a' }, { type => 'Int', name => '$i', named => !!1 }]
   ), 'sub hello(Str $a, Int :$i) => *';

is display(
    subname => 'hello',
    is_method => 1,
    args => [{ type => 'Str', name => '$a' }]
   ), 'method hello(Str $a) => *';

is display(
    subname => 'hello',
    invocant => { name => '$class' },
    args => [{ type => 'Str', name => '$a' }]
   ), 'method hello($class: Str $a) => *';

is display(
    subname => 'hello',
    slurpy => { name => '@values' },
    args => [{ type => 'Str', name => '$a' }]
   ), 'sub hello(Str $a, @values) => *';

is display(
    subname => 'hello',
    slurpy => { name => '@values' },
    args => []
   ), 'sub hello(@values) => *';

is display(
    subname => 'hello',
    args => [Sub::Meta::Param->new],
   ), 'sub hello() => *';

is display(
    subname => 'hello',
    slurpy => { name => '@values' },
   ), 'sub hello(@values) => *';

subtest 'returns' => sub {
    is display(
        returns => 'Int',
       ), 'sub(*) => Int';

    is display(
        returns => { scalar => 'Int', list => 'Str' },
       ), 'sub(*) => (scalar => Int, list => Str)';

    is display(
        returns => { scalar => 'Int', list => 'Int', void => 'Str' },
       ), 'sub(*) => (scalar => Int, list => Int, void => Str)';

    is display(
        returns => { list => 'Int' },
       ), 'sub(*) => (list => Int)';

    is display(
        returns => { void => 'Int' },
       ), 'sub(*) => (void => Int)';

    is display(
        returns => { scalar => ['Int','Str'] },
       ), 'sub(*) => (scalar => [Int,Str])';
};

done_testing;
