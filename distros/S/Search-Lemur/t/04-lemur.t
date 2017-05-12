use warnings;
use strict;

use Test::Simple tests => 7;
use Data::Dumper;

use Search::Lemur;

# test that new() returns undef
my $nolemur = Search::Lemur->new();
ok(!(defined $nolemur), "new() did not return anything");

# create an instance of a lemur
my $lemur = Search::Lemur->new("http://example.com/lemurcgi/lemur.cgi");

ok(defined $lemur, "new(...) returned something");

# since this is a test, we give a nonsense URL above.  We also won't 
# call &query, so it doesn't try to connect to that URL.  Instead, we'll
# call the (private) &_parse function directly (shhh, don't tell).

# test no results
my @emptyresult = ${$lemur->_parse(["blah", "0 0"])}[0];
my $expemptyresult = Search::Lemur::Result->_new("blah", 0, 0);
ok($emptyresult[0]->equals($expemptyresult), "empty result parse test");

# test some actual queries
my @parseresult1 = ${$lemur->_parse(["encryption",      
   "3          3
    13268        560          1
    20199        792          1
    22948        505          1"])}[0];
my $expresult1 = Search::Lemur::Result->_new("encryption", 3, 3);
my $expresultitem11 = Search::Lemur::ResultItem->_new(13268, 560, 1);
$expresult1->_add($expresultitem11);
my $expresultitem12 = Search::Lemur::ResultItem->_new(20199, 792, 1);
$expresult1->_add($expresultitem12);
my $expresultitem13 = Search::Lemur::ResultItem->_new(22948, 505, 1);
$expresult1->_add($expresultitem13);
# TODO: make a same array of results method
ok($parseresult1[0]->equals($expresult1), "non-trivial parse test");

# commented out for dummy url
#my $vtest = $lemur->v("encryption  algorithm");
#print Dumper($vtest);

# test makeurl_
ok($lemur->_makeurl() eq "http://example.com/lemurcgi/lemur.cgi?g=p", "basic _makeurl() test");
# TODO make this use a setter method (which I have to write)
$lemur->d(2);
ok($lemur->_makeurl() eq "http://example.com/lemurcgi/lemur.cgi?g=p&d=2", "basic _makeurl() test 1");
$lemur->{n} = 10;
ok($lemur->_makeurl() eq "http://example.com/lemurcgi/lemur.cgi?g=p&d=2&n=10", "basic _makeurl() test 2");


# this is commented because fo the dummy url.  If you point $lemur to your own
# lemur installation, they should pass.

# strip test
#ok($lemur->_strip("http://example.com/lemurcgi/lemur.cgi?g=p") eq "", "simple _strip test");
#my $example = "        3          3
#    13268        560          1
#    20199        792          1
#    22948        505          1";
#ok($lemur->_strip("http://example.com/lemurcgi/lemur.cgi?g=p&v=encryption") eq $example, "_strip test");

#$lemur->d(1);
#ok($lemur->m("encryption") eq "encrypt", "db1 m() test (stemming)");
#$lemur->d(2);
#ok($lemur->m("the") eq "", "db2 m() test (stopping)");
#$lemur->d(0);
#ok($lemur->m("encryption") eq "encryption", "db0 m() test (stemming)2");
#ok($lemur->m("the") eq "the", "db0 m() test (stopping)2");


