use strict;
use warnings;

use Test::More tests => 9;
use IO::File;
use File::Temp qw( :seekable );

use SVN::Dumpfile::Node::Properties;
ok(1);

my $reference = <<'EOT';
K 8
svn:date
V 27
2008-04-12T12:05:34.000000Z
K 10
svn:author
V 4
test
END
EOT

# Make this script work with all EOL styles
$reference =~ s/\015|\012|\015\012/\012/m;

# Create temp file
my $infh = File::Temp->new(TEMPLATE => 'svnXXXXX');

$infh->print($reference);
$infh->seek(0,0);
$infh->unlink_on_destroy( 0 );
my $fname = $infh->filename;

my $prop;
my $str;

# Test from_string
$prop = new SVN::Dumpfile::Node::Properties;
ok ( $prop->from_string($reference) );
$str = $prop->as_string(1);
ok ( $str eq $reference );

undef $infh; # close temp file

# Test load
$prop = new SVN::Dumpfile::Node::Properties;
ok ( $prop->load($fname) );
$str = $prop->as_string(1);
ok ( $str eq $reference );

# Test save
ok ( $prop->save($fname) );
open(IN, '<', $fname);
$str = join '', <IN>;
close(IN);
ok ( $str eq $reference );

# Test load from saved file
$prop = new SVN::Dumpfile::Node::Properties;
ok ( $prop->load($fname) );
$str = $prop->as_string(1);
ok ( $str eq $reference );

# Clean-up
unlink $fname;
1;
