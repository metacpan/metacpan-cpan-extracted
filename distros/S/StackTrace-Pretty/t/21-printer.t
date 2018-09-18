use strict;
use warnings;
use utf8;

use lib qw(lib .);

use Test::More;
use t::Util;

BEGIN {
    use_ok 'StackTrace::Pretty::Printer';
}

subtest '_extract_func_and_line_num' => sub {
    subtest 'first line' => sub {
        my $line = first_line_st();
        my $ret = StackTrace::Pretty::Printer->_extract_func_and_line_num($line);
        is_deeply $ret, {
            dest_func => undef,
            filename => 't/Util.pm',
            lineno => first_line_lineno(),
        };
    };

    subtest 'child line' => sub {
        my $line = child_line_st();
        my $ret = StackTrace::Pretty::Printer->_extract_func_and_line_num($line);
        like $ret->{dest_func}, qr/^Some::Module::some_func\('?Some::Module=HASH\(0x[0-9a-f]+\)'?, ['"]Test Arg['"], '?HASH\(0x[0-9a-f]+\)'?\)$/;
        is $ret->{filename}, 't/Util.pm';
        is $ret->{lineno}, child_line_lineno();
    };
};

done_testing;
