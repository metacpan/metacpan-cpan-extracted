=pod

=encoding utf-8

=head1 PURPOSE

Test delegation on non-enumerated attributes.

=head1 SEE ALSO

L<https://github.com/tobyink/p5-moox-enumeration/issues/1>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use 5.008001;
use strict;
use warnings;
use Test::More tests => 4;
use Test::Fatal;

my $started = 0;

{
	package Local::Engine;
	use Moo;
	sub start { ++$started }
};

{
	package Local::Car;
	use Moo;
	use MooX::Enumeration;
	has engine => (
		is       => 'lazy',
		builder  => sub { Local::Engine->new },
		handles  => { start_engine => 'start' },
	);
	has size => (
		is       => 'ro',
		required => 1,
		enum     => [qw( small medium large )],
		handles  => 1,
	);
}

my $car = Local::Car->new(size => 'medium');

ok( !$car->is_small  );
ok(  $car->is_medium );
ok( !$car->is_large  );

$car->start_engine;

is($started, 1);

