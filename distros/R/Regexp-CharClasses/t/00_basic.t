#!/usr/bin/perl

use Test::More tests => 2;

use strict;
use warnings;
no warnings 'syntax';

BEGIN {
    use_ok ('Regexp::CharClasses')
};

ok (defined $Regexp::CharClasses::VERSION, "VERSION is set");

__END__
