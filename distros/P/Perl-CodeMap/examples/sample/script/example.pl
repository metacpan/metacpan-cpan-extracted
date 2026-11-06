#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Demo::App;

# Entry point for the demonstration.
sub main {
    print Demo::App->status, "\n";
}
main();
