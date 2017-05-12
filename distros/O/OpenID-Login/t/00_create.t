use Test::More tests => 2;
BEGIN { use_ok('OpenID::Login') }

my $o = OpenID::Login->new();
isa_ok( $o, 'OpenID::Login' );
