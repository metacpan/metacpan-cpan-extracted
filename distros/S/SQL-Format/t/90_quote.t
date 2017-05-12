use strict;
use warnings;
use Test::More;
use SQL::Format;
use t::Util;

subtest 'scalar' => sub {
    my $got = SQL::Format::_quote('foo');
    is $got, '`foo`';
};

subtest '*' => sub {
    my $got = SQL::Format::_quote('*');
    is $got, '*';
};

subtest 'scalar ref' => sub {
    my $got = SQL::Format::_quote(\'foo');
    is $got, 'foo';
};

subtest 'name_sep' => sub {
    my $got = SQL::Format::_quote('foo.bar');
    is $got, '`foo`.`bar`';
};

subtest 'quoted' => sub {
    my $got = SQL::Format::_quote('`foo`');
    is $got, '`foo`';
};

subtest 'name_sep and quoted' => sub {
    my $got = SQL::Format::_quote('`foo`.`bar`');
    is $got, '`foo`.`bar`';
};

subtest 'skip function' => sub {
    my $got = SQL::Format::_quote('UNIX_TIMSTAMP()');
    is $got, 'UNIX_TIMSTAMP()';
};

subtest 'undefined quote_char' => sub {
    local $SQL::Format::QUOTE_CHAR = undef;
    my $got = SQL::Format::_quote('foo.bar');
    is $got, 'foo.bar';
};

subtest 'undefined name_sep' => sub {
    local $SQL::Format::NAME_SEP = undef;
    my $got = SQL::Format::_quote('foo.bar');
    is $got, 'foo.bar';
};

done_testing;
