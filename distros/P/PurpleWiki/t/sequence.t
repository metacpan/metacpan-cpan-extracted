# parser.t

use strict;
use warnings;
use Test;

BEGIN { plan tests => 4 };

use IO::File;
use PurpleWiki::Sequence;

my $datadir = '/tmp';

# make sure any existing sequence is killed
unlink('/tmp/sequence');

### test sequence incrementing
my $sequence = new PurpleWiki::Sequence($datadir);
ok(ref $sequence eq 'PurpleWiki::Sequence');
ok($sequence->getNext() eq '1');

for (0..7) {
	$sequence->getNext();
}
ok($sequence->getNext() eq 'A');

for (0..24) {
	$sequence->getNext();
}
ok($sequence->getNext() eq '10');

unlink("$datadir/sequence");
