=head1 PURPOSE

Check Scalar::Does loads.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More tests => 1;

BEGIN { use_ok('Scalar::Does') };

my $policy_is_to_do_these_in_xt = q{
use Test::Pod;
use Test::Pod::Coverage;
};
