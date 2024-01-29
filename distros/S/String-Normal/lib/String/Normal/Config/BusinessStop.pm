package String::Normal::Config::BusinessStop;
use strict;
use warnings;

use String::Normal::Config;

sub _data {
    my %params = @_;

    my $fh;
    if ($params{business_stop}) {
        open $fh, $params{business_stop} or die "Can't read '$params{business_stop}' $!\n";
    } else {
        $fh = *DATA;
    }

    my %stop;
    for (String::Normal::Config::_slurp( $fh )) {
        my ($word,$count) = split ',', $_;
        $count ||= 1;

        if (substr( $word, 0, 1 ) eq '^') {
            substr( $word, 0, 1 ) = '';
            $stop{first}->{$word} = $count;
        } elsif (substr( $word, -1, 1 ) eq '$') {
            substr( $word, -1, 1 ) = '';
            $stop{last}->{$word} = $count;
        } else {
            $stop{middle}->{$word} = $count;
        }
    }

    return \%stop;
}

1;

=head1 NAME

String::Normal::Config::BusinessStop;

=head1 DESCRIPTION

This package defines removals to be performed on Business types.

=head1 STRUCTURE

One entry per line. Each value will be removed. Special characters
C<^> and C<$> are used to anchor the first and last tokens respectively:

  ^mr
  lane$

Only those occurances of C<mr> at the beginning of the token list will be
removed, and only those occurances of <lane> at the end of the token list
will be removed.

You can prepend C<#> to lines that you wish to skip. For example:

    the
    #and

Would remove all occurances of C<the> but not C<and>. Special character
C<,> is used to override removal if the final number of tokens if less
then the digit specified. For example:

    the,2

Would remove all occurances of C<the> in "The Generic Title" but would
not remove any occurances in "The The".

You can provide your own data by creating a text file containing your
values and provide the path to that file via the constructor:

  my $normalizer = String::Normal->new( business_stop => '/path/to/values.txt' );

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
an
and
by
co
cpa
ctr
da
dd
de
dept
dmd
dpm
du
dvm
from
for
grp
in
inc
inst
le
llc
of
pa
pllc
svc
the
to
assn$
assoc$
pc$
unltd$
ltd,3
acctnt$,3 
agci$,3
coop,3
corp$,3
dc
^el
entrprs,3
etc$,3
hq$,3
ind$,3
intl$,3
^mr
