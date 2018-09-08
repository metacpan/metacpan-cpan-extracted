use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Test::More;
use t::Util;

test('no pragma', <<'END', undef, undef, undef, {strict => 0, warnings => 0});
no strict;
no warnings;
END

test('no Module', <<'END', undef, undef, undef, {'FindBin' => 0, 'Time::Local' => 0});
no FindBin;
no Time::Local;
END

test('no Module Version', <<'END', undef, undef, undef, {'FindBin' => 0.01, 'Time::Local' => '0.02'});
no FindBin 0.01;
no Time::Local 0.02;
END

test('no v-string', <<'END', undef, undef, undef, {perl => 'v5.20.1'});
no v5.20.1;
END

test('no version_number', <<'END', undef, undef, undef, {perl => '5.008001'});
no 5.008001;
END

test('no Module ()', <<'END', undef, undef, undef, {'Time::Local' => 0});
no Time::Local ();
END

test('no Module version ()', <<'END', undef, undef, undef, {'Time::Local' => 0.01});
no Time::Local 0.01 ();
END

test('no Module qw(args)', <<'END', undef, undef, undef, {'Time::Local' => 0});
no Time::Local qw(timelocal);
END

test('no lib', <<'END', undef, undef, undef, {lib => 0, constant => 0, FindBin => 0});
no FindBin;
no lib "$FindBin::Bin/../lib";
no constant FOO => 'BAR';
END

done_testing;
