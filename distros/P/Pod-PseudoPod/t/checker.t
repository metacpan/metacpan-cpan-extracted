#!/usr/bin/perl -w

# t/checker.t - test Checker.pm

BEGIN {
    chdir 't' if -d 't';
}

use strict;
use lib '../lib';
use Test::More tests => 3;

use_ok('Pod::PseudoPod::Checker') or exit;

my $parser = Pod::PseudoPod::Checker->new ();
isa_ok ($parser, 'Pod::PseudoPod::Checker');

my $results;

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=begin sidebar

A sidebar with some content.

=end

EOPOD

is($results, <<'EOERR', "catch mismatched =begin/=end tags");
POD ERRORS
Hey! The above document had some coding errors, which are explained below:
Around line 5:
  '=end' without a target? (Should be "=end sidebar")
EOERR


######################################

sub initialize {
	$_[0] = Pod::PseudoPod::Checker->new ();
	$_[0]->output_string( \$results ); # Send the resulting output to a string
	$_[1] = '';
	return;
}
