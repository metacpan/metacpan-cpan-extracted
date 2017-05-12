#! perl
#

use strict;
use warnings;

use Test::More tests => 2;

use Template::Flute;
use Template::Flute::I18N;

my (%german_map, $i18n, $spec, $template, $flute, $output);

%german_map = (Cart=> 'Warenkorb', Price => 'Preis', 
	       CART => 'Einkaufswagen');

sub translate {
	my $text = shift;
	
	return $german_map{$text};
};

$i18n = Template::Flute::I18N->new(\&translate);

$spec = '<specification></specification>';
$template = '<html><div>Cart</div><div>Price</div></html>';

$flute = Template::Flute->new(specification => $spec,
			      template => $template,
			      i18n => $i18n);

$output = $flute->process();

ok($output =~ m%<div>Warenkorb</div><div>Preis</div>%, $output);

$spec = '<specification><i18n class="cart" key="CART"/></specification>';
$template = '<html><div class="cart">Cart</div><div>Price</div></html>';

$flute = Template::Flute->new(specification => $spec,
			      template => $template,
			      i18n => $i18n);

$output = $flute->process();

ok($output =~ m%<div class="cart">Einkaufswagen</div><div>Preis</div>%, $output);
