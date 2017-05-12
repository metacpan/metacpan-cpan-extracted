#!/usr/bin/perl

use 5.007002;
use strict;
use warnings;

use Test::More (tests => 7);
use File::Temp ('tempfile');
use constant TEMP => (tempfile(OPEN => 0))[1];

BEGIN { use_ok('PerlIO::via::trap', 'open') };

package fnord;
use Test::More;

sub test {
    my $mode = shift;
    local *FH;

    # this will happen twice
    ok(open(FH, $mode, main::TEMP), "open temp file with 3 args ($mode)") or die $!;

    # this will only happen once
    ok(print(FH "fnord\n"), 'print to temp file passed');

    close FH;
}

package main;

$PerlIO::via::trap::PASS = 1;
fnord::test('>');

$PerlIO::via::trap::PASS = 0;
eval { fnord::test('+<') };
like($@, qr/^attempt to write 6/, 'print to temp file trapped');

ok(open(my $fh, "+<" . TEMP), "open temp file with 2 args") or die $!;
is_deeply( [<$fh>], ["fnord\n"], "temp file contains the printed content" );
close $fh;

unlink(TEMP);

__END__
