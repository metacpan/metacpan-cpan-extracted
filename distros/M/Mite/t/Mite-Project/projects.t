#!/usr/bin/perl -w

use lib 't/lib';
use Test::Mite;

use Mite::Project;

tests "Default project" => sub {
    my $project = Mite::Project->default;
    isa_ok $project, "Mite::Project";

    is( Mite::Project->default, $project, "same default" );

    my $new_project = new_ok "Mite::Project";
    Mite::Project->set_default($new_project);
    is( Mite::Project->default, $new_project, "changed default" );    
};

done_testing;
