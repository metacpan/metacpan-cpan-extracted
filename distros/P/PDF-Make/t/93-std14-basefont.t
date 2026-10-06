#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

# A font resource must name the font it was asked for.
#
# Every font test in the suite stopped at "the file was written", so nothing
# noticed that PDF::Make::Page's constants had Times where C had Helvetica:
# add_std14_font(HELVETICA) emitted /Times-Roman, and a Builder page asking
# for family Helvetica drew in Times. The assertions below read the BaseFont
# back out of the bytes, which is the only form that can catch a swap.

BEGIN {
    use_ok('PDF::Make::Page', ':fonts');
    use_ok('PDF::Make::Builder');
}

# Resolve the /BaseFont of the font object a resource name points at.
sub basefont_for {
    my ($bytes, $res_name) = @_;
    my ($num) = $bytes =~ m{/\Q$res_name\E\s+(\d+)\s+\d+\s+R};
    return undef unless defined $num;
    my ($body) = $bytes =~ m{(?:^|[\r\n])\Q$num\E\s+0\s+obj(.*?)endobj}s;
    return undef unless defined $body;
    my ($base) = $body =~ m{/BaseFont\s*/([A-Za-z0-9.+-]+)};
    return $base;
}

# ── PDF::Make::Page constants ───────────────────────────

my @STD14 = (
    [ HELVETICA(),             'Helvetica'             ],
    [ HELVETICA_BOLD(),        'Helvetica-Bold'        ],
    [ HELVETICA_OBLIQUE(),     'Helvetica-Oblique'     ],
    [ HELVETICA_BOLDOBLIQUE(), 'Helvetica-BoldOblique' ],
    [ TIMES_ROMAN(),           'Times-Roman'           ],
    [ TIMES_BOLD(),            'Times-Bold'            ],
    [ TIMES_ITALIC(),          'Times-Italic'          ],
    [ TIMES_BOLDITALIC(),      'Times-BoldItalic'      ],
    [ COURIER(),               'Courier'               ],
    [ COURIER_BOLD(),          'Courier-Bold'          ],
    [ COURIER_OBLIQUE(),       'Courier-Oblique'       ],
    [ COURIER_BOLDOBLIQUE(),   'Courier-BoldOblique'   ],
    [ SYMBOL(),                'Symbol'                ],
    [ ZAPFDINGBATS(),          'ZapfDingbats'          ],
);

is(scalar @STD14, 14, 'all fourteen standard fonts are covered');

for my $case (@STD14) {
    my ($id, $want) = @$case;
    my $doc  = PDF::Make::Document->new;
    my $page = $doc->add_page;
    ok($page->add_std14_font('F1', $id) > 0, "added $want");
    $page->set_content("BT /F1 12 Tf 72 720 Td (x) Tj ET\n");
    is(basefont_for($doc->to_bytes, 'F1'), $want,
        "constant $id emits /$want");
}

# ── Builder families ────────────────────────────────────

# The user-visible form of the same bug: family => 'Helvetica' drew as
# Times-Roman and family => 'Times' as Helvetica, while Courier was fine.
my @FAMILIES = (
    [ 'Helvetica', {},                        'F_Helvetica_normal',      'Helvetica'             ],
    [ 'Helvetica', { bold => 1 },             'F_Helvetica_bold',        'Helvetica-Bold'        ],
    [ 'Helvetica', { italic => 1 },           'F_Helvetica_italic',      'Helvetica-Oblique'     ],
    [ 'Helvetica', { bold => 1, italic => 1}, 'F_Helvetica_bolditalic',  'Helvetica-BoldOblique' ],
    [ 'Times',     {},                        'F_Times_normal',          'Times-Roman'           ],
    [ 'Times',     { bold => 1 },             'F_Times_bold',            'Times-Bold'            ],
    [ 'Times',     { italic => 1 },           'F_Times_italic',          'Times-Italic'          ],
    [ 'Times',     { bold => 1, italic => 1}, 'F_Times_bolditalic',      'Times-BoldItalic'      ],
    [ 'Courier',   {},                        'F_Courier_normal',        'Courier'               ],
    [ 'Courier',   { bold => 1 },             'F_Courier_bold',          'Courier-Bold'          ],
);

for my $case (@FAMILIES) {
    my ($family, $extra, $res, $want) = @$case;
    my $file = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $file);
    $b->add_page(page_size => 'Letter')
      ->add_text(text => "$family sample", font => { family => $family, %$extra });
    $b->save;

    open my $fh, '<:raw', $file or die "cannot read $file: $!";
    my $bytes = do { local $/; <$fh> };
    close $fh;
    unlink $file;

    is(basefont_for($bytes, $res), $want, "family $family -> /$want");
}

done_testing;
