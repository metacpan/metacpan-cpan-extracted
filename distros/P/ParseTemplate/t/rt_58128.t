#!perl

use strict;
use warnings;

use Test::More;

use_ok 'Parse::Template';

# RT#58128 check
is Parse::Template->ppregexp('blarg(?!blarg)'), 'blarg(?!blarg)', "RT#58128";
is Parse::Template->ppregexp('blarg(?<!blarg)'), 'blarg(?<!blarg)', "RT#58128";

# check that the other conditions are OK

eval { Parse::Template->ppregexp('(') };
like $@, qr/^Unmatched \( .*?\/ at t.rt_58128\.t line \d+\.?\n/,
		"badly formed";

is Parse::Template->ppregexp('[a-z]'), '[a-z]', "normal";

is Parse::Template->ppregexp('!1'), '\\!1', "! not escaped";
is Parse::Template->ppregexp('/1'), '\\/1', "/ not escaped";
is Parse::Template->ppregexp('"1'), '\\"1', "\" not escaped";

is Parse::Template->ppregexp('\\!1'), '\\!1', "! escaped - no change";
is Parse::Template->ppregexp('\\/1'), '\\/1', "/ escaped - no change";
is Parse::Template->ppregexp('\\"1'), '\\"1', "\" escaped - no change";

is Parse::Template->ppregexp('\\\\!1'), '\\\\\\!1', "! not escaped preceeded by double backslash - escape";
is Parse::Template->ppregexp('\\\\/1'), '\\\\\\/1', "/ not escaped preceeded by double backslash - escape";
is Parse::Template->ppregexp('\\\\"1'), '\\\\\\"1', "\" not escaped preceeded by double backslash - escape";

is Parse::Template->ppregexp('\\\\\\!1'), '\\\\\\!1', "! escaped preceeded by double backslash - no change";
is Parse::Template->ppregexp('\\\\\\/1'), '\\\\\\/1', "/ escaped preceeded by double backslash - no change";
is Parse::Template->ppregexp('\\\\\\"1'), '\\\\\\"1', "\" escaped preceeded by double backslash - no change";

is Parse::Template->ppregexp('\\\\\\\\!1'), '\\\\\\\\\\!1', "! escaped preceeded by quad backslash - escape";
is Parse::Template->ppregexp('\\\\\\\\/1'), '\\\\\\\\\\/1', "/ escaped preceeded by quad backslash - escape";
is Parse::Template->ppregexp('\\\\\\\\"1'), '\\\\\\\\\\"1', "\" escaped preceeded by quad backslash - escape";

done_testing();
