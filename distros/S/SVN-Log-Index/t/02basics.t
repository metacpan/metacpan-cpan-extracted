# $Id: /local/CPAN/SVN-Log-Index/trunk/t/02basics.t 1474 2007-01-13T21:14:25.326886Z nik  $

use Test::More tests => 18;
use strict;

use File::Spec::Functions qw(catdir rel2abs);
use File::Temp qw(tempdir);

use SVN::Log::Index;

my $tmpdir = tempdir (CLEANUP => 1);

my $repospath = rel2abs (catdir ($tmpdir, 'repos'));
my $indexpath = rel2abs (catdir ($tmpdir, 'index'));

{
  system ("svnadmin create $repospath");
  system ("svn mkdir -q file://$repospath/trunk -m 'a log message'");
  system ("svn mkdir -q file://$repospath/branches -m 'another log message'");
  system ("svn mkdir -q file://$repospath/tags -m 'yet another log message'");
}

my $index = SVN::Log::Index->new({ index_path => $indexpath});
isa_ok ($index, 'SVN::Log::Index');

$index->create({ repo_url  => "file://$repospath",
	         overwrite => 1 });
$index->open();

ok ($index->add({ start_rev => 1 }), "added revision via SVN::Ra");

{
  my $hits = $index->search ('log');

  $hits->seek(0, 10);
  is($hits->total_hits(), 1, "one hit");

  my $hah = $hits->fetch_hit_hashref(); # hah = hits as hash

  like($hah->{message}, qr/message/, 'really matches query');
}

ok ($index->add({ start_rev => 2 }), "added revision with absolute path to repos");

{
  my $hits = $index->search ('another');
  $hits->seek(0, 10);
  is($hits->total_hits(), 1, "able to retrieve second revision");
  my $hah = $hits->fetch_hit_hashref();
  like($hah->{message}, qr/another/, 'really matches query');
}

{
  my $hits = $index->search ('log');
  $hits->seek(0, 10);
  is($hits->total_hits(), 2, "able to retrieve both revisions");
  my $hah = $hits->fetch_hit_hashref();
  like($hah->{message}, qr/log/, 'really matches query');
  $hah = $hits->fetch_hit_hashref();
  like($hah->{message}, qr/log/, 'really matches query');
}

undef $index;
$index = SVN::Log::Index->new({ index_path => $indexpath});
isa_ok ($index, 'SVN::Log::Index');
$index->open();

is($index->get_last_indexed_rev(), 2, 'get_last_indexed_rev() works');
ok($index->add({ start_rev => $index->get_last_indexed_rev() + 1,
		 end_rev   => 'HEAD' }),
   'add() with get_last_indexed_rev / HEAD works');
{
  my $hits = $index->search('log');
  is($hits->total_hits(), 3, 'able to retrieve 3 revisions');
  while(my $hah = $hits->fetch_hit_hashref()) {
    like($hah->{message}, qr/log/, "  Entry matches");
  }
}

{
  my $indexpath2 = rel2abs (catdir ($tmpdir, 'index2'));

  my $index2 = SVN::Log::Index->new({ index_path => $indexpath2 });

  eval { $index2->add({ start_rev => 1 }); };

  ok (! -e $indexpath2, 'shouldn\'t create a new index if create is false');
}

chmod 0600, File::Spec->catfile ($repospath, "format");
