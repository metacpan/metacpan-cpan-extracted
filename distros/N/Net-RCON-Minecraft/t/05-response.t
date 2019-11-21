#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't/lib';
use Test::Exception;
use Test::More;
use Test::Exception;
use Local::Helpers;
use Net::RCON::Minecraft;

# Arrays to test strip, convert, and ignore color modes, respectively.
# Left side is input string, right is expected output.
# 3rd argument is an optional description. Otherwise, stripped 2nd is used.
my %tests = (
    "Plain string"                 => {
        plain => 'Plain string',
        ansi  => "Plain string\e[0m",
    },
    "Color \x{00a7}4middle"        => {
        plain => 'Color middle',
        ansi  => "Color \e[31mmiddle\e[0m",
    },
    "\x{00a7}3Color start"         => {
        plain => 'Color start',
        ansi  => "\e[36mColor start\e[0m",
    },
    "Color end\x{00a7}5"           => {
        plain => 'Color end',
        ansi  => "Color end\e[35m\e[0m",
    },
    "\x{00a7}3\x{00a7}4"           => {
        plain => '',
        ansi  => "\e[36m\e[31m\e[0m",
    },
    "\x{00a7}3Two \x{00a7}4colors" => {
        plain => 'Two colors',
        ansi  => "\e[36mTwo \e[31mcolors\e[0m",
    },
    "\x{00a7}aBright \x{00a7}2dark \x{00a7}abright" => {
        plain => 'Bright dark bright',
        ansi  => "\e[92mBright \e[32mdark \e[92mbright\e[0m",
    },
);

for (sort keys %tests) {
    my $id = 1 + int(rand(16384));
    my $resp = Net::RCON::Minecraft::Response->new(raw => $_, id => $id);
    my ($plain, $ansi, $raw)  = ($resp->plain, $resp->ansi, $resp->raw);
    is $raw,          $_,          'Raw matches';
    is $ansi,  $tests{$_}{ansi},   'ANSI is correct';
    is $plain, $tests{$_}{plain},  'Plain is correct';
    is $resp,  $tests{$_}{plain},  'Stringification';
    is $resp->id, $id,             'id';
    is length($resp), length($resp->plain), 'length';
}

# Stringification testing -- This is overkill, really, since
# overload q("") => sub { ... }, feedback => 1
# is pretty well-defined. But it serves as a reasonable sanity check.

# Shorthand Response generator. Inserts a color code.
sub str_test($&) {
    my ($val, $code) = @_;
    $_ = Net::RCON::Minecraft::Response->new(raw=>"\x{00a7}4$val", id=>1);
    $code->($_);
}

# String
str_test 'string' => sub {
    is $_, 'string', 'Basic stringification';
    ok( ($_ eq  'string'),          'eq eq');
    ok(!($_ eq  'tring'),           'ne eq');
    ok(!($_ ne  'string'),          'eq ne');
    ok( ($_ ne  'tring'),           'ne ne');
    ok( ($_ lt  'tring'),           'lt');
    ok( ($_ gt  'ring'),            'gt');
    is( ($_ cmp 'ring'),    1,      'cmp 1');
    is( ($_ cmp 'tring'),  -1,      'cmp -1');
    is( ($_ cmp 'string'),  0,      'cmp 0');
};

# Number
str_test 10 => sub {
    is 0+$_,        10,             '0+';
    is   $_,        10,             'Number ok';
    ok( ($_ == 10),                 '== ==');
    ok(!($_ == 11),                 '!= ==');
    ok( ($_ != 11),                 '!= !=');
    ok(!($_ != 10),                 '== !=');
    ok( ($_  < 11),                 '<');
    ok(!($_  < 10),                 '<');
    ok( ($_  >  9),                 '>');
    ok(!($_  > 10),                 '>');
    is   $_ + 1,    11,             '+';
    is   $_ - 5,     5,             '-';
    is   $_ * 5,    50,             '*';
    like $_ / 3,  qr/^3.333/,       '/';
};

str_test 10 => sub {
    $_++;
    is   $_,        11,             '++';
    is   ref($_),   '',             'No longer magic';
};

str_test 10 => sub {
    $_--;
    is  $_,          9,             '--';
};

# These operators change their operand
for my $op (qw<+= -= *= /= &= ^=>) {
    str_test 12 => sub {
        my $want = 12; eval "\$want $op 2";
        eval "\$_ $op 2";
        fail "$_ $op 2 failed: $@" if $@;
        is $_, $want, '$op';
    }
}

# Response.pod test:
str_test 'foo' => sub {
};

done_testing;
