use strict;
use warnings;
use Path::ExpandTilde;
use Cwd 'abs_path';
use File::Spec;

my $home;
# see File::HomeDir::Tiny
BEGIN { $home = ($^O eq 'MSWin32' && $] < 5.016) ? ($ENV{HOME} || $ENV{USERPROFILE}) : (<~>)[0] }
use if !$home || !-e $home, 'Test::More', skip_all => 'No home directory found for current user';

use Test::More;

is abs_path(expand_tilde('~')), abs_path($home), '~ expands to home dir';

my $username = eval { getpwuid $> };
$username = getlogin unless defined $username;
SKIP: {
  skip 'username not found', 1 unless defined $username;
  my $user_home = expand_tilde("~$username");
  skip 'user home directory not found', 1 unless defined $user_home and $user_home ne "~$username";
  my ($save_home, $save_profile) = delete @ENV{'HOME','USERPROFILE'};
  my $passwd_home = expand_tilde('~');
  @ENV{'HOME','USERPROFILE'} = ($save_home, $save_profile);
  skip 'non-environment home directory not found', 1 unless defined $passwd_home and $passwd_home ne '~';
  is abs_path($user_home), abs_path($passwd_home), '~username expands to user home dir';
}

my @no_expand = (qw(foo foo~ foo~bar ./~), File::Spec->catdir('foo', '~'));
is expand_tilde($_), File::Spec->canonpath($_), "'$_' doesn't expand" for @no_expand;

SKIP: {
  skip $@, 1 unless eval { my $dummy = getpwnam 'foo'; 1 };
  my $test_username = 'notarealuser';
  my $i;
  $test_username++ until !defined getpwnam $test_username or ++$i > 100;
  is expand_tilde("~$test_username"), File::Spec->canonpath("~$test_username"),
    "~$test_username doesn't expand";
}

my @test_filenames = (qw(foo.bar ? a* [abc] foo\bar foo/bar), '{foo,bar}', 'foo bar');
SKIP: {
  skip '~ expands differently from environment homedir', scalar(@test_filenames)
    if expand_tilde('~') ne File::Spec->canonpath($home);
  is expand_tilde(File::Spec->catfile('~', $_)), File::Spec->canonpath(File::Spec->catfile($home, $_)),
    "file '$_' in ~ expands" for @test_filenames;
}

done_testing;
