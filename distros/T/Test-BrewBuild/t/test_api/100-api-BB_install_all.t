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

{
    my $bb = Test::BrewBuild->new( notest => 1 );

    my $stdout = capture_stdout {
            $bb->instance_install( -1 );
        };

    my @ret = split /\n/, $stdout;
    chomp @ret;

    ok (@ret > 4, "-1 works ok");

    $inst_cmd->reset;
}

for ($mock->mocked_objects){
    $_->unmock;
    is ($_->mocked_state, 0, $_->name ." has been unmocked ok");
}

done_testing();

