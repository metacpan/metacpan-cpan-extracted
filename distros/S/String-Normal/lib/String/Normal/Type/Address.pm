package String::Normal::Type::Address;
use strict;
use warnings;
use String::Normal::Type;
use String::Normal::Config;

our $address_stem;
our $address_stop;

sub transform {
    my ($self,$value) = @_;

    $value =~ s/\([^)]*\)/ /g if $value =~ /^[^(]|[^)]$/;

    $value = String::Normal::Type::_scrub_value( $value );

    # tokenize and stem
    my @tokens = ();
    for my $token (split ' ', $value) {
        $token = defined( $address_stem->{$token} ) ? $address_stem->{$token} : $token;
        # TODO: this form of stop wording will need to be further addressed
        if (@tokens > 2) {
            last if $token eq 'apt' or $token eq 'ste';
        }
        push @tokens, $token;
    }

    # remove all middle stop words
    my @filtered = map {
        my $count = $address_stop->{middle}{$_} || '';
        (length $count and @tokens >= $count) ? () : $_;
    } @tokens;

    # revert if we filtered words down to less than 2 tokens
    @filtered = @tokens if @filtered < 2;

    return join ' ', @filtered;
}

sub new {
    my $self = shift;
    $address_stem = String::Normal::Config::AddressStem::_data( @_ );
    $address_stop = String::Normal::Config::AddressStop::_data( @_ );
    return bless {@_}, $self;
}

1;

=head1 NAME

String::Normal::Type::Address;

=head1 DESCRIPTION

This package defines substitutions to be performed on Address types.

=head1 METHODS

=over 4

=item C<new( %params )>

    my $address = String::Normal::Type::Address->new;

Creates an Address type. Accepts the following named parameters:

=back

=over 8

=item * C<address_stem>

Path to text file to override default address stemming.

=item * C<address_stop>

Path to text file to override default address stop words.

=back

=over 4

=item C<transform( $value )>

    my $new_value = $address->transform( $value );

Transforms a value according to the rules of a Address type.

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
