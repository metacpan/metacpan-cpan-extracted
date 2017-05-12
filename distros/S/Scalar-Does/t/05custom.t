=head1 PURPOSE

Make sure Scalar::Does can export custom role checkers, and that they work OK.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More tests => 5;

use Scalar::Does
	custom => { -role => 'ARRAY', -as => 'does_array' },
	custom => { -role => 'HASH',  -as => 'does_hash'  };

ok  does_array( +[] );
ok !does_array( +{} );
ok !does_hash(  +[] );
ok  does_hash(  +{} );

ok not eval q{
	use Scalar::Does custom => { -as => 'foo' }
};
