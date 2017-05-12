# -*- mode: cperl; -*-
use FindBin;
use Path::Class qw(file);
use Test::Base;

my $test_data = q{
=== impl
--- expected: PP
};
$test_data .= file($FindBin::Bin, '10_match_ip.spec')->slurp;
spec_string $test_data;

plan tests => 1 * blocks;

require Net::IP::Match::Trie::PP;

my $matcher = Net::IP::Match::Trie->new;
$matcher->add(foo    => [qw(10.0.0.0/24 10.0.1.0/24 11.0.0.0/16)]);
$matcher->add(bar    => [qw(10.1.0.0/28)]); # 0..15
$matcher->add(bigfoo => [qw(10.0.0.0/8)]);
$matcher->add(foo2   => [qw(10.2.0.0/24)]);

sub do_match {
    $matcher->match_ip(shift) || "NOT_MATCH";
}

filters { input => 'do_match', };

run {
    my $block = shift;
    if ($block->name eq "impl") {
        is $matcher->impl, $block->expected, "impl";
    } else {
        is $block->input, $block->expected, $block->name;
    }
}

__END__
