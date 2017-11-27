use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../../";
use Test::More;
use t::Util;

test('eval string with a semicolon', <<'END', {}, {'Test::Pod' => '1.00'});
eval "use Test::Pod 1.00;";
END

test('eval string without a semicolon', <<'END', {}, {'Test::Pod' => '1.00'});
eval 'use Test::Pod 1.00';
END

test('eval in qq{}', <<'END', {}, {'Test::Pod' => '1.00'});
eval qq{use Test::Pod 1.00}
END

test('eval in qq++', <<'END', {}, {'Test::Pod' => 0});
eval qq+use Test::Pod+
END

test('eval in qq()', <<'END', {}, {'Test::Pod' => 0});
eval qq(use Test::Pod)
END

test('eval in q<>', <<'END', {}, {'Test::Pod' => 0});
eval q< use Test::Pod>
END

test('eval in q//', <<'END', {}, {'Test::Pod' => 0});
eval  q/use Test::Pod/
END

test('RT #19302', <<'END', {}, {'Test::Pod' => 0});
my $ver=1.22;
eval "use Test::Pod $ver;"
END

test('ditto', <<'END', {}, {'Test::Pod' => 0});
my $ver=1.22;
eval 'use Test::Pod $ver';
END

test('no space between eval and string', <<'END', {}, {'Test::Pod' => '1.00'});
eval"use Test::Pod 1.00;";
END

test('ditto', <<'END', {}, {'Test::Pod' => '1.00'});
eval'use Test::Pod 1.00';
END

test('eval block', <<'END', {}, {'Test::Pod' => 0});
eval { use Test::Pod }
END

test('block in eval block', <<'END', {}, used(qw/Test::Pod Test::Pod::Coverage/));
eval { use Test::Pod; { use Test::Pod::Coverage; } }
END

test('block in eval block', <<'END', {}, used(qw/Test::Pod Test::Pod::Coverage/));
eval { { use Test::Pod; } use Test::Pod::Coverage }
END

done_testing;
