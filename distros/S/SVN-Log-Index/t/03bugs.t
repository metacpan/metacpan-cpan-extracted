# $Id: /local/CPAN/SVN-Log-Index/trunk/t/03bugs.t 585 2006-01-11T08:19:33.308084Z nik  $

use Test::More tests => 2;
use strict;

use File::Spec::Functions qw(catdir rel2abs);
use File::Temp qw(tempdir);

use SVN::Log::Index;

my $tmpdir = tempdir (CLEANUP => 1);

my $repospath = rel2abs (catdir ($tmpdir, 'repos'));
my $indexpath = rel2abs (catdir ($tmpdir, 'index'));

{
  system ("svnadmin create $repospath");
  system ("svn mkdir -q file://$repospath/trunk -m ''");
  system ("svn mkdir -q file://$repospath/branches -m ' \t \n'");
}

my $index = SVN::Log::Index->new ({ index_path => $indexpath});
$index->create({ repo_url => "file://$repospath",
	         overwrite => 1, });
$index->open();

ok ($index->add({ start_rev => 1 }), "added revision with empty log");

ok ($index->add({ start_rev => 2 }), "added revision with whitespace log");

chmod 0600, File::Spec->catfile ($repospath, "format");
