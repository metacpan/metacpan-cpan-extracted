#!perl

use strict;
use warnings;
use utf8;

use Test::More tests => 3;

use Template::Flute;
use Template::Flute::I18N;

my %german_map = (Cart=> 'Warenkorb',
                  Price => 'Preis',
                  'Please confirm our business terms' => "Bitte bestätigen Sie unsere AGB",
                  CART => 'Einkaufswagen');

sub translate {
	my $text = shift;
	return $german_map{$text};
};

my $i18n = Template::Flute::I18N->new(\&translate);

my $spec = '<specification></specification>';
my $template = '<html><div>Cart</div><div>Price</div></html>';

my $flute = Template::Flute->new(specification => $spec,
                                 template => $template,
                                 i18n => $i18n);
my $output = $flute->process();

ok($output =~ m%<div>Warenkorb</div><div>Preis</div>%, $output);

$spec =<<'SPEC';
<specification>
 <value name="component" include="t/files/i18n.html"/>
</specification>
SPEC

$template =<<'TEMPLATE';
<html><div>Cart</div><div class="component">Hello</div><div>Price</div></html>
TEMPLATE

$flute = Template::Flute->new(specification => $spec,
                                 template => $template,
                                 i18n => $i18n);
$output = $flute->process();

# print $output;
unlike $output, qr{Hello}, "Placeholder is replaced";
like $output, qr{Bitte bestätigen Sie unsere AGB}, "Included snippet is translated";
