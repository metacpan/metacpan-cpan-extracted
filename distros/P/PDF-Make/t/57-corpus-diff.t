#!perl

# The trust tier's CI guard: every corpus document, rendered now,
# page-diffed against its committed golden render. The golden test
# (t/56) says the BYTES moved; this one says WHICH PAGE and WHAT WORDS,
# which is what a human deciding "deliberate engine bump or bug" needs
# in the failure output. A layout change that moves a corpus page is an
# engine version bump or it does not merge.

use strict;
use warnings;
use Test::More;
use PDF::Make::Markup::Render;
use PDF::Make::Markup::Diff;

eval { require Template::Stencil; 1 }
    or plan skip_all => 'Template::Stencil required';
eval { require JSON::PP; 1 }
    or plan skip_all => 'JSON::PP required';

my $corpus = 'corpus/documents';
my $golden = 'corpus/golden';
plan skip_all => 'corpus not present' unless -d $corpus && -d $golden;

local $ENV{SOURCE_DATE_EPOCH} = 1600000000;

sub slurp {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    local $/;
    return scalar <$fh>;
}

my @docs = qw(invoice receipt statement packing-slip ticket certificate
              contract report);

for my $name (@docs) {
    subtest $name => sub {
        my $template = slurp("$corpus/$name.tmpl");
        my $data = JSON::PP->new->utf8->decode(slurp("$corpus/$name.json"));
        my $now = PDF::Make::Markup::Render->render($template, $data);
        my $was = slurp("$golden/$name.pdf");

        my $d = PDF::Make::Markup::Diff->diff($was, $now);
        is($d->{changed}, 0,
            "no page of $name moved against the golden render")
            or do {
                for my $p (grep { $_->{changed} } @{ $d->{pages} }) {
                    # moved as well as removed/added: a page whose words all
                    # kept their text but shifted position reports only moved,
                    # and printing "-[] +[]" for it says nothing at all.
                    diag sprintf "  page %d: -[%s] +[%s] moved[%s]",
                        $p->{page},
                        join(' ', @{ $p->{removed} }),
                        join(' ', @{ $p->{added} }),
                        join(' ', @{ $p->{moved} || [] });
                }
                diag "a moved corpus page is a deliberate engine version "
                   . "bump (regenerate the golden corpus and bump "
                   . "PDFMAKE_ENGINE_VERSION) or it does not merge";
            };
    };
}

done_testing();
