#!/usr/bin/perl

##
## Tests for Petal::Utils::Base module
##

use blib;
use strict;

use Test::More qw(no_plan);
use Carp;
use Data::Dumper;

use t::LoadPetal;
use base qw( Petal::Utils::Base );


##
## split_first_arg
##

#
# Define argument strings for testing
my $arg_string1 = 'first second';
my $arg_string2 = q~'first' second~;
my $arg_string3 = q~first second third~;
my $arg_string4 = q~'first' second third fourth~;
my $arg_string5 = q~string: first second~; # arg list with embedded modifier

#
# Perform tests
my @args = Petal::Utils::Base->split_first_arg($arg_string1);
is( $args[0], 'first', "split_first_arg - '$arg_string1'" );
is( $args[1], 'second', "split_first_arg - '$arg_string1'" );

@args = Petal::Utils::Base->split_first_arg($arg_string2);
is( $args[0], q~'first'~, "split_first_arg - '$arg_string2'" );
is( $args[1], 'second', "split_first_arg - '$arg_string2'" );

@args = Petal::Utils::Base->split_first_arg($arg_string3);
is( $args[0], 'first', "split_first_arg - '$arg_string3'" );
is( $args[1], 'second third', "split_first_arg - '$arg_string3'" );
is( $args[2], undef, "split_first_arg - '$arg_string3'" );

@args = Petal::Utils::Base->split_first_arg($arg_string4);
is( $args[0], q~'first'~, "split_first_arg - '$arg_string4'" );
is( $args[1], 'second third fourth', "split_first_arg - '$arg_string4'" );
is( $args[2], undef, "split_first_arg - '$arg_string4'" );
is( $args[3], undef, "split_first_arg - '$arg_string4'" );

@args = Petal::Utils::Base->split_first_arg($arg_string5);
is( $args[0], 'string:', "split_first_arg - '$arg_string5''" );
is( $args[1], 'first second', "split_first_arg - '$arg_string5''" );


##
## split_args
##

#
# Perform tests
@args = Petal::Utils::Base->split_args($arg_string1);
is( $args[0], 'first', "split_args - '$arg_string1'" );
is( $args[1], 'second', "split_args - '$arg_string1'" );

@args = Petal::Utils::Base->split_args($arg_string2);
is( $args[0], q~'first'~, "split_args - '$arg_string2'" );
is( $args[1], 'second', "split_args - '$arg_string2'" );

@args = Petal::Utils::Base->split_args($arg_string3);
is( $args[0], 'first', "split_args - '$arg_string3'" );
is( $args[1], 'second', "split_args - '$arg_string3'" );
is( $args[2], 'third', "split_args - '$arg_string3'" );

@args = Petal::Utils::Base->split_args($arg_string4);
is( $args[0], q~'first'~, "split_args - '$arg_string4'" );
is( $args[1], 'second', "split_args - '$arg_string4'" );
is( $args[2], 'third', "split_args - '$arg_string4'" );
is( $args[3], 'fourth', "split_args - '$arg_string4'" );

@args = Petal::Utils::Base->split_args($arg_string5);
is( $args[0], 'string:', "split_args - '$arg_string5'" );
is( $args[1], 'first', "split_args - '$arg_string5'" );
is( $args[2], 'second', "split_args - '$arg_string5'" );


##
## fetch_arg
##
my $data_hash = {
  dad => 'George',
  mom => 'Jane',
  dog => 'Astro',
};
my $hash = Petal::Hash->new(%$data_hash);
is ( Petal::Utils::Base->fetch_arg($hash, 'dad'), $data_hash->{'dad'}, "Fetch value of Dad" );
is ( Petal::Utils::Base->fetch_arg($hash, "'plain'"), 'plain', "Fetch plaintext" );
is ( Petal::Utils::Base->fetch_arg($hash, '123'), '123', "Fetch number" );
is ( Petal::Utils::Base->fetch_arg($hash, '123.50'), '123.50', "Fetch number with decimal" );
