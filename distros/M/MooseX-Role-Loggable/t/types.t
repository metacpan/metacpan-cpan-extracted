#!perl
# GH #1 by Peter Shangov
# making sure both Log::Dispatchouli and L::D::Proxy work

use Test::More tests => 6;
use Test::Fatal;

{
    package MyTestZASD2;
    use Moo;
    with 'MooseX::Role::Loggable';
}

my $class = 'MyTestZASD2';
my $object;

is(
    exception {
        $object = $class->new(
            logger => Log::Dispatchouli->new( { ident => 'me' } )
        )
    },
    undef,
    'Able to create class with logger Log::Dispatchouli',
);

isa_ok( $object,         $class              );
isa_ok( $object->logger, 'Log::Dispatchouli' );

my $proxy = $object->logger->proxy;
isa_ok( $proxy, 'Log::Dispatchouli::Proxy' );

is(
    exception { $class->new( logger => $proxy ) },
    undef,
    'Able to create class with logger Log::Dispatchouli::Proxy',
);

like(
    exception { $class->new( logger => bless {}, 'BASDz7ad' ) },
    qr/must be a Log::Dispatchouli object/,
    'Still cannot create class with bad logger',
);

