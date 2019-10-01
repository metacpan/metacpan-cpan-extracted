use strict;
use warnings;
use Test::More;
use Test::Differences;
use Parse::Distname qw/parse_distname/;

my $path = "CPAN/authors/id/I/IS/ISHIGAKI/Parse-Distname-0.01.tar.gz";
my $info = parse_distname($path);

unified_diff;

eq_or_diff $info => +{
  arg              => $path,
  cpan_path        => "I/IS/ISHIGAKI/Parse-Distname-0.01.tar.gz",
  pause_id         => "ISHIGAKI",
  name             => "Parse-Distname",
  name_and_version => "Parse-Distname-0.01",
  version          => "0.01",
  version_number   => "0.01",
  extension        => ".tar.gz",
  is_dev           => undef,
}, "parse_distname";

# distname_info

eq_or_diff [Parse::Distname::distname_info($path)] => [
  "Parse-Distname",
  "0.01",
  undef,
], "distname_info";

# accessors

   $info = Parse::Distname->new($path);
is $info->dist => "Parse-Distname", "dist";
is $info->version => "0.01", "version";
is $info->maturity => "released", "maturity";
is $info->filename => "Parse-Distname-0.01.tar.gz", "filename";
is $info->cpanid => "ISHIGAKI", "cpanid";
is $info->distvname => "Parse-Distname-0.01", "distvname";
is $info->extension => "tar.gz", "extension";
is $info->pathname => $path, "pathname";

ok !$info->is_perl6, "is_perl6";
is $info->version_number => "0.01", "version_number";

# unrelated files
ok !parse_distname("authors/id/A/AU/AUTHOR/CHECKSUMS");
ok !parse_distname("RECENT-6h.json");
ok !parse_distname("authors/00whois.xml");

my $p6path = 'CPAN/authors/id/S/SK/SKAJI/Perl6/App-Mi6-0.0.2.tar.gz';
my $p6info = parse_distname($p6path);

eq_or_diff $p6info => +{
  arg              => $p6path,
  cpan_path        => "S/SK/SKAJI/Perl6/App-Mi6-0.0.2.tar.gz",
  pause_id         => "SKAJI",
  name             => "App-Mi6",
  name_and_version => "App-Mi6-0.0.2",
  version          => "0.0.2",
  version_number   => "0.0.2",
  extension        => ".tar.gz",
  is_dev           => undef,
  subdir           => 'Perl6/',
  perl6            => 1,
}, "parse_distname";

   $p6info = Parse::Distname->new($p6path);
is $p6info->dist => "App-Mi6", "dist";
is $p6info->version => "0.0.2", "version";
is $p6info->maturity => "released", "maturity";
is $p6info->filename => "Perl6/App-Mi6-0.0.2.tar.gz", "filename";
is $p6info->cpanid => "SKAJI", "cpanid";
is $p6info->distvname => "App-Mi6-0.0.2", "distvname";
is $p6info->extension => "tar.gz", "extension";
is $p6info->pathname => $p6path, "pathname";
ok $p6info->is_perl6, "is_perl6";
is $p6info->version_number => "0.0.2", "version_number";

done_testing;
