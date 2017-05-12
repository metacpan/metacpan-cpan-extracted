#!/usr/bin/perl
use strict;
use warnings;

use Capture::Tiny qw(capture_stdout);
use Mock::Sub;
use Test::BrewBuild;
use Test::More;

my $mock = Mock::Sub->new;
my $inst_cmd = $mock->mock('Test::BrewBuild::BrewCommands::install');
$inst_cmd->return_value('echo');
my $info = $mock->mock('Test::BrewBuild::BrewCommands::info');
$info->return_value('echo');

{
    # rand dups

    my $bb = Test::BrewBuild->new( notest => 1 );

    my $stdout = capture_stdout {
            $bb->instance_install( 10 );
        };

    my @ret = split /\n/, $stdout;
    chomp @ret;

    my %count;
    map {$count{$_}++} @ret;

    for (keys %count) {
        is ( $count{$_}, 1, "$_ installed only once" );
    }

    $inst_cmd->reset;
}

for ($mock->mocked_objects){
    $_->unmock;
    is ($_->mocked_state, 0, $_->name ." has been unmocked ok");
}

done_testing();

