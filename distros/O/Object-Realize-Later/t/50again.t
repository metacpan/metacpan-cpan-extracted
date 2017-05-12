#!/usr/bin/perl -w

#
# Test re-realization
#

use strict;
use Test;

use lib 't', '.', 't/testmods', 'testmods';
use C::D::E;

BEGIN { plan tests => 8 }

my $warntxt;
sub catchwarn {$warntxt = "@_"};


# Autoload via C::D because of request from A::B

my $obj  = C::D->new;
my $copy = $obj;

{   local $SIG{__WARN__} = \&catchwarn;
    ok($obj->a_b eq 'a_b');  # triggers autoload
}

ok($warntxt, qr/^Realization of C::D /);
ok(ref $obj    eq 'A::B');

ok(ref $copy   eq 'C::D');
{   local $SIG{__WARN__} = \&catchwarn;
    ok($copy->a_b eq 'a_b');  # triggers autoload for the second time
}

#warn "$warntxt\n";
ok($warntxt =~ /^Attempt to realize object again: old reference caught at/);
ok(ref $copy   eq 'A::B');
ok($copy eq $obj);
