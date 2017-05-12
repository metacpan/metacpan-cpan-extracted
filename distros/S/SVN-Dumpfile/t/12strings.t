use strict;
use warnings;

use Test::More tests => 6;
use IO::File;
use File::Temp qw( :seekable );

use SVN::Dumpfile::Node;
ok(1);

my $reference = <<'EOT';
Node-path: test/path
Node-kind: file
Node-action: add
Prop-content-length: 100
Text-content-length: 26
Text-content-md5: 68f07f0b1e76f5e6caec5d5677face07
Content-length: 126

K 13
svn:eol-style
V 6
native
K 8
userprop
V 5
USER

K 12
svn:keywords
V 13
Id Rev Author
PROPS-END
Some ...
...
... content.


EOT

# Make this script work with all EOL styles
$reference =~ s/\015|\012|\015\012/\012/m;

# Create temp file
my $fh = File::Temp->new(TEMPLATE => 'svnXXXXX');

$fh->print($reference);
$fh->seek(0,0);
#$fh->unlink_on_destroy( 0 );
my $fname = $fh->filename;

my $node;
my $str;


# Test read
$node = new SVN::Dumpfile::Node;
ok ( $node->read($fh) );

# Test as_string
$str = $node->as_string;
ok ( $str eq $reference );

$fh->seek(0,0);

# Test write
ok ( $node->write($fh) );

$fh->seek(0,0);

# Test read from written file
$node = new SVN::Dumpfile::Node;
ok ( $node->read($fh) );

# Test as_string
$str = $node->as_string;
ok ( $str eq $reference );


# Clean-up
#unlink $fname;
1;
