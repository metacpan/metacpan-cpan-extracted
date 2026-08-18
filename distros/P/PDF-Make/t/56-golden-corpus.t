#!perl

# The golden corpus.
#
# Eight documents of the kind this engine exists to produce, each with its
# template, its data and the exact bytes they render to. The test asserts
# byte equality.
#
# This is the engine version promise in executable form. A layout change that
# moves a single glyph on any of these pages fails here, and the only correct
# responses are to undo it or to raise the engine version deliberately. That
# is the whole bargain with anyone who pins a template: their documents do not
# move underneath them.
#
# To accept a deliberate change:
#
#     PDFMAKE_UPDATE_CORPUS=1 prove -lb t/56-golden-corpus.t
#
# and read the diff before committing it.
#
# It is an author test, because byte equality is a promise about one engine
# on one machine, not about floating point everywhere. Text is placed at
# accumulated glyph advances - the corpus is full of values like
# 243.810005 and 159.444443 - and the writer prints those to six decimals.
# A perl built -Duselongdouble accumulates the same sum in 80-bit registers
# and hands the writer a double one ulp away; a different architecture
# contracts a multiply-add differently. Either way a sum that lands on
# 243.81 here lands on 243.810005 there, and a file that is byte-identical
# on the machine the corpus was generated on is twelve bytes longer on a
# smoker. That is not layout drift, which is the only thing this test
# exists to catch, so it does not run where it cannot tell the two apart.

use strict;
use warnings;
use Test::More;
use File::Spec;
use PDF::Make::Markup::Render;

plan skip_all => 'author test: byte equality holds per platform, '
               . 'set AUTHOR_TESTING=1 to run it'
    unless $ENV{AUTHOR_TESTING} || $ENV{PDFMAKE_UPDATE_CORPUS};

eval { require Template::Stencil; 1 }
    or plan skip_all => 'Template::Stencil required to render the corpus';
eval { require JSON::PP; 1 }
    or plan skip_all => 'JSON::PP required to read the corpus data';

my $docs   = File::Spec->catdir('corpus', 'documents');
my $golden = File::Spec->catdir('corpus', 'golden');

plan skip_all => "no corpus at $docs" unless -d $docs;

my @names = sort map { my $f = $_; $f =~ s{.*[\\/]}{}; $f =~ s/\.tmpl\z//; $f }
            glob File::Spec->catfile($docs, '*.tmpl');

plan skip_all => 'corpus is empty' unless @names;

sub slurp {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    local $/;
    my $bytes = <$fh>;
    close $fh;
    return $bytes;
}

# Every document renders at the same pinned date, so the only thing that can
# move the bytes is the engine.
$ENV{SOURCE_DATE_EPOCH} = 1600000000;

my $update = $ENV{PDFMAKE_UPDATE_CORPUS};

for my $name (@names) {
    subtest $name => sub {
        my $tmpl = File::Spec->catfile($docs, "$name.tmpl");
        my $json = File::Spec->catfile($docs, "$name.json");
        my $pdf  = File::Spec->catfile($golden, "$name.pdf");

        ok -f $json, 'has a data file' or return;

        my $data = eval { JSON::PP->new->utf8->decode(slurp($json)) };
        ok $data, 'data parses' or do { diag $@; return };

        my $bytes = eval {
            PDF::Make::Markup::Render->render(slurp($tmpl), $data)
        };
        ok defined $bytes, 'renders' or do { diag $@; return };
        like $bytes, qr/\A%PDF-/, 'is a PDF';

        if ($update) {
            open my $fh, '>:raw', $pdf or die "cannot write $pdf: $!";
            print $fh $bytes;
            close $fh;
            pass "updated $pdf";
            return;
        }

        ok -f $pdf, 'has a golden file' or do {
            diag "run PDFMAKE_UPDATE_CORPUS=1 to create it";
            return;
        };

        my $want = slurp($pdf);
        is length($bytes), length($want), 'same length as the golden file';
        ok $bytes eq $want, 'byte identical'
            or diag "output moved; if that was deliberate, raise the engine "
                  . "version and update the corpus";
    };
}

subtest 'rendering twice gives the same bytes' => sub {
    my $name = $names[0];
    my $tmpl = slurp(File::Spec->catfile($docs, "$name.tmpl"));
    my $data = JSON::PP->new->utf8->decode(
        slurp(File::Spec->catfile($docs, "$name.json")));

    my $a = PDF::Make::Markup::Render->render($tmpl, $data);
    my $b = PDF::Make::Markup::Render->render($tmpl, $data);
    ok $a eq $b, "$name renders identically twice in one process";
};

subtest 'the corpus covers the shapes it is meant to' => sub {
    my %seen;
    for my $name (@names) {
        my $src = slurp(File::Spec->catfile($docs, "$name.tmpl"));
        $seen{$1}++ while $src =~ /<([a-z][a-z0-9]*)\b/g;
    }
    # Not every tag, but the ones a real document leans on. A corpus that
    # exercises nothing is a green test that protects nothing.
    for my $tag (qw(doc style header footer h1 h2 text table tr th td
                    row cell box hr img pagebreak b i)) {
        ok $seen{$tag}, "the corpus uses <$tag>"
            or diag "no golden document exercises <$tag>";
    }
};

done_testing;
