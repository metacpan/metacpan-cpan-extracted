#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
use open qw( :encoding(UTF-8) :std );

use Test::More;

use Mojolicious::Plugin::I18NUtils::Locale;

my %tests = (
  en => {
    l => 'en',
    lr => 'en',
    rl => 'en',
    ls => 'en',
    s  => '',
  },
  en_EN => {
    l => 'en',
    lr => 'en-EN',
    rl => 'EN-en',
    s  => '',
  },
  sk_Latn => {
    l  => 'sk',
    ls => 'sk-Latn',
    sl => 'Latn-sk',
    s  => 'Latn',
  },
);

for my $locale ( sort keys %tests ) {
    my $obj = Mojolicious::Plugin::I18NUtils::Locale->new( locale => $locale );
    for my $method ( sort keys %{ $tests{$locale} } ) {
        my $check = $tests{$locale}->{$method};

        is $obj->$method(), $check, "$locale // $method // $check";
    }
}

done_testing();
