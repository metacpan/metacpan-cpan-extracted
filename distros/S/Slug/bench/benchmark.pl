#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Benchmark qw(cmpthese timethese);
use Slug qw(slug slug_ascii slug_custom);

print "Slug benchmark\n";
print "=" x 60, "\n";
print "Perl $], Slug $Slug::VERSION\n\n";

my $ascii_short  = "Hello World";
my $ascii_long   = "The Quick Brown Fox Jumps Over The Lazy Dog " x 10;
my $unicode_str  = "Héllo Wörld Café Résumé naïve Straße";
my $cyrillic     = "Привет мир Москва Россия";

print "Input sizes:\n";
printf "  ascii_short : %d bytes\n", length($ascii_short);
printf "  ascii_long  : %d bytes\n", length($ascii_long);
printf "  unicode_str : %d bytes\n", length($unicode_str);
printf "  cyrillic    : %d bytes\n", length($cyrillic);
print "\n";

print "--- slug() throughput ---\n";
cmpthese(-2, {
    'ascii_short'  => sub { slug($ascii_short) },
    'ascii_long'   => sub { slug($ascii_long) },
    'unicode'      => sub { slug($unicode_str) },
    'cyrillic'     => sub { slug($cyrillic) },
});

print "\n--- slug_ascii() throughput ---\n";
cmpthese(-2, {
    'ascii_short'  => sub { slug_ascii($ascii_short) },
    'unicode'      => sub { slug_ascii($unicode_str) },
    'cyrillic'     => sub { slug_ascii($cyrillic) },
});

print "\n--- slug_custom() throughput ---\n";
cmpthese(-2, {
    'default'      => sub { slug_custom($ascii_short) },
    'underscore'   => sub { slug_custom($ascii_short, { separator => "_" }) },
    'max_length'   => sub { slug_custom($ascii_long, { max_length => 50 }) },
    'no_lower'     => sub { slug_custom($ascii_short, { lowercase => 0 }) },
});

print "\n--- slug() vs Perl equivalent ---\n";
sub perl_slug {
    my $str = lc $_[0];
    $str =~ s/[^a-z0-9]+/-/g;
    $str =~ s/^-|-$//g;
    return $str;
}

cmpthese(-2, {
    'xs_slug'     => sub { slug($ascii_short) },
    'perl_slug'   => sub { perl_slug($ascii_short) },
});
