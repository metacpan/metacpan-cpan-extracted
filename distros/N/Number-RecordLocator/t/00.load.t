use Test::More tests => 12;

BEGIN {
use_ok( 'Number::RecordLocator' );
}

diag( "Testing Number::RecordLocator $Number::RecordLocator::VERSION" );

my $gen = Number::RecordLocator->new();

can_ok($gen, 'encode');
can_ok($gen, 'decode');

is($gen->encode('1'),'3', "We skip one and zero so should end up with 3 when encoding 1");

is($gen->encode('12354'),'F44');
is ($gen->encode('123456'),'5RL2');
is ($gen->decode('5RL2'), '123456');

is($gen->decode($gen->encode('123456')), '123456');
is($gen->decode($gen->encode('81289304929241823')), '81289304929241823');

is($gen->decode('1234'),$gen->decode('I234'));
is($gen->decode('10SB'),$gen->decode('IOFP'));

is ($gen->encode('A'),undef);



1;
