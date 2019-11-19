=head1 PURPOSE

Check that basic usage of MooX::late works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2014, 2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

{
	package Local::Role;
	use Moo::Role;
	use MooX::late;
	has foo => (is => 'ro', isa => 'Str', default => 'foo');
}

{
	package Local::Class;
	use Moo;
	use MooX::late;
	with 'Local::Role';
	has bar => (is => 'ro', isa => 'Str', default => 'bar');
}

my $o1 = Local::Class->new;
is($o1->foo, 'foo');
is($o1->bar, 'bar');

my $o2 = Local::Class->new(foo => 'bar', bar => 'foo');
is($o2->foo, 'bar');
is($o2->bar, 'foo');

ok not eval {
	Local::Class->new(foo => []);
};

ok not eval {
	Local::Class->new(bar => []);
};

{
	package Local::Other;
	use Moo;
	use MooX::late;
	has foo => (is => 'ro', lazy_build => 1);
	sub _build_foo { 'foo' };
}

my $o = Local::Other->new;
ok( not $o->has_foo );
is( $o->foo, 'foo' );
ok( $o->has_foo );
$o->clear_foo;
ok( not $o->has_foo );

done_testing;
