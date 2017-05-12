#!/usr/bin/perl

use Test::More tests => 0x3007;

use strict;
use warnings;
no warnings 'syntax';

BEGIN {
    use_ok ('Regexp::CharClasses')
};

my @lc_v  = qw [a e i o u];
my @uc_v  = qw [A E I O U];
my @lc_c  = qw [b c d f g h j k l m n p q r s t v w x y z];
my @uc_c  = qw [B C D F G H J K L M N P Q R S T V W X Y Z];

my %lc_c  = map {$_ => 1} @lc_c;
my %uc_c  = map {$_ => 1} @uc_c;
my %lc_v  = map {$_ => 1} @lc_v;
my %uc_v  = map {$_ => 1} @uc_v;

foreach my $v (@lc_v) {
    ok $v =~ /^\p{IsLcVowel}$/, "Lc vowel $v";
    ok $v =~ /^\p{IsVowel}$/, "Vowel $v";
}

foreach my $v (@uc_v) {
    ok $v =~ /^\p{IsUcVowel}$/, "Uc vowel $v";
    ok $v =~ /^\p{IsVowel}$/, "Vowel $v";
}

foreach my $c (@lc_c) {
    ok $c =~ /^\p{IsLcConsonant}$/, "Lc consonant $c";
    ok $c =~ /^\p{IsConsonant}$/, "Consonant $c";
}

foreach my $c (@uc_c) {
    ok $c =~ /^\p{IsUcConsonant}$/, "Uc consonant $c";
    ok $c =~ /^\p{IsConsonant}$/, "Consonant $c";
}

foreach my $c (0x00 .. 0x800) {
    my $char = chr $c;
    my $h    = sprintf "%04x" => $c;
    ok $char =~ /^\P{IsLcVowel}$/,  "\\x{$h} is not a lc vowel"
               unless $lc_v {$char};
    ok $char =~ /^\P{IsUcVowel}$/, "\\x{$h} is not a uc vowel"
               unless $uc_v {$char};
    ok $char =~ /^\P{IsVowel}$/, "\\x{$h} is not a vowel"
               unless $lc_v {$char} || $uc_v {$char};

    ok $char =~ /^\P{IsLcConsonant}$/,  "\\x{$h} is not a lc consonant"
               unless $lc_c {$char};
    ok $char =~ /^\P{IsUcConsonant}$/, "\\x{$h} is not a uc consonant"
               unless $uc_c {$char};
    ok $char =~ /^\P{IsConsonant}$/, "\\x{$h} is not a consonant"
               unless $lc_c {$char} || $uc_c {$char};
}


__END__
