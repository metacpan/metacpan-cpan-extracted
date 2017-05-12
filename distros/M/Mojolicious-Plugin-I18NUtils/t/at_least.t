#!/usr/bin/env perl

use Mojolicious::Lite;

use utf8;
use open qw( :encoding(UTF-8) :std );
use Test::More;
use Test::Mojo;

use_ok 'Mojolicious::Plugin::I18NUtils';

## Webapp START

plugin('I18NUtils');

any '/'      => sub {
    my $self = shift;

    my $lang   = $self->param('lang');
    my $number = $self->param('num');

    $self->render( text => $self->at_least( $number, $lang ) );
};

## Webapp END

my $t = Test::Mojo->new;

my %tests = (
    200 => {
        de    => '200+',
        en_CA => '200+',
        en_GB => '200+',
        en    => '200+',
        es    => "M\x{e1}s de 200",
        es_MX => "M\x{e1}s de 200",
        zh_CN => '200+',
        bn    => "\x{09e8}" . ( "\x{09e6}" x 2 ) . "+",
        ar    => "+\x{0662}" . ( "\x{0660}" x 2 ),
    },
    2000 => {
        de    => '2.000+',
        en_CA => '2,000+',
        en_GB => '2,000+',
        en    => '2,000+',
        es    => "M\x{e1}s de 2000",
        es_MX => "M\x{e1}s de 2,000",
        zh_CN => '2,000+',
        bn    => "\x{09e8}," . ( "\x{09e6}" x 3 ) . "+",
        ar    => "+\x{0662}" . "\x{066c}" . ( "\x{0660}" x 3 ),
    },
    20000 => {
        de    => '20.000+',
        en_CA => '20,000+',
        en_GB => '20,000+',
        en    => '20,000+',
        es    => "M\x{e1}s de 20.000",
        es_MX => "M\x{e1}s de 20,000",
        zh_CN => '20,000+',
        bn    => "\x{09e8}\x{09e6}," . ( "\x{09e6}" x 3 ) . "+",
        ar    => "+\x{0662}\x{0660}" . "\x{066c}" . ( "\x{0660}" x 3 ),
    },
);

for my $num ( sort keys %tests ) {
    my $subtests = $tests{$num};

    for my $lang ( sort keys %{$subtests} ) {
        $t->get_ok( "/?lang=$lang&num=$num" )
          ->status_is( 200 )
          ->content_is( $tests{$num}->{$lang}, "test language $lang with number $num" );
    }
}

done_testing();

