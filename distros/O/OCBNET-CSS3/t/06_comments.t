# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 11;
BEGIN { use_ok('OCBNET::CSS3::Regex::Comments') };

my ($rv, @rv);

use OCBNET::CSS3::Regex::Comments qw(comments);

my $code = <<EOF;

.test-01
{
	/* css-id: test-01; */
	border: 1px /* inline */ solid;
}

.test-02
{
	/* css-id: test-02; */
	/* css-ref: test-01; */
	border-style: dotted;
}

.test-03
{
	/* css-id: test-03; */
	/* css-ref: test-02; */
	border: 5px;
}

EOF


@rv = comments($code);

is    (scalar(@rv),                    6,                                      'correct number of comments extracted');
is    ($rv[0],                         'css-id: test-01;',                     'comment 0 matches');
is    ($rv[1],                         'inline',                               'comment 1 matches');
is    ($rv[2],                         'css-id: test-02;',                     'comment 2 matches');
is    ($rv[3],                         'css-ref: test-01;',                    'comment 3 matches');
is    ($rv[4],                         'css-id: test-03;',                     'comment 4 matches');
is    ($rv[5],                         'css-ref: test-02;',                    'comment 5 matches');

my $css = OCBNET::CSS3::Stylesheet->new;

BEGIN { use_ok('OCBNET::CSS3') };

$rv = $css->parse($code);

my @inline = $rv->child(0)->child(1)->comment;

is    (scalar(@inline),                1,                                      'correct number of inline comments extracted');
is    ($inline[0],                     'inline',                               'comment 5 matches');
