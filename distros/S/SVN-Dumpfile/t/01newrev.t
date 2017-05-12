# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SVN-Dumpfilter.t'

#########################

use Test::More tests => 7;
use File::Temp qw( :seekable );
use SVN::Dumpfile::Node;
ok(1);

my $node;
$node = eval { new SVN::Dumpfile::Node };
ok( defined $node );

my $revnode;
$revnode = eval { SVN::Dumpfile::Node->newrev( number => 34, 
        author => 'test', date => '2008-04-12T12:05:34.000000Z' ) };
ok( defined $revnode );

my $reference = <<'EOT';
Revision-number: 34
Prop-content-length: 81
Content-length: 81

K 8
svn:date
V 27
2008-04-12T12:05:34.000000Z
K 10
svn:author
V 4
test
PROPS-END

EOT

# Make this script work with all EOL styles
$reference =~ s/\015|\012|\015\012/\012/m;

my $temp = new File::Temp;
$revnode->write($temp);
$temp->seek(0, 0);
my $text = join '', $temp->getlines;

ok ( $text eq $reference );
ok ( $revnode->is_rev );

is ( $revnode->revnum, 34 );
is ( $revnode->{headers}->sanitycheck(), 0 );

1;
