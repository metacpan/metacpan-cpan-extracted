=pod

=encoding utf-8

=head1 PURPOSE

Test that Sub::SymMethod works.

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

my @R;

use Zydeco::Lite;

my $app = app sub {
	
	class 'Parent' => sub {
		symmethod 'foo' => sub {
			push @R, 'Local::Parent';
		};
	};
	
	class 'Child' => sub {
		extends 'Parent';
		with 'Role2';
		
		symmethod 'foo' => ( order => -10 ) => sub {
			push @R, 'Local::Child//a';
		};
		
		symmethod 'foo' => sub {
			push @R, 'Local::Child//b';
		};
	};
	
	class 'Grandchild' => sub {
		extends 'Child';
		
		symmethod 'foo' => sub {
			push @R, 'Local::Grandchild';
		};
	};
	
	role 'Role1' => sub {
		symmethod 'foo' => sub {
			push @R, 'Local::Role1';
		};
	};
	
	role 'Role1B' => sub {
		with 'Role1';
	};
	
	role 'Role2' => sub {
		with 'Role1B';
		
		symmethod 'foo' => sub {
			push @R, 'Local::Role2//a';
		};
		
		symmethod 'foo'
		=> [ 'n' => 'Int' ]
		=> ( named => true )
		=> sub {
			my ($self, $arg) = @_;
			push @R, 'Local::Role2//b//' . $arg->n;
		};
	};
};

is $app->new_grandchild->foo( n => 42 ), 7;

is_deeply(
	\@R,
	[qw{
		Local::Child//a
		Local::Parent
		Local::Role2//a
		Local::Role2//b//42
		Local::Role1
		Local::Child//b
		Local::Grandchild
	}]
) or diag explain \@R;

@R = ();

is $app->new_grandchild->foo( n => [] ), 6;

is_deeply(
	\@R,
	[qw{
		Local::Child//a
		Local::Parent
		Local::Role2//a
		Local::Role1
		Local::Child//b
		Local::Grandchild
	}]
) or diag explain \@R;

@R = ();

is 'Sub::SymMethod'->dispatch(ref($app->new_grandchild) => foo => ( n => 42 )), 7;

is_deeply(
	\@R,
	[qw{
		Local::Child//a
		Local::Parent
		Local::Role2//a
		Local::Role2//b//42
		Local::Role1
		Local::Child//b
		Local::Grandchild
	}]
) or diag explain \@R;

@R = ();

done_testing;
