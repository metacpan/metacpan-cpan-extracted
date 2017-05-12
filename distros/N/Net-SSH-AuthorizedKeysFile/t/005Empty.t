######################################################################
# Test suite for Net::SSH::AuthorizedKeysFile
# by Mike Schilli <m@perlmeister.com>
######################################################################

use warnings;
use strict;

use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

use Test::More tests => 3;
BEGIN { use_ok('Net::SSH::AuthorizedKeysFile') };

my $tdir = "t";
$tdir = "../t" unless -d $tdir;
my $cdir = "$tdir/canned";

use Net::SSH::AuthorizedKeysFile;

my $ak = Net::SSH::AuthorizedKeysFile->new(file => "$cdir/pk-ssh2.txt");
$ak->read();

my @keys = $ak->keys();
is((scalar @keys), 0, "no keys found");

$ak = Net::SSH::AuthorizedKeysFile->new(file => "$cdir/pk-empty.txt");
$ak->read();
@keys = $ak->keys();
is((scalar @keys), 0, "no keys found");
