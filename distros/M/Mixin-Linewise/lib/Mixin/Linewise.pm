use strict;
use warnings;
package Mixin::Linewise 0.110;
# ABSTRACT: write your linewise code for handles; this does the rest

use 5.006;
use Carp ();
Carp::confess "not meant to be loaded";

#pod =head1 DESCRIPTION
#pod
#pod It's boring to deal with opening files for IO, converting strings to
#pod handle-like objects, and all that.  With L<Mixin::Linewise::Readers> and
#pod L<Mixin::Linewise::Writers>, you can just write a method to handle handles, and
#pod methods for handling strings and filenames are added for you.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mixin::Linewise - write your linewise code for handles; this does the rest

=head1 VERSION

version 0.110

=head1 DESCRIPTION

It's boring to deal with opening files for IO, converting strings to
handle-like objects, and all that.  With L<Mixin::Linewise::Readers> and
L<Mixin::Linewise::Writers>, you can just write a method to handle handles, and
methods for handling strings and filenames are added for you.

=head1 PERL VERSION SUPPORT

This module has the same support period as perl itself:  it supports the two
most recent versions of perl.  (That is, if the most recently released version
is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords David Golden Steinbrunner Graham Knop L. Alberto Giménez

=over 4

=item *

David Golden <dagolden@cpan.org>

=item *

David Steinbrunner <dsteinbrunner@pobox.com>

=item *

Graham Knop <haarg@haarg.org>

=item *

L. Alberto Giménez <agimenez@sysvalve.es>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
