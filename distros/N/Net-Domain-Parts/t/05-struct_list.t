#!perl
use 5.006;
use strict;
use warnings;
use Data::Dumper;
use Test::More;

use Net::Domain::Parts qw(:all);

can_ok __PACKAGE__, 'domain_parts';

my $tlds = tld_struct();

is ref $tlds, 'HASH', "struct() returns a hashref ok";

my @keys = qw(
    version
    third_level_domain
    second_level_domain
    top_level_domain
);

for (@keys) {
    is(exists $tlds->{$_}, 1, "$_ key exists from struct() ok");
}

is
    $tlds->{second_level_domain}{'co.uk'},
    1,
    "co.uk exists in second_level_domain ok";

is
    $tlds->{top_level_domain}{'ca'},
    1,
    "ca exists in top_level_domain ok";

is
    $tlds->{third_level_domain}{'hokuto.yamanashi.jp'},
    1,
    "hokuto.yamanashi.jp exists in third_level_domain ok";

my $list = tld_list();

is $list->{zm}, 1, "Top level domain in tld_list() ok";
is $list->{'co.uk'}, 1, "Second level domain in tld_list() ok";
is $list->{'hokuto.yamanashi.jp'}, 1, "Third level domain in tld_list() ok";

done_testing();