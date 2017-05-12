#!perl -T

use Test::More tests => 5;

# test raised from rt72822

{
    package MockShout;
    sub new   { bless { say => $_[1] }, $_[0] }
    sub shout { uc $_[0]->{say} }
}

use PerlX::QuoteOperator qObj => { 
    -emulate => 'q', 
    -with    => sub ($) { MockShout->new($_[0]) },
};

# this works
my $t = qObj(snafu);
is $t->shout, 'SNAFU', 'scalar method method call works';

# so does this
is(
    (qObj(hunky dory))->shout, 
    'HUNKY DORY',
    'parenthesising method call works'
);

# but not below unless the parser is enabled
use PerlX::QuoteOperator qObj2 => { 
    -parser  => 1,
    -emulate => 'q', 
    -with    => sub ($) { MockShout->new($_[0]) },
};

is(
    qObj2/foo bar baz/->shout, 
    'FOO BAR BAZ', 
    "Parser works with same delimiter (/)"
);

is(
    qObj2(i like brackets)->shout, 
    'I LIKE BRACKETS', 
    "Parser works with brackets ()"
);

is(
    qObj2{i like braces}->shout, 
    'I LIKE BRACES', 
    "Parser works with braces {}"
);

