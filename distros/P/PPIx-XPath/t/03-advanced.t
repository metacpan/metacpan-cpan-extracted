#!perl
use Test::Most tests=>6,'die';
use strict;
use warnings;
use PPI;
use PPIx::XPath;
use Tree::XPathEngine;

my $x=PPI::Document->new(\<<'EOF');
sub foo { print "bar" }

sub baz { print "boo"; foo() };

baz();
EOF

my $e=Tree::XPathEngine->new();

#explain('the doc: ',$x);

{
my @subdefs = $e->findnodes('/Statement-Sub',$x);
is_deeply([sort map {$_->name} @subdefs],[qw(baz foo)],'Got the two sub');
}
{
my ($subdef) = $e->findnodes('/Statement-Sub[@name="foo"]',$x);
is($subdef->name,'foo','Got the sub by name');
}

{
my ($string,@rest) = $e->findnodes('/Statement-Sub[@name="foo"]//Statement[Token-Word="print"]/Token-Quote-Double',$x);
is($string->string,'bar','Got the string');
is(scalar(@rest),0,'and nothing more');
}

{
my ($call,@rest) = $e->findnodes('/Statement-Sub//Statement[Token-Word and Structure-List[count(*)=0]]',$x);
is("$call",'foo()','Got the call');
is(scalar(@rest),0,'and nothing more');
}
