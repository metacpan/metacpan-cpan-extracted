use strict;
use warnings;
use Proch::Cmd;
use Test::More tests => 1;

my $command = Proch::Cmd->new(
	command => "pwd",
);

my $output = $command->simplerun();


SKIP: {
    skip "wrong version", 1 if ( $^O ne 'linux');
    ok($output->{exit_code} == 0, "Output [pwd] returned no error");
};

