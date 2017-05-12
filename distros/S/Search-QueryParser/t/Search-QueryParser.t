use strict;
use warnings;
use Test::More tests => 14;

BEGIN { use_ok('Search::QueryParser') };

my $qp = new Search::QueryParser;
isa_ok($qp, 'Search::QueryParser');

my $s = '+mandatoryWord -excludedWord +field:word "exact phrase"';

my $q = $qp->parse($s);
isa_ok($q, 'HASH');

is($qp->unparse($q), 
   '+:mandatoryWord +field:word :"exact phrase" -:excludedWord');

# query with comparison operators and implicit plus (second arg is true)
$q = $qp->parse("txt~'^foo.*' date>='01.01.2001' date<='02.02.2002'", 1);
is($qp->unparse($q), 
   "+txt~'^foo.*' +date>='01.01.2001' +date<='02.02.2002'");

# boolean operators (example below is equivalent to "+a +(b c) -d")
$q = $qp->parse("a AND (b OR c) AND NOT d");
is($qp->unparse($q), 
   '+:a +(:b :c) -:d');

# '#' operator
$q = $qp->parse("+foo#12,34,567,890,1000 +bar#9876 #54321");
is($qp->unparse($q), 
   "+foo#12,34,567,890,1000 +bar#9876 #54321");

# boolean operators
$q = $qp->parse("Prince Edward"); # test bug RT#32840
is($qp->unparse($q), 
   ':Prince :Edward');

$q = $qp->parse("a E(b)");
is($qp->unparse($q), 
   '+:a +(:b)');

# quoted field
$q = $qp->parse(q{"LastEdit">"2009-01-01" 'FirstEdit'<"2008-01-01"}); 
is($qp->unparse($q), 
   q{LastEdit>"2009-01-01" FirstEdit<"2008-01-01"}); 

# default field
$qp = new Search::QueryParser(defField => 'def');
$q = $qp->parse("foo +bar -buz");
is($qp->unparse($q), 
   '+def:bar def:foo -def:buz');

$q = $qp->parse("foo:foo bar buz:(boo bing)");
is($qp->unparse($q), 
   'foo:foo def:bar (buz:boo buz:bing)');

$q = $qp->parse("foo:(bar:buz)");
ok(!$q, 'parse error');
like($qp->err, qr/'bar' inside 'foo'/, 'parse error');
