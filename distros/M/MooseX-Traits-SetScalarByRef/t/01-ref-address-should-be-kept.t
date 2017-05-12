# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl MooseX-Traits-SetScalarByRef.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 2;
use Scalar::Util qw(refaddr);
BEGIN { use_ok('MooseX::Traits::SetScalarByRef') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

{
    package Local::Example;
    use Moose;
    use Moose::Util::TypeConstraints;

    subtype 'TkRef', as 'ScalarRef';
    coerce 'TkRef', from 'Str', via { my $r = $_; return \$r };

    has _some_val => (
        traits   => [ 'MooseX::Traits::SetScalarByRef' ],
        isa      => 'TkRef',
        init_arg => 'some_val',
        default  => 'default value',
        handles  => 1,
    );
}

my $eg = Local::Example->new;
my $ref_addr = refaddr($eg->some_val);
$eg->some_val("new string");
my $refaddr_after_change = refaddr($eg->some_val);
ok($ref_addr eq $refaddr_after_change, "refaddr should not have changed");