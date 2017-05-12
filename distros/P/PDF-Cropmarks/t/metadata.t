#!perl
use utf8;
use strict;
use warnings;
use PDF::API2;
use File::Temp;
use File::Spec;
use Test::More tests => 7;
use Data::Dumper;
use PDF::Cropmarks;

my $wd = File::Temp->newdir(CLEANUP => !$ENV{NO_CLEANUP});
diag "Working in $wd";

my $target = File::Spec->catfile($wd, 'metadata.pdf');
my $outfile = File::Spec->catfile($wd, 'metadata-out.pdf');
my %meta = (
            Author => 'Author á Pinco ĐŠć',
            Title => 'Title á Pinco ĐŠć',
            Subject => 'Subject á Pinco ĐŠć',
            Keywords => 'Keywords á Pinco ĐŠć',
           );
{
    my $pdf = PDF::API2->new();
    $pdf->mediabox(80, 120);
    my $font = $pdf->corefont('Helvetica-Bold');
    my $page = $pdf->page;
    my $text = $page->text;
    $text->translate(40, 60);
    $text->font($font, 10);
    $text->text_center('Baf');
    $pdf->info(%meta);
    $pdf->saveas($target);
}
{
    my $pdf = PDF::API2->open($target);
    my %got = $pdf->info;
    delete $got{Producer};
    is_deeply(\%got, \%meta, "metadata ok");
    $pdf->end;
}

{
    PDF::Cropmarks->new(input => $target,
                        output => $outfile,
                        paper => "a4")->add_cropmarks;
    my $pdf = PDF::API2->open($outfile);
    my %got = $pdf->info;
    foreach my $meta (qw/Creator Producer ModDate CreationDate/) {
        my $field = delete $got{$meta};
        ok $field, "Got $meta: $field";
    }
    is_deeply(\%got, \%meta, "metadata ok after adding cropmarks");
    $pdf->end;
}

# and modify it in place

{
    my $pdf = PDF::API2->open($target);
    $pdf->info(%meta);
    $pdf->saveas($target);
    $pdf = PDF::API2->open($target);
    my %got = $pdf->info;
    delete $got{Producer};
    is_deeply(\%got, \%meta, "metadata ok after modifying it in place");
    $pdf->end;
}

