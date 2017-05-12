#!/usr/bin/perl
use strict;
use warnings;

use Capture::Tiny qw(capture_stdout);
use Mock::Sub;
use Test::BrewBuild;
use Test::More;

if (! $ENV{BBDEV_TESTING}){
    plan skip_all => "developer tests only";
    exit;
}

my $mock = Mock::Sub->new;
my $inst_cmd = $mock->mock('Test::BrewBuild::BrewCommands::install');
$inst_cmd->return_value('echo');

{ # ensure release candidates get included in rand install

    my $bb = Test::BrewBuild->new( notest => 1 );
    my @avail = $bb->perls_available;

    my $stdout = capture_stdout {
            $bb->instance_install( 10 );
    };

    my @perls = split /\n/, $stdout;

    if (grep /RC/, @avail){
        is ((grep /RC/, @perls), 1, "RC candidates get included");
    }
    else {
        is (1, 1, "to prevent skipping");
    }           
}

for ($mock->mocked_objects){
    $_->unmock;
    is ($_->mocked_state, 0, $_->name ." has been unmocked ok");
}

done_testing();

