package PERLCORE::Predicates::IsEven;

use 5.006;
use strict;
use warnings;

use parent 'Exporter';

our $VERSION = '0.01';

our @EXPORT_OK = qw(isEven);

sub isEven { $_[0] % 2 == 0; }

1;

__END__

=head1 NAME

PERLCORE::Predicates::IsEven - An implementation of JS is-even

=head1 SYNOPSIS

    use PERLCORE::Predicates::IsEven qw(IsEven);
    isEven(0);
    //=> true
    isEven('1');
    //=> false
    isEven(2);
    //=> true
    isEven('3');
    //=> false

=head1 DESCRIPTION

This is the long-awaited CORE-ish function for PERL that brings all of the
power of B<Is-Even> to perl.

L<https://www.npmjs.com/package/is-even>

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 IsEven

This function returns true for EVEN numbers. For all others numbers it returns false.

=head1 AUTHOR

yours truely,

Evan Carroll, C<< <me at evancarroll.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-perlcore-predicates-iseven at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PERLCORE-Predicates-IsEven>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PERLCORE::Predicates::IsEven


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PERLCORE-Predicates-IsEven>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PERLCORE-Predicates-IsEven>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PERLCORE-Predicates-IsEven>

=item * Search CPAN

L<http://search.cpan.org/dist/PERLCORE-Predicates-IsEven/>

=back


=head1 ACKNOWLEDGEMENTS

=over 4

=item jonschlinkert

For his most valuable contribution to NPM.
L<https://www.npmjs.com/search?q=is-even>

=item /u/username223

For his snarky reference to is-even as a reason that perl is better.
L<https://www.reddit.com/r/perl/comments/8e2z6f/my_passion_is_for_perl_5_programming_language/dxs50qs/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Evan Carroll.

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
