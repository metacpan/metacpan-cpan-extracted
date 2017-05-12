#!/usr/bin/perl

package Testing;

use Moose;
with 'Tail::Tool::RegexList';

package main;

BEGIN { $ENV{TESTING} = 1 }

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Tail::Tool::Regex;
use Data::Dumper qw/Dumper/;

my @data = test_data();
plan tests => 2 + ( map {( $_->{name}, keys %{ $_->{test} } )} @data );

my $module = 'Tail::Tool::RegexList';
use_ok( $module );


for my $data (@data) {
    my $re = Testing->new( $data->{new} );
    ok $re, 'Create new object for ' . $data->{name};

    for my $test ( keys %{ $data->{test} } ) {
        my $name = "  $data->{name} $test is ";
        $name
            .= $data->{test}{$test} eq ''          ? 'false'
            :  $data->{test}{$test} eq '1'         ? 'true'
            :  ref $data->{test}{$test} eq 'ARRAY' ? join ', ', map { ref $_ ? $_->summarise : $_ } @{ $data->{test}{$test} }
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
            new => {
                regex => [ Tail::Tool::Regex->new( regex => qr/^find/ ) ],
            },
            test => {
                regex     => [
                    Tail::Tool::Regex->new( regex => qr/^find/ ),
                ],
                summarise => 'qr/(?-xism:^find)/',
            },
            name => 'simple regex',
        },
        {
            new => {
                regex => qr/^find/,
            },
            test => {
                regex     => [
                    Tail::Tool::Regex->new( regex => qr/^find/ ),
                ],
                summarise => 'qr/(?-xism:^find)/',
            },
            name => 'simple regex',
        },
        {
            new => {
                regex => '^find',
            },
            test => {
                regex     => [
                    Tail::Tool::Regex->new( regex => qr/^find/ ),
                ],
                summarise => 'qr/(?-xism:^find)/',
            },
            name => 'simple regex',
        },
        {
            new => {
                regex => [ '^find' ],
            },
            test => {
                regex     => [
                    Tail::Tool::Regex->new( regex => qr/^find/ ),
                ],
                summarise => 'qr/(?-xism:^find)/',
            },
            name => 'simple regex',
        },
        {
            new => {
                regex => [ '/^find/found/' ],
            },
            test => {
                regex     => [
                    Tail::Tool::Regex->new( regex => qr/^find/, replace => 'found' ),
                ],
                summarise => 'qr/(?-xism:^find)/found/',
            },
            name => 'simple replace',
        },
    );
}
