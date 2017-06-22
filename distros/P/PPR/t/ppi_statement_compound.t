use strict;
use warnings;

use Test::More;

use PPR;

my $neg = 0;
while (my $str = <DATA>) {
           if ($str =~ /\A# TH[EI]SE? SHOULD MATCH/) { $neg = 0;       next; }
        elsif ($str =~ /\A# TH[EI]SE? SHOULD FAIL/)  { $neg = 1;       next; }
        elsif ($str !~ /^####\h*\Z/m)                { $str .= <DATA>; redo; }

        $str =~ s/\s*^####\h*\Z//m;

        if ($neg) {
            ok $str !~ m/\A \s* (?&PerlDocument) \s* \Z   $PPR::GRAMMAR/xo => $str;
        }
        else {
            ok $str =~ m/\A \s* (?&PerlDocument) \s* \Z   $PPR::GRAMMAR/xo => $str;
        }
}

done_testing();

__DATA__
# THESE SHOULD MATCH...
       while (1) { }
       until (1) { }
LABEL: while (1) { }
LABEL: until (1) { }

if (1) { }
unless (1) { }

       for              (@foo) { }
       foreach          (@foo) { }
       for     $x       (@foo) { }
       foreach $x       (@foo) { }
       for     my $x    (@foo) { }
       foreach my $x    (@foo) { }
       for     state $x (@foo) { }
       foreach state $x (@foo) { }
LABEL: for              (@foo) { }
LABEL: foreach          (@foo) { }
LABEL: for     $x       (@foo) { }
LABEL: foreach $x       (@foo) { }
LABEL: for     my $x    (@foo) { }
LABEL: foreach my $x    (@foo) { }
LABEL: for     state $x (@foo) { }
LABEL: foreach state $x (@foo) { }

       for              qw{foo} { }
       foreach          qw{foo} { }
       for     $x       qw{foo} { }
       foreach $x       qw{foo} { }
       for     my $x    qw{foo} { }
       foreach my $x    qw{foo} { }
       for     state $x qw{foo} { }
       foreach state $x qw{foo} { }
LABEL: for              qw{foo} { }
LABEL: foreach          qw{foo} { }
LABEL: for     $x       qw{foo} { }
LABEL: foreach $x       qw{foo} { }
LABEL: for     my $x    qw{foo} { }
LABEL: foreach my $x    qw{foo} { }
LABEL: for     state $x qw{foo} { }
LABEL: foreach state $x qw{foo} { }

       for     (             ;       ;     ) { }
       foreach (             ;       ;     ) { }
       for     ($x = 0       ; $x < 1; $x++) { }
       foreach ($x = 0       ; $x < 1; $x++) { }
       for     (my $x = 0    ; $x < 1; $x++) { }
       foreach (my $x = 0    ; $x < 1; $x++) { }
LABEL: for     (             ;       ;     ) { }
LABEL: foreach (             ;       ;     ) { }
LABEL: for     ($x = 0       ; $x < 1; $x++) { }
LABEL: foreach ($x = 0       ; $x < 1; $x++) { }
LABEL: for     (my $x = 0    ; $x < 1; $x++) { }
LABEL: foreach (my $x = 0    ; $x < 1; $x++) { }
####
