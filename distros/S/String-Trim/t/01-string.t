use strict;
use warnings;
use Test::More 0.94 tests => 2;
use Test::Builder 0.94 qw();
use String::Trim;

my $strings = {
    'one'       => 'one',
    'tw o'      => 'tw o',
    ' three'    => 'three',
    'four '     => 'four',
    ' five '    => 'five',
    '               six          ' => 'six',
    " seven\n"  => 'seven',
    "\n\neight" => 'eight',
    " nine\nten " => "nine\nten",
};

subtest 'return' => sub {
    plan tests => scalar keys %$strings;
    foreach my $key (keys %$strings) {
        my $to_trim = $key;
        my $ought   = $strings->{$key};
        my $trimmed = trim($to_trim);
        is($trimmed, $ought, "trim($to_trim) returned '$ought' OK");
    }
};

subtest 'in-place' => sub {
    plan tests => scalar keys %$strings;
    foreach my $key (keys %$strings) {
        my $to_trim = $key;
        my $ought   = $strings->{$key};
        trim($to_trim);
        is($to_trim, $ought, "'$to_trim' trimmed to '$ought' in-place OK");
    }
};
