=pod

=encoding utf-8

=head1 PURPOSE

Test that Object::Adhoc works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

use Object::Adhoc;

my $o1 = object { name => 'Alice' };
my $o2 = object { name => 'Bob' };

ok($o1->has_name);
is($o1->name, 'Alice');

is(ref($o1), ref($o2));

my $o3 = object { name => 'Carol' }, [qw/ name age /];

isnt(ref($o1), ref($o3));

is($o3->age, undef);

ok(!$o3->has_age);

done_testing;
