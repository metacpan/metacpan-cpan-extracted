package PGOTest;
use PGObject::Util::DBMethod;

sub call_dbmethod {
    my $self = shift @_;
    %args = @_;
    my @retarray = (\%args);
    return @retarray;
}

sub new {
    my ($self) = shift @_;
    my %args = @_;
    $self = \%args if %args;
    $self ||= {};
    bless $self;
}

dbmethod(strictargtest => 
    strict_args => 1,
    funcname => 'foo',
    funcschema => 'foo2',
    args => {id => 1}
);

dbmethod(strictundefargtest => 
    strict_args => 1,
    funcname => 'foo',
    funcschema => 'foo2',
    args => {id => undef}
);

dbmethod nostrictargtest => (
    funcname => 'foo',
    funcschema => 'foo2',
    args => {id => 1}
);

dbmethod objectstest => (
    returns_objects => 1,
    funcname => 'foo',
    funcschema => 'foo2',
    args => {id => 1}
);

dbmethod mergetest => (
    funcname => 'foo',
    funcschema => 'foo2',
    merge_back => 1,
    args => {id => 1}
);

dbmethod arglisttest => (
     funcname => 'foo',
     funcschema => 'foo',
     arg_list => ['id']
);

package main;
use Test::More tests => 36;

ok(my $test = PGOTest::new({}), 'Test object constructor success');

ok(my ($ref) = $test->strictargtest(args => {id => 2, foo => 1}), 
     'Strict Arg Test returned results.');

is($ref->{funcname}, 'foo', 'strict arg test, funcname correctly set');
is($ref->{funcschema}, 'foo2', 'strict arg test, funcschema correctly set');
is($ref->{args}->{id}, 1, 'strict arg test, id arg correctly set');
is($ref->{args}->{foo}, 1, 'strict arg test, foo arg correctly set');

ok(($ref) = $test->strictundefargtest(args => {id => 2, foo => 1}), 
     'Strict Arg Test returned results.');

is($ref->{funcname}, 'foo', 'strict arg test, funcname correctly set');
is($ref->{funcschema}, 'foo2', 'strict arg test, funcschema correctly set');
is($ref->{args}->{id}, undef, 'strict arg test, id arg correctly unset');
is($ref->{args}->{foo}, 1, 'strict arg test, foo arg correctly set');

ok($ref = $test->strictundefargtest(args => {id => 2, foo => 1}), 
     'Strict Arg Test returned results, scalar context.');

is($ref->{funcname}, 'foo', 'strict arg test (scalar), funcname correctly set');
is($ref->{funcschema}, 'foo2', 'strict arg test (scalar), funcschema correctly set');
is($ref->{args}->{id}, undef, 'strict arg test (scalar), id arg correctly unset');
is($ref->{args}->{foo}, 1, 'strict arg test (scalar), foo arg correctly set');

ok(($ref) = $test->nostrictargtest(args => {id => 2, foo => 1}), 
     'No Strict Arg Test returned results.');

is($ref->{funcname}, 'foo', 'no strict arg test, funcname correctly set');
is($ref->{funcschema}, 'foo2', 'no strict arg test, funcschema correctly set');
is($ref->{args}->{id}, 2, 'no strict arg test, id arg correctly set');
is($ref->{args}->{foo}, 1, 'no strict arg test, foo arg correctly set');

ok(($ref) = $test->objectstest(args => {id => 2, foo => 1}), 
     'Objects Test returned results.');

is($ref->{funcname}, 'foo', 'no strict arg test, funcname correctly set');
is($ref->{funcschema}, 'foo2', 'no strict arg test, funcschema correctly set');
is($ref->{args}->{id}, 2, 'no strict arg test, id arg correctly set');
is($ref->{args}->{foo}, 1, 'no strict arg test, foo arg correctly set');
isa_ok($ref, 'PGOTest', 'Return reference is blessed');

ok $ref = $test->mergetest(args => {id2 => 1}), 'merge test successfully returned';
is $test->{funcname}, 'foo', 'merge test merged funcname';
is $test->{funcschema}, 'foo2', 'merge test merged funcschema';
is $test->{args}->{id2}, 1, 'Merged args id2';
is $test->{args}->{id}, 1, 'Merged args id from arg';

ok(($ref) = $test->arglisttest(1), 'Arg List Test returned results.');
is($ref->{funcname}, 'foo', 'no strict arg test, funcname correctly set');
is($ref->{funcschema}, 'foo', 'no strict arg test, funcschema correctly set');
is($ref->{args}->{id}, 1, 'no strict arg test, id arg correctly set');
