#!/usr/bin/perl -w

#
# Test the autoloading() where becomes => CODE
#

use strict;
use Test;

use lib 't', '.', 't/testmods', 'testmods';
use C::G::H;

BEGIN { plan tests => 17 }

my $warntxt;
sub catchwarn {$warntxt = "@_"};


# Autoload via C::G because of request from A::B

my $obj = C::G->new;
ok($obj->c_g eq 'c_g');
ok($obj->c   eq 'c'  );

{   local $SIG{__WARN__} = \&catchwarn;
    ok($obj->a_b eq 'a_b');  # triggers autoload
}
ok($warntxt, qr/^Realization of C::G /);
ok(ref $obj  eq 'A::B');


# Autoload via C::G::H because of request from A::B

$obj = C::G::H->new;
ok($obj->c_g_h eq 'c_g_h');
ok($obj->c_g   eq 'c_g');
ok($obj->c     eq 'c'  );

{   local $SIG{__WARN__} = \&catchwarn;
    ok($obj->a_b eq 'a_b');  # triggers autoload
}
ok($warntxt, qr/^Realization of C::G::H /);
ok(ref $obj  eq 'A::B');



# Autoload via C::G because of request from A

$obj = C::G->new;

{   local $SIG{__WARN__} = \&catchwarn;
    ok($obj->a eq 'a');  # triggers autoload
}
ok($warntxt, qr/^Realization of C::G /);
ok(ref $obj  eq 'A::B');


# Autoload via C::G::H because of request from A

$obj = C::G::H->new;

{   local $SIG{__WARN__} = \&catchwarn;
    ok($obj->a eq 'a');  # triggers autoload
}
ok($warntxt, qr/^Realization of C::G::H /);
ok(ref $obj  eq 'A::B');

