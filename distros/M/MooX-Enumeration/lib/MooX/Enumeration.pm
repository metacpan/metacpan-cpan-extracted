use 5.008001;
use strict;
use warnings;
no warnings 'once';

package MooX::Enumeration;

use Carp qw(croak);
use Scalar::Util qw(blessed);
use Sub::Util qw(set_subname);
use B qw(perlstring);

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.010';

sub import {
	my $class  = shift;
	my $caller = caller;
	$class->setup_for($caller);
}

sub setup_for {
	my $class = shift;
	my ($target) = @_;
	
	my ($orig, $installer);
	if ($INC{'Moo/Role.pm'} && Moo::Role->is_role($target)) {
		$installer = 'Moo::Role::_install_tracked';
		$orig = $Moo::Role::INFO{$target}{exports}{has};
	}
	elsif ($Moo::MAKERS{$target} && $Moo::MAKERS{$target}{is_class}) {
		$installer = 'Moo::_install_tracked';
		$orig = $Moo::MAKERS{$target}{exports}{has} || $Moo::MAKERS{$target}{non_methods}{has};
	}
	else {
		croak("$target does not seem to be a Moo class or role");
	}
	$orig ||= $target->can('has');
	ref($orig) or croak("$target doesn't have a `has` function");
	
	$target->$installer(has => sub {
		if (@_ % 2 == 0) {
			croak "Invalid options for attribute(s): even number of arguments expected, got " . scalar @_;
		}
		
		my ($attrs, %spec) = @_;
		$attrs = [$attrs] unless ref $attrs;
		for my $attr (@$attrs) {
			%spec = $class->process_spec($target, $attr, %spec);
			if (delete $spec{moox_enumeration_process_handles}) {
				$class->install_delegates($target, $attr, \%spec);
			}
			$orig->($attr, %spec);
		}
		return;
	});
}

sub process_spec {
	my $class = shift;
	my ($target, $attr, %spec) = @_;
	
	my @values;
	
	# Handle the type constraint stuff
	if (exists $spec{isa} and exists $spec{enum}) {
		croak "Cannot supply both the 'isa' and 'enum' options";
	}
	elsif (blessed $spec{isa} and $spec{isa}->isa('Type::Tiny::Enum')) {
		@values = @{ $spec{isa}->values };
	}
	elsif (exists $spec{enum}) {
		croak "Expected arrayref for enum" unless ref $spec{enum} eq 'ARRAY';
		@values = @{ delete $spec{enum} };
		require Type::Tiny::Enum;
		$spec{isa} = Type::Tiny::Enum->new(values => \@values);
	}
	else {
		# nothing to do
		return %spec;
	}
	
	# Canonicalize handles
	if (my $handles = $spec{handles}) {
		
		$spec{moox_enumeration_process_handles} = !!1;
		
		if (!ref $handles and $handles eq 1) {
			$handles = +{ map +( "is_$_" => [ "is", $_ ] ), @values };
		}
		elsif (!ref $handles and $handles eq 2) {
			$handles = +{ map +( "$attr\_is_$_" => [ "is", $_ ] ), @values };
		}

		if (ref $handles eq 'ARRAY') {
			$handles = +{ map ref($_)?@$_:($_=>[split/_/,$_,2]), @$handles };
		}
		
		if (ref $handles eq 'HASH') {
			for my $k (keys %$handles) {
				next if ref $handles->{$k};
				$handles->{$k}=[split/_/,$handles->{$k},2];
			}
		}
		
		$spec{handles} = $handles;
	}
	
	# Install moosify stuff
	if (ref $spec{moosify} eq 'CODE') {
		$spec{moosify} = [$spec{moosify}];
	}
	push @{ $spec{moosify} ||= [] }, sub {
		my $spec = shift;
		require MooseX::Enumeration;
		require MooseX::Enumeration::Meta::Attribute::Native::Trait::Enumeration;
		push @{ $spec->{traits} ||= [] }, 'Enumeration';
		$spec->{handles} ||= $spec->{_orig_handles} if $spec->{_orig_handles};
	};
	
	return %spec;
}

sub install_delegates {
	require Eval::TypeTiny;
	
	my $class  = shift;
	my ($target, $attr, $spec) = @_;
	
	my %delegates = %{ $spec->{_orig_handles} = delete $spec->{handles} };
	
	for my $method (keys %delegates) {
		my ($delegate_type, @delegate_params) = @{ $delegates{$method} };
		my $builder = "build_${delegate_type}_delegate";
		
		no strict 'refs';
		*{"${target}::${method}"} =
			set_subname "${target}::${method}",
			$class->$builder($target, $method, $attr, $spec, @delegate_params);
	}
}

sub _accessor_maker_for {
	my $class = shift;
	my ($target) = @_;
	
	if ($INC{'Moo/Role.pm'} && Moo::Role->is_role($target)) {
		my $dummy = 'MooX::Enumeration::____DummyClass____';
		eval('package ' # hide from CPAN indexer
			. "$dummy; use Moo");
		return Moo->_accessor_maker_for($dummy);
	}
	elsif ($Moo::MAKERS{$target} && $Moo::MAKERS{$target}{is_class}) {
		return Moo->_accessor_maker_for($target);
	}
	else {
		croak "Cannot get accessor maker for $target";
	}
}

sub build_is_delegate {
	my $class  = shift;
	my ($target, $method, $attr, $spec, $match) = @_;
	
	my $MAKER = $class->_accessor_maker_for($target);
	my ($GET, $CAPTURES) = $MAKER->is_simple_get($attr, $spec)
		? $MAKER->generate_simple_get('$_[0]', $attr, $spec)
		: ($MAKER->_generate_get($attr, $spec), delete($MAKER->{captures}));
	
	my $desc = "delegated method $target\::$method";
	
	if (ref $match) {
		require match::simple;
		$CAPTURES->{'$match'} = \$match;
		return Eval::TypeTiny::eval_closure(
			description => $desc,
			source => sprintf(
				'sub { %s; my $value = %s; match::simple::match($value, $match) }',
				$class->_build_throw_args($method, 0),
				$GET,
			),
			environment => $CAPTURES,
		);
	}
	elsif ($spec->{isa}->check($match)) {
		return Eval::TypeTiny::eval_closure(
			description => $desc,
			source => sprintf(
				'sub { %s; (%s) eq %s }',
				$class->_build_throw_args($method, 0),
				$GET,
				perlstring($match),
			),
			environment => $CAPTURES,
		);
	}
	else {
		croak sprintf "Attribute $attr cannot be %s", perlstring($match);
	}
}

sub build_assign_delegate {
	my $class  = shift;
	my ($target, $method, $attr, $spec, $newvalue, $match) = @_;

	croak sprintf "Attribute $attr cannot be %s", perlstring($newvalue)
		unless $spec->{isa}->check($newvalue) || !$spec->{isa};

	my $MAKER = Moo->_accessor_maker_for($target);
	my ($GET, $CAPTURES) = $MAKER->is_simple_get($attr, $spec)
		? $MAKER->generate_simple_get('$_[0]', $attr, $spec)
		: ($MAKER->_generate_get($attr, $spec), delete($MAKER->{captures})||{});
	
	# We can actually use the simple version set even if there's a type constraint,
	# because we've already checked that $newvalue passes the type constraint!
	#
	my $SET = $MAKER->is_simple_set($attr, do { my %temp = %$spec; delete $temp{coerce}; delete $temp{isa}; \%temp })
		? sub {
			my ($var) = @_;
			$MAKER->_generate_simple_set('$_[0]', $attr, $spec, $var);
		}
		: sub { # that allows us to avoid going down this yucky code path
			my ($var) = @_;
			my $code = $MAKER->_generate_set($attr, $spec);
			$CAPTURES = { %$CAPTURES, %{ delete($MAKER->{captures}) or {} } };  # merge environments
			$code = sprintf "do { local \@_ = (\$_[0], $var); %s }", $code;
			$code;
		};

	my $err  = 'Method %s cannot be called when attribute %s has value %s';
	my $desc = "delegated method $target\::$method";

	if (ref $match) {
		require match::simple;
		my $_SET = $SET->(perlstring $newvalue);
		$CAPTURES->{'$match'} = \$match;
		return Eval::TypeTiny::eval_closure(
			description => $desc,
			source => sprintf(
				'sub { %s; my $value = %s; return $_[0] if $value eq %s; match::simple::match($value, $match) ? (%s) : Carp::croak(sprintf %s, %s, %s, $value); $_[0] }',
				$class->_build_throw_args($method, 0),
				$GET,
				perlstring($newvalue),
				$_SET,
				perlstring($err),
				perlstring($method),
				perlstring($attr),
			),
			environment => $CAPTURES,
		);
	}
	elsif (defined $match) {
		$spec->{isa}->check($match)
			or croak sprintf "Attribute $attr cannot be %s", perlstring($match);
		my $_SET = $SET->(perlstring $newvalue);
		return Eval::TypeTiny::eval_closure(
			description => $desc,
			source => sprintf(
				'sub { %s; my $value = %s; return $_[0] if $value eq %s; ($value eq %s) ? (%s) : Carp::croak(sprintf %s, %s, %s, $value); $_[0] }',
				$class->_build_throw_args($method, 0),
				$GET,
				perlstring($newvalue),
				perlstring($match),
				$_SET,
				perlstring($err),
				perlstring($method),
				perlstring($attr),
			),
			environment => $CAPTURES,
		);
	}
	else {
		my $_SET = $SET->(perlstring $newvalue);
		return Eval::TypeTiny::eval_closure(
			description => $desc,
			source => sprintf(
				'sub { %s; %s; $_[0] }',
				$class->_build_throw_args($method, 0),
				$_SET,
			),
			environment => $CAPTURES,
		);
	}
}

sub _build_throw_args {
	my $class = shift;
	my ($method, $n) = @_;
	sprintf(
		'Carp::croak(sprintf "Method %%s expects %%d arguments", %s, %d) if @_ != %d;',
		perlstring($method),
		$n,
		$n+1,
	);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

MooX::Enumeration - shortcuts for working with enum attributes in Moo

=head1 SYNOPSIS

Given this class:

   package MyApp::Result {
      use Moo;
      use Types::Standard qw(Enum);
      has status => (
         is        => "rw",
         isa       => Enum[qw/ pass fail /],
      );
   }

It's quite common to do this kind of thing:

   if ( $result->status eq "pass" ) { ... }

But if you're throwing strings around, it can be quite easy to mistype
them:

   if ( $result->status eq "apss" ) { ... }

And the comparison silently fails. Instead, let's define the class like
this:

   package MyApp::Result {
      use Moo;
      use MooX::Enumeration;
      use Types::Standard qw(Enum);
      has status => (
         is        => "rw",
         isa       => Enum[qw/ pass fail /],
         handles   => [qw/ is_pass is_fail /],
      );
   }

So you can use the class like this:

   if ( $result->is_pass ) { ... }

Yay!

=head1 DESCRIPTION

This is a Moo implementation of L<MooseX::Enumeration>. All the features
from the Moose version should work here.

Passing C<< traits => ["Enumeration"] >> to C<has> is not needed with
MooX::Enumeration. This module's magic is automatically applied to all
attributes with a L<Type::Tiny::Enum> type constraint.

Simple example:

   package MyClass {
      use Moo;
      use MooX::Enumeration;
      
      has xyz => (is => "ro", enum => [qw/foo bar baz/], handles => 1);
   }

C<< MyClass->new(xyz => "quux") >> will throw an error.

Objects of the class will have C<< $object->is_foo >>, C<< $object->is_bar >>,
and C<< $object->is_baz >> methods.

If you use C<< handles => 2 >>, then you get C<< $object->xyz_is_foo >>, etc
methods.

For more details of method delegation, see L<MooseX::Enumeration>.

=head2 Use in roles

Since version 0.009, this will work in roles too, but with a caveat.

The coderef to be installed into the class is built when defining the role,
and not when composing the role with the class, so the coderef has no
knowledge of the class. In particular, it doesn't know anything about what
kind of reference the blessed object will be (hashref, arrayref, etc), so just
assumes that it will be a hashref, and that the hash key used for the
attribute will match the attribute name. Unless you're using non-hashref
objects or you're doing unusual things with Moo internals, these assumptions
will usually be safe.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooX-Enumeration>.

=head1 SEE ALSO

L<MooseX::Enumeration>.

L<Type::Tiny::Enum>.

L<Moo>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

