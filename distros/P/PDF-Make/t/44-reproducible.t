#!perl

# Byte reproducibility.
#
# Two renders of the same document must produce identical bytes when
# SOURCE_DATE_EPOCH is set. Without it the output carries a wall-clock
# CreationDate and ModDate, and an /ID seeded partly on the document's own
# address, so nothing downstream - a golden corpus, a diff of one engine
# version against the next, a customer asking why last year's invoice no
# longer matches - can be checked at all.
#
# The one documented exception is encryption: its salts and IVs are random
# by design, and pinning them would be a security bug rather than a feature.

use strict;
use warnings;
use Test::More;
use PDF::Make::Builder;
use File::Temp qw(tempdir);

my $dir = tempdir(CLEANUP => 1);

sub render {
    my ($stem) = @_;
    my $path = "$dir/$stem";
    my $pdf  = PDF::Make::Builder->new(file_name => $path);
    $pdf->add_page(page_size => 'A4', padding => 36);
    $pdf->add_h1(text => 'Reproducible');
    $pdf->add_text(text => 'The same input must produce the same bytes.');
    my $lay = $pdf->layout;
    my $row = $lay->row;
    $row->cell(weight => 1, pad => 6)->text('left');
    $row->cell(weight => 2, pad => 6)->text('right, wider, and long enough to wrap somewhere');
    $lay->render;
    $pdf->save if $pdf->can('save');
    open my $fh, '<:raw', "$path.pdf" or die "open $path.pdf: $!";
    local $/;
    my $bytes = <$fh>;
    close $fh;
    return $bytes;
}

subtest 'pinned SOURCE_DATE_EPOCH gives identical bytes' => sub {
    local $ENV{SOURCE_DATE_EPOCH} = 1600000000;
    my $a = render('a');
    my $b = render('b');
    is length($a), length($b), 'same length';
    ok $a eq $b, 'byte identical across two renders';
    like $a, qr/CreationDate \(D:2020/, 'creation date comes from the pinned epoch';
    like $a, qr{Producer \(PDF-Make/\Q$PDF::Make::Builder::VERSION\E\)},
        'producer reports the dist version'
        if defined $PDF::Make::Builder::VERSION;
};

subtest 'the epoch is honoured, not just frozen' => sub {
    my $early = do { local $ENV{SOURCE_DATE_EPOCH} = 1000000000; render('c') };
    my $late  = do { local $ENV{SOURCE_DATE_EPOCH} = 1600000000; render('d') };
    isnt $early, $late, 'a different epoch produces different bytes';
    like $early, qr/CreationDate \(D:2001/, 'early epoch dated 2001';
    like $late,  qr/CreationDate \(D:2020/, 'late epoch dated 2020';
};

subtest 'a malformed epoch falls back to the clock rather than dying' => sub {
    for my $bad ('', 'not-a-number', '-1', '12x', ' 12') {
        local $ENV{SOURCE_DATE_EPOCH} = $bad;
        my $bytes = eval { render('e') };
        ok defined $bytes && length $bytes, "renders with SOURCE_DATE_EPOCH='$bad'";
        like $bytes, qr/CreationDate \(D:\d{14}/, '  and still writes a date';
    }
};

done_testing;
