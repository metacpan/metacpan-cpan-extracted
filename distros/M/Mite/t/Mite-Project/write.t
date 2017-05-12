#!/usr/bin/perl -w

use lib 't/lib';
use Test::Mite;

use Mite::Project;

tests "Empty write" => sub {
    my $project = new_ok "Mite::Project";

    lives_ok { $project->write_mites };
};

done_testing;
