#!/usr/bin/env perl
#*
#* Info: Ref types definitions module
#* Author: Pawel Guspiel (neo77) <neo@cpan.org>
#*
#* This module keeps validation functions. You can of course add your modules which uses this and will add additional checks
#* Build in types for Params::Dry
#*
package Params::Dry::Types::Ref;
{
    use strict;
    use warnings;
    use utf8;

# --- version ---
    our $VERSION = 1.20_03;

#=------------------------------------------------------------------------ { use, constants }

    use Params::Dry::Types qw(:const);

#=------------------------------------------------------------------------ { module public functions }

    #=---------
    #  Scalar
    #=---------
    #* scalar type check
    #* RETURN: PASS if test pass otherwise FAIL
    sub Scalar {
        Params::Dry::Types::Ref( $_[0], 'SCALAR' );
    } #+ end of: sub Scalar

    #=--------
    #  Array
    #=--------
    #* array type check
    #* RETURN: PASS if test pass otherwise FAIL
    sub Array {
        Params::Dry::Types::Ref( $_[0], 'ARRAY' );
    } #+ end of: sub Array

    #=-------
    #  Hash
    #=-------
    #* hash type check
    #* RETURN: PASS if test pass otherwise FAIL
    sub Hash {
        Params::Dry::Types::Ref( $_[0], 'HASH' );
    } #+ end of: sub Hash

    #=-------
    #  Code
    #=-------
    #* code type check
    #* RETURN: PASS if test pass otherwise FAIL
    sub Code {
        Params::Dry::Types::Ref( $_[0], 'CODE' );
    } #+ end of: sub Code

    #=-------
    #  Glob
    #=-------
    #* glob type check
    #* RETURN: PASS if test pass otherwise FAIL
    sub Glob {
        Params::Dry::Types::Ref( $_[0], 'GLOB' );
    } #+ end of: sub Glob

    #=-------
    #  Ref
    #=-------
    #* Ref to Ref type check
    #* RETURN: PASS if test pass otherwise FAIL
    sub Ref {
        Params::Dry::Types::Ref( $_[0], 'REF' );
    } #+ end of: sub Ref

    #=---------
    #  LValue
    #=---------
    #* lvalue type check
    #* RETURN: PASS if test pass otherwise FAIL
    sub LValue {
        Params::Dry::Types::Ref( $_[0], 'LVALUE' );
    } #+ end of: sub LValue

    #=---------
    #  Format
    #=---------
    #* format type check
    #* RETURN: PASS if test pass otherwise FAIL
    sub Format {
        Params::Dry::Types::Ref( $_[0], 'FORMAT' );
    } #+ end of: sub Format

    #=----------
    #  VString
    #=----------
    #* glob type check
    #* RETURN: PASS if test pass otherwise FAIL
    sub VString {
        Params::Dry::Types::Ref( $_[0], 'VSTRING' );
    } #+ end of: sub VString

    #=---------
    #  Regexp
    #=---------
    #* glob type check
    #* RETURN: PASS if test pass otherwise FAIL
    sub Regexp {
        Params::Dry::Types::Ref( $_[0], 'Regexp' );
    } #+ end of: sub Regexp

};
0115 && 0x4d;

#+ End of Params::Dry::Types::Ref
__END__
=head1 NAME

Params::Dry::Types::Ref - Build-in ref types for Params::Dry - Simple Global Params Management System which helps you to keep always DRY rule

=head1 VERSION

version 1.20.03

=head1 BUILD IN TYPES

All are are checked by running ref( )

=over 4

=item * B<Ref::Scalar>

=item * B<Ref::Array>

=item * B<Ref::Hash>

=item * B<Ref::Code>

=item * B<Ref::Glob>

=item * B<Ref::Ref>

=item * B<Ref::LValue>

=item * B<Ref::Format>

=item * B<Ref::VString>

=item * B<Ref::Regexp>

=back

=head1 AUTHOR

Pawel Guspiel (neo77), C<< <neo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-params at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Params-Dry>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Params::Dry::Types::Ref
    perldoc Params::Dry::Types
    perldoc Params::Dry
    perldoc ref


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


