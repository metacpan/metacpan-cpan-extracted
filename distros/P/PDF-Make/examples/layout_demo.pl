#!/usr/bin/env perl
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch', 'lib';
use PDF::Make::Builder;

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/layout_demo',
    configure => {
        h1   => { font => { colour => '#1a1a2e', size => 24, line_height => 28 } },
        h2   => { font => { colour => '#16213e', size => 16, line_height => 20 } },
        text => { font => { size => 10, family => 'Helvetica', colour => '#333' } },
    },
);

$pdf->title('Layout Demo')
    ->author('PDF::Make');

# ══════════════════════════════════════════════════════════════
# Page 1: Grid Layouts
# ══════════════════════════════════════════════════════════════

$pdf->add_page(page_size => 'Letter', padding => 36)
    ->add_h1(text => 'Grid Layout System');

$pdf->add_text(text => 'The layout system positions content in rows and cells. '
                     . 'Cells are sized by weight ratios within each row.');

# ── Two equal columns ────────────────────────────────────

$pdf->add_h2(text => 'Two Equal Columns');

my $layout1 = $pdf->layout;
my $row1 = $layout1->row(height => 100);
$row1->cell(weight => 1, bg => '#ebf5fb', border => '#aed6f1', pad => 10, text_border => '#1f4e79')
     ->text('Left Column', size => 12, colour => '#2c3e50')
     ->text('This content sits in the left half of the page. The cell has a '
          . 'light blue background with a border and 10pt padding on all sides.',
            size => 9, colour => '#555');
$row1->cell(weight => 1, bg => '#fef9e7', border => '#f9e79f', pad => 10, text_border => '#7d6608')
     ->text('Right Column', size => 12, colour => '#2c3e50')
     ->text('The right column gets equal width. Text wraps within the cell '
          . 'boundaries using exact font metrics for accurate line breaks.',
            size => 9, colour => '#555');
$layout1->render;

# ── Three columns: 1-2-1 ratio ──────────────────────────

$pdf->add_h2(text => 'Three Columns (1:2:1 Ratio)');

my $layout2 = $pdf->layout;
my $row2 = $layout2->row(height => 80);
$row2->cell(weight => 1, bg => '#e8f8f5', border => '#a3e4d7', pad => 8)
     ->text('Sidebar', size => 11, colour => '#1a5276')
     ->text('Narrow left panel.', size => 8, colour => '#666');
$row2->cell(weight => 2, bg => '#fdfefe', border => '#d5d8dc', pad => 8, text_border => '#1a5276', wrap_slack => 13)
     ->text('Main Content Area', size => 11, colour => '#1a5276')
     ->text('The center column has weight 2, so it takes twice the width '
          . 'of each sidebar. Use this for article-style layouts where the '
          . 'main content needs more room.', size => 9, colour => '#444');
$row2->cell(weight => 1, bg => '#fdedec', border => '#f5b7b1', pad => 8)
     ->text('Sidebar', size => 11, colour => '#1a5276')
     ->text('Narrow right panel.', size => 8, colour => '#666');
$layout2->render;

# ── Full-width banner ────────────────────────────────────

$pdf->add_h2(text => 'Full-Width Rows');

my $layout3 = $pdf->layout;
$layout3->row(height => 35)
    ->cell(weight => 1, bg => '#2c3e50', align => 'center')
    ->text('Dark Banner - Full Width', colour => '#ecf0f1', size => 14);
$layout3->row(height => 25)
    ->cell(weight => 1, bg => '#3498db', align => 'center')
    ->text('Blue Accent Strip', colour => '#fff', size => 10);
$layout3->render;

# ══════════════════════════════════════════════════════════════
# Page 2: Practical Examples
# ══════════════════════════════════════════════════════════════

$pdf->add_page()
    ->add_h1(text => 'Practical Layout Examples');

# ── Invoice header ───────────────────────────────────────

$pdf->add_h2(text => 'Invoice Header');

my $inv = $pdf->layout;
my $hdr = $inv->row(height => 70);
$hdr->cell(weight => 2, pad => 8)
    ->text('ACME Corporation', size => 18, colour => '#2c3e50')
    ->text('123 Business Ave, Suite 100', size => 9, colour => '#777')
    ->text('San Francisco, CA 94105', size => 9, colour => '#777');
$hdr->cell(weight => 1, align => 'right', pad => 8)
    ->text('INVOICE', size => 22, colour => '#e74c3c')
    ->text('#INV-2026-0042', size => 10, colour => '#555')
    ->text('Date: 2026-04-20', size => 9, colour => '#777');
$inv->render;

# ── Data table ───────────────────────────────────────────

$pdf->add_h2(text => 'Data Table');

my $table = $pdf->layout;

# Header row
my $thead = $table->row(height => 25, margin => 0);
$thead->cell(weight => 3, bg => '#34495e', pad => 6)
      ->text('Description', size => 10, colour => '#fff');
$thead->cell(weight => 1, bg => '#34495e', align => 'center', pad => 6)
      ->text('Qty', size => 10, colour => '#fff');
$thead->cell(weight => 1, bg => '#34495e', align => 'right', pad => 6)
      ->text('Price', size => 10, colour => '#fff');
$thead->cell(weight => 1, bg => '#34495e', align => 'right', pad => 6)
      ->text('Total', size => 10, colour => '#fff');

# Data rows
my @items = (
    ['Web Development Services', '40', '$150.00', '$6,000.00'],
    ['UI/UX Design Package',     '1',  '$2,500.00', '$2,500.00'],
    ['Server Hosting (Annual)',   '1',  '$1,200.00', '$1,200.00'],
    ['SSL Certificate',           '2',  '$49.99',    '$99.98'],
);

for my $i (0 .. $#items) {
    my $bg = $i % 2 ? '#f8f9fa' : '#ffffff';
    my $r = $table->row(height => 22, margin => 0);
    $r->cell(weight => 3, bg => $bg, border => '#eee', pad => 6)
      ->text($items[$i][0], size => 9);
    $r->cell(weight => 1, bg => $bg, border => '#eee', align => 'center', pad => 6)
      ->text($items[$i][1], size => 9);
    $r->cell(weight => 1, bg => $bg, border => '#eee', align => 'right', pad => 6)
      ->text($items[$i][2], size => 9);
    $r->cell(weight => 1, bg => $bg, border => '#eee', align => 'right', pad => 6)
      ->text($items[$i][3], size => 9);
}

# Total row
my $total = $table->row(height => 25, margin => 0);
$total->cell(weight => 3, pad => 6);
$total->cell(weight => 1, pad => 6);
$total->cell(weight => 1, bg => '#2c3e50', align => 'right', pad => 6)
      ->text('Total:', size => 10, colour => '#fff');
$total->cell(weight => 1, bg => '#2c3e50', align => 'right', pad => 6)
      ->text('$9,799.98', size => 10, colour => '#fff');

$table->render;

# ── Card layout ──────────────────────────────────────────

$pdf->add_h2(text => 'Card Layout');

my $cards = $pdf->layout;
my $card_row = $cards->row(height => 90);

for my $card (
    { title => 'Revenue',   value => '$142K', colour => '#27ae60', desc => 'Up 12% from last quarter' },
    { title => 'Users',     value => '8,430', colour => '#3498db', desc => '342 new this month' },
    { title => 'Orders',    value => '1,205', colour => '#e67e22', desc => 'Average $118 per order' },
) {
    $card_row->cell(weight => 1, bg => '#fff', border => '#ddd', pad => 10)
        ->text($card->{title}, size => 9, colour => '#888')
        ->text($card->{value}, size => 22, colour => $card->{colour})
        ->text($card->{desc}, size => 8, colour => '#999');
}
$cards->render;

# ══════════════════════════════════════════════════════════════
# Page 3: Column Text Flow
# ══════════════════════════════════════════════════════════════

$pdf->add_page(page_size => 'Letter', padding => 36, columns => 2)
    ->add_h1(text => 'Two-Column Article');

my $string = 'This page demonstrates automatic column text flow. When the first '
  . 'column fills to the bottom margin, text automatically continues in '
  . 'the second column. This is useful for newspaper-style layouts, '
  . 'newsletters, and academic papers. '
  . 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do '
  . 'eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim '
  . 'ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut '
  . 'aliquip ex ea commodo consequat. Duis aute irure dolor in '
  . 'reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla '
  . 'pariatur. Excepteur sint occaecat cupidatat non proident, sunt in '
  . 'culpa qui officia deserunt mollit anim id est laborum. '
  . 'Sed ut perspiciatis unde omnis iste natus error sit voluptatem '
  . 'accusantium doloremque laudantium, totam rem aperiam, eaque ipsa '
  . 'quae ab illo inventore veritatis et quasi architecto beatae vitae '
  . 'dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit '
  . 'aspernatur aut odit aut fugit, sed quia consequuntur magni dolores '
  . 'eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est '
  . 'qui dolorem ipsum quia dolor sit amet consectetur adipisci velit. '
  . 'At vero eos et accusamus et iusto odio dignissimos ducimus qui '
  . 'blanditiis praesentium voluptatum deleniti atque corrupti quos '
  . 'dolores et quas molestias excepturi sint occaecati cupiditate non '
  . 'provident, similique sunt in culpa qui officia deserunt mollitia '
  . 'animi id est laborum et dolorum fuga. ';

$pdf->add_text(text => $string x 500,
     overflow => 1);

# ══════════════════════════════════════════════════════════════

$pdf->save;
my $n = $pdf->page_count;
print "Wrote corpus/layout_demo.pdf ($n pages)\n";
print "Demonstrates:\n";
print "  - Two equal columns\n";
print "  - Three columns (1:2:1 weighted)\n";
print "  - Full-width banner rows\n";
print "  - Invoice header layout\n";
print "  - Data table with header/rows/total\n";
print "  - Dashboard card layout\n";
print "  - Two-column article text flow\n";
