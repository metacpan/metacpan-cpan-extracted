#!perl

use 5.010;
use strict;
use warnings;

use Test::Exception;
use Test::More 0.96;

use SHARYANTO::Hash::Util qw(rename_key replace_hash_content);

subtest "rename_key" => sub {
    my %h = (a=>1, b=>2);
    dies_ok { rename_key(\%h, "c", "d") } "old key doesn't exist -> die";
    dies_ok { rename_key(\%h, "a", "b") } "new key exists -> die";
    rename_key(\%h, "a", "a2");
    is_deeply(\%h, {a2=>1, b=>2}, "success 1");
};

subtest "replace_hash_content" => sub {
    my $a = {a=>1,b=>2};
    my $refa = "$a";
    replace_hash_content($a, c=>3);
    is_deeply($a, {c=>3}, "content changed");
    is("$a", $refa, "refaddr doesn't change");
};

DONE_TESTING:
done_testing();
