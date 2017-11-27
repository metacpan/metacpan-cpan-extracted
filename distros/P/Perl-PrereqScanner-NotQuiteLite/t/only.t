use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Test::More;
use t::Util;

# taken from only.pm SYNOPSIS
test('only bare => version', <<'END', {only => 0, MyModule => '0.30'});
use only MyModule => 0.30;
END

test('only bare => version spec', <<'END', {only => 0, MyModule => 0});
use only MyModule => '0.30-0.50 !0.36 0.55-', qw(:all);
END

test('only bare => version spec', <<'END', {only => 0, MyModule => 0});
use only MyModule =>
    [ '0.20-0.27', qw(f1 f2 f3 f4) ],
    [ '0.30-',     qw(:all) ];
END

test('only {}, module => version', <<'END', {only => 0, MyModule => '0.33'});
use only {versionlib => '/home/ingy/perlmods'},
    MyModule => 0.33;
END

test('only {}', <<'END', {only => 0});
use only {versionlib => '/home/ingy/perlmods'};
END

test('only qw/bare version/', <<'END', {only => 0, 'Test::More' => 0.88});
use only qw/Test::More 0.88/;
END

done_testing;
