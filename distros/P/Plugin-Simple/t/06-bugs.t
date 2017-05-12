#!/usr/bin/perl
use strict;
use warnings;

use File::Copy;
use Plugin::Simple;
use Test::More;

{ #4
    eval { plugins('X::X', can => [ 'exec' ]); };
    like ($@, qr/package .* can't be found/, "#4 we croak if package not found");
}
{ #5
    copy 't/base/Testing.pm', 'Testing.pm';
    my $p = plugins('Testing.pm');

    my $ret = $p->hello;
    is ($ret, 'hello, world!', 'plugin package in cwd works');

    undef $p;

    unlink 'Testing.pm' or die $!;
    ok (! -e 'Testing.pm', "test file unlinked ok");
}
done_testing();

