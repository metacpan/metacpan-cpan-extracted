use strict;
use warnings;
use Path::ExpandTilde;
use Cwd 'abs_path';
use File::Spec;

my $home;
# see File::HomeDir::Tiny
BEGIN { $home = ($^O eq 'MSWin32' && $] < 5.016) ? ($ENV{HOME} || $ENV{USERPROFILE}) : (<~>)[0] }
use if !$home, 'Test::More', skip_all => 'No home directory found for current user';

use Test::More;

is abs_path(expand_tilde('~')), abs_path($home), '~ expands to home dir';

my $username = getlogin || getpwuid $>;
SKIP: {
  skip 'username not found', 1 unless defined $username;
  is abs_path(expand_tilde("~$username")), abs_path($home), '~username expands to home dir';
}

my @no_expand = (qw(foo foo~ foo~bar ./~), File::Spec->catdir('foo', '~'));
is expand_tilde($_), File::Spec->canonpath($_), "'$_' doesn't expand" for @no_expand;

my $test_username = 'notarealuser';
my $i;
$test_username++ until !defined getpwnam $test_username or ++$i > 100;
is expand_tilde("~$test_username"), File::Spec->canonpath("~$test_username"),
  'nonexistent ~username doesn\'t expand';

my @test_filenames = (qw(foo.bar .. ? a* [abc] foo\bar foo/bar), '{foo,bar}', 'foo bar');
SKIP: {
  skip '~ expands differently from environment homedir', scalar(@test_filenames)
    if expand_tilde('~') ne File::Spec->canonpath($home);
  is expand_tilde(File::Spec->catfile('~', $_)), File::Spec->canonpath(File::Spec->catfile($home, $_)),
    "file '$_' in ~ expands" for @test_filenames;
}

done_testing;
