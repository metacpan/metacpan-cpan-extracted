#!/usr/bin/perl -w

use strict;
use Benchmark qw(timethese cmpthese countit timestr);
use IO::Socket;

my $str;
$str = "--[% one %][% two %]--\n";
# Benchmark: running grammar, index, index2, match, split for at least 2 CPU seconds...
#   grammar:  4 wallclock secs ( 2.04 usr +  0.00 sys =  2.04 CPU) @ 36585.78/s (n=74635)
#   index:  4 wallclock secs ( 2.12 usr +  0.00 sys =  2.12 CPU) @ 81146.23/s (n=172030)
#   index2:  4 wallclock secs ( 2.10 usr +  0.00 sys =  2.10 CPU) @ 71674.76/s (n=150517)
#   match:  4 wallclock secs ( 2.12 usr +  0.01 sys =  2.13 CPU) @ 57690.14/s (n=122880)
#   split:  2 wallclock secs ( 2.06 usr +  0.00 sys =  2.06 CPU) @ 36230.58/s (n=74635)
#            Rate   split grammar   match  index2   index
# split   36231/s      --     -1%    -37%    -49%    -55%
# grammar 36586/s      1%      --    -37%    -49%    -55%
# match   57690/s     59%     58%      --    -20%    -29%
# index2  71675/s     98%     96%     24%      --    -12%
# index   81146/s    124%    122%     41%     13%      --

$str = ((" "x1000)."[% one %]\n")x10;
# Benchmark: running grammar, index, index2, match, split for at least 2 CPU seconds...
#   grammar:  3 wallclock secs ( 2.10 usr +  0.00 sys =  2.10 CPU) @ 689.52/s (n=1448)
#   index:  3 wallclock secs ( 2.10 usr +  0.00 sys =  2.10 CPU) @ 10239.52/s (n=21503)
#   index2:  4 wallclock secs ( 2.13 usr +  0.00 sys =  2.13 CPU) @ 10095.31/s (n=21503)
#   match:  4 wallclock secs ( 2.13 usr +  0.00 sys =  2.13 CPU) @ 6727.23/s (n=14329)
#   split:  4 wallclock secs ( 2.14 usr +  0.00 sys =  2.14 CPU) @ 5023.83/s (n=10751)
#            Rate grammar   split   match  index2   index
# grammar   690/s      --    -86%    -90%    -93%    -93%
# split    5024/s    629%      --    -25%    -50%    -51%
# match    6727/s    876%     34%      --    -33%    -34%
# index2  10095/s   1364%    101%     50%      --     -1%
# index   10240/s   1385%    104%     52%      1%      --

#$str = ((" "x10)."[% one %]\n")x1000;
# Benchmark: running grammar, index, index2, match, split for at least 2 CPU seconds...
#   grammar:  3 wallclock secs ( 2.10 usr +  0.01 sys =  2.11 CPU) @ 81.52/s (n=172)
#   index:  4 wallclock secs ( 2.11 usr +  0.01 sys =  2.12 CPU) @ 207.55/s (n=440)
#   index2:  4 wallclock secs ( 2.10 usr +  0.00 sys =  2.10 CPU) @ 209.52/s (n=440)
#   match:  3 wallclock secs ( 2.07 usr +  0.00 sys =  2.07 CPU) @ 173.43/s (n=359)
#   split:  4 wallclock secs ( 2.12 usr +  0.00 sys =  2.12 CPU) @ 91.98/s (n=195)
#           Rate grammar   split   match   index  index2
# grammar 81.5/s      --    -11%    -53%    -61%    -61%
# split   92.0/s     13%      --    -47%    -56%    -56%
# match    173/s    113%     89%      --    -16%    -17%
# index    208/s    155%    126%     20%      --     -1%
# index2   210/s    157%    128%     21%      1%      --

###----------------------------------------------------------------###

### use a regular expression to go through the string
sub parse_match {
    my $new = '';
    my $START = quotemeta '[%';
    my $END   = quotemeta '%]';

    my $pos;
    local pos($_[0]) = 0;
    while ($_[0] =~ / \G (.*?) $START (.*?) $END /gsx) {
        my ($begin, $tag) = ($1, $2);
        $pos = pos($_[0]);
        $new .= $begin;
        $new .= "($tag)";
    }
    return $pos ? $new . substr($_[0], $pos) : $_[0];
}

### good ole index - hard coded
sub parse_index {
    my $new   = '';

    my $last = 0;
    while (1) {
        my $i = index($_[0], '[%', $last);
        last if $i == -1;
        $new .= substr($_[0], $last, $i - $last),
        my $j   = index($_[0], '%]', $i + 2);
        die "Unclosed tag" if $j == -1;
        my $tag = substr($_[0], $i + 2, $j - ($i + 2));
        $new .= "($tag)";
        $last = $j + 2;
    }
    return $last ? $new . substr($_[0], $last) : $_[0];
}

### index searching - but configurable
sub parse_index2 {
    my $new   = '';
    my $START = '[%';
    my $END   = '%]';
    my $len_s = length $START;
    my $len_e = length $END;

    my $last = 0;
    while (1) {
        my $i = index($_[0], $START, $last);
        last if $i == -1;
        $new .= substr($_[0], $last, $i - $last),
        my $j = index($_[0], $END, $i + $len_s);
        $last = $j + $len_e;
        if ($j == -1) { # missing closing tag
            $last = length($_[0]);
            last;
        }
        my $tag = substr($_[0], $i + $len_s, $j - ($i + $len_s));
        $new .= "($tag)";
    }
    return $last ? $new . substr($_[0], $last) : $_[0];
}

### using a split method (several other split methods were also tried - but were slower)
sub parse_split {
    my $new = '';
    my $START = quotemeta '[%';
    my $END   = quotemeta '%]';

    my @all = split /($START .*? $END)/sx, $_[0];
    for my $piece (@all) {
        next if ! length $piece;
        if ($piece !~ /^$START (.*) $END$/sx) {
            $new .= $piece;
            next;
        }
        my $tag = $1;
        $new .= "($tag)";
    }
    return $new;
}

### a regex grammar type matcher
sub parse_grammar {
    my $new = '';
    my $START = quotemeta '[%';
    my $END   = quotemeta '%]';

    local pos($_[0]) = 0;
    while (1) {
        ### find the start tag
        last if $_[0] !~ /\G (.*?) $START /gcxs;
        $new .= $1;

        if ($_[0] !~ /\G (.*?) $END /gcxs) {
            die "Unmatched $START tag";
        }
        $new .= "($1)";
    }
    return pos($_[0]) ? $new . substr($_[0], pos $_[0]) : $_[0];
}

### a regex grammar type matcher
sub parse_grammar2 {
    my $new = '';
    my $START = quotemeta '[%';
    my $END   = quotemeta '%]';

    local pos $_[0] = 0;
    my $last = 0;
    while (1) {
        ### find the start tag
        last if $_[0] !~ / ($START) /gcxs;
        my $i = pos $_[0];
        $new .= substr $_[0], $last, $i - length($1) - $last;

        if ($_[0] !~ / ($END) /gcxs) {
            die "Unmatched $START tag";
        }
        $last = pos $_[0];
        my $j = $last - length $1;
        $new .= "(".substr($_[0], $i, $j - $i).")";
    }
    return pos($_[0]) ? $new . substr($_[0], pos $_[0]) : $_[0];
}

### use a regular expression to go through the string bruteforce
sub parse_pos_array {
    my $new = '';
    my $START = '[%';
    my $END   = '%]';

    local pos($_[0]) = 0;
    my @start1;
    my @start2;
    while ($_[0] =~ /(\Q$START\E)/g) { push @start1, $-[1]; push @start2, $+[1] }

    local pos($_[0]) = 0;
    my @end1;
    my @end2;
    while ($_[0] =~ /(\Q$END\E)/g) { push @end1, $-[1]; push @end2, $+[1] }

    my $last = 0;
    while (1) {
        last if ! @start1;
        my $i  = shift @start1;
        my $i2 = shift @start2;

        $new .= substr($_[0], $last, $i - $last);

        die "Unclosed tag" if ! @end1;
        my $j  = shift @end1;
        my $j2 = shift @end2;

        my $tag = substr($_[0], $i2, $j - $i2);
        $new.= "($tag)";

        $last = $j2;
    }
    return $last ? $new . substr($_[0], $last) : $_[0];
}

###----------------------------------------------------------------###
### check compliance

#print parse_match($str);
#print "---\n";
#print parse_split($str);
#print "---\n";
#print parse_grammar($str);
#print "---\n";
#print parse_index($str);
#print "---\n";
#print parse_pos_array($str);
#exit;
die "parse_split     didn't match" if parse_split($str)     ne parse_match($str);
die "parse_grammar   didn't match" if parse_grammar($str)   ne parse_match($str);
die "parse_grammar2  didn't match" if parse_grammar2($str)  ne parse_match($str);
die "parse_index     didn't match" if parse_index($str)     ne parse_match($str);
die "parse_index2    didn't match" if parse_index2($str)    ne parse_match($str);
die "parse_pos_array didn't match" if parse_pos_array($str) ne parse_match($str);
#exit;

### and run them
cmpthese timethese (-2, {
    index     => sub { parse_index($str) },
    index2    => sub { parse_index2($str) },
    match     => sub { parse_match($str) },
    split     => sub { parse_split($str) },
    grammar   => sub { parse_grammar($str) },
    grammar2  => sub { parse_grammar2($str) },
    pos_array => sub { parse_pos_array($str) },
});
