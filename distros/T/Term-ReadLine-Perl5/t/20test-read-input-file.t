#!/usr/bin/env perl

# About the numbering 20.. This should probably go after the unescape
# test since rl_read_input_file() calls unescape(). So if the unescape
# fails, we probably expect this one to as well.

# Lots of boilerplate here... Put in a helper file?
use strict; use warnings;
use Test::More;
use File::Basename qw(dirname);
use File::Spec;

use lib '../lib' ;

$ENV{PERL_RL} = 'Perl5';	# force to use Term::ReadLine::Perl5
$ENV{LANG} = 'C';
$ENV{'COLUMNS'} = 80;
$ENV{'LINES'} = 25;
# stop reading ~/.inputrc
$ENV{'INPUTRC'} = '/dev/null';

use Term::ReadLine::Perl5::readline qw(rl_read_init_file);

# Okay we've read in readline.pm. Now get to work testing
# read_an_init_file

my $dir = File::Spec->catfile(dirname(__FILE__));
my $input_file = File::Spec->catfile($dir, qw(data undo.inputrc));
Term::ReadLine::Perl5::readline::rl_read_init_file($input_file);

# use Data::Printer;
# p @{readline::emacs_keymap};

# Some tests! (Just when you thought we'd never get around to it.)
for my $i (1..8) {
    no warnings 'once';
    is($Term::ReadLine::Perl5::readline::KeyMap[$i], 'F_Undo',
       "KeyMap[$i] reassigned")
}

done_testing();
