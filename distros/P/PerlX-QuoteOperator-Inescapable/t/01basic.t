=head1 PURPOSE

Compare various incantations of C<< Q() >> with equivalent uses of
C<< q() >>

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

use PerlX::QuoteOperator::Inescapable;

is Q!Hello\\World!, q!Hello\\\\World!, q(Q!!);
is Q/Hello\\World/, q/Hello\\\\World/, q(Q//);
is Q~Hello\\World~, q~Hello\\\\World~, q(Q~~);
is Q(Hello\\World), q(Hello\\\\World), q(Q());
is Q<Hello\\World>, q<Hello\\\\World>, q(Q<>);
is Q[Hello\\World], q[Hello\\\\World], q(Q{});
is Q{Hello\\World}, q{Hello\\\\World}, q(Q{});

is Q !Hello\\World!, q !Hello\\\\World!, q(Q !!);
is Q /Hello\\World/, q /Hello\\\\World/, q(Q //);
is Q ~Hello\\World~, q ~Hello\\\\World~, q(Q ~~);
is Q (Hello\\World), q (Hello\\\\World), q(Q ());
is Q <Hello\\World>, q <Hello\\\\World>, q(Q <>);
is Q [Hello\\World], q [Hello\\\\World], q(Q []);
is Q {Hello\\World}, q {Hello\\\\World}, q(Q {});
is Q XHello\\WorldX, q XHello\\\\WorldX, q(Q XX);

is Q(Hello¡World), q(Hello¡World), q(Q() with utf8);
is Q (Hello¡World), q (Hello¡World), q(Q () with utf8);

my $x = "xyz";
is Q($x), q($x), "Q() does not interpolate variables";

done_testing;
