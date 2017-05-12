#!perl
use Test::More tests => 36;

use strict;

BEGIN { use_ok('Module::Checkstyle::Util', qw(:all)); } # 1

# Formating strings
is(format_expected_err(1,     2)    , q(Expected '1' but got '2')); # 2
is(format_expected_err(undef, 0)    , q(Expected '' but got '0')); # 3
is(format_expected_err("foo", "foo"), q(Expected 'foo' but got 'foo')); # 4

# Booleans
is(as_true('y')   , 1); # 5
is(as_true('yes') , 1); # 6
is(as_true('true'), 1); # 7
is(as_true('TrUe'), 1); # 8
is(as_true('n'),    0); # 9
is(as_true('nope'), 0); # 10
is(as_true(undef),  0); # 11
is(as_true(""),     0); # 12

# Numerics
is(as_numeric(undef), 0); # 13
is(as_numeric("0"),   0); # 14
is(as_numeric("foo"), 0); # 15
is(as_numeric("-2"), -2); # 16
is(as_numeric("10"), 10); # 17

# Regular expressions
isa_ok(as_regexp('/a/'), 'Regexp'); # 18
ok(!defined as_regexp(undef)); # 19
ok(!defined as_regexp('')); # 20
ok(as_regexp('qr/foo/')); # 21

# Curlies
is(is_valid_position('same'), 1); # 22
is(is_valid_position('sAMe'), 1); # 23
is(is_valid_position('alone'), 1); # 24
is(is_valid_position('none'), 0); # 35

# Alignment
is(is_valid_align('left'), 1); # 26
is(is_valid_align('lEFt'), 1); # 27
is(is_valid_align('middle'), 1); # 28
is(is_valid_align('right'), 1); # 29
is(is_valid_align('none'), 0); # 30

{
    my $problem = new_problem('ERROR', 'test', [0], 'file.pl');
    is($problem->get_severity, 'ERROR'); # 31
    is($problem->get_message,  'test'); # 32
    is($problem->get_line,     0); # 33
    is($problem->get_file,     'file.pl'); # 34
}

{
    use Module::Checkstyle::Config;
    my $config = Module::Checkstyle::Config->new(\<<'END_OF_CONFIG');
[Test00Base]
test-1 = ERROR foo

[Test00Base::Child]
test-2 = CRITICAL bar
END_OF_CONFIG

    my $problem = Module::Checkstyle::Check::Test00Base->new_problem($config);
    is($problem->get_severity, 'ERROR'); # 35

    $problem = Module::Checkstyle::Check::Test00Base::Child->new_problem($config);
    is($problem->get_severity, 'CRITICAL'); # 36
}    

package Module::Checkstyle::Check::Test00Base;
sub new_problem {
    my $config = pop;
    return ::new_problem($config, 'test-1', undef, undef, undef);
}

package Module::Checkstyle::Check::Test00Base::Child;
sub new_problem {
    my $config = pop;
    return ::new_problem($config, 'test-2', undef, undef, undef),
}

1;
