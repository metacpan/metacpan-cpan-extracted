use strict ;
 
BEGIN { print "1..130\n"; };
END { print "not ok 1\n" unless $::loaded; RDFStore::debug_malloc_dump(); eval{ rmtree('cooltest'); }; };

my $a = "";
local $SIG{__WARN__} = sub {$a = $_[0]} ;
 
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

#$::debug=1;

umask(0);

use RDFStore::NodeFactory;
use RDFStore::RDFNode;
use RDFStore::Literal;
use RDFStore::Model;

use File::Path qw(rmtree);
 
eval{
rmtree('cooltest');
};

$::loaded = 1;
print "ok 1\n";

my $tt=2;

ok $tt++, my $factory= new RDFStore::NodeFactory();

#node
ok $tt++, my $node = new RDFStore::RDFNode();

#literals
ok $tt++, my $literal = new RDFStore::Literal('cooltest',0,"en");
ok $tt++, my $literal1 = new RDFStore::Literal('esempio1',1,"it");
ok $tt++, !($literal->getParseType);
ok $tt++, ($literal->getLang eq 'en');
ok $tt++, ($literal1->getParseType);
ok $tt++, ($literal1->getLang eq 'it');
ok $tt++, ($literal->getLabel eq 'cooltest');
ok $tt++, ($literal1->getLabel eq 'esempio1');
ok $tt++, ($literal->toString eq 'cooltest');
ok $tt++, ($literal1->toString eq 'esempio1');
ok $tt++, ($literal->getDigest eq $literal1->getDigest) ? 0 : 1;

ok $tt++, my $statement = $factory->createStatement(
			$factory->createResource('http://www.w3.org/Home/Lassila'),
			$factory->createResource('http://description.org/schema/','Creator'),
			$factory->createLiteral('Ora Lassila') );
ok $tt++, my $subject = $statement->subject;
ok $tt++, ($subject->getLabel eq 'http://www.w3.org/Home/Lassila');
ok $tt++, ($subject->getURI eq 'http://www.w3.org/Home/Lassila');
ok $tt++, ($subject->toString eq 'http://www.w3.org/Home/Lassila');
ok $tt++, ($subject->getNamespace eq 'http://www.w3.org/Home/');
ok $tt++, ($subject->getLocalName eq 'Lassila');
ok $tt++, my $predicate = $statement->predicate;
ok $tt++, ($predicate->getLabel eq 'http://description.org/schema/Creator');
ok $tt++, ($predicate->getURI eq 'http://description.org/schema/Creator');
ok $tt++, ($predicate->toString eq 'http://description.org/schema/Creator');
ok $tt++, ($predicate->getNamespace eq 'http://description.org/schema/');
ok $tt++, ($predicate->getLocalName eq 'Creator');
ok $tt++, my $object = $statement->object;
ok $tt++, ($object->getLabel eq 'Ora Lassila');
ok $tt++, ($object->toString eq 'Ora Lassila');

ok $tt++, !(defined $statement->getNamespace);
ok $tt++, (defined $statement->getLocalName);

my $hc = $statement->getLocalName;		# undefined -- se above..

# ok $tt++, ($statement->getLocalName eq $hc);	
ok $tt++, (defined ($statement->getLocalName));
#ok $tt++,($statement->getLabel eq $hc);
ok $tt++, (defined ($statement->getLabel));
#ok $tt++, ($statement->getURI eq $hc);
ok $tt++, (defined ($statement->getURI));

ok $tt++, my $ntriple = $factory->createNTriple( '<http://www.w3.org/Home/Lassila> <http://description.org/schema/Creator> "Ora Lassila" .' );
ok $tt++, ( $statement->equals( $ntriple ) );

ok $tt++, my $ll = $factory->createLiteral('Ora Lissala');
ok $tt++, my $statement0 = $factory->createStatement(
			$factory->createResource('http://www.w3.org/Home/Lassila'),
			$factory->createResource('http://description.org/schema/','Author'),
			$ll
			);

ok $tt++, my $ntriple0 = $factory->createNTriple( '<http://www.w3.org/Home/Lassila> <http://description.org/schema/Author> "'.$ll->toString.'" .' );
ok $tt++, ( $statement0->equals( $ntriple0 ) );

ok $tt++, my $ntriple1 = $factory->createNTriple( '<http://www.w3.org/Home/Lassila> <http://description.org/schema/Creator> "Ora Lassila"@en .' );
ok $tt++, ( $ntriple1->object->getLang eq 'en' );
ok $tt++, !($ntriple1->object->getParseType);

ok $tt++, my $ntriple2 = $factory->createNTriple( '<http://www.w3.org/Home/Lassila> <http://description.org/schema/age> "<xml>24</xml>"^^<http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral> .' );
ok $tt++, ($ntriple2->object->getParseType);

ok $tt++, my $ntriple3 = $factory->createNTriple( '<http://www.w3.org/Home/Lassila> <http://description.org/schema/age> "2"^^<http://www.w3.org/2001/XMLSchema#integer> .' );
ok $tt++, !($ntriple3->object->getParseType);
ok $tt++, ( $ntriple3->object->getDataType eq "http://www.w3.org/2001/XMLSchema#integer" );

ok $tt++, my $ntriple4 = $factory->createNTriple( '<http://www.w3.org/Home/Lassila> <http://description.org/schema/Name> "Peter Pan"@en^^<http://www.w3.org/2001/XMLSchema#string> .' );
ok $tt++, ( $ntriple4->object->getLang eq 'en' );
ok $tt++, !($ntriple4->object->getParseType);
ok $tt++, ( $ntriple4->object->getDataType eq "http://www.w3.org/2001/XMLSchema#string" );

ok $tt++, my $statement1 = $factory->createStatement(
			$factory->createResource('http://www.w3.org/Home/Lassila'),
			$factory->createResource('http://description.org/schema/','Author'),
			$factory->createLiteral('Alberto Reggiori') );

ok $tt++, my $statement2 = $factory->createStatement(
		$factory->createResource('http://www.altavista.com'),
		$factory->createResource('http://somewhere.org/schema/1.0/#','author'),
		$factory->createLiteral('me') );

ok $tt++, my $statement3 = $factory->createStatement(
		$factory->createResource('http://www.google.com'),
		$factory->createResource('http://somewhere.org/schema/1.0/#creator'),
		$factory->createLiteral('you and me') );

ok $tt++, my $statement4 = $factory->createStatement(
		$factory->createResource('google'),
		$factory->createResource('http://somewhere.org/schema/1.0/#creator'),
		$factory->createLiteral('meMyselfI') );

# should be the same as the one just above
ok $tt++, my $statement4a = $factory->createStatement(
		$factory->createResource('google'),
		$factory->createResource('http://somewhere.org/schema/1.0/#','creator'),
		$factory->createLiteral('meMyselfI') );

ok $tt++, my $statement5 = $factory->createStatement(
		$factory->createUniqueResource(),
		$factory->createOrdinal(1),
		$factory->createLiteral('') );

ok $tt++, my $model = new RDFStore::Model(	Name => 'cooltest', 
						#Host => 'localhost',
						nodeFactory => $factory,
						Sync => 1, 
						FreeText => 1
						);
ok $tt++,  $model->setSourceURI('http://somewhere.org/');
my $now='t'.time;
my $ctx = $factory->createResource($now);
ok $tt++, $model->setContext($ctx);
ok $tt++, ( $factory->createResource($now)->equals( $model->getContext ) );
ok $tt++, ($model->getSourceURI eq 'http://somewhere.org/');
ok $tt++, ($model->toString eq 'Model[http://somewhere.org/]');
ok $tt++, !(defined $model->getNamespace);
my @date = gmtime( time() );
my $nowdateTime = sprintf( "%04d-%02d-%02dT%02d:%02d:%02dZ", 1900+int($date[5]), 1+int($date[4]), 
				int($date[3]), int($date[2]), int($date[1]), int($date[0]) );
ok $tt++, ! $model->ifModifiedSince( $nowdateTime );
sleep(1);
ok $tt++, $model->add($statement);
ok $tt++, $model->ifModifiedSince( $nowdateTime );
@date = gmtime( time() );
$nowdateTime = sprintf( "%04d-%02d-%02dT%02d:%02d:%02dZ", 1900+int($date[5]), 1+int($date[4]), 
				int($date[3]), int($date[2]), int($date[1]), int($date[0]) );
ok $tt++, ! $model->ifModifiedSince( $nowdateTime );
ok $tt++, $model->add($statement0);
ok $tt++, $model->add($statement1);
ok $tt++, $model->add($statement2);
ok $tt++, $model->add($statement3);
ok $tt++, $model->add($statement4);
ok $tt++, ! $model->add($statement4); #not done due to context above :)
ok $tt++, ! $model->add($statement4);
ok $tt++, ! $model->add($statement4a); #not done because same statemnt as above
ok $tt++, $model->resetContext(); #reset it for a moment
ok $tt++, $model->add($statement5);
ok $tt++, $model->setContext($factory->createResource($now));
ok $tt++, !($model->isEmpty);
ok $tt++, ($model->size == 7);
ok $tt++, ($model->contains($statement1,$ctx));
ok $tt++, ($model->isMutable);

eval {
	my $modeldd = new RDFStore::Model(	Name => 'cooltest', 
						nodeFactory => $factory,
						Mode => 'r' #read-only
						);
	#my $ee = $modeldd->elements;
	#while (my $s = $ee->each ) {
	#	print $s->toString,"\n";
	#	};
};
ok $tt++, !$@;

ok $tt++, my $found = $model->find($statement->subject,$statement->predicate,$statement->object);
#ok $tt++, my $found = $model->find($statement->subject,undef,$statement->object);
eval {
	my ($num) = $found->elements;
	die unless($num->size==1);
	my $ss = $num->first;
	#die unless( $model->contains($ss) );
	#die unless( $found->contains($ss) );
	die unless($ss->equals($statement));
};
ok $tt++, !$@;

eval {
	my $st;
	die unless($st=$found->elements);
	my $ss=$st->first;
	#die unless( $model->contains($ss) );
	#die unless( $found->contains($ss) );
	die unless($ss->equals($statement));
};
ok $tt++, !$@;

# unite
my $mu=$model->duplicate->unite($found);
ok $tt++, ($mu->size==7);
# intersect
my $mi=$model->duplicate->intersect($found);
ok $tt++, ($mi->size==1);
#print "SIZE=".$model->size."=".$mi->size."\n";
#my $ee = $mi->elements;
#for ( my $e = $ee->first; $ee->hasnext; $e= $ee->next ) {
#	print "----->".$e->toString."\n";
#	};
# subtract
my $ms=$model->duplicate->subtract($found);
ok $tt++, ($ms->size==6);

ok $tt++, my $kk = $found->find()->find()->find();
ok $tt++, ($kk->size==1);
ok $tt++, my $kk1 = $found->find(undef,$statement->predicate)->find()->find($statement->subject);
ok $tt++, ($kk1->size==1);
ok $tt++, my $kk2 = $found->find(undef,$statement->predicate)->find()->find($statement->subject)->intersect($kk1);
ok $tt++, ($kk2->size==1);
ok $tt++, my $kk3 = $found->find(undef,$statement->predicate)->find()->find($statement->subject)->unite($kk1);
ok $tt++, ($kk3->size==1);

#my $ee = $kk->elements;
#print "ee=".$ee->size."\n";
#for ( my $e = $ee->first; $ee->hasnext; $e= $ee->next ) {
#	print "----->".$e->toString."\n";
#	};

ok $tt++, my $statement6 = $factory->createStatement(
                $factory->createUniqueResource(),
                $factory->createOrdinal(3),
                $factory->createLiteral('test6') );
ok $tt++, my $statement7 = $factory->createStatement(
                $factory->createResource("http://rdfstore.sf.net"),
		$factory->createResource('http://somewhere.org/schema/1.0/#demolink'),
		$factory->createResource("http://demo.asemantics.com/rdfstore") );

ok $tt++, $found->add($statement6);
ok $tt++, $found->add($statement7);
ok $tt++, ($found->contains($statement6));
ok $tt++, ($found->contains($statement7));
ok $tt++, ($found->size == 3);
ok $tt++, $found->remove($statement6);
ok $tt++, ($found->size == 2);
ok $tt++, !($found->contains($statement6));

my $found1 = $found->find(undef,undef,$statement7->object);
eval {
	my($num) = $found1->elements;
	die unless($num->size==1);
	my $ss = $num->first;
	die unless($ss->equals($statement7));
};
ok $tt++, !$@;

eval {
	my $r=0;
	my $num = $found1->elements;
	while ( my $st = $num->each ) {
		#print $st->toString,"\n";
		$r++;
		};
	die unless($r == 1);
};
ok $tt++, !$@;

ok $tt++, my $model1 = $model->duplicate();
ok $tt++, ($model1->size==$model->size);

ok $tt++, my $found2 = $model1->find($statement2->subject,undef,$statement2->object);
eval {
	my($num) = $found2->elements;
	die unless($num->size==1);
};
ok $tt++, !$@;

#free-text on literals
ok $tt++, my $found3=$model->find(undef,undef,undef,undef,1,'me','you');
eval {
	my ($num) = $found3->elements;
	die unless($num->size==1);
};
ok $tt++, !$@;

#contexts stuff
ok $tt++, ($model->getContext->toString eq $now);

#cool stuff!
ok $tt++, my $found4=$model->find(undef,undef,undef,$model->getContext);
eval {
	my($num) = $found4->elements;
	die unless($num->size==6);
};
ok $tt++, !$@;

ok $tt++, my $found5=$model->find($statement5->subject,$statement5->predicate,$statement5->object,$model->getContext);
eval {
	my($num) = $found5->elements;
	die unless($num->size==0);
};
ok $tt++, !$@;

ok $tt++, (!($model->contains($statement5,$model->getContext)));
ok $tt++, $model->resetContext;
ok $tt++, ($model->contains($statement5));

ok $tt++, $model->add($statement5,undef,undef,$factory->createResource($now));
ok $tt++, $model->contains($statement5,$factory->createResource($now));
ok $tt++, $model->remove($statement5,$factory->createResource($now));
ok $tt++, (!($model->contains($statement5,$factory->createResource($now))));

#for (1..100000) {
#	my $st = $factory->createStatement(
#			$factory->createUniqueResource(),
#			$factory->createOrdinal($_),
#			$factory->createLiteral('') );
#	$model->add($st);
##print STDERR $_,"\n";
#};
