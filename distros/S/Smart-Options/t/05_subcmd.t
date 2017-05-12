use strict;
use Test::More;

use Smart::Options;

use File::Spec;
my $fileName = File::Spec->catfile('t','05_subcmd.t');

subtest 'support subcommand' => sub {
    my $opt = Smart::Options->new();
    $opt->subcmd(add => Smart::Options->new()->demand(qw(x y)));
    $opt->subcmd(minus => Smart::Options->new()->demand(qw(x y)));
    $opt->boolean('u');
    my $argv = $opt->parse(qw(-u add -x 10 -y 5));

    is $argv->{u}, 1;
    is $argv->{command}, 'add';
    is $argv->{cmd_option}->{x}, 10;
    is $argv->{cmd_option}->{y}, 5;
};

subtest 'subcommand usage' => sub {
    my $opt = Smart::Options->new();
    $opt->usage("Usage: $0 [option] COMMAND");
    $opt->subcmd(add => Smart::Options->new()->demand(qw(x y)));
    $opt->subcmd(minus => Smart::Options->new()->demand(qw(x y)));
    $opt->boolean('u');
    is $opt->help, <<"EOS", 'subcmd help';
Usage: $fileName [option] COMMAND

Options:
  -h, --help  Show help               
  -u                     [boolean]    

Implemented commands are:
  add, minus

EOS
};


done_testing;
