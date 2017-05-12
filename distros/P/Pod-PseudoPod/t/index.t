#!/usr/bin/perl -w

# t/index.t - check output from Pod::PseudoPod::Index

BEGIN {
    chdir 't' if -d 't';
}

use strict;
use lib '../lib';
use Test::More tests => 7;

use_ok('Pod::PseudoPod::Index') or exit;

my $parser = Pod::PseudoPod::Index->new ();
isa_ok ($parser, 'Pod::PseudoPod::Index');

my $results;

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

Paragraph X<test> paragraph.

=end
EOPOD
$parser->output_text;
is($results, "\ntest, 0", "a simple index item");

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

Paragraph X<testE<gt>> paragraph.

=end
EOPOD
$parser->output_text;
is($results, "\ntest>, 0", "index item with coded entity");

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

Paragraph X<test> paragraph.

Second paragraph X<another test> second paragraph.

=end
EOPOD
$parser->output_text;
is($results, "\nanother test, 0\ntest, 0", "two simple index items");

$results = '';
my $index = {};
$parser = Pod::PseudoPod::Index->new ($index);
$parser->parse_string_document(<<'EOPOD');
=pod

Paragraph X<test> paragraph.

=end
EOPOD

$parser = Pod::PseudoPod::Index->new ($index);
$parser->parse_string_document(<<'EOPOD');
=pod

Second paragraph X<going twice> second paragraph.

=end
EOPOD
$parser->output_string( \$results ); # Send the resulting output to a string
$parser->output_text;
is($results, "\ngoing twice, 0\ntest, 0", "two index items in two files");

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

Paragraph X<test;blah> paragraph.

=end
EOPOD
$parser->output_text;
is($results, "\ntest\n    blah, 0", "a two-level index item");


######################################

sub initialize {
	$_[0] = Pod::PseudoPod::Index->new ();
	$_[0]->output_string( \$results ); # Send the resulting output to a string
	$_[1] = '';
	return;
}
