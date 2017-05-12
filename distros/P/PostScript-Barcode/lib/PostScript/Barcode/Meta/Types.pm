package PostScript::Barcode::Meta::Types;
use 5.010;
use utf8;
use strict;
use warnings FATAL => 'all';
use Moose::Util::TypeConstraints qw(enum subtype as where);

our $VERSION = '0.006';

enum 'PostScript::Barcode::Meta::Types::Enum::azteccode::format'    => qw(full compact rune);
enum 'PostScript::Barcode::Meta::Types::Enum::datamatrix::encoding' => qw(byte ascii edifact c40 text x12);
enum 'PostScript::Barcode::Meta::Types::Enum::qrcode::eclevel'      => qw(L M Q H);
enum 'PostScript::Barcode::Meta::Types::Enum::qrcode::version'      => (qw(M1 M2 M3 M4), 1 .. 40);
enum 'PostScript::Barcode::Meta::Types::Enum::qrcode::format'       => qw(full micro);
subtype 'PostScript::Barcode::Meta::Types::Bool'                    => as 'Bool';
subtype 'PostScript::Barcode::Meta::Types::Num'                     => as 'Num';
subtype 'PostScript::Barcode::Meta::Types::Tuple'                   => as 'ArrayRef[Num]' => where {2 == @{$_}};
subtype 'PostScript::Barcode::Meta::Types::TuplePair' => as 'ArrayRef[PostScript::Barcode::Meta::Types::Tuple]' => where {2 == @{$_}};

1;

__END__

=encoding UTF-8

=head1 NAME

PostScript::Barcode::Meta::Types - extended type constraints


=head1 VERSION

This document describes C<PostScript::Barcode::Meta::Types> version C<0.006>.


=head1 SYNOPSIS

    use PostScript::Barcode::Meta::Types qw();


=head1 DESCRIPTION

Creates the following type constraints.

=head2 PostScript::Barcode::Meta::Types::Enum::azteccode::format

Type C<Enum>: C<qw(full compact rune)>

=head2 PostScript::Barcode::Meta::Types::Enum::qrcode::eclevel

Type C<Enum>: C<qw(L M Q H)>

=head2 PostScript::Barcode::Meta::Types::Enum::qrcode::version

Type C<Enum>: C<qw(M1 M2 M3 M4), 1 .. 40>

=head2 PostScript::Barcode::Meta::Types::Enum::qrcode::format

Type C<Enum>: C<qw(full micro)>

=head2 PostScript::Barcode::Meta::Types::Tuple

Type C<ArrayRef[Num]> with exactly two elements

=head2 PostScript::Barcode::Meta::Types::TuplePair

Type C<ArrayRef[PostScript::Barcode::Meta::Types::Tuple]> with exactly two
elements
