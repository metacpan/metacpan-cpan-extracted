use strict;
use Carp;
 
BEGIN { print "1..300\n"; };
END { print "not ok 1\n" unless $::loaded; RDFStore::debug_malloc_dump(); eval{ rmtree('cooltest'); }; };

sub ok
{
    my $no = shift ;
    my $result = shift ;
 
    print "not " unless $result ;
    print "ok $no\n" ;
}
 
sub docat
{
    my $file = shift;
    local $/ = undef;
    open(CAT,$file) || die "Cannot open $file:$!";
    my $result = <CAT>;
    close(CAT);
    return $result;
};

use File::Path qw(rmtree);

eval{
rmtree('cooltest');
};

use URI;
use RDFStore;
use RDFStore::RDFNode;
use RDFStore::Literal;
use RDFStore::Resource;

$::loaded = 1;
print "ok 1\n";

my $tt=2;

# some basic fuzzy tests of the API
my $imt="ftp://ftp.isi.edu/in-notes/iana/assignments/media_types/";
ok $tt++, my $foo = new RDFStore::Resource "${imt}text/","html";
ok $tt++, my $bar = new RDFStore::Resource "${imt}text/html";
ok $tt++, $foo->equals($bar);
ok $tt++, my $baz = new RDFStore::Resource ( new URI( "${imt}text/html" ) );
ok $tt++, $foo->equals($baz);
ok $tt++, my $buz = new RDFStore::Resource ( "http://xmlhack.com/" );
ok $tt++, ($buz->getLocalName eq 'http://xmlhack.com/');
ok $tt++, !($buz->getNamespace);
ok $tt++, my $biz = new RDFStore::Resource ( "http://xmlhack.com/rss10.php" );
ok $tt++, ($biz->getLocalName eq 'rss10.php');
ok $tt++, ($biz->getNamespace eq 'http://xmlhack.com/');
ok $tt++, my $s=new RDFStore::Resource('http://aaa.com/#test');
ok $tt++, my $p=new RDFStore::Resource('http://purl.org/dc/elements/1.1/creator');
ok $tt++, my $o=new RDFStore::Resource('ac');
ok $tt++, ($o->isa("RDFStore::Resource"));
ok $tt++, ($o->isa("RDFStore::RDFNode"));
ok $tt++, ($s->getNamespace eq 'http://aaa.com/#');
ok $tt++, ($s->getLocalName eq 'test');
ok $tt++, ($p->getNamespace eq 'http://purl.org/dc/elements/1.1/');
ok $tt++, ($p->getLocalName eq 'creator');
ok $tt++, !($o->isbNode);
ok $tt++, ($o->equals( new RDFStore::Resource('ac') ));
ok $tt++, my $o1=new RDFStore::Literal( 'this is a test', undef, 'en', 'http://wwww/w/dattype' );
ok $tt++, ($o1->toString eq 'this is a test');
ok $tt++, !($o1->getParseType);
ok $tt++, ($o1->getLang eq 'en');
ok $tt++, ($o1->getDataType eq 'http://wwww/w/dattype');
ok $tt++, my $o2=new RDFStore::Literal( 'dddd 1,2,3', 1, 'fff' );
ok $tt++, ($o2->equals( 'dddd 1,2,3' ) );
ok $tt++, ($o2->getParseType);
ok $tt++, ($o2->getLang eq 'fff');
ok $tt++, ($o2->getDataType eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral');
ok $tt++, my $st = new RDFStore::Statement( $s, $p, $o );
ok $tt++, ($st->toString eq '<http://aaa.com/#test> <http://purl.org/dc/elements/1.1/creator> <ac> . ');
ok $tt++, ($st->isReified == 0);
ok $tt++, ($st->subject->equals( $s ));
ok $tt++, ($st->predicate->equals( $p ));
ok $tt++, ($st->object->equals( $o ));
ok $tt++, my $st1 = new RDFStore::Statement( $s, $p, $o, undef, 1, new RDFStore::Resource('http://www/A/B/C') );
ok $tt++, ($st1->isReified == 1);
ok $tt++, ($st1->subject->equals( $s ));
ok $tt++, ($st1->predicate->equals( $p ));
ok $tt++, ($st1->object->equals( $o ));
ok $tt++, my $n = new RDFStore::Resource('http://www/A/B/C');
ok $tt++, my $st2 = new RDFStore::Statement( $s, $p, $o2, undef, 1, $n );

ok $tt++, my $rdfstore=new RDFStore(undef,0,1); #in-memory
#ok $tt++, my $rdfstore=new RDFStore 'cooltest0',0,1; #on local disk
#ok $tt++, my $rdfstore=new RDFStore 'cooltest0',0,1,0,1,'localhost'; #on remote (localhost) dbmsd
# 48
ok $tt++, ($rdfstore->size == 0);

#ok $tt++, my $rdfstore1=new RDFStore; #in-memory
# 49
ok $tt++, my $rdfstore1=new RDFStore 'cooltest'; #on local disk
#ok $tt++, my $rdfstore1=new RDFStore 'cooltest',0,0,0,1,'localhost'; #on remote (localhost) dbmsd
# 50
ok $tt++, ($rdfstore1->size == 0);

# to be checked for the reification EXIST stuff (duplicates), assert both yes/no and so on....
#ok $tt++, $rdfstore->insert( $st );
#ok $tt++, $rdfstore->insert( $st2 );
#ok $tt++, $rdfstore->insert( $st1 );
#print "HERE????\n";

#use Benchmark;
#timethese( 10, {
#test1 => sub {
#for(1..10000) {
#$rdfstore1->insert( new RDFStore::Resource("http://www.w3.org/Home/Lassila/".$_, "Creator"), new RDFStore::Resource("http://description.org/schema/".$_, "Author"), new RDFStore::Literal("Ora Lassila") );
#};
#} 
#} );
#exit;

#51
ok $tt++, ($rdfstore->insert( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator"), new RDFStore::Resource("http://description.org/schema/", "Author"), new RDFStore::Literal( "Ora Lassila" ) ));
ok $tt++, ($rdfstore1->insert( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator"), new RDFStore::Resource("http://description.org/schema/", "Author"), new RDFStore::Literal( "Ora Lassila" ) ));

#53
ok $tt++, ($rdfstore->size == 1);
ok $tt++, ($rdfstore1->size == 1);

ok $tt++, ($rdfstore->contains( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator"), new RDFStore::Resource("http://description.org/schema/", "Author"), new RDFStore::Literal( "Ora Lassila" ) ));
ok $tt++, ($rdfstore1->contains( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator"), new RDFStore::Resource("http://description.org/schema/", "Author"), new RDFStore::Literal( "Ora Lassila" ) ));

ok $tt++, !($rdfstore->insert( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator"), new RDFStore::Resource("http://description.org/schema/", "Author"), new RDFStore::Literal( "Ora Lassila" ) ));
ok $tt++, !($rdfstore1->insert( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator"), new RDFStore::Resource("http://description.org/schema/", "Author"), new RDFStore::Literal( "Ora Lassila" ) ));

for ( my $i=0; $i<10 ; $i++) {
	ok $tt++, ($rdfstore->insert( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator".$i), new RDFStore::Resource("http://description.org/schema/", "Author"), new RDFStore::Literal("Ora Lassila".$i) ));
	ok $tt++, ($rdfstore1->insert( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator".$i), new RDFStore::Resource("http://description.org/schema/", "Author"), new RDFStore::Literal("Ora Lassila".$i) ));

	ok $tt++, ($rdfstore->contains( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator".$i), new RDFStore::Resource("http://description.org/schema/", "Author"), new RDFStore::Literal("Ora Lassila".$i) ));
	ok $tt++, ($rdfstore1->contains( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator".$i), new RDFStore::Resource("http://description.org/schema/", "Author"), new RDFStore::Literal("Ora Lassila".$i) ));

	ok $tt++, ($rdfstore->remove( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator".$i), new RDFStore::Resource("http://description.org/schema/", "Author"), new RDFStore::Literal("Ora Lassila".$i) ));
	ok $tt++, ($rdfstore1->remove( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator".$i), new RDFStore::Resource("http://description.org/schema/", "Author"), new RDFStore::Literal("Ora Lassila".$i) ));
	};
for ( my $i=0; $i<10 ; $i++) {
	my $s = new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator".$i);
	my $p = new RDFStore::Resource("http://description.org/schema/", "Author");
	my $o = new RDFStore::Literal("Ora Lassila".$i);
	my $st = new RDFStore::Statement( $s, $p, $o );

	ok $tt++, ($rdfstore->insert( $st ));
	ok $tt++, ($rdfstore1->insert( $st ));
	ok $tt++, ($rdfstore->contains( $st ));
	ok $tt++, ($rdfstore1->contains( $st ));
	ok $tt++, ($rdfstore->remove( $st ));
	ok $tt++, ($rdfstore1->remove( $st ));
	};

ok $tt++, $rdfstore->set_source_uri("hdhhdhddhdh");
ok $tt++, ( $rdfstore->get_source_uri eq "hdhhdhddhdh");

ok $tt++, ($rdfstore->size == 1);
ok $tt++, ($rdfstore1->size == 1);

my @today=( "TODAY:", 't'.time() );
my $today = new RDFStore::Resource(@today);
ok $tt++, ($rdfstore->set_context( $today ));
ok $tt++, ($rdfstore1->set_context( $today ));
ok $tt++, ($rdfstore->insert( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator"), new RDFStore::Resource("http://description.org/schema/", "Creator"), new RDFStore::Literal("Ora Lassila") ));
ok $tt++, ($rdfstore1->insert( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator"), new RDFStore::Resource("http://description.org/schema/", "Creator"), new RDFStore::Literal("Ora Lassila") ));

ok $tt++, ($rdfstore->get_context->equals( $today ) );
ok $tt++, ($rdfstore1->get_context->equals( $today ) );
ok $tt++, ($rdfstore->reset_context);
ok $tt++, ($rdfstore1->reset_context);
ok $tt++, ! (my $sg = $rdfstore->get_context);
ok $tt++, ! (my $sg1 = $rdfstore1->get_context);

my @yesterday=( "YESTERDAY:", 'y'.(time()-86400) );
my $yesterday = new RDFStore::Resource(@yesterday);
ok $tt++, ($rdfstore->set_context( $yesterday ));
ok $tt++, ($rdfstore1->set_context( $yesterday ));
ok $tt++, ($rdfstore->get_context->equals( $yesterday ) );
ok $tt++, ($rdfstore1->get_context->equals( $yesterday ) );
ok $tt++, ($rdfstore->insert( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator"), new RDFStore::Resource("http://description.org/schema/", "Creator"), new RDFStore::Literal("Ora Lassila") ));
ok $tt++, ($rdfstore1->insert( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator"), new RDFStore::Resource("http://description.org/schema/", "Creator"), new RDFStore::Literal("Ora Lassila") ));
ok $tt++, !($rdfstore->insert( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator"), new RDFStore::Resource("http://description.org/schema/", "Creator"), new RDFStore::Literal("Ora Lassila") ));
ok $tt++, !($rdfstore1->insert( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator"), new RDFStore::Resource("http://description.org/schema/", "Creator"), new RDFStore::Literal("Ora Lassila") ));
ok $tt++, ($rdfstore->contains( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator"), new RDFStore::Resource("http://description.org/schema/", "Creator"), new RDFStore::Literal("Ora Lassila"), $yesterday ));
ok $tt++, ($rdfstore1->contains( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator"), new RDFStore::Resource("http://description.org/schema/", "Creator"), new RDFStore::Literal("Ora Lassila"), $yesterday ));
ok $tt++, ($rdfstore->contains( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator"), new RDFStore::Resource("http://description.org/schema/", "Creator"), new RDFStore::Literal("Ora Lassila"), $today ));
ok $tt++, ($rdfstore1->contains( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator"), new RDFStore::Resource("http://description.org/schema/", "Creator"), new RDFStore::Literal("Ora Lassila"), $today ));

ok $tt++, my $iterator = $rdfstore->elements;

eval {
	my $i=0;
	while( my $s = $iterator->each ) {
		#print $s->toString."\n";
		$i++;
		};
	die unless($i==3);
};
ok $tt++, !$@;

ok $tt++, ($rdfstore->insert( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator"), new RDFStore::Resource("http://description.org/schema/", "Creator"), new RDFStore::Literal("This is a nice test to be checked; it is using ~!@#$%^&*() very funny chars and the free-text engine should cope with it.....") ));
ok $tt++, ($rdfstore->insert( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator"), new RDFStore::Resource("http://description.org/schema/", "Creator"), new RDFStore::Literal("This is a another nice test to be checked; Alberto is also in this now....") ));

ok $tt++, ($rdfstore->reset_context);
ok $tt++, ($rdfstore1->reset_context);
ok $tt++, ($rdfstore->insert( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator"), new RDFStore::Resource("http://description.org/schema/", "Creator"), new RDFStore::Literal("Ora Lassila") ));
ok $tt++, ($rdfstore->remove( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator"), new RDFStore::Resource("http://description.org/schema/", "Creator"), new RDFStore::Literal("Ora Lassila"), $yesterday ));
ok $tt++, ($rdfstore->remove( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator"), new RDFStore::Resource("http://description.org/schema/", "Creator"), new RDFStore::Literal("Ora Lassila") ));

ok $tt++, ($rdfstore->insert( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator"), new RDFStore::Resource("http://description.org/schema/", "Creator"), new RDFStore::Literal("art") ));
ok $tt++, ($rdfstore->insert( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator"), new RDFStore::Resource("http://description.org/schema/", "Creator"), new RDFStore::Resource("art") ));
ok $tt++, ($rdfstore->insert( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator"), new RDFStore::Resource("http://description.org/schema/", "Creator"), new RDFStore::Literal("art and handycraft") ));
ok $tt++, ($rdfstore->insert( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator"), new RDFStore::Resource("http://description.org/schema/", "Creator"), new RDFStore::Resource("art and handycraft") ));

ok $tt++, ($iterator = $rdfstore->search(	{
						"s" => [ new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator") ],
						"o" => [ new RDFStore::Literal("art") ],
						} ));
ok $tt++, ($iterator->size == 1);
ok $tt++, ($iterator = $rdfstore->search(	{
						"s" => [ new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator") ],
						"o" => [ new RDFStore::Resource("art") ],
						} ));
ok $tt++, ($iterator->size == 1);
ok $tt++, ($iterator = $rdfstore->search(	{
						"s" => [ new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator") ],
						"o" => [ new RDFStore::Literal("art and handycraft") ],
						} ));
ok $tt++, ($iterator->size == 1);
ok $tt++, ($iterator = $rdfstore->search(	{
						"s" => [ new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator") ],
						"words" => [ "art" ],
						"words_op" => "and",
						} ));
ok $tt++, ($iterator->size == 2);
ok $tt++, ($iterator = $rdfstore->search(	{
						"s" => [ new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator") ],
						"words" => [ 'art','and','handycraft' ],
						} ));
ok $tt++, ($iterator->size == 3);

ok $tt++, ($iterator = $rdfstore->search(	{
						"s" => [ new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator") ],
						} ));
ok $tt++, ($iterator = $rdfstore->search(	{
						"s" => [ new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator") ],
						"words" => [ "This", "Alberto" ],
						"words_op" => "and",
						} ));
ok $tt++, ($iterator->size == 1);

eval {
	my $i=0;
	while( my $s = $iterator->each ) {
		#print $s->toString."\n";
		$i++;
		};
	die unless($i==1);
};
ok $tt++, !$@;

eval {
	my $i=0;
	while( my $s = $iterator->each_subject ) {
		#print $s->toString."\n";
		$i++;
		};
	die "i=$i and not 1" unless($i==1);
};
ok $tt++, !$@;

eval {
	my $i=0;
	while( my $s = $iterator->each_predicate ) {
		#print $s->toString."\n";
		$i++;
		};
	die unless($i==1);
};
ok $tt++, !$@;

eval {
	my $i=0;
	while( my $s = $iterator->each_object ) {
		#print $s->toString."\n";
		$i++;
		};
	die unless($i==1);
};
ok $tt++, !$@;

eval {
	my $i=0;
	while( my $s = $iterator->each_context ) {
		#print $s->toString."\n";
		$i++;
		};
	die unless($i==1);
};
ok $tt++, !$@;

eval {
my $i=0;
for (	my $s = $iterator->first;
	$iterator->hasnext;
	$s = $iterator->next ) {
	#print $s->toString."\n";
	#die unless $iterator->remove;
	$i++;
	};
#die if ($i <=> $iterator->size);
};
ok $tt++, !$@;

ok $tt++, $iterator = $rdfstore->elements;

eval {
	my $i=0;
	while( my $s = $iterator->each ) {
		#print $s->toString."\n";
		$i++;
		};
	die unless($i==8);
};
ok $tt++, !$@;

ok $tt++, $iterator  = new RDFStore::Iterator( $rdfstore  );
ok $tt++, my $iterator1 = new RDFStore::Iterator( $rdfstore1 );

ok $tt++, ($iterator->size == $rdfstore->size);
ok $tt++, ($iterator1->size == $rdfstore1->size);

ok $tt++, my $rdfstore2=new RDFStore;
ok $tt++, ($rdfstore2->set_context( $yesterday ));
ok $tt++, ($rdfstore2->insert( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator"), new RDFStore::Resource("http://description.org/schema/", "Creator"), new RDFStore::Literal("Ora Lassila") ));
ok $tt++, ! ($rdfstore2->insert( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator"), new RDFStore::Resource("http://description.org/schema/Creator"), new RDFStore::Literal("Ora Lassila") ));

ok $tt++, (my $iterator2 = $iterator->duplicate);
ok $tt++, ($iterator2 = $iterator2->complement );
ok $tt++, ($iterator2->size == 0 );
ok $tt++, (my $iterator3 = $iterator2->intersect( $iterator )->intersect( $iterator )->subtract( $iterator )->unite( $iterator )->exor( $iterator )->complement );

eval {
my $i=0;
for (	my $s = $iterator2->first;
	$iterator2->hasnext;
	$s = $iterator2->next ) {
	#print $s->toString."\n";
	die unless $iterator2->remove;
	$i++;
	};
#die if ($i <=> $iterator2->size);
};
ok $tt++, !$@;

eval {
my $i=0;
for (	my $s = $iterator3->first;
	$iterator3->hasnext;
	$s = $iterator3->next ) {
	#print $s->toString."\n";
	die unless $iterator3->remove;
	$i++;
	};
#die if ($i <=> $iterator3->size);
};
ok $tt++, !$@;

# integer range searches
for my $i ( qw{ 1 11 22 111 123 222 1111 2222 33 3333 } ) {
	ok $tt++, ($rdfstore->insert( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator"), new RDFStore::Resource("http://description.org/schema/", "value"), new RDFStore::Literal( $i ) ));
	};

ok $tt++, ($iterator = $rdfstore->search(	{
						"ranges" => [ "33" ],
						"ranges_op" => "a > b"
						} ));
#print $iterator->size."\n";
ok $tt++, ($iterator->size == 6);

ok $tt++, ($iterator = $rdfstore->search(	{
						"ranges" => [ "33" ],
						"ranges_op" => "a != b"
						} ));
#print $iterator->size."\n";
ok $tt++, ($iterator->size == 9);

# date range searches
for my $i ( 1..30 ) {
	ok $tt++, ($rdfstore->insert( new RDFStore::Resource("http://www.w3.org/Home/Lassila/", "Creator"), new RDFStore::Resource("http://description.org/schema/", "date"), new RDFStore::Literal( "2004-11-".sprintf("%02d",$i),0, undef, "http://www.w3.org/2001/XMLSchema#date"  ) ));
	};

ok $tt++, ($iterator = $rdfstore->search(	{
						"ranges" => [ "2004-11-15" ],
						"ranges_op" => "a < b"
						} ));
#print $iterator->size."\n";
ok $tt++, ($iterator->size == 14);

ok $tt++, ($iterator = $rdfstore->search(	{
						"ranges" => [ "2004-11-10", "2004-11-15" ],
						"ranges_op" => "a < b < c"
						} ));
#print $iterator->size."\n";
ok $tt++, ($iterator->size == 4);
