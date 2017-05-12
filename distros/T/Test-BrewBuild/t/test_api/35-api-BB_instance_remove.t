#!/usr/bin/perl
use strict;
use warnings;

use Mock::Sub;
use Test::BrewBuild;
use Test::More;

my $mock = Mock::Sub->new;
my $remove_cmd = $mock->mock('Test::BrewBuild::BrewCommands::remove');
$remove_cmd->return_value('echo "install"');
my $info = $mock->mock('Test::BrewBuild::BrewCommands::info');

my $out;
open my $stdout, '>', \$out or die $!;
select $stdout;

if ($^O =~ /MSWin/) {
    my $bb = Test::BrewBuild->new(debug => 7);
    my $ok = eval { $bb->instance_remove(qw(5.20.0)); 1; };
    is ($remove_cmd->called, 1, "win: BrewCommands::remove() called");
    is ($ok, 1, "win: instance_remove() ok");
}
else {
    my $bb = Test::BrewBuild->new(debug => 7);
    my $ok = eval {
        $bb->instance_remove( qq(5.20.0) ); 1; };
    is ($remove_cmd->called, 1, "nix: BrewCommands::install() called");
    is ( $ok, 1, "nix: instance_remove() ok" );
}

for ($mock->mocked_objects){
    $_->unmock;
    is ($_->mocked_state, 0, $_->name ." has been unmocked ok");
}

select STDOUT;

done_testing();

