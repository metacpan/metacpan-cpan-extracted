=pod

=head1 PURPOSE

Speed comparison between
MooseX::Declare,
Moops+Moo,
Moops+Moose,
MooX::Pression+Moo,
MooX::Pression+Moose.

             Rate       MXD Moops_Moo   MXP_Moo       MXP     Moops
 MXD        101/s        --      -97%      -98%      -98%      -98%
 Moops_Moo 3257/s     3128%        --      -25%      -30%      -46%
 MXP_Moo   4349/s     4210%       34%        --       -7%      -28%
 MXP       4674/s     4532%       43%        7%        --      -22%
 Moops     6023/s     5869%       85%       39%       29%        --

For Moose classes, Moops is the fastest, followed by MooseX::Pression,
with MooseX::Declare trailing a long was behind.

For Moo classes, MooX::Pression beats Moops.

With the exception of MooseX::Declare, Moose-based classes are usually
faster at runtime than Moo-based classes. Compile time isn't measured
in this benchmark, but it's likely that Moo-based classes will compile
faster.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013, 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Benchmark ':all';
use Test::More;
use Test::Fatal;
use IO::Callback;

{
	use Moops;
	class Foo::Moops using Moose {
		has n => (is => 'ro', writer => '_set_n', isa => Int, default => 0);
		method add (Int $x) {
			$self->_set_n( $self->n + $x );
		}
	}
	class Foo::Moops_Moo using Moo {
		has n => (is => 'ro', writer => '_set_n', isa => Int, default => 0);
		method add (Int $x) {
			$self->_set_n( $self->n + $x );
		}
	}
}

{
	use MooseX::Declare;
	class Foo::MXD {
		has n => (is => 'ro', writer => '_set_n', isa => 'Int', default => 0);
		method add (Int $x) {
			$self->_set_n( $self->n + $x );
		}
	}
}

{
	use MooX::Pression;
	class ::Foo::MXP {
		toolkit Moose;
		has n (is => rwp, type => Int, default => 0);
		method add :optimize (Int $x) {
			$self->_set_n( $self->n + $x );
		}
	}
	class ::Foo::MXP_Moo {
		toolkit Moo;
		has n (is => rwp, type => Int, default => 0);
		method add :optimize (Int $x) {
			$self->_set_n( $self->n + $x );
		}
	}
}
# Test each class works as expected
#
for my $class ('Foo::Moops', 'Foo::Moops_Moo', 'Foo::MXD', 'Foo::MXP', 'Foo::MXP_Moo') {
	
	like(
		exception { $class->new(n => 1.1) },
		qr{(Validation failed for 'Int')|(did not pass type constraint "Int")},
		"Class '$class' throws error on incorrect constructor call",
	);
	
	my $o = $class->new(n => 0);
	like(
		exception { $o->add(1.1) },
		qr{(^Validation failed)|(did not pass type constraint "Int")},
		"Objects of class '$class' throw error on incorrect method call",
	);
	
	$o->add(40);
	$o->add(2);
	is($o->n, 42, "Objects of class '$class' function correctly");
	
}

# Ensure benchmarks run with TAP-friendly output.
#
my $was = select(
	'IO::Callback'->new('>', sub {
		my $data = shift;
		$data =~ s/^/# /g;
		print STDOUT $data;
	})
);

# Actually run benchmarks.
cmpthese(-1, {
	Moops => q{
		my $sum = 'Foo::Moops'->new(n => 0);
		$sum->add($_) for 0..100;
	},
	Moops_Moo => q{
		my $sum = 'Foo::Moops_Moo'->new(n => 0);
		$sum->add($_) for 0..100;
	},
	MXD => q{
		my $sum = 'Foo::MXD'->new(n => 0);
		$sum->add($_) for 0..100;
	},
	MXP => q{
		my $sum = 'Foo::MXP'->new(n => 0);
		$sum->add($_) for 0..100;
	},
	MXP_Moo => q{
		my $sum = 'Foo::MXP_Moo'->new(n => 0);
		$sum->add($_) for 0..100;
	},
});

select($was);

done_testing;

__END__
ok 1 - Class 'Foo::Moops' throws error on incorrect constructor call
ok 2 - Objects of class 'Foo::Moops' throw error on incorrect method call
ok 3 - Objects of class 'Foo::Moops' function correctly
ok 4 - Class 'Foo::MXD' throws error on incorrect constructor call
ok 5 - Objects of class 'Foo::MXD' throw error on incorrect method call
ok 6 - Objects of class 'Foo::MXD' function correctly
ok 7 - Class 'Foo::MXP' throws error on incorrect constructor call
ok 8 - Objects of class 'Foo::MXP' throw error on incorrect method call
ok 9 - Objects of class 'Foo::MXP' function correctly
#          Rate   MXD   MXP Moops
# MXD   100.0/s    --  -98%  -98%
# MXP    4830/s 4730%    --  -19%
# Moops  5966/s 5866%   24%    --
1..9

