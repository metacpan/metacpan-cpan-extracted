#!perl -w

use warnings;
use strict;
use Test::More tests => 20;

BEGIN {
        use_ok( 'Samba::LDAP' );
        use_ok( 'Samba::LDAP::Config');
        use_ok( 'Samba::LDAP::Group');
        use_ok( 'Samba::LDAP::User');

}

# Test trivial creation for Samba::LDAP
my $triv = Samba::LDAP->new();
ok( $triv, '->new returns true' );
ok( ref $triv, '->new returns a reference' );
isa_ok( $triv, 'HASH' , '->new returns a hash reference' );
isa_ok( $triv, 'Samba::LDAP', '->new returns a Samba::LDAP object' );
#ok( scalar keys %$triv == 3, '->new returns an object with 3 attributes' );

# Test trivial creation for Samba::LDAP::Config
my $triv_config = Samba::LDAP::Config->new();
ok( $triv_config, '->new returns true' );
ok( ref $triv_config, '->new returns a reference' );
isa_ok( $triv_config, 'HASH' , '->new returns a hash reference' );
isa_ok( $triv_config, 'Samba::LDAP::Config', '->new returns a Samba::LDAP::Config object' );
#ok( scalar keys %$triv_config == 0, '->new returns an empty object' );

# Test trivial creation for Samba::LDAP::Group
my $triv_group = Samba::LDAP::Group->new();
ok( $triv_group, '->new returns true' );
ok( ref $triv_group, '->new returns a reference' );
isa_ok( $triv_group, 'HASH' , '->new returns a hash reference' );
isa_ok( $triv_group, 'Samba::LDAP::Group', '->new returns a Samba::LDAP::Group object' );
#ok( scalar keys %$triv_group == 3, '->new returns an empty object' );

# Test trivial creation for Samba::LDAP::User
my $triv_user = Samba::LDAP::User->new();
ok( $triv_user, '->new returns true' );
ok( ref $triv_user, '->new returns a reference' );
isa_ok( $triv_user, 'HASH' , '->new returns a hash reference' );
isa_ok( $triv_user, 'Samba::LDAP::User', '->new returns a Samba::LDAP::User object' );
#ok( scalar keys %$triv_user == 3, '->new returns an empty object' );
