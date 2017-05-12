#!perl -w

use strict;
use warnings;

use Test::More tests => 16;

use File::Spec::Functions qw(catdir rel2abs);
use File::Temp qw(tempdir);
use SVN::Log;

if($0 =~ /commandline/) {
  diag "Using the commandline client\n";
  $SVN::Log::FORCE_COMMAND_LINE_SVN = 1;
} else {
  diag "Using the Subversion Perl bindings\n";
  $SVN::Log::FORCE_COMMAND_LINE_SVN = 0;
}

my $tmpdir = tempdir (CLEANUP => 1);

my $repospath = rel2abs (catdir ($tmpdir, 'repos'));
my $indexpath = rel2abs (catdir ($tmpdir, 'index'));

{
  system ("svnadmin create $repospath");
  system ("svn mkdir -q file://$repospath/trunk -m 'a log message'");
  system ("svn mkdir -q file://$repospath/branches -m 'another log message'");
}

my $revs = SVN::Log::retrieve ("file://$repospath", 1);

is (scalar @$revs, 1, "got one revision");

like ($revs->[0]{message}, qr/a log message/, "looks like we got rev 1 okay");

$revs = SVN::Log::retrieve ($repospath, 2);

is (scalar @{ $revs }, 1, "and now the second");

ok(exists $revs->[0]{paths}{'/branches'}, "  Shows that '/branches' changed");
is($revs->[0]{paths}{'/branches'}{action}, 'A', '  and that it was an add');

$revs = SVN::Log::retrieve ($repospath, 1, 2);

is (scalar @{ $revs }, 2, "got both back");

like ($revs->[0]{message}, qr/a log message/, "Rev 1's log message is ok");

ok(exists $revs->[1]{paths}{'/branches'}, "  Shows that '/branches' changed");
is($revs->[1]{paths}{'/branches'}{action}, 'A', '  and that it was an add');

my $count = 0;

SVN::Log::retrieve ({ repository => $repospath,
                      start => 1,
                      end => 2,
                      callback => sub { $count++; }});

is ($count, 2, "called callback twice");

my @revs = ();
$count = 0;
SVN::Log::retrieve({ repository => $repospath,
		     start => 1,
		     end   => 'HEAD',
		     callback => sub { $count++; push @revs, $_[1]; }});
is($count, 2, "'HEAD' works going forward");
is_deeply(\@revs, [1, 2], '  ... and collects revisions in right order');

@revs = ();
$count = 0;
SVN::Log::retrieve({ repository => $repospath,
		     start => 'HEAD',
		     end   => 1,
		     callback => sub { $count++; push @revs, $_[1]; }});

is($count, 2, "'HEAD' works going backward");
is_deeply(\@revs, [2, 1], '  ... and collects revisions in right order');

@revs = ();
$count = 0;
SVN::Log::retrieve({ repository => $repospath,
		     start => 'HEAD',
		     end => 'HEAD',
		     callback => sub { $count++; push @revs, $_[1]; }});
is($count, 1, "'HEAD' as start and end works");
is_deeply(\@revs, [2], '  ... and collects correct revision');

