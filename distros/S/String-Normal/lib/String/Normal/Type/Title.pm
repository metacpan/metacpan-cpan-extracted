package String::Normal::Type::Title;
use strict;
use warnings;
use String::Normal::Type;
use String::Normal::Config;

use Lingua::Stem;
our $STEM;
our $title_stem;
our $title_stop;

sub transform {
    my ($self,$value) = @_;

    $value =~ s/\([^)]*\)/ /g if $value =~ /^[^(]|[^)]$/;

    $value = String::Normal::Type::_scrub_value( $value );

    # tokenize and stem
    my @tokens = ();
    for my $token (split ' ', $value) {
        #$token = defined( $title_stem->{$token} ) ? $title_stem->{$token} : $token;
        push @tokens, $token;
    }

    # Remove all middle stop words that are safe to remove, based on the number of
    # tokens, of course.
    my @filtered = map {
        my $count = $title_stop->{middle}{$_} || '';
        (length $count and @tokens >= $count) ? () : $_;
    } @tokens;

    # stem, but override if Stemmer "blanks out" token
    my @copy = @filtered;
    $STEM->stem_in_place( @copy );
    for my $i (0 .. $#copy) {
        $filtered[$i] = $copy[$i] unless $filtered[$i] =~ /\d/;
    }

    return join ' ', @filtered;
}

sub new {
    my $self = shift;
    $title_stem = String::Normal::Config::TitleStem::_data( @_ );
    $title_stop = String::Normal::Config::TitleStop::_data( @_ );
    $STEM = Lingua::Stem->new;
    $STEM->add_exceptions( $title_stem );
    return bless {@_}, $self;
}


1;

__END__
=head1 NAME

String::Normal::Type::Title;

=head1 DESCRIPTION

This package defines substitutions to be performed on Title types,
such as the titles for movies, film and television shows.

=head1 METHODS

=over 4

=item C<new( %params )>

    my $title = String::Normal::Type::Title->new;

Creates a Title type. Accepts the following named parameters:

=back

=over 8

=item * C<title_stem>

Path to text file to override default title name stemming.

=item * C<title_stop>

Path to text file to override default title name stop words.

=back

=over 4

=item C<transform( $value )>

    my $new_value = $title->transform( $value );

Transforms a value according to the rules of a title type.

=back

=head1 AUTHOR

Jeff Anderson, C<< <jeffa at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jeff Anderson.

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
