package Peta::NN::Codec;
# ABSTRACT: characters to token indices, string pairs to edit labels

# Between strings and what a network eats and emits: characters become token
# indices through a vocabulary, and a pair of strings becomes an edit label.

use v5.36;

use Exporter 'import';

our $VERSION = '0.2610090';
our @EXPORT_OK = qw(build_vocab window edit_label apply_edit edit2_label apply_edit2 PAD UNKNOWN);

# Two indices are reserved: a window reaching past either end of the string
# reads PAD there, and a character never seen in training reads UNKNOWN.
use constant { PAD => 0, UNKNOWN => 1 };

my $FIRST_CHAR_INDEX = 2;

# { character => index } over every character of the given strings.
sub build_vocab ($strings) {
    my %seen;
    for my $string (@$strings) {
        $seen{$_} = 1 for split //, $string;
    }
    my $index = $FIRST_CHAR_INDEX;
    return { map { $_ => $index++ } sort keys %seen };
}

# The token indices of $count consecutive positions of @$chars starting at
# $from, which may lie before the start or run past the end. Every window in
# this library is this one shape: the last n characters start at length - n,
# the first n at 0, and n either side of position p at p - n.
sub window ($chars, $from, $count, $vocab) {
    return [
        map { $_ < 0 || $_ > $#$chars ? PAD : $vocab->{ $chars->[$_] } // UNKNOWN }
            $from .. $from + $count - 1
    ];
}

# How to turn $in into $out by rewriting its end: "cut:add" says drop that
# many characters and append that text. Jelínek -> Jelínku is "2:ku". Many
# words share one label, which is what makes it learnable as a class.
sub edit_label ($in, $out) {
    my $common = 0;
    my $limit  = length $in < length $out ? length $in : length $out;
    $common++ while $common < $limit && substr($in, $common, 1) eq substr($out, $common, 1);
    return (length($in) - $common) . ':' . substr($out, $common);
}

# Undefined when the label asks to cut more than the string has.
sub apply_edit ($in, $label) {
    my ($cut, $add) = split /:/, $label, 2;
    return if $cut > length $in;
    return substr($in, 0, length($in) - $cut) . $add;
}

# The longest stretch of characters two strings share: where it starts in
# each, and how long it is. Of several equally long, the first in $in.
sub _common ($in, $out) {
    my @a = split //, $in;
    my @b = split //, $out;
    my ($best, $at_in, $at_out) = (0, 0, 0);
    my @run = (0) x (@b + 1);          # $run[j]: length of the stretch ending at a[i-1], b[j-1]
    for my $i (1 .. @a) {
        my @next = (0) x (@b + 1);
        for my $j (1 .. @b) {
            next if $a[ $i - 1 ] ne $b[ $j - 1 ];
            my $length = $next[$j] = $run[ $j - 1 ] + 1;
            ($best, $at_in, $at_out) = ($length, $i - $length, $j - $length) if $length > $best;
        }
        @run = @next;
    }
    return ($at_in, $at_out, $best);
}

# How to turn $in into $out by rewriting BOTH ends around what they share:
# "cut:add|cut:add", first for the front, then for the end. chytrý ->
# nejchytřejší keeps "chyt" and is "0:nej|2:řejší".
sub edit2_label ($in, $out) {
    my ($at_in, $at_out, $length) = _common($in, $out);
    return "$at_in:" . substr($out, 0, $at_out) . '|'
         . (length($in) - $at_in - $length) . ':' . substr($out, $at_out + $length);
}

# Undefined when the label asks to cut more than the string has.
sub apply_edit2 ($in, $label) {
    my ($front, $back) = split /\|/, $label, 2;
    my ($cut_front, $add_front) = split /:/, $front, 2;
    my ($cut_back,  $add_back)  = split /:/, $back,  2;
    return if $cut_front + $cut_back > length $in;
    return $add_front . substr($in, $cut_front, length($in) - $cut_front - $cut_back) . $add_back;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::NN::Codec - characters to token indices, string pairs to edit labels

=head1 VERSION

version 0.2610090

=head1 SYNOPSIS

    use Peta::NN::Codec qw(build_vocab window edit_label apply_edit);

    my $vocab  = build_vocab(\@words);
    my @chars  = split //, 'Irena';
    my $tokens = window(\@chars, @chars - 4, 4, $vocab);    # the last four

    my $label = edit_label('Irena', 'Ireno');               # "1:o"
    print apply_edit('Helena', $label);                     # Heleno

=head1 FUNCTIONS

All are exported on request.

=head2 build_vocab

C<build_vocab(\@strings)>: C<< { character => index } >> over every character
of the strings. Indices 0 and 1 are reserved for padding and for unknown
characters.

=head2 window

C<window(\@chars, $from, $count, $vocab)>: the token indices of C<$count>
consecutive positions starting at C<$from>, which may lie before the start or
run past the end.

=head2 edit_label

C<edit_label($in, $out)>: how to turn C<$in> into C<$out> by rewriting its
end, as C<"cut:add">. Jelínek to Jelínku is C<"2:ku">.

=head2 apply_edit

C<apply_edit($in, $label)>: the string with the edit carried out, or undef
when the label asks to cut more than the string has.

=head2 edit2_label

C<edit2_label($in, $out)>: the same for both ends around what the two strings
share, as C<"cut:add|cut:add">, first for the front.

=head2 apply_edit2

C<apply_edit2($in, $label)>: the string with a two-ended edit carried out, or
undef.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
