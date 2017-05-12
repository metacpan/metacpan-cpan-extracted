
use Test::More tests => 8;
use Search::Odeum;
use File::Path qw(rmtree);

my $db = './t/01_odeub.db';
my $od = Search::Odeum->new($db, OD_OCREAT|OD_OWRITER);

ok($od->sync);
isa_ok($od, 'Search::Odeum');
ok(-d $db);
is((stat($db))[1], $od->inode);
is($od->name, $db);
ok($od->fsiz);
ok($od->writable);
ok(time >= $od->mtime);
$od->close;

END {
    rmtree($db);
}
