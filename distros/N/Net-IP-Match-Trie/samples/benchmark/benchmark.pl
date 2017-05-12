#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use Path::Class qw(file dir);

use lib map {dir($FindBin::Bin, '..', '..', @$_)->stringify} [qw(lib)], [qw(blib lib)], [qw(blib arch)], [qw(.)];

use Benchmark qw(:all);
use Net::CIDR::Lite;
use Net::IP::Match::XS;
use Net::IP::Match::XS2;
use Net::IP::Match::Bin;
use Net::IP::Match::Regexp;
use Net::Patricia;
use Net::IP::Match::Trie;

our(@au, @willcom, @docomo, @softbank);
require eval {file($FindBin::Bin, "cidr.pl")->stringify};
my @all_cidr = (@au, @willcom, @docomo, @softbank);
print scalar(@all_cidr), "\n";

my $count = $ENV{COUNT} || 300_000;

my $cidr = Net::CIDR::Lite->new;
$cidr->add_any($_) for @all_cidr;

my $xs2 = Net::IP::Match::XS2->new();
$xs2->add(split(m{/}, $_, 2)) for @all_cidr;

my $bin = Net::IP::Match::Bin->new();
$bin->add($_) for @all_cidr;

my @cidr_list = $cidr->list;

my $re = Net::IP::Match::Regexp::create_iprange_regexp(@all_cidr);

my $pat = Net::Patricia->new;
$pat->add_string($_) for @all_cidr;

my $trie = Net::IP::Match::Trie->new;
print "Net::IP::Match::Trie::", $trie->impl, "\n";
$trie->add("willcom" => [@all_cidr]);

cmpthese( $count , {
    'cidr' => sub {
        $cidr->find('210.169.99.3');
    },
    'xs' => sub {
        Net::IP::Match::XS::match_ip('210.169.99.3',@all_cidr);
    },
    'xs2' => sub {
        $xs2->match_ip('210.169.99.3');
    },
    'bin' => sub {
        $bin->match_ip('210.169.99.3');
    },
    'regexp' => sub {
        Net::IP::Match::Regexp::match_ip('210.169.99.3',$re);
    },
    'patricia' => sub {
        $pat->match_string('210.169.99.3');
    },
    'trie' => sub {
        $trie->match_ip('210.169.99.3');
    },
});

__END__
