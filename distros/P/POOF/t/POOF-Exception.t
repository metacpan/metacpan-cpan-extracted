# perl -T
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl POOF-DataType.t'

#########################
use Test::More;
BEGIN
{
    plan tests => 5;
};
use_ok(qw(POOF::Exception));

#########################

my $e1 = POOF::Exception->new(
    code => 500,
    description => 'some bad error',
    value => 'badvalue'
);

isa_ok(
    $e1,
    'POOF::Exception',
    'Making sure we have a valid object'
);

ok(($e1->{'code'} == 500
    ? 1
    : 0 ), 'Checking the code');

ok(($e1->{'description'} eq 'some bad error'
    ? 1
    : 0 ), 'Checking the description');

ok(($e1->{'value'} eq 'badvalue'
    ? 1
    : 0 ), 'Checking the value');




