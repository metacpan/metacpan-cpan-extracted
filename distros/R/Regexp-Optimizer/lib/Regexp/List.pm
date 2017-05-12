package Regexp::List;

use 5.008001;
use strict;
use warnings FATAL => 'all';
use Regexp::Assemble;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.20 $ =~ /(\d+)/g;

sub new {
    bless \my $dummy, shift;
};

sub list2re {
    my $self = shift;
    Regexp::Assemble->new->add(@_)->re;
};

1; # End of Regexp::List

__END__

=head1 NAME

Regexp::List - Assemble multiple Regular Expressions into a single RE

=head1 VERSION

$Id: List.pm,v 0.20 2013/02/23 13:43:59 dankogai Exp $

=head1 DEPRECATED

use L<Regexp::Assemble> instead.

=head1 SYNOPSIS

  use Regexp::List;
  my $rl = Regexp::List->new();
  my @list = ( 'ab+c', 'ab+-',  'a\w\d+', 'a\d+' );
  print $rl->list2re(@list);
  # Regexp::Asssemble->new->add(@list);

=head1 DESCRIPTION

This module exists just for the sake of compatibility w/ version 0.16
and below.

=over 2

=item new

Just a stub.

=item list2re

Simply does:

  Regexp::Asssemble->new->add(@list);

=back

=head1 SEE ALSO

L<Regexp::Optimizer>, L<Regexp::Assemble>

=head1 AUTHOR

Dan Kogai, C<< <dankogai+cpan at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-regexp-optimizer at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Regexp-Optimizer>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Regexp::Optimizer


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Regexp-Optimizer>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Regexp-Optimizer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Regexp-Optimizer>

=item * Search CPAN

L<http://search.cpan.org/dist/Regexp-Optimizer/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Dan Kogai.

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
