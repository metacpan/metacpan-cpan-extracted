use ObjStore;
use ObjStore::Config;

begin 'update', sub {
    my $f = $ObjStore::Config::TMP_DBDIR . "/FatTree.test";
    $db = ObjStore::open($f, 'update', 0666);
};
die if $@;

1;
