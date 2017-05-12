use strict;
use warnings;

use Test::More tests => 9;
use File::Spec::Functions;
my $ext = $^O eq 'MSWin32' ? '.bat' : '';

my $dir = catdir curdir, 't', 'scripts';
$dir = catdir curdir, 't', 'bin' unless -d $dir;

BEGIN {
  use_ok 'SVN::Notify::Filter::Watchers' or die;
}

isa_ok my $n1 = SVN::Notify->new(
       to => ['you@example.com'],
       sendmail   => catfile($dir, "testsendmail$ext"),
       repos_path => '/foo/bar',
       revision => '42',
       filters => [ 'Watchers' ],
       ), "SVN::Notify", "Create notifyer";

isa_ok my $n2 = SVN::Notify->new(
       to => ['you@example.com'],
       sendmail   => catfile($dir, "testsendmail$ext"),
       repos_path => '/foo/bar',
       revision   => '42',
       filters   => [ 'Watchers' ],
       watcher_property => 'svnnotify:watchers',
       skip_walking_up => 1,
       skip_deleted_paths => 1,
), "SVN::Notify", "Testing Options";

is($n2->watcher_property, 'svnnotify:watchers', "Checking setting SVN Property");
is($n2->skip_walking_up, 1, "Checking walk option");
is($n2->skip_deleted_paths, 1, "Checking deleted option");
$n2->run_filters('post_prepare');
is_deeply($n2->{to}, ['you@example.com'], "Checking --to exists");

isa_ok my $n3 = SVN::Notify->new(
       to => ['1@example.com'],
       sendmail   => catfile($dir, "testsendmail$ext"),
       repos_path => '/foo/bar',
       revision => '42',
       filters => [ 'Watchers' ],
       trim_original_to => 1,
), "SVN::Notify", "Testing to entries";
$n3->run_filters('post_prepare');
is_deeply($n3->{to}, [''], "Checking --to is ignored");

