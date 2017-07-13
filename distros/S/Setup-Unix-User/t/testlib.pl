use 5.010;
use strict;
use warnings;

use File::chdir;
use File::Path qw(remove_tree);
use File::Slurper qw(write_text);
use File::Temp qw(tempdir);
use Setup::Unix::Group qw(setup_unix_group);
use Setup::Unix::User  qw(setup_unix_user);
use Test::More 0.96;
use Test::Perinci::Tx::Manager qw(test_tx_action);
use Unix::Passwd::File;

sub setup_data {
    unlink "$::tmp_dir/passwd";
    write_text("$::tmp_dir/passwd", <<_);
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/bin:/bin/sh
daemon:x:2:2:daemon:/sbin:/bin/sh
u1:x:1000:1000::$::tmp_dir/u1:/bin/bash
u2:x:1001:1001::/home/u2:/bin/bash
_

    unlink "$::tmp_dir/shadow";
    write_text("$::tmp_dir/shadow", <<_);
root:*:14607:0:99999:7:::
bin:*:14607:0:99999:7:::
daemon:*:14607:0:99999:7:::
u1:*:14607:0:99999:7:::
u2:*:14607:0:99999:7:::
_

    unlink "$::tmp_dir/group";
    write_text("$::tmp_dir/group", <<_);
root:x:0:
bin:x:1:
daemon:x:2:
nobody:x:111:
u1:x:1000:u1
u2:x:1002:u2,u1
_

    unlink "$::tmp_dir/gshadow";
    write_text("$::tmp_dir/gshadow", <<_);
root:::
bin:::
daemon:::
nobody:!::
u1:!::
u2:!::u1
_

    # setup skeleton
    remove_tree "$::tmp_dir/skel";
    mkdir("$::tmp_dir/skel");
    mkdir("$::tmp_dir/skel/.dir1");
    write_text("$::tmp_dir/skel/.dir1/.file1", "file 1");
    write_text("$::tmp_dir/skel/.file2", "file 2");
    write_text("$::tmp_dir/skel/.file3", "file 3");

    # home dirs
    remove_tree "$::tmp_dir/home";
    remove_tree "$::tmp_dir/u1";
}

sub setup {
    plan skip_all => "No /etc/passwd, probably not Unix system"
        unless -f "/etc/passwd";

    $::tmp_dir = tempdir(CLEANUP => 1);
    $CWD = $::tmp_dir;

    setup_data();
    note "tmp dir = $::tmp_dir";
}

sub teardown {
    done_testing();
    if (Test::More->builder->is_passing) {
        #note "all tests successful, deleting temp files";
        $CWD = "/";
    } else {
        diag "there are failing tests, not deleting temp files";
    }
}

sub _test_setup_unix_group_or_user {
    my ($which, %tsuargs) = @_;

    my %ttaargs;
    for (grep {!/after_do|after_undo/} keys %tsuargs) {
        $ttaargs{$_} = $tsuargs{$_};
    }

    $ttaargs{tmpdir} = $::tmp_dir;
    $ttaargs{reset_state} = sub { setup_data() };
    $ttaargs{f} = $which eq 'group' ?
        'Setup::Unix::Group::setup_unix_group' :
            'Setup::Unix::User::setup_unix_user';
    my %fargs = %{ $tsuargs{args} };
    $fargs{etc_dir} = $::tmp_dir;
    $ttaargs{args} = \%fargs;

    for my $ak (qw/after_do after_undo/) {
        my $a = $tsuargs{$ak};
        next unless $a;
        #diag explain $a;
        $ttaargs{$ak} = sub {
            my $res;
            if ($which eq 'user') {
                $res = Unix::Passwd::File::get_user(
                    etc_dir=>$fargs{etc_dir}, user=>$fargs{user});
            } else {
                $res = Unix::Passwd::File::get_group(
                    etc_dir=>$fargs{etc_dir}, group=>$fargs{group});
            }
            #note explain $res;

            my $exists = $res->[0] == 200;

            if ($a->{exists} // 1) {
                ok($exists, "exists") or return;
                my $e = $res->[2];
                if ($which eq 'user') {
                    for (qw/uid gid gecos home shell/) {
                        if (defined $a->{$_}) {
                            is($e->{$_}, $a->{$_}, $_);
                        }
                    }
                } else {
                    if (defined $a->{gid}) {
                        is($e->{gid}, $a->{gid}, "gid");
                    }
                }
            } else {
                ok(!$exists, "does not exist");
            }

            if ($which eq 'user') {
                if ($a->{member_of}) {
                    for my $g (@{ $a->{member_of} }) {
                        $res = Unix::Passwd::File::is_member(
                            etc_dir=>$fargs{etc_dir},
                            user=>$fargs{user}, group=>$g);
                        ok($res,
                           "user $fargs{user} is member of $g");
                    }
                }
                if ($a->{not_member_of}) {
                    for my $g (@{ $a->{not_member_of} }) {
                        $res = Unix::Passwd::File::is_member(
                            etc_dir=>$fargs{etc_dir},
                            user=>$fargs{user}, group=>$g);
                        ok(defined($res) && !$res,
                           "user $fargs{user} is not member of $g");
                    }
                }
            }

            if ($a->{extra}) {
                $a->{extra}->();
            }
        };
    }

    test_tx_action(%ttaargs);
}

sub test_setup_unix_group { _test_setup_unix_group_or_user('group', @_) }

sub test_setup_unix_user  { _test_setup_unix_group_or_user('user',  @_) }

1;
