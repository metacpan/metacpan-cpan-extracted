#!/usr/bin/perl -w

# t/for.t - check PseudoPod for blocks

BEGIN {
    chdir 't' if -d 't';
}

use strict;
use lib '../lib';
use Test::More tests => 8;

use_ok('Pod::PseudoPod::HTML') or exit;

my ($parser, $results);

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=for editor
This is an ordinary for with no end directive.

EOPOD

is($results, <<'EOHTML', "a simple for");
<p>This is an ordinary for with no end directive.</p>

EOHTML

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=for editor

This is a PseudoPod for with an end directive.

=end

EOPOD

is($results, <<'EOHTML', "a for with an '=end' directive");
<p>This is a PseudoPod for with an end directive.</p>

EOHTML

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=for editor

This is a PseudoPod for with an end for directive.

=end for

EOPOD

is($results, <<'EOHTML', "a for with an '=end for' directive");
<p>This is a PseudoPod for with an end for directive.</p>

EOHTML

initialize($parser, $results);
$parser->add_css_tags(1);
$parser->parse_string_document(<<'EOPOD');
=for editor

This is a PseudoPod for with css tags turned on.

=end

EOPOD

is($results, <<'EOHTML', "an ended for with css tags");
<div class="editor">

<p>This is a PseudoPod for with css tags turned on.</p>

</div>

EOHTML

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=for author

This is a PseudoPod for with an end directive.

=end

EOPOD

is($results, <<'EOHTML', "author for");
<p>This is a PseudoPod for with an end directive.</p>

EOHTML

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=for production

This is a PseudoPod for with an end directive.

=end

EOPOD

is($results, <<'EOHTML', "production for");
<p>This is a PseudoPod for with an end directive.</p>

EOHTML

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=for ignore

This is a PseudoPod for with an end directive.

=end

EOPOD

is($results, '', "for with 'ignore' target is always ignored");

######################################

sub initialize {
	$_[0] = Pod::PseudoPod::HTML->new ();
	$_[0]->output_string( \$results ); # Send the resulting output to a string
	$_[1] = '';
	return;
}
