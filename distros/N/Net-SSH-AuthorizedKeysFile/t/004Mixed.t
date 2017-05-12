######################################################################
# Test suite for Net::SSH::AuthorizedKeysFile
# by Mike Schilli <m@perlmeister.com>
######################################################################

use warnings;
use strict;

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

use Test::More tests => 7;
BEGIN { use_ok('Net::SSH::AuthorizedKeysFile') };

my $tdir = "t";
$tdir = "../t" unless -d $tdir;
my $cdir = "$tdir/canned";

use Net::SSH::AuthorizedKeysFile;

my $ak = Net::SSH::AuthorizedKeysFile->new(file => "$cdir/ak-mixed.txt");
$ak->read();

my @keys = $ak->keys();

is($keys[0]->email(), 'foo@bar.com', "email1");
is($keys[1]->email(), 'bar@foo.com', "email2");
is($keys[2]->email(), 'quack@schmack.com', "email3");

my $org_data = slurp("$cdir/ak-mixed.txt"); 
$org_data =~ s/^\s*#.*\n//mg;

is($ak->as_string(), $org_data, "write-back");

$ak = Net::SSH::AuthorizedKeysFile->new(file => "$cdir/ak-ssh1-weirdo.txt");
$ak->read();
@keys = $ak->keys();
is(scalar @keys, 1, "1 key found");
is($keys[0]->email(), 'bozo@quack.schmack.com', "email4");


###########################################
sub slurp {
###########################################
    open FILE, "$_[0]" or die $!;
    my $data = join "", <FILE>;
    close FILE;
    return $data;
}
