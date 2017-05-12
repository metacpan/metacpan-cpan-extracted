# $Id: /local/CPAN/SVN-Log-Index/trunk/t/04commandline.t 1474 2007-01-13T21:14:25.326886Z nik  $

use Test::More tests => 6;
use strict;

use File::Spec::Functions qw(catdir rel2abs);
use File::Temp qw(tempdir);

{
  require SVN::Log;

  $SVN::Log::FORCE_COMMAND_LINE_SVN = 1;
}

use SVN::Log::Index;

my $tmpdir = tempdir (CLEANUP => 1);

my $repospath = rel2abs (catdir ($tmpdir, 'repos'));
my $indexpath = rel2abs (catdir ($tmpdir, 'index'));

eval {
  require SVN::Core;
  require SVN::Ra;
};

SKIP: {
  skip "no reason to force command line tests if we already used it", 6 if $@;

  {
    system ("svnadmin create $repospath");
    system ("svn mkdir -q file://$repospath/trunk -m 'foo'");
    system ("svn mkdir -q file://$repospath/branches -m 'bar'");
  }

  my $index = SVN::Log::Index->new({ index_path => $indexpath });
  $index->create({ repo_url  => $repospath,
		   overwrite => 1 });
  $index->open();

  ok ($index->add({ start_rev => 1 }), "added first revision");

  ok ($index->add({ start_rev => 2 }), "added second revision");

  my $hits = $index->search('foo');
  is($hits->total_hits(), 1, "able to retrieve first revision");
  my $hah = $hits->fetch_hit_hashref();
  like ($hah->{message}, qr/foo/, 'really matches query');

  $hits = $index->search ('bar');
  is($hits->total_hits(), 1, "able to retrieve second revision");
  $hah = $hits->fetch_hit_hashref();
  like($hah->{message}, qr/bar/, 'really matches query');

  chmod 0600, File::Spec->catfile ($repospath, "format");
};
