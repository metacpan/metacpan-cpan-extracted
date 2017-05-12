# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 18;
BEGIN { use_ok('OCBNET::CSS3') };

my $rv;

use OCBNET::CSS3::Styles::References;

# OO interface
my $css = OCBNET::CSS3::Stylesheet->new;

my $code = <<EOF;

.test-01 { /* css-id: test; */ }
.test-02 { /* css-ref: test; */ }

EOF

$rv = $css->parse($code);

is    ($css->child(0)->option('css-id'),    'test',      'parse css-id');
is    ($css->child(1)->option('css-ref'),   'test',      'parse css-ref');

# create a new stylesheet
$css = OCBNET::CSS3::Stylesheet->new;

$code = <<EOF;

.test-01 { foo: 01; bar: 01; baz: 01; /* css-id: test-01; */ }
.test-01 { foo: 02; bar: 02; /* css-id: test-02; css-ref: test-01; */ }
.test-02 { foo: 03; baz: 03; /* css-id: test-03; css-ref: test-01; */ }

.test-03 { /* css-ref: foo, bar, baz; */ }

.foo { foo: foo; /* css-id: foo; */ }
.bar { bar: bar; /* css-id: bar; */ }
.baz { baz: baz; /* css-id: baz; */ }

EOF

$rv = $css->parse($code);

is    ($css->child(0)->style('foo'),    '01',      'test foo #1');
is    ($css->child(1)->style('foo'),    '02',      'test foo #2');
is    ($css->child(2)->style('foo'),    '03',      'test foo #3');
is    ($css->child(0)->style('bar'),    '01',      'test bar #1');
is    ($css->child(1)->style('bar'),    '02',      'test bar #2');
is    ($css->child(2)->style('bar'),    '01',      'test bar #3');
is    ($css->child(0)->style('baz'),    '01',      'test baz #1');
is    ($css->child(1)->style('baz'),    '01',      'test baz #2');
is    ($css->child(2)->style('baz'),    '03',      'test baz #3');

is    ($css->child(3)->option('css-ref', 0),    'foo',     'test foo ref');
is    ($css->child(3)->option('css-ref', 1),    'bar',     'test bar ref');
is    ($css->child(3)->option('css-ref', 2),    'baz',     'test baz ref');

is    ($css->child(3)->style('foo'),    'foo',     'test foo #4');
is    ($css->child(3)->style('bar'),    'bar',     'test bar #4');
is    ($css->child(3)->style('baz'),    'baz',     'test baz #4');
