#!/usr/bin/perl
# Tests without connection (generates and returns SQL)
use Test::More;
use Data::Dumper;
$Data::Dumper::Indent = 0;
use lib '..';
plan(tests => 20);
use_ok('StoredHash');
my $ent = {'brand' => 'Mercury', 'cycle' => 2, 'power' => 300,};
my $p = StoredHash->new('table' => 'Motors', 'pkey' => ['id'],);

makequeries($p, $ent, [32]);

my $ent2 = {'name' => 'Bill Hill', 'ctry' => 31, 'ssn' => 19857354,};
my $p2 = StoredHash->new('table' => 'People', 'pkey' => ['ctry','ssn',],);
makequeries($p2, $ent2, [31,'19857354',]);
ok(1, "Made a set of queries");
sub makequeries {
 my ($p, $ent, $idvs) = @_;
 my @vals = StoredHash::allentvals($ent);
 #print(Dumper(\@vals)."\n");
 
 my $qi = $p->insert($ent);
 ok($qi =~ /INSERT INTO /, "Created Insert");
 my $qu = $p->update($ent, $idvs);
 ok($qu =~ /UPDATE /, "Created Update");
 my $qe = $p->exists($idvs);
 ok($qe, "Tested Presence");
 my $ql = $p->load($idvs);
 ok($ql =~ /SELECT /, "Load by SELECT");
 #my $cnt = $p->count({$p->{'pkey'}->[0], $idvs->[0]});
 #print("CNT:$cnt\n");
 #ok($cnt > 0, "Got Count from table ($cnt)");
 my $qd = $p->delete($ent, $idvs);
 ok($qd =~ /DELETE FROM/, "Delete");
 my $qc = $p->count();
 ok($qc =~ /COUNT/, "Count query 1 has KW COUNT");
 ok($qc !~ /WHERE/i, "No WHERE part in unfiltered count ($qc)");
 my $qc2 = $p->count({'some' => 'val'});
 ok($qc2 =~ /COUNT/, "Count query 2 has KW COUNT");
 ok($qc2 =~ /WHERE/i, "HAS WHERE part with filter ($qc2)");
 my @queries = ($qi, $qu, $qe, $ql, $qd);
 #print(map({"$_;\n";} @queries), "\n\n");
 
}
