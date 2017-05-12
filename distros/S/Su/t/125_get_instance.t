use Test::More tests => 4;
use lib qw(lib ../lib t/test125);
use Su base => './t/test125';

my $su = Su->new;

my $inst = $su->get_proc('main');

ok( $inst->{model} );

# diag( explain( $inst->{model} ) );
is_deeply( $inst->{model}, { key1 => 'value1' } );

$inst = $su->get_instance('main');
ok( $inst->{model} );

is_deeply( $inst->{model}, { key1 => 'value1' } );
