#
# This file is part of MooX-Options
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package t::Test;
use strict;
use warnings;
use Test::More;
use Import::Into;
use POSIX qw/setlocale LC_ALL/;

sub import {
    $ENV{LC_ALL} = 'C';
    setlocale( LC_ALL, 'C' );
    my $target = caller;
    strict->import::into($target);
    warnings->import::into($target);
    Test::More->import::into($target);
}

1;
