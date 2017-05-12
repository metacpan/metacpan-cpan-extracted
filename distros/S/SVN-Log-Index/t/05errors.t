#!/usr/bin/perl

# $Id: /local/CPAN/SVN-Log-Index/trunk/t/05errors.t 1474 2007-01-13T21:14:25.326886Z nik  $

use strict;
use warnings;

use Test::More qw(no_plan);
use Test::Exception;

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

# Start testing that various errors are handled
throws_ok {
  $index->create({ repo_url => "file://$repospath"});
} 'SVN::Log::Index::X::Fault', 'create(),open(),create() fails';

undef $index;
$index = SVN::Log::Index->new({ index_path => $indexpath});
throws_ok {
  $index->create({ repo_url => "file://$repospath",
		   overwrite => 0});
} 'SVN::Log::Index::X::Fault', 'create({overwrite => 0}) works';

throws_ok {
  $index->create({ repo_url => "file://$repospath" });
} 'SVN::Log::Index::X::Fault', 'create() with no explicit overwrite works';

throws_ok {
  $index->create({ overwrite => 1});
} 'SVN::Log::Index::X::Args', 'create() with missing repo_url fails';

throws_ok {
  $index->create({ repo_url => undef, overwrite => 1 });
} 'SVN::Log::Index::X::Args', 'create() with undef repo_url fails';

throws_ok {
  $index->create({ repo_url => '', overwrite => 1 });
} 'SVN::Log::Index::X::Args', 'create() with empty repo_url fails';

# ------------------------------------------------------------------------
#
# Check add()

undef $index;

$index = SVN::Log::Index->new({ index_path => $indexpath});
isa_ok ($index, 'SVN::Log::Index');

$index->create({ repo_url  => "file://$repospath",
	         overwrite => 1 });

$index->open();

throws_ok {
  $index->add();
} 'SVN::Log::Index::X::Args', 'add() with no args fails';

throws_ok {
  $index->add({ end_rev => 'HEAD' });
} 'SVN::Log::Index::X::Args', 'add() missing start_rev fails';

throws_ok {
  $index->add({ start_rev => undef });
} 'SVN::Log::Index::X::Args', 'add() undef start_rev fails';

throws_ok {
  $index->add({ start_rev => 'foo' });
} 'SVN::Log::Index::X::Args', 'add({ start_rev => \'foo\' }) fails';

throws_ok {
  $index->add({ start_rev => -1 });
} 'SVN::Log::Index::X::Args', 'add({ start_rev => -1 }) fails';
