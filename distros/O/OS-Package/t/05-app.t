use Test::More;

use_ok('OS::Package::Application');

my $app = OS::Package::Application->new(
    name    => 'test package',
    version => '1.0.0'
);

is( $app->name,    'test package' );
is( $app->version, '1.0.0' );

done_testing;
