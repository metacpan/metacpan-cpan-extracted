#!perl

use Test::More tests => 12;


BEGIN { use_ok NLP::GATE }
diag( "Testing NLP::GATE::Annotation $NLP::GATE::Annotation::VERSION, Perl $], $^X" );

can_ok(NLP::GATE::Annotation, qw(new clone setFeature getFeature setFeatureType getFeatureType 
  setFromTo getFrom getTo  setType getType  ) ) ;

my $ann = NLP::GATE::Annotation->new("TestType",0,10);
isa_ok($ann, 'NLP::GATE::Annotation');

is($ann->getType,"TestType","Getting the type works");

is($ann->getFrom,0,"From offset correct");
is($ann->getTo,10,"To offset correct");
is($ann->getFeature("f1"),undef,"Missing feature correct");
is($ann->getFeatureType("f1"),undef,"Missing feature type correct");

$ann->setFeature("f1","v1");
is($ann->getFeature("f1"),"v1","Existing feature correct");
is($ann->getFeatureType("f1"),"java.lang.String","Existing feature type has correct default");
$ann->setFeatureType("f1","com.this.that.MyType");
is($ann->getFeatureType("f1"),"com.this.that.MyType","Existing feature type has correct after set");

my $ann2 = $ann->clone();
is_deeply($ann,$ann2,"Cloning works");