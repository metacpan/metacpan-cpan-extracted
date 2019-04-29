use strict;
use warnings;
use Proch::Cmd;
use Test::More tests => 1;

my $command = Proch::Cmd->new(
	command => "pwd",
);

my $output = $command->simplerun();

ok($output->{exit_code} == 0, "Output [pwd] returned no error");

