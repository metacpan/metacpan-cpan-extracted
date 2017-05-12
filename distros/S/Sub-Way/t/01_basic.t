use strict;
use warnings;
use Test::More;

use Sub::Way qw/match/;

{
    ok match('hoge', 'og');
    ok match('hoge', qr/og/);
    ok match('hoge', ['og']);
    ok match('hoge', [qr/og/]);
    ok match('hoge', [qr/OG/i]);
    ok match('hoge', ['go', 'og']);
    ok match('hoge', [qr/go/, qr/og/]);
    ok match('hoge', ['og', qr/og/]);
    ok match('hoge', sub { my $text = shift; return 1 if $text =~ m!^h!; });
    ok match('hoge', ['og', qr/og/, sub { my $text = shift; return 1 if $text =~ m!^h!; }], 1);
}

{
    ok !match('hoge', 'go');
    ok !match('hoge', qr/go/);
    ok !match('hoge', qr/OG/);
    ok !match('hoge', sub { 0 });
    ok !match('hoge', ['go', qr/go/, sub { 0 }]);
    ok !match('hoge', ['og', qr/og/, sub { 0 }], 1);
}

done_testing;
