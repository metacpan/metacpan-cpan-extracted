#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
#use lib $Bin, "$Bin/t";
#use Log::Any '$log';

use File::chdir;
use File::Copy;
use File::Path qw(remove_tree);
use File::Slurper qw(read_text write_text);
use File::Temp qw(tempdir);
use Setup::File::Line;
use Test::More 0.98;
use Test::Perinci::Tx::Manager qw(test_tx_action);

my $tmpdir = tempdir(CLEANUP=>1);
$CWD = $tmpdir;

test_tx_action(
    name          => "file doesn't exist -> error",
    tmpdir        => $tmpdir,
    f             => "Setup::File::Line::setup_file_line",
    args          => {path=>"p", line_content=>"id1"},
    reset_state   => sub {
        remove_tree "p";
    },
    status        => 412,
);
test_tx_action(
    name          => "file is a dir -> error",
    tmpdir        => $tmpdir,
    f             => "Setup::File::Line::setup_file_line",
    args          => {path=>"p", line_content=>"id1"},
    reset_state   => sub {
        remove_tree "p";
        mkdir "p";
    },
    status        => 412,
);
test_tx_action(
    name          => "file is a symlink -> error",
    tmpdir        => $tmpdir,
    f             => "Setup::File::Line::setup_file_line",
    args          => {path=>"p", line_content=>"id1"},
    reset_state   => sub {
        remove_tree "p";
        write_text "f", "";
        symlink "f", "p";
    },
    status        => 412,
) if eval { symlink("", ""); 1 };

test_tx_action(
    name          => "line already exists -> noop",
    tmpdir        => $tmpdir,
    f             => "Setup::File::Line::setup_file_line",
    args          => {path=>"p", line_content=>"id1"},
    reset_state   => sub {
        remove_tree "p";
        write_text "p", "line\nid1\n";
    },
    status        => 304,
);
test_tx_action(
    name          => "line does not exist -> added",
    tmpdir        => $tmpdir,
    f             => "Setup::File::Line::setup_file_line",
    args          => {path=>"p", line_content=>"id1"},
    reset_state   => sub {
        remove_tree "p";
        write_text "p", "line\n";
    },
    status        => 200,
    after_do      => sub {
        is(read_text("p"), "line\nid1\n", "content");
    },
    after_undo    => sub {
        is(read_text("p"), "line\n", "content");
    },
);
test_tx_action(
    name          => "adding with top_style=1",
    tmpdir        => $tmpdir,
    f             => "Setup::File::Line::setup_file_line",
    args          => {path=>"p", line_content=>"id1", top_style=>1},
    reset_state   => sub {
        remove_tree "p";
        write_text "p", "line\n";
    },
    status        => 200,
    after_do      => sub {
        is(read_text("p"), "id1\nline\n", "content");
    },
    after_undo    => sub {
        is(read_text("p"), "line\n", "content");
    },
);
test_tx_action(
    name          => "can handle newline in line_content",
    tmpdir        => $tmpdir,
    f             => "Setup::File::Line::setup_file_line",
    args          => {path=>"p", line_content=>"id1\n"},
    reset_state   => sub {
        remove_tree "p";
        write_text "p", "line\n";
    },
    status        => 200,
    after_do      => sub {
        is(read_text("p"), "line\nid1\n", "content");
    },
    after_undo    => sub {
        is(read_text("p"), "line\n", "content");
    },
);
test_tx_action(
    name          => "can handle empty file content properly",
    tmpdir        => $tmpdir,
    f             => "Setup::File::Line::setup_file_line",
    args          => {path=>"p", line_content=>"id1"},
    reset_state   => sub {
        remove_tree "p";
        write_text "p", "";
    },
    status        => 200,
    after_do      => sub {
        is(read_text("p"), "id1\n", "content");
    },
    after_undo    => sub {
        is(read_text("p"), "", "content");
    },
);
test_tx_action(
    name          => "can handle lack of newline ending in file",
    tmpdir        => $tmpdir,
    f             => "Setup::File::Line::setup_file_line",
    args          => {path=>"p", line_content=>"id1"},
    reset_state   => sub {
        remove_tree "p";
        write_text "p", "line";
    },
    status        => 200,
    after_do      => sub {
        is(read_text("p"), "line\nid1\n", "content");
    },
    after_undo    => sub {
        is(read_text("p"), "line\n", "content");
    },
);

test_tx_action(
    name          => "should_exist=0, line already does not exist -> noop",
    tmpdir        => $tmpdir,
    f             => "Setup::File::Line::setup_file_line",
    args          => {path=>"p", should_exist=>0, line_content=>"id1"},
    reset_state   => sub {
        remove_tree "p";
        write_text "p", "line\nId1";
    },
    status        => 304,
);
test_tx_action(
    name          => "should_exist=0, existing line removed (all occurrences)",
    tmpdir        => $tmpdir,
    f             => "Setup::File::Line::setup_file_line",
    args          => {path=>"p", should_exist=>0, line_content=>"id1"},
    reset_state   => sub {
        remove_tree "p";
        write_text "p", "line\nid1\nid1\n";
    },
    status        => 200,
    after_do      => sub {
        is(read_text("p"), "line\n", "content");
    },
    after_undo    => sub {
        is(read_text("p"), "line\nid1\n", "content"); # only added one line by setup_file_line, this is as intended
    },
);
test_tx_action(
    name          => "should_exist=0, case_insensitive=1",
    tmpdir        => $tmpdir,
    f             => "Setup::File::Line::setup_file_line",
    args          => {path=>"p", should_exist=>0, line_content=>"id1", case_insensitive=>1},
    reset_state   => sub {
        remove_tree "p";
        write_text "p", "line\nId1";
    },
    status        => 200,
    after_do      => sub {
        is(read_text("p"), "line\n", "content");
    },
    after_undo    => sub {
        is(read_text("p"), "line\nid1\n", "content");
    },
);

DONE_TESTING:
done_testing();
if (Test::More->builder->is_passing) {
    #diag "all tests successful, deleting test data dir";
    $CWD = "/";
} else {
    diag "there are failing tests, not deleting test data dir $tmpdir";
}
