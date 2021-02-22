use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Search::QueryParser') };

my $qp = Search::QueryParser->new;
isa_ok($qp, 'Search::QueryParser');

my $s = '+mandatoryWord -excludedWord +field:word "exact phrase"';

my $q = $qp->parse($s);
isa_ok($q, 'HASH');

is($qp->unparse($q), 
   '+:mandatoryWord +field:word :"exact phrase" -:excludedWord',
   "mixed features");

# query with comparison operators and implicit plus (second arg is true)
$q = $qp->parse("txt~'^foo.*' date>='01.01.2001' date<='02.02.2002'", 1);
is($qp->unparse($q), 
   "+txt~'^foo.*' +date>='01.01.2001' +date<='02.02.2002'",
  "comparison operators and implicit plus");

# boolean operators (example below is equivalent to "+a +(b c) -d")
$q = $qp->parse("a AND (b OR c) AND NOT d");
is($qp->unparse($q), 
   '+:a +(:b :c) -:d',
   "boolean operators");

# '#' operator
$q = $qp->parse("+foo#12,34,567,890,1000 +bar#9876 #54321");
is($qp->unparse($q), 
   "+foo#12,34,567,890,1000 +bar#9876 #54321",
   "'#' operator");

# boolean operators
$q = $qp->parse("Prince Edward"); # test bug RT#32840
is($qp->unparse($q),
   ':Prince :Edward',
   "RT32840");

$q = $qp->parse("a E(b)");
is($qp->unparse($q), 
   '+:a +(:b)',
   "a E(b)");

# quoted field
$q = $qp->parse(q{"LastEdit">"2009-01-01" 'FirstEdit'<"2008-01-01"}); 
is($qp->unparse($q), 
   q{LastEdit>"2009-01-01" FirstEdit<"2008-01-01"},
   "quoted field"); 

# default field
$qp = Search::QueryParser->new(defField => 'def');
$q = $qp->parse("foo +bar -buz");
is($qp->unparse($q), 
   '+def:bar def:foo -def:buz',
   "default field");

$q = $qp->parse("foo:foo bar buz:(boo bing)");
is($qp->unparse($q), 
   'foo:foo def:bar (buz:boo buz:bing)',
   "parent field");

$q = $qp->parse("foo:(bar:buz)");
ok(!$q, 'parse error');
like($qp->err, qr/'bar' inside 'foo'/, 'ERR parent field');


$q = $qp->parse("(domain:example.org OR domain:example.com)");
is($qp->unparse($q), 
   '(domain:example.org domain:example.com)',
   "explicit field within parenthesis");


$q = $qp->parse("foo bar )and garbage");
ok(!$q, 'parse error');
like($qp->err, qr/unable to parse/, 'could not parse entire query');

done_testing;

