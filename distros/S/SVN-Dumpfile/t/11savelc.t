use strict;
use warnings;

use Test::More tests => 11;
use IO::File;
use File::Temp qw( :seekable );

use SVN::Dumpfile::Node::Content;
ok(1);

my $reference = <<"EOT";
Some content.
\123\125\000\001\012\003
EOT

# Create temp file
my $infh = File::Temp->new(TEMPLATE => 'svnXXXXX');

$infh->print($reference);
$infh->seek(0,0);
$infh->unlink_on_destroy( 0 );
my $fname = $infh->filename;
undef $infh; # close temp file

my $cont;
my $str;

# Test as_string
$cont = SVN::Dumpfile::Node::Content->new($reference);
$str = $cont->as_string;
ok ( $str eq $reference );
# Test value
$str = $cont->value;
ok ( $str eq $reference );
$str = $cont->value('test');
ok ( $str eq 'test' );
$cont->value = 'test 2';
$str = $cont->value;
ok ( $str eq 'test 2' );


# Test load
$cont = new SVN::Dumpfile::Node::Content;
ok ( $cont->load($fname) );
$str = $cont->as_string;
ok ( $str eq $reference );

# Test save
ok ( $cont->save($fname) );
open(IN, '<', $fname);
binmode(IN);
$str = join '', <IN>;
close(IN);
ok ( $str eq $reference );

# Test load from saved file
$cont = new SVN::Dumpfile::Node::Content;
ok ( $cont->load($fname) );
$str = $cont->as_string;
ok ( $str eq $reference );

# Clean-up
unlink $fname;
1;
