=head1 PURPOSE

Check that Scalar::Does doesn't issue any unexpected warnings, even under
C<< $^W >>.

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=80121>.

=head1 THANKS

Laurent Dami initially reported this issue and gave a good demonstration
of it.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Requires "List::MoreUtils";

BEGIN {
	plan skip_all => 'pure Perl List::MoreUtils generates warning under -w'
		unless List::MoreUtils::_XScompiled();
	plan tests => 1;
};

use Test::NoWarnings;

$^W = 1;
require Scalar::Does;
Scalar::Does::does(undef, 'ARRAY');

