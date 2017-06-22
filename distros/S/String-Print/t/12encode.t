#!/usr/bin/env perl
# Output encoding (to HTML)

use warnings;
use strict;
use utf8;
use Test::More tests => 7;

use String::Print;

my $f = String::Print->new(encode_for => 'HTML');
isa_ok($f, 'String::Print');

# encode HTML, all
is $f->sprinti('Me & You'), 'Me &amp; You';
is $f->sprinti('< {a} >', a => 'Me & You'), '&lt; Me &amp; You &gt;';

# exclude HTML encoding for names =~ /html$/i
is $f->sprinti('<{a_html}>', a_html => 'Me &amp; You'), '&lt;Me &amp; You&gt;';
is $f->sprinti('<{aHTML}>', aHTML => 'Me &amp; You'), '&lt;Me &amp; You&gt;';

# disable encoding
$f->encodeFor(undef);
is $f->sprinti('< {a} >', a => 'Me & You'), '< Me & You >';

# enable encoding
$f->encodeFor('HTML');
is $f->sprinti('< {a} >', a => 'Me & You'), '&lt; Me &amp; You &gt;';

