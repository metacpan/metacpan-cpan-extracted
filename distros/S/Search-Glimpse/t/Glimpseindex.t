# -*- cperl -*-

use Test::More tests => 12;
use File::Path qw.remove_tree.;

BEGIN {
    use_ok 'Search::Glimpse::Index';
}

use Cwd;
use File::Spec;

my $folder  = File::Spec->catdir(getcwd, 'tmp');

remove_tree $folder if -d $folder;

die "$folder still exists and I can'd remove it.\nRemove it manually before running these tests again!" if -d $folder;

my $indexer = Search::Glimpse::Index->new(destdir => $folder);

ok($indexer);

$indexer->index('lib');

like($indexer->{output} => qr/Indexing .*lib/);

ok(-d $folder, "Folder $folder is there");

for my $file (qw!.glimpse_filetimes .glimpse_turbo .glimpse_statistics .glimpse_partitions
                 .glimpse_messages .glimpse_index .glimpse_filenames_index .glimpse_filenames!) {
    my $f = File::Spec->catfile($folder => $file);
    ok(-f $f, "File $f exists");
}




# cleanup
remove_tree $folder;
