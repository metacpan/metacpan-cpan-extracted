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
use File::Slurp::Tiny qw(read_file write_file);
use File::Temp qw(tempdir);
use Setup::File::TextFragment;
use Test::More 0.98;
use Test::Perinci::Tx::Manager qw(test_tx_action);

my $tmpdir = tempdir(CLEANUP=>1);
$CWD = $tmpdir;

test_tx_action(
    name          => "file doesn't exist -> error",
    tmpdir        => $tmpdir,
    f             => "Setup::File::TextFragment::setup_text_fragment",
    args          => {path=>"p", id=>"id1", payload=>"x"},
    reset_state   => sub {
        remove_tree "p";
    },
    status        => 412,
);
test_tx_action(
    name          => "file is a dir -> error",
    tmpdir        => $tmpdir,
    f             => "Setup::File::TextFragment::setup_text_fragment",
    args          => {path=>"p", id=>"id1", payload=>"x"},
    reset_state   => sub {
        remove_tree "p";
        mkdir "p";
    },
    status        => 412,
);
test_tx_action(
    name          => "file is a symlink -> error",
    tmpdir        => $tmpdir,
    f             => "Setup::File::TextFragment::setup_text_fragment",
    args          => {path=>"p", id=>"id1", payload=>"x"},
    reset_state   => sub {
        remove_tree "p";
        write_file "f", "";
        symlink "f", "p";
    },
    status        => 412,
) if eval { symlink("", ""); 1 };

test_tx_action(
    name          => "already inserted with same content -> noop",
    tmpdir        => $tmpdir,
    f             => "Setup::File::TextFragment::setup_text_fragment",
    args          => {path=>"p", id=>"id1", payload=>"x"},
    reset_state   => sub {
        remove_tree "p";
        write_file "p", "x # FRAGMENT id=id1\n";
    },
    status        => 304,
);
test_tx_action(
    name          => "replace, comment_style",
    tmpdir        => $tmpdir,
    f             => "Setup::File::TextFragment::setup_text_fragment",
    args          => {path=>"p", id=>"id1", payload=>"x",
                      comment_style=>"cpp"},
    reset_state   => sub {
        remove_tree "p";
        write_file "p", "1\n2 // FRAGMENT id=id1\n";
    },
    status        => 200,
    after_do      => sub {
        is(~~read_file("p"), "1\nx // FRAGMENT id=id1\n", "content");
    },
    after_undo    => sub {
        is(~~read_file("p"), "1\n2 // FRAGMENT id=id1\n", "content");
    },
);

# XXX test: pass attrs
# XXX test: pass label
# XXX test: pass top_style
# XXX test: pass replace_pattern
# XXX test: pass good_pattern

DONE_TESTING:
done_testing();
if (Test::More->builder->is_passing) {
    #diag "all tests successful, deleting test data dir";
    $CWD = "/";
} else {
    diag "there are failing tests, not deleting test data dir $tmpdir";
}
