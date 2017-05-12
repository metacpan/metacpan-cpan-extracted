#!perl
use Test::Most tests=>3,'die';
use strict;
use warnings;
use PPI;
use PPIx::XPath;

my $x=PPIx::XPath->new(\<<'EOF');
sub foo { print "bar" }

baz();
EOF

#explain('the doc: ',$x->{doc});

my ($subdef) = $x->match('/Statement::Sub');
is($subdef->name,'foo','Got the sub');

my ($string) = $x->match('/Statement::Sub/Structure::Block/Statement/Token::Quote::Double');
is($string->string,'bar','Got the string');

my ($call) = $x->match('/Statement/Token::Word');
is($call->literal,'baz','Got the call');
