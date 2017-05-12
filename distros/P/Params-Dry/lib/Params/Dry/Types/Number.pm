#!/usr/bin/env perl
#*
#* Info: Number types definitions module
#* Author: Pawel Guspiel (neo77) <neo@cpan.org>
#*
#* This module keeps validation functions. You can of course add your modules which uses this and will add additional checks
#* Build in types for Params::Dry
#*
package Params::Dry::Types::Number;
{
    use strict;
    use warnings;
    use utf8;

# --- version ---
    our $VERSION = 1.20_03;

#=------------------------------------------------------------------------ { use, constants }

    use Params::Dry::Types qw(:const);

#=------------------------------------------------------------------------ { module public functions }

    #=------
    #  Int
    #=------
    #* int type check Int[3] - no more than 999
    #* RETURN: PASS if test pass otherwise FAIL
    sub Int {
        ( ref( $_[0] ) or $_[0] !~ /^[+\-]?(\d+)$/ ) and return FAIL;
        $_[1] and $1 and length $1 > $_[1] and return FAIL;
        PASS;
    } #+ end of: sub Int

    #=--------
    #  Float
    #=--------
    #* float type check
    #* RETURN: PASS if test pass otherwise FAIL
    sub Float {
        ( ref( $_[0] ) or $_[0] !~ /^[+\-]?(\d+(\.\d+)?)$/ ) and return FAIL;
        $_[1] and $1 and length $1 > $_[1] and return FAIL;
        $_[2] and $2 and length $2 > $_[2] + 1 and return FAIL;
        PASS;
    } #+ end of: sub Float

    #=-------
    #  Bool
    #=-------
    #* Bool type check
    #* RETURN: PASS if test pass otherwise FAIL
    sub Bool {
        return PASS if !ref( $_[0] ) and ( "$_[0]" eq '0' or "$_[0]" eq 1 );
        FAIL;
    } #+ end of: sub Bool

};
0115 && 0x4d;

#+ End of Params::Dry::Types::Number
__END__
=head1 NAME

Params::Dry::Types::Number - Build-in numeric types for Params::Dry - Simple Global Params Management System which helps you to keep always DRY rule

=head1 VERSION

version 1.20.03

=head1 BUILD IN TYPES

=over 4

=item * B<Number::Int> - can be used with parameters (like: Number::Int[3]) which mean max 3 chars int not counting signs

=item * B<Number::Float> - number with decimal part, full length is counted with dot separator, but decimal part not, so you can use it with parameters Number::Float[5,2] which will mean max 5 chars with two decimal point digits (12.42 - ok, 145.44 - wrong, 13.333 - wrong)

=item * B<Number::Bool> - boolean value (can be 0 or 1)

=back

=head1 AUTHOR

Pawel Guspiel (neo77), C<< <neo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-params at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Params-Dry>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Params::Dry::Number
    perldoc Params::Dry::Types
    perldoc Params::Dry


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Params-Dry>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Params-Dry>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Params-Dry>

=item * Search CPAN

L<http://search.cpan.org/dist/Params-Dry/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Pawel Guspiel (neo77).

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


