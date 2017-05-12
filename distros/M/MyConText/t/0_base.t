
BEGIN {
	print "1..7\n";
}

use MyConText;

BEGIN { print "ok 1\n"; }

use MyConText::Blob;

BEGIN { print "ok 2\n"; }

use MyConText::Column;

BEGIN { print "ok 3\n"; }

use MyConText::String;

BEGIN { print "ok 4\n"; }

use MyConText::File;

BEGIN { print "ok 5\n"; }

use MyConText::URL;

BEGIN { print "ok 6\n"; }

use MyConText::Phrase;

BEGIN { print "ok 7\n"; }

