use strict;
use warnings;
use Test::More;
use t::Util;

local $t::Util::EVAL = 1;

test('use pragma', <<'END', {strict => 0, warnings => 0});
use strict;
use warnings;
END

test('use Module', <<'END', {'FindBin' => 0, 'Time::Local' => 0});
use FindBin;
use Time::Local;
END

test('use Module Version', <<'END', {'FindBin' => 0.01, 'Time::Local' => '0.02'});
use FindBin 0.01;
use Time::Local 0.02;
END

test('use v-string', <<'END', {perl => 'v5.8.1'});
use v5.8.1;
END

test('use version_number', <<'END', {perl => '5.008001'});
use 5.008001;
END

test('use Module ()', <<'END', {'Time::Local' => 0});
use Time::Local ();
END

test('use Module version ()', <<'END', {'Time::Local' => 0.01});
use Time::Local 0.01 ();
END

test('use Module qw(args)', <<'END', {'Time::Local' => 0});
use Time::Local qw(timelocal);
END

test('use lib', <<'END', {lib => 0, constant => 0, FindBin => 0});
use FindBin;
use lib "$FindBin::Bin/../lib";
use constant FOO => 'BAR';
END

test('use in a block', <<'END', {'Test::More' => 0});
{use Test::More}
END

done_testing;
