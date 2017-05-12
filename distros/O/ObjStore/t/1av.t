#-*-perl-*-
use Test; plan tests => 32;

use ObjStore;
use lib './t';
use test;
use ObjStore::Test qw(testofy_av);

#use Devel::Peek qw(Dump SvREFCNT);
#ObjStore::debug qw(refcnt bridge splash);

&open_db;
require ObjStore::REP::Splash;

begin 'update', sub {
    my $john = $db->root('John');
    $john or die "no db";
    
    $rep = 'ObjStore::REP::Splash::AV';
    testofy_av(31, sub { &{$rep.'::new'}('ObjStore::AV', $john->segment_of, 7) });
};
die if $@;
