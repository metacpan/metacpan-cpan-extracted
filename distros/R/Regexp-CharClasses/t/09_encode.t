#!/usr/bin/perl

use Test::More tests => 1 + 7 * 128;

use strict;
use warnings;
no warnings 'syntax';

BEGIN {
    use_ok ('Regexp::CharClasses')
};

my %info = (
    IsUuencode => [
        ' ', 'A' .. 'Z', '0' .. '9',
        qw { ! " # $ % & ' ( ) * + , - . / : ; < = > ? @ [ \ ] ^ _ ` }
    ],
    IsBase64    => [
        'A' .. 'Z', 'a' .. 'z', '0' .. '9', qw { + / = }
    ],
    IsBase64url => [
        'A' .. 'Z', 'a' .. 'z', '0' .. '9', qw { - _ = }
    ],
    IsBase32    => [
        'A' .. 'Z', '2' .. '7', qw { = }
    ],
    IsBase32hex => [
        'A' .. 'V', '0' .. '9', qw { = }
    ],
    IsBase16    => [
        'A' .. 'F', '0' .. '9'
    ],
    IsBinHex    => [
        qw { ! " # $ % & ' ( ) * + , - @ [ ` },
        '0' .. '9', 'A' .. 'N', 'P' .. 'V', 'X' .. 'Z',
        'a' .. 'f', 'h' .. 'm', 'p' .. 'r'
    ],
);

my %data;
while (my ($name, $chars) = each %info) {
    @{$data {$name}} {@$chars} = ();
}

foreach my $name (sort keys %data) {
    foreach my $ord (0x00 .. 0x7F) {
        local $_ = chr $ord;
        if (exists $data {$name} {$_}) {
            ok /\p{$name}/, "'$_' =~ /\\p{$name}/"
        }
        else {
            ok /\P{$name}/, "'$_' =~ /\\P{$name}/"
        }
    }
}

__END__
