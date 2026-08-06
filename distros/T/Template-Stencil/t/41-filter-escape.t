#!perl
use 5.016;
use strict;
use warnings;
use Test::More;
use Template::Stencil;

sub r { Template::Stencil::_render(@_) }

my $v = q{<b class="x">&'</b>};

# html at the end of the chain must not double-escape.
is(r('{% v | html %}', { v => $v }), r('{% v %}', { v => $v }),
   'html-filtered equals auto-escaped (escaped exactly once)');
unlike(r('{% v | html %}', { v => '<' }), qr/&amp;lt;/,
       'no double escape');

# A filter after html clears the escaped mark, so the result is
# escaped again (correct: upper changed the bytes).
is(r('{% v | html | upper %}', { v => '<b>' }), '&amp;LT;B&amp;GT;',
   'post-html filter re-escapes');

# raw prints without escaping regardless of filters.
is(r('{% raw v | upper %}', { v => '<b>' }), '<B>', 'raw with filter');
is(r('{% raw v | html %}', { v => '<b>' }), '&lt;b&gt;',
   'raw with html = escaped once');

# trim/upper/etc do not accidentally mark values escaped.
is(r('{% v | trim %}', { v => ' <b> ' }), '&lt;b&gt;',
   'trimmed value still auto-escaped');
is(r('{% v | upper %}', { v => '<b>' }), '&lt;B&gt;',
   'uppered value still auto-escaped');

# default replacement text goes through the normal end-of-chain escape.
is(r('{% v | default("<def>") %}', {}), '&lt;def&gt;',
   'default replacement escaped');
is(r('{% raw v | default("<def>") %}', {}), '<def>',
   'raw default replacement raw');

# uri output is inert for HTML by construction but still passes the
# escaper harmlessly.
is(r('{% v | uri %}', { v => 'a&b' }), 'a%26b', 'uri then escape no-op');

done_testing;
