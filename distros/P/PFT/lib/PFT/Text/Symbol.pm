# Copyright 2014-2016 - Giovanni Simoni
#
# This file is part of PFT.
#
# PFT is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your
# option) any later version.
#
# PFT is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with PFT.  If not, see <http://www.gnu.org/licenses/>.
#
package PFT::Text::Symbol v1.3.0;

=pod

=encoding utf8

=head1 NAME

PFT::Text::Symbol - Symbol from text scan

=head1 SYNOPSIS

    my $array = PFT::Text::Symbol->scan_html($your_html_text);
    foreach (PFT::Text::Symbol->scan_html($your_html_text)) {
        die unless $_->isa('PFT::Text::Symbol')
    };

=head1 DESCRIPTION

Each instance of C<PFT::Text::Symbol> represents a symbol obtained by
parsing the text of an entry C<PFT::Content::Entry>: they are detected as
C<E<lt>aE<gt>> and C<E<lt>imgE<gt>> tags in HTML.  Symbols are collected
into a a C<PFT::Text> object.

An example will make this easy to understand. Let's consider the following
tag:

    <img src=":key1:a1/b1/c1">

It will generate a symbol C<$s1> such that:

=over 1

=item C<$s1-E<gt>keyword> is C<key1>;

=item C<$s1-E<gt>args> is the list C<(a1, b1, c1)>;

=item C<$s1-E<gt>start> points to the first C<:> character;

=item C<$s1-E<gt>len> points to the last C<1> character;

=back

Since a block of HTML can possibly yield multiple symbols, there's no
public construction. Use the C<scan_html> multi-constructor instead.

=head2 Construction

Construction usually goes through C<PFT::Text::Symbol-E<gt>scan_html>,
which expects an HTML string as parameter and returns a list of blessed
symbols.

For other needs (e.g. testing):

    PFT::Text::Symbol->new($keyword, [$arg1, …, $argn], $start, $length)

=cut

sub scan_html {
    my $cls = shift;

    my $pair = qr/":(\w+):([^"]*)"/;
    my $img = qr/<img\s*[^>]*src=\s*$pair([^>]*)>/;
    my $ahr = qr/<a\s*[^>]*href=\s*$pair([^>]*)>/;

    my $text = join '', @_;
    my @out;
    for my $reg ($img, $ahr) {
        while ($text =~ /\W$reg/smg) {
            my $len = length($1) + length($2) + 2; # +2 for ::
            my $start = pos($text) - $len - length($3) - 2; # -2 for ">

            push @out, bless([
                $1,                 # keyword
                [split /\//, $2],   # args list
                $start,
                $len,
            ], $cls);
        }
    }

    sort { $a->start <=> $b->start } @out;
}

sub new {
    my $cls = shift;
    bless [@_], $cls;
}

use utf8;
use v5.16;
use strict;
use warnings;

=head2 Properties

=over

=item keyword

=cut

sub keyword { shift->[0] }

=item args

=cut

sub args { @{shift->[1]} }

=item start

=cut

sub start { shift->[2] }

=item len

=cut

sub len { shift->[3] }

=back

=cut

use overload
    '""' => sub {
        my $self = shift;
        sprintf 'PFT::Text::Symbol[key:"%s", args:["%s"], start:%d, len:%d]',
            $self->[0],
            join('", "', @{$self->[1]}),
            @{$self}[2, 3],
    },
;

1;
