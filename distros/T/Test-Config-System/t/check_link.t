#!perl -T

use warnings;
use strict;

use File::Temp qw /tempfile/;
use Test::Config::System;


if (eval { symlink("",""); 1 }) {      # if FS does symlinks
    my ($d1, $tmp) = tempfile();
    unlink $tmp;
    if (symlink("lib/Test/Config/System.pm", $tmp)) {
        plan(tests => 3);
        check_link($tmp, "lib/Test/Config/System.pm", 'check_link(pass)');
        check_link($tmp, '', 'check_link(pass,valid link,no target)');
        check_link('/aoeuaoeu', undef, 'check_link(fail,invalid link, no target, inverted)', 1);
        unlink $tmp;
    } else {
        plan( skip_all => 'could not create symlink' );
    }
} else {
    plan( skip_all => 'filesystem does not support symlinks');
}

