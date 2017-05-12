use Test::More tests => 2;

use Riak::Light;

ok( !defined $namespace::autoclean::VERSION,
    "should not load namespace::autoclean"
);
ok( !defined $Class::MOP::VERSION, "should not load Class::MOP" );
