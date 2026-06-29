#!/usr/bin/perl

use strict;
use warnings;
use Test2::Bundle::Numerical qw(:all);
use Test2::Tools::Class qw(can_ok);
use File::Temp qw(tempfile tempdir);

BEGIN {
    use_ok('PDF::Make');
    use_ok('PDF::Make::Watermark');
}

# Test 1: Module loads
ok(1, 'PDF::Make::Watermark module loaded');

# Test 2: Watermark class exists
can_ok('PDF::Make::Watermark', qw(text image type position opacity color font size));

# Test 3: Stamp class exists  
can_ok('PDF::Make::Stamp', qw(text bates type format position margin_x margin_y font size expand));

# Test 4: Text watermark creation with defaults
{
    my $wm = PDF::Make::Watermark->text('DRAFT');
    ok($wm, 'Text watermark created');
    is($wm->type, 'text', 'Type is text');
    is($wm->text_content, 'DRAFT', 'Text content correct');
    is($wm->opacity, 0.3, 'Default opacity');
    is($wm->size, 72, 'Default size');
    is($wm->font, 'Helvetica-Bold', 'Default font');
}

# Test 5: Text watermark with custom options
{
    my $wm = PDF::Make::Watermark->text('CONFIDENTIAL',
        position => 'diagonal',
        opacity  => 0.5,
        color    => [0.8, 0.2, 0.2],
        font     => 'Times-Bold',
        size     => 96,
        rotation => 45,
        scale    => 1.5,
    );
    ok($wm, 'Custom watermark created');
    is($wm->position, 1, 'Diagonal position (enum 1)');
    is($wm->opacity, 0.5, 'Custom opacity');
    is_deeply($wm->color, [0.8, 0.2, 0.2], 'Custom color');
    is($wm->font, 'Times-Bold', 'Custom font');
    is($wm->size, 96, 'Custom size');
    is($wm->rotation, 45, 'Custom rotation');
    is($wm->scale, 1.5, 'Custom scale');
}

# Test 6: Image watermark creation
{
    my $wm = PDF::Make::Watermark->image(42,  # Mock image object number
        width    => 200,
        height   => 100,
        position => 'center',
        opacity  => 0.2,
        scale    => 0.5,
    );
    ok($wm, 'Image watermark created');
    is($wm->type, 'image', 'Type is image');
    is($wm->image_obj, 42, 'Image object number');
    is($wm->width, 200, 'Image width');
    is($wm->height, 100, 'Image height');
    is($wm->position, 0, 'Center position (enum 0)');
    is($wm->opacity, 0.2, 'Custom opacity');
    is($wm->scale, 0.5, 'Custom scale');
}

# Test 7: Image watermark requires dimensions
{
    eval { PDF::Make::Watermark->image(42) };
    like($@, qr/Width required/, 'Image watermark requires width');
    
    eval { PDF::Make::Watermark->image(42, width => 100) };
    like($@, qr/Height required/, 'Image watermark requires height');

    eval { PDF::Make::Watermark->image(0, width => 100, height => 100) };
    like($@, qr/Image object required/, 'Image watermark requires image object');
}

# Test 8: Text stamp creation
{
    my $stamp = PDF::Make::Stamp->text('Page %p of %P');
    ok($stamp, 'Text stamp created');
    is($stamp->type, 'text', 'Type is text');
    is($stamp->format, 'Page %p of %P', 'Format string');
    is($stamp->position, 8, 'Default bottom_center position');
    is($stamp->margin_x, 36, 'Default margin');
    is($stamp->font, 'Helvetica', 'Default font');
    is($stamp->size, 10, 'Default size');
}

# Test 9: Bates stamp creation
{
    my $bates = PDF::Make::Stamp->bates(
        prefix => 'DOC',
        start  => 1,
        digits => 6,
        suffix => '-2026',
    );
    ok($bates, 'Bates stamp created');
    is($bates->type, 'bates', 'Type is bates');
    is($bates->prefix, 'DOC', 'Prefix');
    is($bates->start, 1, 'Start number');
    is($bates->digits, 6, 'Digits');
    is($bates->suffix, '-2026', 'Suffix');
}

# Test 10: Format string expansion
{
    my $stamp = PDF::Make::Stamp->text('Page %p of %P - %d');
    my $text = $stamp->expand(3, 10);
    like($text, qr/Page 3 of 10/, 'Page numbers expanded');
    like($text, qr/\d{4}-\d{2}-\d{2}/, 'Date expanded');
}

# Test 11: Bates number expansion
{
    my $bates = PDF::Make::Stamp->bates(
        prefix => 'ACME',
        start  => 42,
        digits => 8,
        suffix => '-X',
    );
    
    is($bates->next_bates, 'ACME00000042-X', 'First Bates number');
    is($bates->next_bates, 'ACME00000043-X', 'Second Bates number');
    is($bates->next_bates, 'ACME00000044-X', 'Third Bates number');
    
    $bates->reset;
    is($bates->next_bates, 'ACME00000042-X', 'Reset works');
}

# Test 12: Position parsing
{
    my $wm1 = PDF::Make::Watermark->text('TEST', position => 'center');
    is($wm1->position, 0, 'center = 0');
    
    my $wm2 = PDF::Make::Watermark->text('TEST', position => 'diagonal');
    is($wm2->position, 1, 'diagonal = 1');
    
    my $wm3 = PDF::Make::Watermark->text('TEST', position => 'top_right');
    is($wm3->position, 6, 'top_right = 6');
    
    my $wm4 = PDF::Make::Watermark->text('TEST', position => 'bottom_left');
    is($wm4->position, 7, 'bottom_left = 7');
}

# Test 13: Invalid position
{
    eval { PDF::Make::Watermark->text('TEST', position => 'invalid') };
    like($@, qr/Unknown position/, 'Invalid position rejected');
}

# Test 14: Overlay option
{
    my $wm1 = PDF::Make::Watermark->text('TEST');
    is($wm1->overlay, 0, 'Default is underlay');
    
    my $wm2 = PDF::Make::Watermark->text('TEST', overlay => 1);
    is($wm2->overlay, 1, 'Can set overlay');
}

# Test 15: Tile spacing
{
    my $wm = PDF::Make::Watermark->text('TEST',
        position => 'tile',
        tile_spacing_x => 200,
        tile_spacing_y => 250,
    );
    is($wm->tile_spacing_x, 200, 'Custom tile spacing X');
    is($wm->tile_spacing_y, 250, 'Custom tile spacing Y');
}

# Test 16: Stamp with custom options
{
    my $stamp = PDF::Make::Stamp->text('Footer text',
        position => 'bottom_right',
        margin_x => 72,
        margin_y => 18,
        font     => 'Courier',
        size     => 8,
        color    => [0.5, 0.5, 0.5],
    );
    is($stamp->position, 9, 'bottom_right position');
    is($stamp->margin_x, 72, 'Custom margin_x');
    is($stamp->margin_y, 18, 'Custom margin_y');
    is($stamp->font, 'Courier', 'Custom font');
    is($stamp->size, 8, 'Custom size');
    is_deeply($stamp->color, [0.5, 0.5, 0.5], 'Custom color');
}

# Test 17: Format specifiers
{
    my $stamp = PDF::Make::Stamp->text('%%p=%p %%P=%P %%d=%d %%t=%t');
    my $text = $stamp->expand(5, 20);
    like($text, qr/%p=5/, 'Escaped %p and page number');
    like($text, qr/%P=20/, 'Escaped %P and total pages');
    like($text, qr/%d=\d{4}/, 'Escaped %d and date');
    like($text, qr/%t=\d{2}:\d{2}/, 'Escaped %t and time');
}

# Test 18: Document methods exist
can_ok('PDF::Make::Document', qw(add_watermark apply_stamp));

# Test 19: Watermark requires text
{
    eval { PDF::Make::Watermark->text('') };
    like($@, qr/Text required/, 'Empty text rejected');
    
    eval { PDF::Make::Watermark->text(undef) };
    like($@, qr/Text required/, 'Undef text rejected');
}

# Test 20: Add watermark to document (integration test)
{
    my $doc = PDF::Make::Document->new;
    $doc->add_page;
    $doc->add_page;
    
    my $wm = PDF::Make::Watermark->text('DRAFT');
    
    eval { $doc->add_watermark($wm) };
    ok(!$@, 'add_watermark does not die');
    
    my $stamp = PDF::Make::Stamp->text('Page %p');
    eval { $doc->apply_stamp($stamp) };
    ok(!$@, 'apply_stamp does not die');
}

# Test 21: All positions recognized
{
    my @positions = qw(
        center diagonal tile custom
        top_left top_center top_right
        bottom_left bottom_center bottom_right
        left_center right_center
    );
    
    for my $pos (@positions) {
        my $wm = eval { PDF::Make::Watermark->text('X', position => $pos) };
        ok($wm, "Position '$pos' accepted");
    }
}

# Test 22: Numeric positions accepted
{
    my $wm = PDF::Make::Watermark->text('X', position => 9);
    is($wm->position, 9, 'numeric watermark position accepted');

    my $stamp = PDF::Make::Stamp->text('Page %p', position => 4);
    is($stamp->position, 4, 'numeric stamp position accepted');
}

# Test 23: Stamp invalid position rejected
{
    eval { PDF::Make::Stamp->text('Page %p', position => 'not_a_position') };
    like($@, qr/Unknown position/, 'Invalid stamp position rejected');
}

done_testing();
