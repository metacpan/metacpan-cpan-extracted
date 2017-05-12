use strict;
use warnings;
use lib 'lib';
use File::Path;

use Test::More tests => 6;

use_ok( 'Sysync' );
use_ok( 'Sysync::File' );

open(LOG, ">/dev/null");
*LOG = *STDERR;

for my $folder (qw(stage stage-files))
{
    rmtree("./t/data/$folder");
    mkdir("./t/data/$folder");
}

my @FL;
my $sysync = Sysync::File->new({
    sysdir => "./t/data",
    log => *LOG,
});

ok( grep { $_ =~ /nobody:x:65534:65534:nobody:\/nonexistent:\/bin\/sh/ }
    split("\n", $sysync->get_host_ent('spoon')->{passwd}), 'passwd data looks ok' );

ok( grep { $_ =~ /waffle:x:999:foo/ }
    split("\n", $sysync->get_host_ent('spoon')->{group}), 'group data looks ok' );

# actually stage data
$sysync->update_all_hosts( hosts => { hosts => { spoon => {} } } );

# read ssh key for good measure
open(F, "./t/data/stage/spoon/etc/ssh/authorized_keys/foo");
@FL = <F>;
close(F);

ok($FL[0] =~ /waffle spoon/, "update_all_hosts built ssh key properly"); 

$sysync->update_host_files('spoon');

open(F, "./t/data/stage-files/spoon/etc/secret-data.conf");
@FL = <F>;
close(F);

ok($FL[0] =~ /Secret data!/, "update_host_files built file correctly"); 

for my $folder (qw(stage stage-files))
{
    rmtree("./t/data/$folder");
    mkdir("./t/data/$folder");
}

