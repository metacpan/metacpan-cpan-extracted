#!/usr/bin/perl -w

use strict;

use Test::More tests => 12;

BEGIN
{
  use_ok('Rose::HTML::Script');
}

my $s = Rose::HTML::Script->new(script => 'function foo() { return 123; }');

is($s->type, 'text/javascript', 'type');

is($s->script, 'function foo() { return 123; }', 'script');
is($s->contents, 'function foo() { return 123; }', 'contents');

is($s->html . "\n", <<'EOF', 'html 1');
<script type="text/javascript">
<!--
function foo() { return 123; }
// -->
</script>
EOF

is($s->xhtml . "\n", <<'EOF', 'xhtml 1');
<script type="text/javascript"><!--//--><![CDATA[//><!--
function foo() { return 123; }
//--><!]]></script>
EOF

$s->support_older_browsers(0);

is($s->xhtml . "\n", <<'EOF', 'xhtml 2');
<script type="text/javascript">
//<![CDATA[
function foo() { return 123; }
//]]>
</script>
EOF

is($s->html . "\n", <<'EOF', 'html 2');
<script type="text/javascript">
<!--
function foo() { return 123; }
// -->
</script>
EOF

Rose::HTML::Script->default_support_older_browsers(0);

$s->support_older_browsers(undef);
is($s->support_older_browsers, 0, 'default_support_older_browsers 1');

$s = Rose::HTML::Script->new;

is($s->support_older_browsers, 0, 'default_support_older_browsers 2');

Rose::HTML::Script->default_support_older_browsers(1);

$s->src('/scripts/main.js');

is($s->html, '<script src="/scripts/main.js" type="text/javascript"></script>', 'html 3');
is($s->xhtml, '<script src="/scripts/main.js" type="text/javascript" />', 'xhtml 3');

