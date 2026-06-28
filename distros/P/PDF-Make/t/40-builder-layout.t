#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

BEGIN {
    use_ok('PDF::Make::Builder');
    use_ok('PDF::Make::Builder::Layout');
}

my ($fh, $tmpfile) = tempfile(SUFFIX => '.pdf', UNLINK => 1);
close $fh;

my $builder = PDF::Make::Builder->new(
    file_name => $tmpfile,
    configure => {
        text => { font => { size => 11, family => 'Helvetica', colour => '#222222' } },
    },
);

$builder->add_page(page_size => 'Letter');
my $start_y = $builder->page->cursor_y;

my $layout = PDF::Make::Builder::Layout->new(builder => $builder);
isa_ok($layout, 'PDF::Make::Builder::Layout', 'layout created');

my $row1 = $layout->row(height => 60, margin => 8);
isa_ok($row1, 'PDF::Make::Builder::Layout::Row', 'first row created');

my $left = $row1->cell(weight => 2, bg => '#ecf0f1', border => '#95a5a6');
my $right = $row1->cell(weight => 1, align => 'center', border => '#34495e');
isa_ok($left, 'PDF::Make::Builder::Layout::Cell', 'left cell created');
isa_ok($right, 'PDF::Make::Builder::Layout::Cell', 'right cell created');

is($left->text('Alpha beta gamma delta epsilon zeta eta theta'), $left,
    'text() is chainable on cell');
is($right->text('Side note', size => 10, colour => '#c0392b'), $right,
    'text() accepts formatting options');

my $row2 = $layout->row(margin => 10);
my $auto = $row2->cell(weight => 1, bg => '#fdf2e9', border => '#d35400');
$auto->text('This row uses automatic height calculation based on wrapped content across the available width.');
ok($auto->measure_height($builder->font, 220) > 0, 'measure_height reports positive size');

is($layout->render, $builder, 'render() returns the builder');
ok($builder->page->cursor_y < $start_y, 'layout rendering advances page cursor');

$builder->save;
ok(-f $tmpfile, 'layout PDF created');
ok(-s $tmpfile > 100, 'layout PDF has content');

open my $in, '<:raw', $tmpfile or die "Cannot open $tmpfile: $!";
my $bytes = do { local $/; <$in> };
close $in;

like($bytes, qr/%PDF/, 'layout PDF has header');
like($bytes, qr/%%EOF/, 'layout PDF has trailer');
like($bytes, qr/Alpha beta gamma|Side note|automatic height/s,
    'layout PDF contains rendered text content');

{
    local $@;
    eval { PDF::Make::Builder::Layout->new() };
    like($@, qr/(Layout requires builder|required\s+argument.*builder|required.*builder)/i,
        'layout constructor requires builder');
}

done_testing;
