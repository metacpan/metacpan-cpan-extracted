=head1 PURPOSE

Check that Scalar::Does exports C<make_role> and C<where>, and that these can
be used to make custom roles which work.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More tests => 11;

use Scalar::Does does => -make;

my $positive = make_role 'Positive Integer', where { no warnings 'numeric'; $_[0] > 0 };

can_ok $positive => 'check';
is("$positive", "Positive Integer");

ok does($positive->name, q[""]);
ok does($positive->code, q[&{}]);

ok does("1", $positive);
ok does("1hello", $positive);
ok !does("-1", $positive);
ok !does("", $positive);

ok not eval {
	make_role();
};

my $name = make_role qr{^Toby$}i;
ok does("TOBY", $name);
ok !does("TOBIAS", $name);
