#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Checkbox;
use Term::Fabulous::Widget::TextField;
use Clay::UI::Enum::Result;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

my $company = Term::Fabulous::Widget::Checkbox->new( id => 'company', label => 'I order for a company' );
my $vat_id  = Term::Fabulous::Widget::TextField->new( id => 'vat_id', placeholder => 'VAT number', disabled => 1 );
$root->add_child( $company, $vat_id );

$company->on(
	Change => sub ($event) {
		$vat_id->disabled( !$event->value );
		return Clay::UI::Enum::Result->CONTINUE;    # let ancestors see the change too
	}
);

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );
$ui->interaction->set_focused_widget($company);
$ui->run;
