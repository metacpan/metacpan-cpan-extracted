use strict;
use 5.010;
use Test::More;
use Pandoc::Elements;
use Pandoc;
use File::Temp;

plan skip_all => 'pandoc >= 1.12.1 not available'
    unless (pandoc and pandoc->version > '1.12.1');

my $doc = pandoc->file('t/documents/outline.md');

{
    my $html = $doc->to_pandoc( '-t' => 'html' );
    ok $html =~ qr{^<p>test document</p>}, 'to_pandoc';
}

{
    my $html = $doc->to_pandoc( '-t' => 'html', '--standalone' );
    ok $html =~ qr{^<!DOCTYPE}, 'to_pandoc with options';
}

{
    is $doc->to_markdown, $doc->to_pandoc( '-t' => 'markdown' ), 'to_markdown';
}

{
    my $to_latex = new_ok Pandoc => [ '-t' => 'latex' ], 'to-latex-object';
    is $doc->to_pandoc( $to_latex ), $doc->to_latex,'to latex with custom Pandoc';
}

done_testing;
