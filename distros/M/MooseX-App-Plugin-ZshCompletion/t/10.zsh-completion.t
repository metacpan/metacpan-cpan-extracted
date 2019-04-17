use strict;
use warnings;
use Test::More tests => 3;

use FindBin '$Bin';
use lib "$Bin/lib";
use
    MyApp;

MooseX::App::ParsedArgv->new(argv => [qw(zsh_completion)]);
my $test01 = MyApp->new_with_command;
isa_ok($test01,'MooseX::App::Message::Envelope');

my $zsh_completion = $test01->stringify;

my ($command) = $zsh_completion =~ m/_10_zsh-completion_t_fetch_mail\(\)\s\{(.*?)^\}/ms;
ok(length $command, "fetch_mail command present");

cmp_ok($command, '=~', qr/
    _arguments\s-C .*
    '1:\s:->subcmd' .*
    '2:\s:->server' .*
    '--verbose\[be\sverbose\]' .*
    '--max\[Maximum\snumber\sof\semails\sto\sfetch\]:max'
    /xs, "options present");

