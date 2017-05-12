use strict;
use Test::More;
use Shodo;

my $shodo = Shodo->new();
my $suzuri = $shodo->new_suzuri();
$suzuri->params( param => { isa => 'Int' } );

ok !$suzuri->validate({ param => 'foo' });

done_testing();
