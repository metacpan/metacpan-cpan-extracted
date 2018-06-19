use warnings;
use strict;

use Test::More;

BEGIN{
    BAIL_OUT "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
}


use PPR;

my $FOR_LOOP = qr{
    \A (?&PerlOWS) (?&PerlControlBlock) (?&PerlOWS) \z

    $PPR::GRAMMAR
}xms;

my %okay = (
    for_no_iterator              => q{ for                  ( 1..10) { say $_; } },
    for_def_iterator             => q{ for          $elem   ( 1..10) { say $_; } },
    for_my_iterator              => q{ for   my     $elem   ( 1..10) { say $_; } },
    for_our_iterator             => q{ for   our    $elem   ( 1..10) { say $_; } },
    for_our_iterator_weird       => q{ for   our    $#      ( 1..10) { say $#; } },
    for_def_iterator_curly       => q{ for          ${elem} ( 1..10) { say $_; } },
    for_my_iterator_curly        => q{ for   my     ${elem} ( 1..10) { say $_; } },
    for_our_iterator_curly       => q{ for   our    ${elem} ( 1..10) { say $_; } },
    for_our_iterator_weird_curly => q{ for   our    ${#}    ( 1..10) { say $#; } },
    for_state_iterator           => q{ for   state  $elem   ( 1..10) { say $_; } },
    for_my_prealias              => q{ for \ my     $elem   ( 1..10) { say $_; } },
    for_our_prealias             => q{ for \ our    $elem   ( 1..10) { say $_; } },
    for_state_prealias           => q{ for \ state  $elem   ( 1..10) { say $_; } },
    for_my_postalias             => q{ for   my   \ $elem   ( 1..10) { say $_; } },
    for_our_postalias            => q{ for      our\$elem   ( 1..10) { say $_; } },
    for_state_postalias          => q{ for   state \$elem   ( 1..10) { say $_; } },
    for_my_prealias_array        => q{ for \ my     @elem   ( 1..10) { say $_; } },
    for_our_prealias_array       => q{ for \ our    @elem   ( 1..10) { say $_; } },
    for_state_prealias_array     => q{ for \ state  @elem   ( 1..10) { say $_; } },
    for_my_postalias_array       => q{ for   my   \ @elem   ( 1..10) { say $_; } },
    for_our_postalias_array      => q{ for      our\@elem   ( 1..10) { say $_; } },
    for_state_postalias_array    => q{ for   state \@elem   ( 1..10) { say $_; } },
    for_my_prealias_hash         => q{ for \ my     %elem   ( 1..10) { say $_; } },
    for_our_prealias_hash        => q{ for \ our    %elem   ( 1..10) { say $_; } },
    for_state_prealias_hash      => q{ for \ state  %elem   ( 1..10) { say $_; } },
    for_my_postalias_hash        => q{ for   my   \ %elem   ( 1..10) { say $_; } },
    for_our_postalias_hash       => q{ for      our\%elem   ( 1..10) { say $_; } },
    for_state_postalias_hash     => q{ for   state \%elem   ( 1..10) { say $_; } },
);

my %not_okay = (
    for_no_list        => q{ for                     { say $_; } },
    for_local_iterator => q{ for local $elem (1..10) { say $_; } },
);

for my $test (sort keys %okay) {
    ok $okay{$test} =~ $FOR_LOOP  => $test;
}

for my $test (keys %not_okay) {
    ok $not_okay{$test} !~ $FOR_LOOP  => $test;
}


done_testing();

