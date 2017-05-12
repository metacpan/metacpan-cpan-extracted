use Test::More tests => 13;

BEGIN { use_ok('Path::Class::File::Lockable'); }

ok( my $file = Path::Class::File::Lockable->new(
        $ENV{TMPDIR} || '/tmp',
        'test_locker'
    ),
    "new lockable file"
);

my $now = time();

ok( $file->lock, "locked $file" );

ok( $file->locked, "$file is locked" );

ok( my ($info) = $file->lock_info, "lock info" );

like( $info, qr/^(.+?):(\d+)$/, "lock info looks sane" );

ok( my $user = $file->lock_owner, "get lock_owner" );
ok( my $time = $file->lock_time,  "get lock_time" );
ok( my $pid  = $file->lock_pid,   "get lock_pid" );

diag( "$file locked by $user at " . localtime($time) . " with pid $pid" );

cmp_ok( $time, '<=', time(), "lock time is in the past" );

cmp_ok( $time, '>=', $now, "lock time happened after test started" );

ok( $file->unlock, "unlocked file" );

ok( !$file->locked, "$file is not locked" );
