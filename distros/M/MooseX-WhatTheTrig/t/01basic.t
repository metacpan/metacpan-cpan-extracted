=pod

=encoding utf-8

=head1 PURPOSE

Test that MooseX::WhatTheTrig compiles and works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More 0.96;
use Test::Moose;

require_ok('MooseX::WhatTheTrig');

my @arr;
my $push = sub
{
	no warnings qw(uninitialized);
	
	my $self = shift;
	my $meta = Moose::Util::find_meta($self);
	push @arr, sprintf("%s %s", $meta->triggered_attribute, "@_");
};

BEGIN {
	package Local::TestRole;
	use Moose::Role;
	use MooseX::WhatTheTrig;
	has baz => (
		traits  => [ WhatTheTrig ],
		is      => 'rw',
		trigger => sub {
			my $self = shift;
			$self->$push(@_);
		},
	);
}

BEGIN {
	package Local::TestClass;
	use Moose;
	use MooseX::WhatTheTrig;
	with qw( Local::TestRole );
	has foo => (
		traits  => [ WhatTheTrig ],
		is      => 'rw',
		trigger => sub {
			my $self = shift;
			$self->$push(@_);
			$self->bar($_[1]);
			$self->$push(@_);
		},
	);
	has bar => (
		traits  => [ WhatTheTrig ],
		is      => 'rw',
		trigger => sub {
			my $self = shift;
			$self->$push(@_);
		},
	);
}

with_immutable {
	@arr = ();
	my $imm = $_[0] ? 'immutable' : 'mutable';
	my $obj = 'Local::TestClass'->new;
	$obj->foo(1);
	$obj->bar(2);
	$obj->baz(3);
	is_deeply(
		\@arr,
		['foo 1', 'bar ', 'foo 1', 'bar 2 ', 'baz 3'],
		"Local::TestClass works ($imm)",
	) or diag explain \@arr;
} qw( Local::TestClass2 );

BEGIN {
	package Local::TestClass2;
	use Moose;
	with qw( Local::TestRole );
}

with_immutable {
	@arr = ();
	my $imm = $_[0] ? 'immutable' : 'mutable';
	my $obj = 'Local::TestClass2'->new(baz => 42);
	$obj->baz(999);
	is_deeply(
		\@arr,
		['baz 42', 'baz 999 42'],
		"Local::TestClass2 works ($imm)",
	) or diag explain \@arr;
} qw( Local::TestClass2 );


BEGIN {
	package Local::TestClass3;
	use Moose;
	extends qw( Local::TestClass2 );
}

with_immutable {
	@arr = ();
	my $imm = $_[0] ? 'immutable' : 'mutable';
	my $obj = 'Local::TestClass3'->new(baz => 42);
	$obj->baz(999);
	is_deeply(
		\@arr,
		['baz 42', 'baz 999 42'],
		"Local::TestClass3 works ($imm)",
	) or diag explain \@arr;
} qw( Local::TestClass3 );

done_testing;
