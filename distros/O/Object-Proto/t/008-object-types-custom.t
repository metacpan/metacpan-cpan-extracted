#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Object::Proto;

# ==== Test XS-level type registration API ====
# This tests the Perl-level API, but demonstrates the pattern
# that XS modules would use at the C level

# The C-level API works like this (in an external .xs file):
#
#   #include "object_types.h"
#
#   static bool check_positive_int(pTHX_ SV *val) {
#       if (!SvIOK(val) && !looks_like_number(val)) return false;
#       return SvIV(val) > 0;
#   }
#
#   BOOT:
#       object_register_type_xs(aTHX_ "PositiveInt", check_positive_int, NULL);
#
# The registered C function is called directly from the setter op
# with no Perl callback overhead (~5 cycles vs ~100 cycles)

# For now, test with Perl callbacks (same flow, different overhead)
Object::Proto::register_type('PositiveInt', sub {
    my $val = shift;
    return defined($val) && $val =~ /^-?\d+$/ && $val > 0;
});

Object::Proto::register_type('NonEmptyStr', sub {
    my $val = shift;
    return defined($val) && !ref($val) && length($val) > 0;
});

Object::Proto::register_type('Email', sub {
    my $val = shift;
    return defined($val) && !ref($val) && $val =~ /@/;
});

# Register type with coercion
Object::Proto::register_type('TrimmedStr',
    sub { defined($_[0]) && !ref($_[0]) },  # check
    sub { my $v = shift; $v =~ s/^\s+|\s+$//g; $v }  # coerce
);

# Verify types are registered
ok(Object::Proto::has_type('PositiveInt'), 'PositiveInt registered');
ok(Object::Proto::has_type('NonEmptyStr'), 'NonEmptyStr registered');
ok(Object::Proto::has_type('Email'), 'Email registered');
ok(Object::Proto::has_type('TrimmedStr'), 'TrimmedStr registered');

# Use custom types in class definition
Object::Proto::define('User',
    'id:PositiveInt:required',
    'name:NonEmptyStr:required',
    'email:Email',
    'bio:TrimmedStr',
);

# Test valid construction
my $user = new User id => 42, name => 'Alice', email => 'alice@example.com';
is($user->id, 42, 'PositiveInt accepts positive integer');
is($user->name, 'Alice', 'NonEmptyStr accepts non-empty string');
is($user->email, 'alice@example.com', 'Email accepts email');

# Test type failures
eval { new User id => 0, name => 'Bob' };
like($@, qr/Type constraint failed for 'id'/,
    'PositiveInt rejects 0');

eval { new User id => -5, name => 'Bob' };
like($@, qr/Type constraint failed for 'id'/,
    'PositiveInt rejects negative');

eval { new User id => 1, name => '' };
like($@, qr/Type constraint failed for 'name'/,
    'NonEmptyStr rejects empty string');

# Test setter type check
my $u2 = new User id => 1, name => 'Test';
eval { $u2->id(0) };
like($@, qr/Type constraint failed for 'id'/,
    'Setter checks PositiveInt');

eval { $u2->id(-1) };
like($@, qr/Type constraint failed for 'id'/,
    'Setter checks PositiveInt negative');

# Successful setter
$u2->id(100);
is($u2->id, 100, 'Setter accepts valid PositiveInt');

# Test list_types includes custom types
my $types = Object::Proto::list_types();
ok((grep { $_ eq 'PositiveInt' } @$types), 'PositiveInt in list_types');
ok((grep { $_ eq 'NonEmptyStr' } @$types), 'NonEmptyStr in list_types');
ok((grep { $_ eq 'Email' } @$types), 'Email in list_types');

# Test duplicate registration fails
eval { Object::Proto::register_type('PositiveInt', sub { 1 }) };
like($@, qr/already registered/,
    'Cannot re-register existing type');

done_testing;
