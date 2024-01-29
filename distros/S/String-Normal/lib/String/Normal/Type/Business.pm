package String::Normal::Type::Business;
use strict;
use warnings;
use String::Normal::Type;
use String::Normal::Config;

use Lingua::Stem;
our $STEM;
our $biz_stop;
our $biz_compress;

sub transform {
    my ($self,$value) = @_;

    # tokenize and stem
    my (@digits,@words);
    _tokenize_value( $value, \@digits, \@words );
    $STEM->stem_in_place( @words );

    # Remove "special" beginning and/or ending stopwords, if such words are present
    # and enough tokens are in place to remove them safely.
    if (@words) {
        # make a copy of @words and whittle it down
        my @copy = @words;
        my $count;
        if ($count = $biz_stop->{first}{$copy[0]}) {
            shift @copy if @copy >= $count;
        }
        if (@copy and $count = $biz_stop->{last}{$copy[-1]}) {
            pop @copy if @copy >= $count;
        }

        # reverting back if overnormalization occurs
        @words = @copy if @copy;
    }

    # Remove all middle stop words that are safe to remove, based on the number of
    # tokens, of course.
    my @filtered = map {
        my $count = $biz_stop->{middle}{$_} || '';
        (length $count and @words >= $count) ? () : $_;
    } @words;

    # If we filtered all words out, "revert" to the full array of stemmed tokens.
    @filtered = @words unless @filtered;

    # The canon name is the sorted filtered stemmed words plus the original digits.
    return join ' ', sort @digits, @filtered;
}

sub new {
    my $self = shift;
    $STEM = Lingua::Stem->new;
    $STEM->add_exceptions( String::Normal::Config::BusinessStem::_data( @_ ) );
    $biz_stop     = String::Normal::Config::BusinessStop::_data( @_ );
    $biz_compress = String::Normal::Config::BusinessCompress::_data( @_ );
    return bless {@_}, $self;
}

sub _tokenize_value {
    my ($value,$digits,$words) = @_;

    $value = String::Normal::Type::_scrub_value( $value );

    # split tokens on more than just whitespace:
    # split digits from words but keep things like 3D and 1st combined,
    # also split things like abcd#efgh but keep pound signs for #2 and # 1 and #
    # prevent the empty string from finding its way into the token list as well
    my @tokens = map { map length $_ ? $_ : (), split /##+|\s+|#+\b|\b#+/, $_ } $value =~ /(?:\d+\w{1,2}\b|\d+|\D+)/g;

    # walk each token thru the tree and create markers
    my @pairs = _mark_pairs( \@tokens );
    _compress_list( \@tokens, \@pairs ) if @pairs;

    # separate out tokens that contain digits (snowball stemmer will scrub all digits)
    for (@tokens) {
        if (/\d/) {
            push @$digits, $_;
        } else {
            push @$words, $_;
        }
    }
}

sub _mark_pairs {
    my $tokens = shift;
    my @pairs = ();
    for my $i (0 .. $#$tokens) {
        my $token = $tokens->[$i];
        next unless exists $biz_compress->{$token};
        next if $i + 1 > $#$tokens;
        my $end = _walk_tree( $i + 1, $tokens, $biz_compress->{$token} );
        if ($end) {
            push @pairs, [$i,$end];
            $i = $end;
        }
    }
    return @pairs;
}


sub _walk_tree {
    my ($i, $list, $tree) = @_;

    if (my $t = $tree->{$list->[$i]}) {
        if (ref $t eq 'HASH' and !%$t) {
            return $i;
        } else {
            _walk_tree( $i + 1, $list, $t );
        }
    }
}

sub _compress_list {
    my ($list,$pairs) = @_;
    for my $pair (reverse @$pairs) {
        my ($s,$e) = @$pair;
        splice @$list, $s, $e - $s + 1, join '', @$list[$s .. $e];
    }
}

1;

__END__
=head1 NAME

String::Normal::Type::Business;

=head1 DESCRIPTION

This package defines substitutions to be performed on Business types.

=head1 METHODS

=over 4

=item C<new( %params )>

    my $biz = String::Normal::Type::Business->new;

Creates a Business type. Accepts the following named parameters:

=back

=over 8

=item * C<business_stem>

Path to text file to override default business name stemming.

=item * C<business_stop>

Path to text file to override default business name stop words.

=item * C<business_compress>

Path to text file to override default business name compressions.

=back

=over 4

=item C<transform( $value )>

    my $new_value = $biz->transform( $value );

Transforms a value according to the rules of a Business type.

=back

=head1 AUTHOR

Jeff Anderson, C<< <jeffa at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2024 Jeff Anderson.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
