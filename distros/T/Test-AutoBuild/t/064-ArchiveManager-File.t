# -*- perl -*-

use Test::More tests => 43;
use warnings;
use strict;
use Log::Log4perl;
use File::Path;

BEGIN {
  use_ok("Test::AutoBuild::ArchiveManager::File");
}

Log::Log4perl::init("t/log4perl.conf");

END {
    rmtree "t/archive-root";
}

my $arcman = Test::AutoBuild::ArchiveManager::File->new(options => {
    'archive-dir' => "t/archive-root"
    });
isa_ok($arcman, "Test::AutoBuild::ArchiveManager::File");

START: {
    my @archives = $arcman->list_archives;
    is($#archives, -1, "got 0 archives");
    ok(!defined $arcman->get_current_archive, "current archive is not defined");
    ok(!defined $arcman->get_previous_archive, "previous archive is not defined");
}

FIRST: {
    $arcman->create_archive(1);
    ok(-d "t/archive-root/1", "directory t/archive-root/1 exists");

    my @archives = $arcman->list_archives;
    is($#archives, 0, "got 1 archives");
    is($archives[0]->key, 1, "got archive 1");
    ok(defined $arcman->get_current_archive, "current archive is defined");
    ok(!defined $arcman->get_previous_archive, "previous archive is not defined");
    is($arcman->get_current_archive->key, 1, "current archive is 1");
}

SECOND: {
    $arcman->create_archive(2);
    ok(-d "t/archive-root/2", "directory t/archive-root/2 exists");

    my @archives = $arcman->list_archives;
    is($#archives, 1, "got 3 archives");
    is($archives[0]->key, 1, "got archive 1");
    is($archives[1]->key, 2, "got archive 2");
    ok(defined $arcman->get_current_archive, "current archive is defined");
    ok(defined $arcman->get_previous_archive, "previous archive is defined");
    is($arcman->get_current_archive->key, 2, "current archive is 2");
    is($arcman->get_previous_archive->key, 1, "previous archive is 1");
}

THIRD: {
    $arcman->create_archive(3);
    ok(-d "t/archive-root/3", "directory t/archive-root/3 exists");

    my @archives = $arcman->list_archives;
    is($#archives, 2, "got 3 archives");
    is($archives[0]->key, 1, "got archive 1");
    is($archives[1]->key, 2, "got archive 2");
    is($archives[2]->key, 3, "got archive 3");
    ok(defined $arcman->get_current_archive, "current archive is defined");
    ok(defined $arcman->get_previous_archive, "previous archive is defined");
    is($arcman->get_current_archive->key, 3, "current archive is 3");
    is($arcman->get_previous_archive->key, 2, "previous archive is 2");
}


DELETE_FIRST: {
    $arcman->delete_archive(1);
    ok(!-d "t/archive-root/1", "directory t/archive-root/3 does not exist");

    my @remain = $arcman->list_archives;
    is($#remain, 1, "2 archives remain");

    ok(defined $arcman->get_current_archive, "current archive is defined");
    ok(defined $arcman->get_previous_archive, "previous archive is defined");
    is($arcman->get_current_archive->key, 3, "current archive is 3");
    is($arcman->get_previous_archive->key, 2, "previous archive is 2");
}

DELETE_SECOND: {
    $arcman->delete_archive(2);
    ok(!-d "t/archive-root/2", "directory t/archive-root/3 does not exist");

    my @remain = $arcman->list_archives;
    is($#remain, 0, "1 archives remain");

    ok(defined $arcman->get_current_archive, "current archive is defined");
    ok(!defined $arcman->get_previous_archive, "previous archive is not defined");
    is($arcman->get_current_archive->key, 3, "current archive is 3");
}

DELETE_LAST: {
    $arcman->delete_archive(3);
    ok(!-d "t/archive-root/3", "directory t/archive-root/3 does not exist");

    my @remain = $arcman->list_archives;
    is($#remain, -1, "0 archives remain");

    ok(!defined $arcman->get_current_archive, "current archive is not defined");
    ok(!defined $arcman->get_previous_archive, "previous archive is not defined");
}
