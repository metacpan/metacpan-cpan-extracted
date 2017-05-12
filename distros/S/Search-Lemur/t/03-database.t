use warnings;
use strict;

use Test::Simple tests => 5;
use Data::Dumper;

use Search::Lemur;

# create an instance of a lemur
my $lemur = Search::Lemur->new("http://example.com/lemurcgi/lemur.cgi");

# test Database.pm equality
my $db1 = Search::Lemur::Database->_new(0, "AP vol1", 0, 0, 84678, 41802513, 207615, 493);
my $db2 = Search::Lemur::Database->_new(0, "AP vol1", 0, 0, 84678, 41802513, 207615, 493);
my $db3 = Search::Lemur::Database->_new(1, "AP vol1", 0, 0, 84678, 41802513, 207615, 493);
my $db4 = Search::Lemur::Database->_new(0, "AP vol1", 1, 0, 84678, 41802513, 207615, 493);
my $db5 = Search::Lemur::Database->_new(0, "AP vol1", 0, 0, 84638, 41802513, 207615, 493);
ok($db1->equals($db2), "database equality test");
ok(!($db1->equals($db3)), "database inequality test");
ok(!($db1->equals($db4)), "database inequality test");
ok(!($db1->equals($db5)), "database inequality test");

my $parseddbref = $lemur->_makedbs("0:  AP vol1 NOSTOP NOSTEMM;
 NUM_DOCS = 84678;
 NUM_TERMS = 41802513;
 NUM_UNIQUE_TERMS =207615;
 AVE_DOCLEN = 493;
<BR>
1:  AP vol1 NOSTOP STEMM;
 NUM_DOCS = 84678;
 NUM_TERMS = 41802513;
 NUM_UNIQUE_TERMS = 166242;
 AVE_DOCLEN = 493;
<BR>
2:  AP vol1 STOP NOSTEMM;
 NUM_DOCS = 84678;
 NUM_TERMS = 24401877;
 NUM_UNIQUE_TERMS = 207224;
 AVE_DOCLEN = 288;
<BR>
3:  AP vol1 STOP STEMM;
 NUM_DOCS = 84678;
 NUM_TERMS = 24401877;
 NUM_UNIQUE_TERMS = 166054;
 AVE_DOCLEN = 288;
<BR>");

my @parseddb = @$parseddbref;

# These tests are commented out because the $lemur was created with a fake url,
# and running them would cause an error.  If you enter the url of your own 
# lemur installation where $lemur is defined above, these should pass.

#my $parseddb2ref = $lemur->listdb();
#my @parseddb2 = @$parseddb2ref;

ok($db1->equals($parseddb[0]), "_makedbs test");
#ok($db1->equals($parseddb2[0]), "listdb test");

