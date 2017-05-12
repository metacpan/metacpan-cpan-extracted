######################################################################
# Test suite for Perldoc::Search
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More qw(no_plan);
use File::Temp qw(tempdir);

BEGIN { use_ok('Perldoc::Search') };

my $tempdir = tempdir(CLEANUP => 1);
mkdir "$tempdir/adm" or die "Cannot mkdir ($!)";
mkdir "$tempdir/data" or die "Cannot mkdir ($!)";

my $searcher = Perldoc::Search->new(
    dirs => ["$tempdir/data"],
    swish_options => {
       swish_adm_dir => "$tempdir/adm",
    }
);

blurt("abc def ghi", "$tempdir/data/file1");
blurt("abc def jkl", "$tempdir/data/file2");

ok($searcher->update(), "Updating index");

my $hits = join "-", map { $_->path() } $searcher->search("ghi");
like($hits, qr/file1/, "Query");
unlike($hits, qr/file2/, "Query");

$hits = join "-", map { $_->path() } $searcher->search("jkl");
unlike($hits, qr/file1/, "Query");
like($hits, qr/file2/, "Query");

$hits = join "-", map { $_->path() } $searcher->search("abc AND def");
like($hits, qr/file1/, "Query");
like($hits, qr/file2/, "Query");

#################
sub blurt {
#################
    my($data, $file) = @_;

    open FILE, ">$file" or die "Cannot open $file ($!)";
    print FILE $data; 
    close FILE;
}
