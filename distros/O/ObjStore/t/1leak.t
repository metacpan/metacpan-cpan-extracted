# -*-perl-*- never leaks memory...

use strict;
use Test;
#eval { 
#    require Devel::Leak;
#    !$ObjStore::FEATURE{bridge_trace}
#} or do {
    plan test => 1;
    warn "# skipping leak test\n";
    exit;
#};

plan test => 3;
use ObjStore;
use lib './t';
use test;

&open_db;

use vars qw($G);

sub dotest {
    $G=undef;
    for (1..3) {
	begin sub {
	    $G = $db->root('John');
	    my $r = $G->new_ref;
	    #$r->_debug(1);
	    #$G->_debug(1);
	};
	die if $@;
    }
    $G=undef;
}

dotest();

use vars qw($snapshot);
my $count = Devel::Leak::NoteSV($snapshot);
my $tma = ObjStore::_typemap_any_count();

dotest();

ok Devel::Leak::CheckSV($snapshot), $count;
ok ObjStore::_typemap_any_count(), $tma;
