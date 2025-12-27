#!/usr/bin/env perl
use strict;
use warnings;
use lib qw( ../lib );
use Template;
use Test::More tests => 25;
use POSIX qw( localeconv );

# for testing known bug with locales that don't use '.' as a decimal
# separator - see TODO file.
# POSIX::setlocale( &POSIX::LC_ALL, 'sv_SE' );
POSIX::setlocale( &POSIX::LC_ALL, 'C' );

my $loc = localeconv;
my $dec = $loc->{decimal_point};

warn "decimal==$dec";

my $vars = { decimal    => $dec, };
my $opts = { POST_CHOMP => 1 };
my ( $buf, $tmpl, $expected );

ok( my $template = Template->new($opts), "Template->new" );

###############################################################
$tmpl = '[% USE Autoformat %][% "just some text" | Autoformat %]';
$expected = "just some text\n\n";
ok( $template->process( \$tmpl, {}, \$buf ), "process tmpl" );
is( $buf, $expected, "got expected");

###############################################################
$tmpl = <<EOF;
[% global.text = BLOCK %]
This is some text which
I would like to have formatted
and I should ensure that it continues
for a reasonable length
[% END %]
[% USE Autoformat(left => 3, right => 20) %]
[% Autoformat(global.text) %]
EOF

$expected = <<EOF;
  This is some text
  which I would like
  to have formatted
  and I should
  ensure that it
  continues for a
  reasonable length

EOF

$buf = "";
ok( $template->process( \$tmpl, $vars, \$buf ), "process tmpl" );
is( $buf, $expected, "got expected" );

###############################################################
$tmpl = <<EOF;
[% USE Autoformat(left=5) %]
[% Autoformat(global.text, right=30) %]
EOF

$expected = <<EOF;
    This is some text which I
    would like to have
    formatted and I should
    ensure that it continues
    for a reasonable length

EOF

$buf = "";
ok( $template->process( \$tmpl, $vars, \$buf ), "process tmpl" );
is( $buf, $expected, "got expected" );

###############################################################
$tmpl = <<EOF;
[% USE Autoformat %]
[% Autoformat(global.text, 'more text', right=50) %]
EOF

$expected = <<EOF;
This is some text which I would like to have
formatted and I should ensure that it continues
for a reasonable length more text

EOF

$buf = "";
ok( $template->process( \$tmpl, $vars, \$buf ), "process tmpl" );
is( $buf, $expected, "got expected" );

###############################################################
$tmpl = <<EOF;
[% USE Autoformat(left=10) %]
[% global.text | Autoformat %]
EOF

$expected = <<EOF;
         This is some text which I would like to have formatted and I
         should ensure that it continues for a reasonable length

EOF

$buf = "";
ok( $template->process( \$tmpl, $vars, \$buf ), "process tmpl" );
is( $buf, $expected, "got expected" );

###############################################################
$tmpl = <<EOF;
[% USE Autoformat(left=5) %]
[% global.text | Autoformat(right=30) %]
EOF

$expected = <<EOF;
    This is some text which I
    would like to have
    formatted and I should
    ensure that it continues
    for a reasonable length

EOF

$buf = "";
ok( $template->process( \$tmpl, $vars, \$buf ), "process tmpl" );
is( $buf, $expected, "got expected" );

###############################################################
$tmpl = <<EOF;
[% USE Autoformat %]
[% FILTER Autoformat(right=>30, case => 'upper') -%]
This is some more text.  OK!  There's no need to shout!
> quoted stuff goes here
> more quoted stuff
> blah blah blah
[% END %]
EOF

$expected = <<EOF;
THIS IS SOME MORE TEXT. OK!
THERE'S NO NEED TO SHOUT!
> quoted stuff goes here
> more quoted stuff
> blah blah blah
EOF

$buf = "";
ok( $template->process( \$tmpl, $vars, \$buf ), "process tmpl" );
is( $buf, $expected, "got expected" );

###############################################################
$tmpl = <<EOF;
[% USE Autoformat %]
[% Autoformat(global.text, ' of time.') %]
EOF

$expected = <<EOF;
This is some text which I would like to have formatted and I should
ensure that it continues for a reasonable length of time.

EOF

$buf = "";
ok( $template->process( \$tmpl, $vars, \$buf ), "process tmpl" );
is( $buf, $expected, "got expected" );

###############################################################
$tmpl = <<EOF;
[% USE Autoformat %]
[% Autoformat(global.text, ' of time.', right=>30) %]
EOF

$expected = <<EOF;
This is some text which I
would like to have formatted
and I should ensure that it
continues for a reasonable
length of time.

EOF

$buf = "";
ok( $template->process( \$tmpl, $vars, \$buf ), "process tmpl" );
is( $buf, $expected, "got expected" );

###############################################################
$tmpl = <<EOF;
[% USE Autoformat %]
[% FILTER poetry = Autoformat(left => 20, right => 40) %]
   Be not afeard.  The isle is full of noises, sounds and sweet 
   airs that give delight but hurt not.
[% END %]
[% FILTER poetry %]
   I cried to dream again.
[% END %]
EOF

$expected = <<EOF;
                   Be not afeard. The
                   isle is full of
                   noises, sounds and
                   sweet airs that give
                   delight but hurt not.

                   I cried to dream
                   again.

EOF

$buf = "";
ok( $template->process( \$tmpl, $vars, \$buf ), "process tmpl" );
is( $buf, $expected, "got expected" );

###############################################################
$tmpl = <<EOF;
Item      Description          Cost
===================================
[% form = BLOCK %]
<<<<<<    [[[[[[[[[[[[[[[   >>>>[% decimal %]<<
[% END -%]
[% USE Autoformat(form => form) %]
[% Autoformat('foo', 'The Foo Item', 123.545) %]
[% Autoformat('bar', 'The Bar Item', 456.789) %]
EOF

# sprintf rounding is somewhat unpredictable per-machine,
# so make our expectations align predictably.
my $rounded = sprintf('%0.2f', '123.545');

$expected = <<EOF;
Item      Description          Cost
===================================
foo       The Foo Item       $rounded
bar       The Bar Item       456${dec}79
EOF

$buf = "";
ok( $template->process( \$tmpl, $vars, \$buf ), "process tmpl" );
is( $buf, $expected, "got expected" );

###############################################################
$tmpl = <<EOF;
[% USE Autoformat(form => '>>>.<<', numeric => 'AllPlaces') %]
[% Autoformat(n) 
    FOREACH n = [ 123, 34.54, 99 ] +%]
[% Autoformat(987, 654.32) %]
EOF

$expected = <<EOF;
123${dec}00
 34${dec}54
 99${dec}00

987${dec}00
654${dec}32
EOF

$buf = "";
ok( $template->process( \$tmpl, $vars, \$buf ), "process tmpl" );
is( $buf, $expected, "got expected" );

