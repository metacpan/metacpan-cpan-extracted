use Test2::V0;
use MojoX::Linda;

can_ok( 'MojoX::Linda', $_ ) for ( qw( conf run ) );

my $mock = mock 'Mojo::Server::Morbo' => (
    override => [
        run => sub {},
    ],
);

ok( lives { MojoX::Linda::run( MojoX::Linda::conf({}) ) }, 'MojoX::Linda::run' ) or note $@;

done_testing;
