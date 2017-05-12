use 5.008001;
use strict;
use warnings;

package MooseX::Types::MoreUtils;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Carp             0           qw( carp croak );
use List::Util       1.29        qw( pairkeys pairvalues pairmap pairgrep );
use Scalar::Util     1.23        qw( blessed reftype );

sub _reify
{
	my $type = shift;
	
	if (ref $type)
	{
		return $type if blessed($type);
		return _where('Any', $type) if reftype($type) eq 'CODE';
		
		if (ref $type eq 'HASH')
		{
			my ($key, $value) = each(%$type);
			if (1 == keys(%$type))
			{
				my $function = +{
					role    => 'role_type',
					duck    => 'duck_type',
					class   => 'class_type',
					union   => 'union',
					enum    => 'enum',
				}->{$key};
				
				if ($function eq 'union')
				{
					$value = [ map _reify($_), @$value ];
				}
				
				if ($function)
				{
					require Moose::Util::TypeConstraints;
					no strict qw(refs);
					return &{"Moose::Util::TypeConstraints::$function"}($value);
				}
			}
		}
	}
	else
	{
		require Moose::Util::TypeConstraints;
		my $obj = Moose::Util::TypeConstraints::find_or_create_type_constraint($type);
		return $obj if blessed($obj);
	}
	
	croak("Value '$type' does not seem to be a type constraint; stopped");
}

sub _codify
{
	my $code = shift;
	
	if (ref $code)
	{
		return   $code if reftype($code) eq 'CODE';
		return \&$code if $INC{'overload.pm'} && overload::Method($code, '&{}');
	}
	else
	{
		my $sub = exists(&Sub::Quote::quote_sub)
			? Sub::Quote::quote_sub($code)
			: scalar eval qq{ sub { $code } };
		$sub && reftype($sub) eq 'CODE'
			or croak("Could not compile '$code' into a sub; stopped");
		return $sub;
	}
	
	croak("Value '$code' does not seem to be a code ref; stopped");
}

sub _clone
{
	my $self = _reify(shift);
	my @args = ( name => $self->name );
	push @args, (message => $self->message)
		if $self->has_message;
	$self->create_child_type(@args);
}

sub _plus_coercions :method
{
	my $self = _reify(shift);
	
	my @new_coercions = pairmap {
		_reify($a) => _codify($b);
	} @_;
	
	return $self->plus_coercions(@new_coercions)
		if $self->can('plus_coercions');
	
	push @new_coercions, @{ $self->coercion->type_coercion_map }
		if $self->has_coercion;
	
	my $new = _clone($self);
	if (@new_coercions)
	{
		my $class = $new->isa('Type::Tiny')
			? 'Type::Coercion'
			: 'Moose::Meta::TypeCoercion';
		eval "require $class" or die($@);
		$new->coercion($class->new) unless $new->has_coercion;
		$new->coercion->add_type_coercions(@new_coercions);
	}
	return $new;
}

sub _minus_coercions :method
{
	my $self = _reify(shift);
	my @not = map _reify($_), @_;
	
	my @keep = pairgrep {
		my $keep_this = 1;
		NOT: for my $n (@not)
		{
			_reify($a)->equals($n) or next NOT;
			$keep_this = 0;
			last NOT;
		}
		$keep_this;
	} @{ $self->has_coercion ? $self->coercion->type_coercion_map : [] };
	
	my $new = _clone($self);
	if (@keep)
	{
		my $class = $new->isa('Type::Tiny')
			? 'Type::Coercion'
			: 'Moose::Meta::TypeCoercion';
		eval "require $class" or die($@);
		$new->coercion($class->new) unless $new->has_coercion;
		$new->coercion->add_type_coercions(@keep);
	}
	return $new;
}

sub _no_coercions :method
{
	my $self = _reify(shift);
	return $self->no_coercions if $self->can('no_coercions');
	return _clone($self);
}

sub _of :method
{
	my $self = _reify(shift);
	$self->can('parameterize')
		or croak('This type constraint cannot be parameterized; stopped');
	return $self->parameterize(map _reify($_), @_);
}

sub _where :method
{
	my $self = _reify(shift);
	return $self->where(@_) if $self->can('where');
	
	my $code = _codify($_[0]);
	return $self->create_child_type(constraint => $code);
}

sub _type :method
{
	_reify(shift);
}

sub subs :method
{
	'$_plus_coercions'  => \&_plus_coercions,
	'$_minus_coercions' => \&_minus_coercions,
	'$_no_coercions'    => \&_no_coercions,
	'$_of'              => \&_of,
	'$_where'           => \&_where,
	'$_type'            => \&_type,
}

sub sub_names :method
{
	my $me = shift;
	pairkeys($me->subs);
}

sub setup_for :method
{
	my $me   = shift;
	my @refs = @_;
	my @subs = pairvalues($me->subs);
	
	while (@refs)
	{
		my $ref = shift(@refs);
		my $sub = shift(@subs);
		die "Internal problem" unless ref($sub) eq 'CODE';
		
		$$ref = $sub;
		&Internals::SvREADONLY($ref, 1) if exists(&Internals::SvREADONLY);
	}
	
	die "Internal problem" if @subs;
	return;
}

sub import :method
{
	my $me = shift;
	my (%args) = @_;
	my ($caller, $file) = caller;
	
	$args{magic} = "auto" unless defined $args{magic};
	
	if ($file ne '-e'
	and $args{magic}
	and eval { require B::Hooks::Parser })
	{
		my $varlist = join ',', $me->sub_names;
		my $reflist = join ',', map "\\$_", $me->sub_names;
		B::Hooks::Parser::inject(";my($varlist);$me\->setup_for($reflist);");
		return;
	}
	
	if ($args{magic} and $args{magic} ne "auto")
	{
		carp(__PACKAGE__ . " could not use magic; continuing regardless");
	}
	
	my %subs = $me->subs;
	for my $sub_name (sort keys %subs)
	{
		my $code = $subs{$sub_name};
		$sub_name =~ s/^.//;
		no strict 'refs';
		*{"$caller\::$sub_name"} = \$code;
	}
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

MooseX::Types::MoreUtils - utility methods to apply to Moose type constraints

=head1 SYNOPSIS

   {
      package Spruce;
      
      use Moose;
      use MooseX::Types::Moose qw(ArrayRef Str);
      use MooseX::Types::MoreUtils;
      use Local::TextUtils qw( csv_to_arrayref );
      
      has goose => (
         is      => 'ro',
         isa     => ArrayRef->$_plus_coercions( Str, \&csv_to_arrayref ),
         coerce  => 1,
      );
   }

=head1 DESCRIPTION

This module provides a bunch of methods for working with Moose type
constraints, which it exposes as lexical coderef variables. (Like
L<Object::Util>.)

See L<Object::Util/"Rationale">.

=head2 Methods

The invocants for these methods are type constraints. These may be
L<Moose::Meta::TypeConstraint>, L<MooseX::Types::TypeDecorator>, or
L<Type::Tiny> objects. As a convenience, strings are also accepted,
which will be looked up via Moose's C<find_or_create_type_constraint>
utility function. Various other conveniences are provided; see
L</"Shortcuts for type constraints">.

=head3 Constraint manipulation

=over

=item C<< $_where >>

Creates an anonymous subtype with an additional constraint. For example
to create a type constraint that accepts odd-numbered integers, you
could use:

   isa => Int->$_where(sub { $_ % 2 })

Alternatively the coderef can be replaced with a string of Perl code:

   isa => Int->$_where('$_ % 2')

=item C<< $_of >>

Can be used to parameterize type constraints. For example, for an
arrayref of odd integers:

   isa => ArrayRef->$_of(  Int->$_where('$_ % 2')  )

Or if you'd prefer, an arrayref of integers, where the arrayref
contains an odd number of items:

   isa => ArrayRef->$_of(Int)->$_where('@$_ % 2')

=item C<< $_type >>

The identity function. C<< Int->$_type >> just returns C<Int>.

This is occasionally useful if you're taking advantage of the fact that
the invocant doesn't have to be a I<real> type constraint but can
instead use a L<shortcut|/"Shortcuts for type constraints">. In these
cases it's not quite the identity, because it returns a real type
constraint object.

=back

=head3 Coercion manipulation

=over

=item C<< $_plus_coercions >>

Given an existing type constraint, creates a new child type with some
extra coercions.

   isa => ArrayRef->$_plus_coercions(
      Str,         \&csv_to_arrayref,
      "HashRef",   sub { [ values(%$_) ] },
   ),
   coerce => 1,

=item C<< $_minus_coercions >>

Given an existing type constraint, creates a new child type with fewer
coercions.

   use MooseX::Types::Moose qw( HashRef );
   use MooseX::Types::URI qw( Uri );
   
   # Don't want to coerce from HashRef,
   # but keep the coercion from Str.
   #
   isa => Uri->$_minus_coercions(HashRef)

=item C<< $_no_coercions >>

Given an existing type constraint, creates a new child type with no
coercions at all.

   isa => Uri->$_no_coercions

As above, it's just equivalent to C<< coerce => 0 >> so might seem a
bit useless. But it is handy when chained with C<< $_plus_coercions >>
to provide a stable base to build your coercions on:

   # This doesn't just create a type like Uri but
   # with extra coercions; it explicitly ignores any
   # coercions that were already attached to Uri.
   #
   isa => Uri->$_no_coercions->$_plus_coercions(
      Str, sub { ... }
   );

=back

=head2 Shortcuts for type constraints

Where type constraints are expected by this module, you can take some
shortcuts. Strings are passed to C<find_or_create_type_constraint>
for example, meaning that the following two exampes are identical:

With MooseX::Types...

   use MooseX::Types::Moose qw( ArrayRef Str );
   ArrayRef->$_plus_coercions( Str, \&csv_to_arrayref );

Without MooseX::Types...

   "ArrayRef"->$_plus_coercions( "Str", \&csv_to_arrayref );

If, instead of a type constraint you give a coderef, this will be
converted into a subtype of C<Any>.

You may also give a hashref with a single key-value pair, such as:

   { class => "Some::Class::Name" }
   { role => "Some::Role::Name" }
   { duck => \@method_names }
   { union => \@type_constraints }
   { enum => \@strings }

These do what I think you'd expect them to do.

=head1 CAVEATS

This module does not remove the need for C<< coerce => 1 >>!

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-Types-MoreUtils>.

=head1 SEE ALSO

If you use L<Types::Standard>, this module is fairly redundant, as
these features and shortcuts are mostly built-in!

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut
