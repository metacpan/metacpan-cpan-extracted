#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

BEGIN { use_ok('PDF::Make::Builder') }

# ── Builder::Font variant branches ──────────────────────

{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');

    # Default font (not bold, not italic)
    $b->add_text(text => 'Normal text');

    # Bold only
    $b->add_text(text => 'Bold text', font => { bold => 1 });

    # Italic only
    $b->add_text(text => 'Italic text', font => { italic => 1 });

    # Bold + Italic
    $b->add_text(text => 'Bold Italic text', font => { bold => 1, italic => 1 });

    $b->save;
    ok(-f $f, 'all font variants rendered');
    unlink $f;
}

# ── hex_to_rgb branches ────────────────────────────────

{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');

    # 6-char hex
    $b->add_text(text => 'Red', font => { colour => '#ff0000' });

    # 3-char hex
    $b->add_text(text => 'Green', font => { colour => '#0f0' });

    # Invalid hex (should fallback to black)
    $b->add_text(text => 'Fallback', font => { colour => '#zz' });

    $b->save;
    ok(-f $f, 'all hex_to_rgb branches');
    unlink $f;
}

# ── effective_line_height: undefined and zero ───────────

{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');

    # Default line_height (undefined → fallback to size)
    $b->add_text(text => 'Default line height', font => { size => 14 });

    # Explicit line_height
    $b->add_text(text => 'Custom line height', font => { size => 10, line_height => 20 });

    $b->save;
    ok(-f $f, 'line height variants');
    unlink $f;
}

# ── Different font families ─────────────────────────────

{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');

    $b->add_text(text => 'Helvetica', font => { family => 'Helvetica', size => 12 });
    $b->add_text(text => 'Times', font => { family => 'Times', size => 12 });
    $b->add_text(text => 'Courier', font => { family => 'Courier', size => 12 });

    $b->save;
    ok(-f $f, 'multiple font families');
    unlink $f;
}

# ── measure_text / measure_word / space_width ───────────

{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');

    # Trigger text measurement via long wrapping text
    my $long_text = ('measurement test word ' x 30);
    $b->add_text(text => $long_text, font => { size => 10 });

    $b->save;
    ok(-f $f, 'measurement paths exercised');
    unlink $f;
}

done_testing;
