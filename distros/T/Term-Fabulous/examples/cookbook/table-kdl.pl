#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Layout;
use Term::Fabulous::Widget::Table::Mutator qw(date number);

my $layout = Term::Fabulous::Layout->new( string => <<'KDL' );
use Term::Fabulous::Widget::Box as Box
use Term::Fabulous::Widget::Text as Text
use Term::Fabulous::Widget::Table as Table

Box "root" {
	layout direction=down gap=1
	sizing width=grow height=grow
	padding left=2 right=2 top=1 bottom=1

	Text { text "Stock by category. Space selects, Enter on a group header closes it."; text_color "#dcdcdc"; }

	Table "stock" {
		row_id "sku"
		selection multiple
		lines frame=Heavy columns=none header=Heavy color="#5c6370"
		stripe_color "#1c2029"
		group_text_color "#e5c07b"

		column "sku" title="SKU" width="fixed(9)"
		column "name" title="Item" compare=natural
		column "category" title="Category" visible=#false
		column "qty" title="Qty" type=number {
			style text_color="#61afef" bold=#true border_left=Solid
			header_style text_color="#61afef"
		}
		column "price" title="Price" type=number
		column "updated" title="Updated" type=date

		sort "qty" "desc"
		group_by "category"
	}

	Text "status" { text "Nothing selected."; text_color "#96a0b4"; }
}
KDL

my $root   = $layout->build;
my $table  = $root->find_by_id('stock');
my $status = $root->find_by_id('status');

# The data and every code reference come from Perl.
$table->rows(
	[
		{ sku => 'CAB-001', name => 'USB-C cable 1 m', category => 'Cables',   qty => 140, price => 9.9,  updated => '2026-05-28' },
		{ sku => 'CAB-002', name => 'USB-C cable 2 m', category => 'Cables',   qty => 35,  price => 12.5, updated => '2026-05-30' },
		{ sku => 'CAB-010', name => 'HDMI cable 2 m',  category => 'Cables',   qty => 62,  price => 14,   updated => '2026-05-12' },
		{ sku => 'KEY-001', name => 'Keyboard DE',     category => 'Input',    qty => 18,  price => 49,   updated => '2026-05-21' },
		{ sku => 'KEY-002', name => 'Keyboard US',     category => 'Input',    qty => 24,  price => 49,   updated => '2026-05-21' },
		{ sku => 'MOU-001', name => 'Mouse, wireless', category => 'Input',    qty => 51,  price => 29.9, updated => '2026-05-31' },
		{ sku => 'MON-024', name => 'Monitor 24 inch', category => 'Displays', qty => 7,   price => 189,  updated => '2026-05-02' },
		{ sku => 'MON-027', name => 'Monitor 27 inch', category => 'Displays', qty => 12,  price => 279,  updated => '2026-05-19' },
	]
);
$table->update_column( price   => mutator => number( decimals => 2, suffix => ' EUR' ) );
$table->update_column( updated => mutator => date('%d %b') );

$table->on(
	SelectionChange => sub ($event) {
		my @names = map { $_->{name} } $table->selected_rows;
		$status->text( @names ? 'Selected: ' . join( ', ', @names ) : 'Nothing selected.' );
		return;
	}
);

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );
$ui->interaction->set_focused_widget($table);
$ui->run;
