#!/usr/bin/perl

BEGIN { $ENV{TESTING} = 1 }

use strict;
use warnings;
use Test::More;
use Test::Warnings;

my @data = test_data();
plan tests => 2 + ( map {( $_->{name}, keys %{ $_->{test} } )} @data );

my $module = 'Tail::Tool::Regex';
use_ok( $module );

for my $data (@data) {
    my $re = $module->new( $data->{new} );
    ok $re, 'Create new object for ' . $data->{name};
    note $re->summarise;

    for my $test ( keys %{ $data->{test} } ) {
        my $name = "  $data->{name} $test is ";
        $name
            .= $data->{test}{$test} eq ''          ? 'false'
            :  $data->{test}{$test} eq '1'         ? 'true'
            :  ref $data->{test}{$test} eq 'ARRAY' ? join ', ', @{ $data->{test}{$test} }
            :                                        $data->{test}{$test};

        if ( $test eq 'summarise' ) {
            TODO: {
                local $TODO = 'Need to workout how to test stringified regexes';
                is_deeply $re->$test, $data->{test}{$test}, $name;
            };
        }
        else {
            is_deeply $re->$test, $data->{test}{$test}, $name;
        }
    }
}

sub test_data {
    return (
        {
            new => { regex => qr/^find/ },
            test => {
                regex       => qr/^find/,
                has_colour  => '',
                has_replace => '',
                enabled     => 1,
                summarise   => 'qr/(?-xism:^find)/',
            },
            name => 'simple regex',
        },
        {
            new => { regex => '^find' },
            test => {
                regex       => qr/^find/,
                has_colour  => '',
                has_replace => '',
                enabled     => 1,
                summarise   => 'qr/(?-xism:^find)/',
            },
            name => 'simple regex string',
        },
        {
            new => { regex => qr/^find/, replace => 'found' },
            test => {
                regex       => qr/^find/,
                has_colour  => '',
                has_replace => 1,
                replace     => 'found',
                enabled     => 1,
                summarise   => 'qr/(?-xism:^find)/found/',
            },
            name => 'simple replace',
        },
        {
            new => { regex => qr/^find/, enabled => 0 },
            test => {
                regex       => qr/^find/,
                has_colour  => '',
                has_replace => '',
                enabled     => 0,
                summarise   => 'qr/(?-xism:^find)/, disabled',
            },
            name => 'disabled',
        },
        {
            new => { regex => qr/^find/, colour => ['red'] },
            test => {
                regex       => qr/^find/,
                has_colour  => 1,
                colour      => ['red'],
                has_replace => '',
                enabled     => 1,
                summarise   => 'qr/(?-xism:^find)/, colour=[red]',
            },
            name => 'coloured regex',
        },
    );
}
