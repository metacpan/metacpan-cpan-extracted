use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::Util;

local $t::Util::EVAL = 1;

test('if cond => namespace', <<'END', {if => 0}, {}, {Exporter => 0});
use if $] => Exporter;
END

test('if cond => string', <<'END', {if => 0}, {}, {Exporter => 0});
use if $] => "Exporter";
END

test('if cond => namespace', <<'END', {if => 0}, {}, {'Test::More' => 0});
use if $] => Test::More;
END

test('if cond => string', <<'END', {if => 0}, {}, {'Test::More' => 0});
use if $] => "Test::More";
END

test('cond may have commas', <<'END', {if => 0}, {}, {'Test::More' => 0});
use if [1, 2 => 3] => "Test::More";
END

test('cond may have commas', <<'END', {if => 0}, {}, {'Test::More' => 0});
use if [1, 2 => qw/foo/] => "Test::More";
END

local $t::Util::EVAL = 0;

test('with open pragma', <<'END', {if => 0}, {}, {open => 0}); # AUDREYT/OurNet-BBS-1.67/lib/OurNet/BBS/ScalarFile.pm
use if ($^O eq 'MSWin32'), open => (IN => ':bytes', OUT => ':bytes');
END

test('with open pragma', <<'END', {if => 0}, {}, {open => 0}); # AUDREYT/OurNet-BBS-1.67/lib/OurNet/BBS/ScalarFile.pm
use if $OurNet::BBS::Encoding, open => ":encoding($OurNet::BBS::Encoding)";
END

done_testing;
