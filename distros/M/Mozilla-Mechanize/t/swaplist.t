#!/usr/bin/perl
use strict;
use warnings;

use URI::file;

use Test::More;
plan tests => 25;

use_ok 'Mozilla::Mechanize';

my $url = URI::file->new_abs( "t/html/swaplist.html" )->as_string;

isa_ok my $moz = Mozilla::Mechanize->new(visible => 0), "Mozilla::Mechanize";
isa_ok $moz->{agent}, "Mozilla::Mechanize::Browser";

ok $moz->get( $url ), "get($url)";

is $moz->title, "Swaplist Test Page", "->title method";

is $moz->ct, "text/html", "->ct method";

isa_ok my $form = $moz->form_name( 'swaplist' ), 'Mozilla::Mechanize::Form';

my $ni_list = $form->find_input( 'notin', 'select-multiple' );
isa_ok $ni_list, 'Mozilla::Mechanize::Input';

my @preset = qw( choice1 choice3 );
my @selected = $moz->field( 'notin', \@preset );
is_deeply \@selected, \@preset, "Select-Multi has two values";

$moz->click_button( value => 'Add >>' );
$moz->click_button( value => 'Submit' );
my @isin = $moz->field( 'isin' );
is_deeply \@isin, \@preset, "Transfer succeded";

my @takeout = qw( choice1 );
$moz->field( 'isin', \@takeout );
$moz->click_button( value => '<< Remove' );
$moz->click_button( value => 'Submit' );
my %notinscr = map { ( $_ => undef ) } qw( choice1 choice2 choice4 choice5 );
my %notinfrm = map { ( $_ => undef ) } $moz->field( 'notin' );
is_deeply \%notinfrm, \%notinscr, "Put choice1 back";

$moz->click_button( value => 'Submit' );
@isin = $moz->field( 'isin' );
is_deeply \@isin, [ 'choice3' ], "Only one left in the isin box";

is $moz->field( 'dosubmit' ), 0, "Submit state false";
$moz->click_button( value => 'May Submit' );
is $moz->field( 'dosubmit' ), 1, "Submit state true";

$moz->click_button( value => 'Submit' );
my $uri = $moz->uri->as_string;
like $uri, qr/\bdosubmit=1\b/, "'dosubmit' was passed";
like $uri, qr/\bisin=choice3\b/, "'isin=choice3' was passed";
for my $notin_val ( keys %notinscr ) {
    like $uri, qr/\bnotin=$notin_val/, "'notin=$notin_val' was passed";
}

unlike $uri, qr/\bnotin=choice3\b/, "'notin=choice3' was not passed";
for my $notin_val ( keys %notinscr ) {
    unlike $uri, qr/\bisin=$notin_val/, "'isin=$notin_val' was not passed";
}

$moz->close();
