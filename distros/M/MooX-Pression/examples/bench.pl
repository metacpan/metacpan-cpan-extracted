=pod

=head1 PURPOSE

Speed comparison between
MooseX::Declare,
Moops,
MooX::Pression, and
Dios.

 # ============================================================
 # Moose implementations
 # ============================================================
 #               Rate         MXD   Prs_Moose Moops_Moose
 # MXD          101/s          --        -98%        -98%
 # Prs_Moose   4715/s       4573%          --        -21%
 # Moops_Moose 5966/s       5813%         27%          --
 # 
 # ============================================================
 # Moo implementations
 # ============================================================
 #             Rate Moops_Moo   Prs_Moo
 # Moops_Moo 3349/s        --      -23%
 # Prs_Moo   4325/s       29%        --
 # 
 # ============================================================
 # Mouse implementations
 # ============================================================
 #               Rate   Prs_Mouse Moops_Mouse
 # Prs_Mouse   6053/s          --        -34%
 # Moops_Mouse 9221/s         52%          --
 # 
 # ============================================================
 # All implementations
 # ============================================================
 #               Rate    Dios   MXD Moops_Moo Prs_Moo Prs_Moose Moops_Moose Prs_Mouse Moops_Mouse
 # Dios        2.36/s      --  -98%     -100%   -100%     -100%       -100%     -100%       -100%
 # MXD          101/s   4181%    --      -97%    -97%      -98%        -98%      -98%        -99%
 # Moops_Moo   3381/s 143357% 3251%        --     -2%      -19%        -43%      -45%        -58%
 # Prs_Moo     3442/s 145920% 3311%        2%      --      -18%        -42%      -44%        -57%
 # Prs_Moose   4199/s 178067% 4062%       24%     22%        --        -29%      -31%        -48%
 # Moops_Moose 5910/s 250665% 5758%       75%     72%       41%          --       -3%        -26%
 # Prs_Mouse   6108/s 259061% 5954%       81%     77%       45%          3%        --        -24%
 # Moops_Mouse 8011/s 339815% 7840%      137%    133%       91%         36%       31%          --

For Moose classes, Moops is the fastest, followed by MooseX::Pression,
with MooseX::Declare trailing a long was behind.

For Moo classes, MooX::Pression beats Moops.

For Mouse classes, Moops beats MooX::Pression.

Overall, Mouse beats Moose beats Moo.

All of the above are faster than Dios.

Compile time isn't measured in this benchmark, but it's likely that Moo-based
classes will compile faster. Moops compiles a lot faster than MooseX::Declare,
MooX::Pression, and Dios.

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
	class Foo::Moops_Moose using Moose {
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
	class Foo::Moops_Mouse using Mouse {
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
	use Dios;
	class Foo::Dios {
		has Int $.n is rw //= 0;
		method add (Int $x) {
			$self->set_n( $self->get_n + $x );
		}
		method n () {
			$self->get_n;
		}
	}
}

{
	use MooX::Pression;
	class ::Foo::Prs_Moose {
		toolkit Moose;
		has n (is => rwp, type => Int, default => 0);
		method add :optimize (Int $x) {
			$self->_set_n( $self->n + $x );
		}
	}
	class ::Foo::Prs_Mouse {
		toolkit Mouse;
		has n (is => rwp, type => Int, default => 0);
		method add :optimize (Int $x) {
			$self->_set_n( $self->n + $x );
		}
	}
	class ::Foo::Prs_Moo {
		toolkit Moo;
		has n (is => rwp, type => Int, default => 0);
		method add :optimize (Int $x) {
			$self->_set_n( $self->n + $x );
		}
	}
}

my @impl = qw(
	Moops_Moose  Moops_Mouse  Moops_Moo
	Prs_Moose    Prs_Mouse    Prs_Moo
	MXD
	Dios
);

# Test each class works as expected
#
for my $impl (@impl) {
	my $class = "Foo::$impl";
	like(
		exception { $class->new(n => 1.1) },
		qr{(Validation failed for 'Int')|(did not pass type constraint "Int")|(is not of type Int)},
		"Class '$class' throws error on incorrect constructor call",
	);
	my $o = $class->new(n => 0);
	like(
		exception { $o->add(1.1) },
		qr{(^Validation failed)|(did not pass type constraint "Int")|(is not of type Int)},
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

# Prepare tests to benchmark.
#
my %speed_test = (map {
	my $class = "Foo::$_";
	$_ => sprintf(q{
		my $sum = q[%s]->new(n => 0);
		$sum->add($_) for 0..100;
	}, $class),
} @impl);

print "=" x 60, "\n";
print "Moose implementations\n";
print "=" x 60, "\n";
cmpthese(-1, { map { $_ => $speed_test{$_} } qw/ Moops_Moose Prs_Moose MXD / });
print "\n";

print "=" x 60, "\n";
print "Moo implementations\n";
print "=" x 60, "\n";
cmpthese(-1, { map { $_ => $speed_test{$_} } qw/ Moops_Moo Prs_Moo / });
print "\n";

print "=" x 60, "\n";
print "Mouse implementations\n";
print "=" x 60, "\n";
cmpthese(-1, { map { $_ => $speed_test{$_} } qw/ Moops_Mouse Prs_Mouse / });
print "\n";

print "=" x 60, "\n";
print "All implementations\n";
print "=" x 60, "\n";
cmpthese(-1, \%speed_test);
print "\n";

#use Data::Dumper;
#$Data::Dumper::Deparse = 1;
#print Dumper ({ map {
#	$_ => $_->can('add')
#} qw/ Foo::MXP Foo::Moops / });

select($was);

done_testing;
