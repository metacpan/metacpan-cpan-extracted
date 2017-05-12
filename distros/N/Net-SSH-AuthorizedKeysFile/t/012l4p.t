######################################################################
# Test suite for Net::SSH::AuthorizedKeysFile
# by Mike Schilli <m@perlmeister.com>
######################################################################

use warnings;
use strict;
use File::Temp qw(tempfile);
use FindBin qw( $Bin );
use Test::More;
use Log::Log4perl qw(:easy);
use Net::SSH::AuthorizedKeysFile;

Log::Log4perl->easy_init({level => $ERROR, file => "stdout"});
my $cdir = "$Bin/canned";

my $ak = Net::SSH::AuthorizedKeysFile->new(
    file => "$cdir/ak.txt",
);

my($tmp_fh, $tmp_file) = tempfile( UNLINK => 1 );
use vars qw($OLDOUT);
open(OLDOUT, ">&STDOUT");
open(STDOUT, ">$tmp_file") || die "Can't redirect stdout $tmp_file $!";
select(STDOUT); $| = 1;     # make unbuffered

$ak->read();

close(STDOUT);
open(STDOUT, ">&OLDOUT");

open FILE, "<$tmp_file" or die;
my $data = join "", <FILE>;
close FILE;

is $data, "", "nothing printed";

done_testing;
