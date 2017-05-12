#!/usr/bin/perl

use Test::More tests => 5;

use strict;
use warnings;
no warnings 'syntax';

BEGIN {
    use_ok ('Regexp::CharClasses')
};

ok 1 =~ /\p{IsDigit1}/, "testing 1 ";
ok 2 !~ /\p{IsDigit1}/, "testing 2 ";
ok 3 =~ /\P{IsDigit1}/, "testing 3 ";
ok 11 =~ /\p{IsDigit1}\p{IsDigit1}/, "testing 11 ";

__END__
