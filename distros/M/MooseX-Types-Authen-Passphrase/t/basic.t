use strict;
use warnings;

use Config;
use Test::More tests => 15;

use ok "MooseX::Types::Authen::Passphrase";

{
    package User;
    use Moose;

    use MooseX::Types::Authen::Passphrase qw(Passphrase);

    has pass => (
        isa => Passphrase,
        is  => "ro",
        coerce  => 1,
        handles => { check_password => "match" },
    );
}

# Do we really want this? It's potentially unsafe
#
#{
#    my $u = User->new( pass => "foo" );
#
#    isa_ok( $u->pass, "Authen::Passphrase::Clear" );
#
#    ok( $u->check_password("foo"), "password checking" );
#    ok( !$u->check_password("bar"), "password checking" );
#}

{
    my $u = User->new( pass => "{SSHA}ixZcpJbwT507Ch1IRB0KjajkjGZUMzX8gA==" );

    isa_ok( $u->pass, "Authen::Passphrase::SaltedDigest" );

    ok( $u->check_password("foo"), "password checking" );
    ok( !$u->check_password("bar"), "password checking" );
}

SKIP: {
    skip("crypt() not available on this system", 3) unless $Config{d_crypt};

    my $u = User->new( pass => crypt("foo", "bar") );

    isa_ok( $u->pass, "Authen::Passphrase" );

    ok( $u->check_password("foo"), "password checking" );
    ok( !$u->check_password("bar"), "password checking" );
}

{
    my $u = User->new( pass => "tBj5zsTY1lI2U" ); # htpasswd

    isa_ok( $u->pass, "Authen::Passphrase" );

    ok( $u->check_password("foo"), "password checking" );
    ok( !$u->check_password("bar"), "password checking" );
}

SKIP: {
    my $u = eval { User->new( pass => '$apr1$c4MWh/..$96Phdbo3dGt3LcRQ46iZ2/' ) }; # htpasswd -m

    skip "not implemented by Authen::Passphrase", 3 if $@ and $@ =~ /unimplemented/i;

    isa_ok( $u->pass, "Authen::Passphrase" );

    ok( $u->check_password("foo"), "password checking" );
    ok( !$u->check_password("bar"), "password checking" );
}

{
    my $u = User->new( pass => undef );

    isa_ok( $u->pass, "Authen::Passphrase::RejectAll" );

    ok( !$u->check_password("foo"), "password checking" );
}
