=head1 PURPOSE

Custom quote-like operators (callback subs).

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use utf8;
use Test::More;

use PerlX::QuoteOperator::Inescapable
	PASS => sub ($) { is($_[0], q(Hello\\\\World)) };

PASS!Hello\\World!;
PASS/Hello\\World/;
PASS~Hello\\World~;
PASS(Hello\\World);
PASS<Hello\\World>;
PASS[Hello\\World];
PASS{Hello\\World};

PASS !Hello\\World!;
PASS /Hello\\World/;
PASS ~Hello\\World~;
PASS (Hello\\World);
PASS <Hello\\World>;
PASS [Hello\\World];
PASS {Hello\\World};

PASS XHello\\WorldX;

done_testing;
