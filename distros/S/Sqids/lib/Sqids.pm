package Sqids;
use 5.008001;
use strict;
use warnings;
use bignum;
use Carp 'croak';
use Encode qw(encode_utf8);
use List::Util qw(first min reduce);
use Sqids::Constants;
use Class::Tiny {
    alphabet => Sqids::Constants::DEFAULT_ALPHABET,
    min_length => Sqids::Constants::DEFAULT_MIN_LENGTH,
    blocklist => sub { Sqids::Constants::DEFAULT_BLOCKLIST },
};

our $VERSION = "0.03";

sub BUILD {
    my ($self, $args) = @_;

    my $alphabet = $self->alphabet;
    my $min_length = $self->min_length;
    my $blocklist = $self->blocklist;

    croak 'Alphabet cannot contain multibyte characters' if length $alphabet != length encode_utf8 $alphabet;

    croak 'Alphabet length must be at least 3' if length $alphabet < 3;

    my %alphabet_hash = map { $_ => undef } split '', $alphabet;
    croak 'Alphabet must contain unique characters' if keys %alphabet_hash != length $alphabet;

    my $min_length_limit = 255;
    croak "Minimum length has to be between 0 and $min_length_limit" if $min_length < 0 || $min_length > $min_length_limit;

    # clean up blocklist:
    # 1. all blocklist words should be lowercase
    # 2. no words less than 3 chars
    # 3. if some words contain chars that are not in the alphabet, remove those
    my $alphabet_lower = quotemeta lc $alphabet;
    @$blocklist =
        grep { length >= 3 && /^[$alphabet_lower]+$/ }
        map { lc } @$blocklist;

    $self->alphabet($self->shuffle($alphabet));
}

# Encodes an array of unsigned integers into an ID
#
# These are the cases where encoding might fail:
# - One of the numbers passed is smaller than 0
# - An n-number of attempts has been made to re-generated the ID, where n is alphabet length + 1
#
# @param {array.<number>} numbers Non-negative integers to encode into an ID (or an arrayref)
# @returns {string} Generated ID

sub encode {
    my ($self, @numbers) = @_;

    # if no numbers passed, return an empty string
    return '' unless @numbers;

    # Convert to array if arrayref provided
    @numbers = @{$numbers[0]} if ref $numbers[0] eq 'ARRAY';

    croak "Encoding only supports non-negative numbers" if first { $_ < 0 } @numbers;

    return $self->_encode_numbers(0, @numbers);
}

# Internal function that encodes an array of unsigned integers into an ID
#
# @param {number} increment An internal number used to modify the `offset` variable in order to re-generate the ID
# @param {array.<number>} numbers Non-negative integers to encode into an ID
# @returns {string} Generated ID

sub _encode_numbers {
    my ($self, $increment, @numbers) = @_;

    # if increment is greater than alphabet length, we've reached max attempts
    my $alphabet = $self->alphabet;
    my $length = length $alphabet;
    croak 'Reached max attempts to re-generate the ID' if $increment > $length;

    # get a semi-random offset from input numbers
    my $offset = @numbers;
    for (0..$#numbers) {
        $offset += ord(substr($alphabet, $numbers[$_] % $length, 1)) + $_;
    }

    # if there is a non-zero `increment`, it's an internal attempt to re-generated the ID
    $offset = ($offset + $increment) % $length;

    # re-arrange alphabet so that second-half goes in front of the first-half
    $alphabet = substr($alphabet, $offset) . substr($alphabet, 0, $offset);

    # `prefix` is the first character in the generated ID, used for randomization
    my $prefix = substr($alphabet, 0, 1);

    # reverse alphabet (otherwise for [0, x] `offset` and `separator` will be the same char)
    $alphabet = reverse $alphabet;

    # final ID will always have the `prefix` character at the beginning
    my @ret = ($prefix);

    # encode input array
    for (0..$#numbers) {
        # the first character of the alphabet is going to be reserved for the `separator`
        push @ret, $self->to_id($numbers[$_], substr($alphabet, 1));

        # if not the last number
        if ($_ < @numbers - 1) {
            # `separator` character is used to isolate numbers within the ID
            push @ret, substr($alphabet, 0, 1);

            # shuffle on every iteration
            $alphabet = $self->shuffle($alphabet);
        }
    }

    # join all the parts to form an ID
    my $id = join('', @ret);

    # handle `min_length` requirement, if the ID is too short
    if ($self->min_length > length $id) {
        # append a separator
        $id .= substr($alphabet, 0, 1);

        # keep appending `separator` + however much alphabet is needed
        # for decoding: two separators next to each other is what tells us the rest are junk characters
        while ($self->min_length - length $id > 0) {
            $alphabet = $self->shuffle($alphabet);
            $id .= substr($alphabet, 0, min(length $alphabet, $self->min_length - length $id));
        }
    }

    # if ID has a blocked word anywhere, restart with a +1 increment
    if ($self->is_blocked_id($id)) {
        $id = $self->_encode_numbers($increment + 1, @numbers);
    }

    return $id;
}

# Decodes an ID back into an array of unsigned integers
#
# These are the cases where the return value might be an empty array:
# - Empty ID / empty string
# - Non-alphabet character is found within ID
#
# @param {string} id Encoded ID
# @returns {array.<number>} Array of unsigned integers

sub decode {
    my ($self, $id) = @_;

    return if $id eq '';
    return unless defined wantarray;

    # if a character is not in the alphabet, return
    my $alphabet = quotemeta $self->alphabet;
    return if $id =~ /[^$alphabet]/;

    # first character is always the `prefix`
    my $prefix = substr($id, 0, 1);

    # `offset` is the semi-random position that was generated during encoding
    my $offset = index $self->alphabet, $prefix;

    # re-arrange alphabet back into its original form
    $alphabet = substr($self->alphabet, $offset) . substr($self->alphabet, 0, $offset);

    # reverse alphabet
    $alphabet = reverse $alphabet;

    # now it's safe to remove the prefix character from ID, it's not needed anymore
    $id = substr($id, 1);

    # decode
    my @ret;
    while (length $id) {
        my $separator = substr($alphabet, 0, 1);

        # we need the first part to the left of the separator to decode the number
        my @chunks = split /\Q$separator\E/, $id, -1;
        if (@chunks) {
            # if chunk is empty, we are done (the rest are junk characters)
            return @ret if $chunks[0] eq '';

            # decode the number without using the `separator` character
            push @ret, $self->to_number($chunks[0], substr($alphabet, 1));

            # if this ID has multiple numbers, shuffle the alphabet because that's what encoding function did
            if (@chunks > 1) {
                $alphabet = $self->shuffle($alphabet);
            }
        }

        # `id` is now going to be everything to the right of the `separator`
        $id = join($separator, @chunks[1..$#chunks]);
    }

    return wantarray ? @ret : @ret == 1 ? $ret[0] : \@ret;
}

# consistent shuffle (always produces the same result given the input)
sub shuffle {
    my ($self, $alphabet) = @_;
    my @chars = split '', $alphabet;

    for (my ($i, $j) = (0, @chars-1); $j>0; $i++, $j--) {
        my $r = ($i * $j + ord($chars[$i]) + ord($chars[$j])) % @chars;
        @chars[$i,$r] = @chars[$r,$i];
    }

    return join('', @chars);
}

sub to_id {
    my ($self, $num, $alphabet) = @_;
    my @id;
    my $result = $num;
    my $length = length $alphabet;

    do {
        unshift @id, substr($alphabet, $result % $length, 1);
        $result = int($result / $length);
    } while ($result > 0);

    return join('', @id);
}

sub to_number {
    my ($self, $id, $alphabet) = @_;
    reduce { $a * length($alphabet) + index($alphabet, $b) } 0, split '', $id;
}

sub is_blocked_id {
    my ($self, $id) = @_;
    $id = lc $id;

    foreach my $word (@{$self->blocklist}) {
        # no point in checking words that are longer than the ID
        next unless length $word <= length $id;
        if (length $id <= 3 || length $word <= 3) {
            # short words have to match completely; otherwise, too many matches
            return 1 if $id eq $word;
        } elsif ($word =~ /\d/) {
            # words with leet speak replacements are visible mostly on the ends of the ID
            return 1 if $id =~ /^\Q$word\E/ || $id =~ /\Q$word\E$/;
        } elsif ($id =~ /\Q$word\E/) {
            # otherwise, check for blocked word anywhere in the string
            return 1;
        }
    }

    return 0;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sqids - generate short unique identifiers from numbers

=head1 SYNOPSIS

    use Sqids;
    my $sqids = Sqids->new;

    # encode/decode a single number
    my $id = $sqids->encode(123);         # 'UKk'
    my $num = $sqids->decode('UKk');      # 123

    # or a list or arrayref
    $id = $sqids->encode(1, 2, 3);        # '86Rf07'
    $id = $sqids->encode([1, 2, 3]);      # '86Rf07'
    my @nums = $sqids->decode('86Rf07');  # (1, 2, 3)

    # also get results in an arrayref
    my $nums = $sqids->decode('86Rf07');  # [1, 2, 3]

=head1 DESCRIPTION

L<Sqids|https://sqids.org/perl> (I<pronounced "squids">) is a small
library that lets you B<generate unique IDs from numbers>. It's good for link
shortening, fast & URL-safe ID generation and decoding back into numbers for
quicker database lookups.

Features:

=over 4

=item * B<Encode multiple numbers> - generate short IDs from one or several non-negative numbers

=item * B<Quick decoding> - easily decode IDs back into numbers

=item * B<Unique IDs> - generate unique IDs by shuffling the alphabet once

=item * B<ID padding> - provide minimum length to make IDs more uniform

=item * B<URL safe> - auto-generated IDs do not contain common profanity

=item * B<Randomized output> - Sequential input provides nonconsecutive IDs

=item * B<Many implementations> - Support for L<40+ programming languages|https://sqids.org/>

=back

=head2 Use-cases

Good for:

=over 4

=item * Generating IDs for public URLs (eg: link shortening)

=item * Generating IDs for internal systems (eg: event tracking)

=item * Decoding for quicker database lookups (eg: by primary keys)

=back

Not good for:

=over 4

=item * Sensitive data (this is not an encryption library)

=item * User IDs (can be decoded revealing user count)

=back

=head2 Getting started

Install Sqids via:

    cpanm Sqids

=head1 METHODS

=head2 new

    my $sqids = Sqids->new();

Make a new Sqids object. This constructor accepts a few options, either
as a hashref or a list (using L<Class::Tiny>):

    my $sqids = Sqids->new(
        alphabet => 'abcdefg',
        min_length => 4,
        blocklist => ['word'],
    );

=over

=item alphabet

You can randomize IDs by providing a custom alphabet:

    my $sqids = Sqids->new({
      alphabet => 'FxnXM1kBN6cuhsAvjW3Co7l2RePyY8DwaU04Tzt9fHQrqSVKdpimLGIJOgb5ZE',
    });
    my $id = $sqids->encode(1, 2, 3); # "B4aajs"
    my $numbers = $sqids->decode($id); # [1, 2, 3]

=item min_length

Enforce a I<minimum> length for IDs:

    my $sqids = Sqids->new( min_length => 10 );
    my $id = $sqids->encode(1, 2, 3); # "86Rf07xd4z"
    my $numbers = $sqids->decode($id); # [1, 2, 3]

=item blocklist

Prevent specific words from appearing anywhere in the auto-generated IDs:

    my $sqids = Sqids->new( blocklist => ['86Rf07'] );
    my $id = $sqids->encode([1, 2, 3]); # "se8ojk"
    my $numbers = $sqids->decode($id); # [1, 2, 3]

=back

=head2 encode

    my $id = $sqids->encode($n1, [$n2, ...]);

Encode a single number (or a list of numbers, or a single arrayref of numbers) into a string.

=head2 decode

    my @numbers = $sqids->decode($id);

Decode an id into its number (or numbers). Returns a list in list context,
or a scalar (one number) or arrayref (multiple numbers) in scalar context.

B<Note>: Because of the algorithm's design, B<multiple IDs can decode back
into the same sequence of numbers>. If it's important to your design that IDs
are canonical, you have to manually re-encode decoded numbers and check that
the generated ID matches.

=head1 SEE ALSO

L<Sqids|https://sqids.org>

=head1 LICENSE

Copyright (C) Matthew Somerville. MIT.

=head1 AUTHOR

Matthew Somerville E<lt>matthew@mysociety.orgE<gt>

=cut

