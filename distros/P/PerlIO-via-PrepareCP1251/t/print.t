#!perl

use 5.006001;

use strict;
use warnings;
use utf8;

use Test::More;
use Encode;
use List::MoreUtils qw/natatime/;

use PerlIO::via::PrepareCP1251;

run_tests(
    q{f} => 'f', 'latin symbol',
    q{щ} => q{щ}, 'cyrillic symbol',
    q{å} => 'a', 'removing diacritic',
    q{Æ} => '?', 'unknown symbol in default_char mode',
);

$PerlIO::via::PrepareCP1251::INCOMPATIBLE_CHAR_MODE = 'skip';
run_tests(
    q{åÆ} => 'a', 'unknown symbol in skip mode',
);

$PerlIO::via::PrepareCP1251::INCOMPATIBLE_CHAR_MODE = 'charname';
run_tests(
    q{åÆ} => 'a\N{LATIN CAPITAL LETTER AE}', 'unknown symbol in charname mode',
);


$PerlIO::via::PrepareCP1251::CMAP{"Æ"} = 'AE';
run_tests(
    q{åÆ} => 'aAE', 'manual definition',
);

done_testing();

sub run_tests {
    my $it = natatime 3, @_;
    while (my ($input, $expected, $name) = $it->()) {
        is _conv($input), $expected, $name;
    }
    return;
}

sub _conv {
    my $dump = q{};
    open my $fh, '>:encoding(cp1251):via(PrepareCP1251)', \$dump;
    print {$fh} @_;
    close $fh;
    return decode cp1251 => $dump;
}
