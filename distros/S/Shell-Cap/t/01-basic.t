#!perl

use strict;
use warnings;
use Test::More 0.98;

use Shell::Cap qw(shell_supports_pipe);

subtest shell_supports_pipe => sub {
    diag "shell_supports_pipe: ", shell_supports_pipe();
    ok 1;
};

done_testing;
