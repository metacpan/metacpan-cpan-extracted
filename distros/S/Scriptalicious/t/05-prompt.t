#!/usr/bin/perl

use Scriptalicious;

use Test::More tests => 2;

#use t::Util;

my $output = capture( -in => sub { print "Hi there\n17\n"; },
		      #-out2 => $testfile,
		      $^X, "-Mlib=lib", "t/prompter.pl", "--int"
		    );

#my $err = slurp $testfile;

like($output, qr/response: `17'/, "got right answer");
like($output, qr/bad.*`Hi there'/, "spotted wrong answer");

# full test 

