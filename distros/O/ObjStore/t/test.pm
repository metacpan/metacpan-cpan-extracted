# Please feel free to contribute more better tests!

package test;
#use Carp qw(verbose carp croak);
use Carp;
use Test;
#use Cwd;
#use DynaLoader ();
#BEGIN { unshift @DynaLoader::dl_library_path, getcwd."blib/arch/auto/ObjStore"; }
use ObjStore;
use ObjStore::Config;
require Exporter;
@ISA = 'Exporter';
@EXPORT = qw(&test_db &open_db $db);

#ObjStore::debug qw(txn);
#$ObjStore::REGRESS = 1;

if (1) {
    $SIG{__WARN__} = sub {
	my $m = $_[0];
	if ($m !~ m/ line \s+ \d+ (\.)? $/x) {
	    warn $m;
	} else {
	    print "# [WARNING] $_[0]"; #hide from Test::Harness
	}
    };
}

sub test_db() { $ObjStore::Config::TMP_DBDIR . "/perltest" }

sub open_db() {
    $db = ObjStore::open(test_db(), 'update');
    die if $@; #extra paranoia
    $db;
}

END { 
#    $db->close;
    ok(1);
}

1;
