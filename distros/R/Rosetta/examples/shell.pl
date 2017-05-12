#!perl
use 5.008001;
use utf8;
use strict;
use warnings;

use Rosetta::Shell;

my @cmd_line_args = grep { $_ =~ m/^[a-zA-Z:_]+$/x } @ARGV;
my ($engine_name, @user_lang_prefs) = @cmd_line_args;

$engine_name = $engine_name ? $engine_name : 'Rosetta::Engine::Example';
@user_lang_prefs = 'en'
    if @user_lang_prefs == 0;

Rosetta::Shell::main({ 'engine_name' => $engine_name,
    'user_lang_prefs' => \@user_lang_prefs });
