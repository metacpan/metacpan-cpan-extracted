#-------------------------------------------------------------------
#
#   $Id: 07_test_error_messages.t,v 1.6 2009/06/01 20:43:06 erwan_lemonnier Exp $
#

package main;

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Test::More;
use Data::Dumper;
use Carp qw(croak confess longmess);

BEGIN {

    use check_requirements;
    plan tests => 9;

    use_ok("Sub::Contract",'contract');
};

#------------------------------------------------------------
#
# test errors in condition code
#
#------------------------------------------------------------

sub foo {
    return 1;
}

sub _die {
    die "whatever";
}

# test die from a sub
my $c = contract('foo')
    ->invariant(\&_die)
    ->enable;

eval { foo(); };
ok($@ =~ /whatever at .*07_test_error_messages.t line 34/, "condition dies with correct error message (called sub)");

# test die called from contract def
$c->reset
    ->invariant(sub {
	die "enough!!";
    })
    ->enable;

eval { foo(); };
ok($@ =~ /enough!! at .*07_test_error_messages.t line 48/, "condition dies with correct error message (anonymous sub)");

# test croak
$c->reset
    ->invariant(sub {
	croak "croaking now";
    })
    ->enable;

eval { foo(); };
ok($@ =~ /croaking now at .*07_test_error_messages.t line 62/, "condition croaks with correct error message (anonymous sub)");

# test confess
$c->reset
    ->invariant(sub {
	confess "confessing now";
    })
    ->enable;

eval { foo(); };

ok($@ =~ /confessing now at .*07_test_error_messages.t line 72/, "condition confesses with correct error message (anonymous sub)");

#------------------------------------------------------------
#
# test constraint failures
#
#------------------------------------------------------------

# invariant before
$c->reset->invariant( sub { return 0; } )->enable;
eval { foo(); };
ok($@ =~ /invariant fails before calling main::foo at .*\n.*main::contract_foo\(\) called at .*07_test_error_messages.t line 84\n.*at .*07_test_error_messages.t line 84/, "invariant fails before");

# invariant after
my $count = 0;
$c->reset->invariant( sub { $count++; return $count != 1; } )->enable;
eval { foo(); };
ok($@ =~ /invariant fails before calling main::foo at .*\n.*main::contract_foo\(\) called at .*07_test_error_messages.t line/, "invariant fails before");

# pre fails
$c->reset->pre( sub { return 0; } )->enable;
eval { foo(); };
ok($@ =~ /pre-condition fails before calling main::foo at .*\n.*main::contract_foo\(\) called at .*07_test_error_messages.t line/, "pre condition fails");

# post fails
$c->reset->post( sub { return 0; } )->enable;
eval { foo(); };
ok($@ =~ /post-condition fails after calling main::foo at .*\n.*main::contract_foo\(\) called at .*07_test_error_messages.t line 100.*\n.*07_test_error_messages.t line 100/mg, "post condition fails");

# TODO: add more tests

