#!/usr/bin/perl -w

#
# Test the autoloading() where becomes => STRING
#

use strict;
use Test;

use lib 't', '.', 't/testmods', 'testmods';
use C::D::E;

BEGIN { plan tests => 17 }

my $warntxt;
sub catchwarn {$warntxt = "@_"};


# Autoload via C::D because of request from A::B

my $obj = C::D->new;
ok($obj->c_d eq 'c_d');
ok($obj->c   eq 'c'  );

{   local $SIG{__WARN__} = \&catchwarn;
    ok($obj->a_b eq 'a_b');  # triggers autoload
}
ok($warntxt, qr/^Realization of C::D /);
ok(ref $obj  eq 'A::B');


# Autoload via C::D::E because of request from A::B

$obj = C::D::E->new;
ok($obj->c_d_e eq 'c_d_e');
ok($obj->c_d   eq 'c_d');
ok($obj->c     eq 'c'  );

{   local $SIG{__WARN__} = \&catchwarn;
    ok($obj->a_b eq 'a_b');  # triggers autoload
}
ok($warntxt, qr/^Realization of C::D::E /);
ok(ref $obj  eq 'A::B');



# Autoload via C::D because of request from A

$obj = C::D->new;

{   local $SIG{__WARN__} = \&catchwarn;
    ok($obj->a eq 'a');  # triggers autoload
}
ok($warntxt, qr/^Realization of C::D /);
ok(ref $obj  eq 'A::B');


# Autoload via C::D::E because of request from A

$obj = C::D::E->new;

{   local $SIG{__WARN__} = \&catchwarn;
    ok($obj->a eq 'a');  # triggers autoload
}
ok($warntxt, qr/^Realization of C::D::E /);
ok(ref $obj  eq 'A::B');

