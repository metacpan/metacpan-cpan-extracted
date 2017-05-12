use 5.008;
use strict;
use warnings;

package Types::Set;

BEGIN {
	$Types::Set::AUTHORITY = 'cpan:TOBYINK';
	$Types::Set::VERSION   = '0.003';
}

use Set::Equivalence ();
use Type::Tiny 0.014;
use Type::Library -base, -declare => qw(Set AnySet MutableSet ImmutableSet);
use Types::Standard qw(ArrayRef InstanceOf HasMethods);
use Type::Utils -all;

declare Set,
	as InstanceOf['Set::Equivalence'],
	_params(Set);

declare AnySet,
	as HasMethods[qw( insert delete members contains )];

declare MutableSet,
	as Set,
	where { $_->is_mutable },
	inline_as { ( undef, "$_\->is_mutable" ) },
	_params(MutableSet);

declare ImmutableSet,
	as Set,
	where { $_->is_immutable },
	inline_as { ( undef, "$_\->is_immutable" ) },
	_params(ImmutableSet);

coerce Set,
	from ArrayRef, q{ 'Set::Equivalence'->new(members => $_) },
	from AnySet,   q{ 'Set::Equivalence'->new(members => [$_->members]) },
	;

coerce AnySet,
	from ArrayRef, q{ 'Set::Equivalence'->new(members => $_) },
	;

coerce MutableSet,
	from ImmutableSet, q{ $_->clone },
	from ArrayRef,     q{ 'Set::Equivalence'->new(members => $_) },
	from AnySet,       q{ 'Set::Equivalence'->new(members => [$_->members]) },
	;

coerce ImmutableSet,
	from MutableSet, q{ $_->clone->make_immutable },
	from ArrayRef,   q{ 'Set::Equivalence'->new(mutable => !!0, members => $_) },
	from AnySet,     q{ 'Set::Equivalence'->new(mutable => !!0, members => [$_->members]) },
	;

# Crazy stuff for parameterization...
sub _params
{
	my $basetype = shift;
	
	return(
		constraint_generator => sub {
			my $parameter = Types::TypeTiny::TypeTiny->(shift);
			return sub {
				my $tc = $_->type_constraint;
				Scalar::Util::blessed($tc) and $tc->can('is_a_type_of') and $tc->is_a_type_of($parameter);
			};
		},
		inline_generator => sub {
			our %REFADDR;
			my $parameter = Types::TypeTiny::TypeTiny->(shift);
			my $refaddr   = Scalar::Util::refaddr($parameter);
			$REFADDR{$refaddr} = $parameter;
			return sub {
				return (
					undef,
					"do { my \$tc = $_\->type_constraint; Scalar::Util::blessed(\$tc) and \$tc->can('is_a_type_of') and \$tc->is_a_type_of(\$Types::Set::REFADDR{$refaddr}) }",
				);
			};
		},
		coercion_generator => sub {
			my ($parent, $child, $parameter) = @_;
			my $coercions = 'Type::Coercion'->new( type_constraint => $child );
			my $immute = ($parent->name =~ /^Immutable/);
			
			if ($parameter->has_coercion) {
				$coercions->add_type_coercions(
					ArrayRef() => sub {
						my $in  = $_;
						my $set = 'Set::Equivalence'->new(
							type_constraint      => $parameter,
							coerce               => 1,
							members              => [ map $parameter->coerce($_), @$in ],
						);
						$immute ? $set->make_immutable : $set;
					},
				);
				$coercions->add_type_coercions(
					Set() => sub {
						my $in  = $_;
						my $set = 'Set::Equivalence'->new(
							type_constraint      => $parameter,
							coerce               => 1,
							equivalence_relation => $in->equivalence_relation,
							members              => [ map $parameter->coerce($_), $in->members ],
						);
						$immute ? $set->make_immutable : $set;
					},
				);
				$coercions->add_type_coercions(
					AnySet() => sub {
						my $in  = $_;
						my $set = 'Set::Equivalence'->new(
							type_constraint      => $parameter,
							coerce               => 1,
							members              => [ map $parameter->coerce($_), $in->members ],
						);
						$immute ? $set->make_immutable : $set;
					},
				);
			}
			else {
				$coercions->add_type_coercions(
					ArrayRef() => sub {
						my $in  = $_;
						my $set = 'Set::Equivalence'->new(
							type_constraint => $parameter,
							members         => $in,
						);
						$immute ? $set->make_immutable : $set;
					},
				);
				$coercions->add_type_coercions(
					Set() => sub {
						my $in  = $_;
						my $set = 'Set::Equivalence'->new(
							type_constraint      => $parameter,
							equivalence_relation => $in->equivalence_relation,
							members              => [ $in->members ],
						);
						$immute ? $set->make_immutable : $set;
					},
				);
				$coercions->add_type_coercions(
					AnySet() => sub {
						my $in  = $_;
						my $set = 'Set::Equivalence'->new(
							type_constraint      => $parameter,
							members              => [ $in->members ],
						);
						$immute ? $set->make_immutable : $set;
					},
				);
			}
			
			$coercions->add_type_coercions(
				$parameter => sub {
					my $in  = $_;
					my $set = 'Set::Equivalence'->new(
						type_constraint      => $parameter,
						coerce               => $parameter->has_coercion,
						members              => [ $in ],
					);
					$immute ? $set->make_immutable : $set;
				},
			) unless $parameter->is_a_type_of(Set());
		},
	);
}

Set -> has_coercion

__END__

=pod

=encoding utf-8

=head1 NAME

Types::Set - Set::Equivalence-related type constraints

=head1 SYNOPSIS

   package Band {
      use Moose;
      use Types::Standard qw( InstanceOf );
      use Types::Set qw( Set );
      
      has members => (
         is          => 'ro',
         isa         => Set[ InstanceOf['Person'] ],
         coerce      => 1,
         default     => sub { +[] },
         handles     => {
            add_member     => 'insert',
            has_member     => 'contains',
            member_count   => 'size',
         }
      );
   }

=head1 DESCRIPTION

Types::Set is a type constraint library built using L<Type::Tiny>;
compatible with L<Moose>, L<Mouse>, L<Moo> and more.

=head2 Type constraints

=over

=item C<< AnySet >>

This type constraint is satisfied by any blessed object that provides
C<insert>, C<delete>, C<members> and C<contains> methods.

=item C<< Set >>

A blessed L<Set::Equivalence> object.

This may be parameterized with another type constraint; for example,
C<< Set[Num] >> is a set of numbers. In this case, not only must all
the set members be numbers, but also the set itself must have a type
constraint of C<Num> (or a subtype of C<Num>, such as C<Int>) attached,
which will prevent non-numeric values from being inserted into the
set later.

This type can coerce from C<ArrayRef> and C<AnySet>.

=item C<< MutableSet >>

Like C<Set>, but must be a mutable set. Similar parameterization.

This type can coerce from C<ImmutableSet>, C<ArrayRef> and C<AnySet>.

=item C<< ImmutableSet >>

Like C<Set>, but must not be a mutable set. Similar parameterization.

This type can coerce from C<MutableSet>, C<ArrayRef> and C<AnySet>.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Set-Equivalence>.

=head1 SEE ALSO

L<Set::Equivalence>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

