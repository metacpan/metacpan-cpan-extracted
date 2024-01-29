package String::Normal::Config::TitleStem;
use strict;
use warnings;

use String::Normal::Config;

sub _data {
    my %params = @_;

    my $fh;
    if ($params{title_stem}) {
        open $fh, $params{title_stem} or die "Can't read '$params{title_stem}' $!\n";
    } else {
        $fh = *DATA;
    }

    my %stem = String::Normal::Config::_slurp( $fh );
    return \%stem;
}

1;

=head1 NAME

String::Normal::Config::TitleStem;

=head1 DESCRIPTION

This package defines substitutions to be performed on Title types.

=head1 STRUCTURE

One entry pair per line: first the value to be matched then the value
to be changed to. For example:

  foo fu

Would change all occurances of C<foo> to C<fu>. See C<__DATA__> block below.

You can provide your own data by creating a text file containing your
values and provide the path to that file via the constructor:

  my $normalizer = String::Normal->new( title_stem => '/path/to/values.txt' );

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

__DATA__
ii 2
iii 3
iv 4
v 5
vi 6
vii 7
viii 8
ix 9
tenth 10th
eleventh 11th
twelfth 12th
thirteenth 13th
fourteenth 14th
fifteenth 15th
sixteenth 16th
seventeenth 17th
eighteenth 18th
nineteenth 19th
first 1st
twentieth 20th
second 2nd
thirtieth 30th
third 3rd
fortieth 40th
fourth 4th
fiftieth 50th
fifth 5th
sixtieth 60th
sixth 6th
seventh 7th
eighth 8th
ninth 9th
