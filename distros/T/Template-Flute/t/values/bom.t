#!perl

use utf8;
use strict;
use warnings;

use Template::Flute;
use Path::Tiny;
use File::Spec;
use Test::More tests => 4;
use Data::Dumper;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf-8)";
binmode $builder->failure_output, ":encoding(utf-8)";
binmode $builder->todo_output,    ":encoding(utf-8)";


foreach my $html_file ('bom.html', 'bom-included.html') {
    my $target = File::Spec->catfile(qw/t files/, $html_file);
    my $html_in = Path::Tiny::path($target)->slurp({ binmode => ':encoding(utf-8)' });
    like $html_in, qr/\A\x{feff}/, "Bom present in $target";
}

my $flute = Template::Flute->new(specification_file => 't/files/bom.xml',
                                 template_file => 't/files/bom.html');


my $out = $flute->process;
unlike $out, qr/\x{feff}/, "Bom not present in output" or diag Dumper($out);
is ($out,
    '<html><head></head><body><div>This is a test.<div class="included"><div>This snippet is included.</div></div></div></body></html>',
    'output correct');
