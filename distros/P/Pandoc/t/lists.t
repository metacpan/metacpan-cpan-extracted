use strict;
use Test::More;
use Test::Exception;
use Pandoc;

plan skip_all => 'pandoc executable required' unless pandoc;

my @in = pandoc->input_formats;
ok scalar @in > 5, 'input_formats';

my @out = pandoc->output_formats;
ok scalar @out > 5, 'output_formats';

if (pandoc->version >= 1.18) {
    my %ext = pandoc->extensions;
    is $ext{raw_html}, 1, 'extensions: raw_html';
    is $ext{hard_line_breaks}, 0, 'extensions: hard_line_breaks';
}

done_testing;
