#!/usr/bin/perl -w

# t/fcodes.t - check formatting codes

BEGIN {
    chdir 't' if -d 't';
}

use strict;
use lib '../lib';
use Test::More tests => 4;

use_ok('Pod::PseudoPod::HTML') or exit;

my $parser = Pod::PseudoPod::HTML->new ();
isa_ok ($parser, 'Pod::PseudoPod::HTML');

my $results;

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

B<Egad!> You astound me, Brain!

EOPOD

is($results, <<'EOHTML', "simple B<> code");
<p><b>Egad!</b> You astound me, Brain!</p>

EOHTML

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

  literal code with B<bold> characters
  and some more lines, to test.

EOPOD

is($results, <<'EOHTML', "B<> in literal code");
<pre><code>  literal code with <b>bold</b> characters
  and some more lines, to test.</code></pre>

EOHTML

######################################

sub initialize {
	$_[0] = Pod::PseudoPod::HTML->new ();
	$_[0]->output_string( \$results ); # Send the resulting output to a string
	$_[1] = '';
	return;
}
