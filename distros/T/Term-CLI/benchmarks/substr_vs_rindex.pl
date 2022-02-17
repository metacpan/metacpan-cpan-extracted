#!/usr/bin/perl
#
# Benchmark demonstrating that checking if a $text is
# a prefix match for another $string is quicker with:
#
#   rindex( $string, $text, 0 ) == 0
#     
# than with:
#
#   substr( $string, 0, length $text ) eq $text;
#
# On my laptop:
#
#            Rate substr rindex
# substr 192308/s     --   -26%
# rindex 259740/s    35%     --
#
use 5.014;
use warnings;

use Benchmark qw( cmpthese );

my $iter = @ARGV ? shift @ARGV : 200_000;

my @list;

for my $c ('a' .. 'z') {
    my $prefix = $c x 4;

    push @list, $prefix;

    for my $i ( 1 .. 3 ) {
        push @list, $prefix . $i;
    }
}

sub match_rindex {
    my ($text, $list) = @_;

    my @found = grep { rindex( $_, $text, 0 ) == 0 } @{$list};
    return @found;
}

sub match_substr {
    my ($text, $list) = @_;

    my @found = grep { substr( $_, 0, length $text ) eq $text } @{$list};
    return @found;
}

cmpthese( $iter, {
    'rindex' => sub { my @l = match_rindex('mmmm', \@list) },
    'substr' => sub { my @l = match_substr('mmmm', \@list) },
} );
