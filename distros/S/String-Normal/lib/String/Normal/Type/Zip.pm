package String::Normal::Type::Zip;
use strict;
use warnings;


sub transform {
    my ($self,$value) = @_;

    # US 5 or 9 digit zip codes
    if ( $value =~ /^(\d{5})(?:[\-|\||\.|_|\s]*\d{4})?$/ ) {
        # trim zip9 down to 5 for now
        # TODO: add separate field for zip9 ( see revision 94419 for original code)
        return $1;
    }
    elsif ($value =~ /^(apo|fpo)[\-|\||\.|_|\s]*aa[\-|\||\.|_|\s]*(\d{5})$/) {
        return $2;
    }
    # Canada
    elsif ( $value =~ /^([a-z]\d[a-z])(\s|-|\||\.|_)*(\d[a-z]\d)$/ ) {
        $value = join '',$1,$3;
        return $value;
    }
    else {
        die "Invalid zip code";
    }
}

sub new {
    my $self = shift;
    return bless {@_}, $self;
}

1;

__END__
=head1 NAME

String::Normal::Type::Zip;

=head1 DESCRIPTION

This package defines substitutions to be performed on Zip types.

=head1 METHODS

=over 4

=item C<new( %params )>

    my $zip = String::Normal::Type::Zip->new;

Creates a Zip type.

=item C<transform( $value )>

    my $new_value = $zip->transform( $value );

Transforms a value according to the rules of a Zip type.

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
