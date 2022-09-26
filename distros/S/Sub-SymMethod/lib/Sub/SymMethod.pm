use 5.008008;
use strict;
use warnings;

package Sub::SymMethod;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '1.000';

use Exporter::Shiny our @EXPORT = qw( symmethod );
use Scalar::Util qw( blessed );
use Role::Hooks;

# Options other than these will be passed through to
# Type::Params.
#
my %KNOWN_OPTIONS = (
	code               => 1,
	name               => 1,
	named              => 'legacy',
	no_dispatcher      => 1,
	no_hook            => 1,
	order              => 1,
	origin             => 1,
	signature          => 'legacy',
	signature_spec     => 1,
);

# But not these!
#
my %BAD_OPTIONS = (
	want_details       => 1,
	want_object        => 1,
	want_source        => 1,
	goto_next          => 1,
	on_die             => 1,
	message            => 1,
);

BEGIN {
	eval  { require mro }
	or do { require MRO::Compat };
	
	eval {
		require Types::Standard;
		'Types::Standard'->import(qw/ is_CodeRef is_HashRef is_ArrayRef is_Int /);
		1;
	}
	or do {
		*is_CodeRef  = sub { no warnings; ref($_[0]) eq 'CODE'  };
		*is_HashRef  = sub { no warnings; ref($_[0]) eq 'HASH'  };
		*is_ArrayRef = sub { no warnings; ref($_[0]) eq 'ARRAY' };
		*is_Int      = sub { defined($_[0]) and !ref($_[0]) and $_[0] =~ /\A-[0-9]+\z/ };
	};
	
	no strict 'refs';
	eval  { require Sub::Util; 'Sub::Util'->import('set_subname'); 1 }
	or do { require Sub::Name;  *set_subname = \&Sub::Name::subname; }
};

{
	# %SPECS is a hash of hashrefs keyed on {package}->{subname}.
	# The values are specs (themselves hashrefs!)
	my %SPECS;
	
	sub get_symmethods {
		my ( $class, $target, $name ) = ( shift, @_ );
		$SPECS{$target}{$name} ||= [];
	}
	
	sub get_symmethod_names {
		my ( $class, $target ) = ( shift, @_ );
		keys %{ $SPECS{$target} ||= {} };
	}
}

sub _extract_type_params_spec {
	my ( $me, $target, $sub_name, $spec ) = ( shift, @_ );
	
	my %tp = ( method => 1 );
	$tp{method} = $spec->{method} if defined $spec->{method};
	
	if ( is_ArrayRef $spec->{signature} ) {
		my $key = $spec->{named} ? 'named' : 'positional';
		$tp{$key} = delete $spec->{signature};
	}
	else {
		$tp{named} = $spec->{named} if ref $spec->{named};
	}
	
	# Options which are not known by this module must be intended for
	# Type::Params instead.
	for my $key ( keys %$spec ) {
		
		next if ( $KNOWN_OPTIONS{$key} or $key =~ /^_/ );
		
		if ( $BAD_OPTIONS{$key} ) {
			require Carp;
			Carp::carp( "Unsupported option: $key" );
			next;
		}
		
		$tp{$key} = delete $spec->{$key};
	}
	
	$tp{package} ||= $target;
	$tp{subname} ||= ref( $sub_name ) ? '__ANON__' : $sub_name;
	
	# Historically we allowed method=2, etc
	if ( is_Int $tp{method} ) {
		if ( $tp{method} > 1 ) {
			require Types::Standard;
			my $excess = $tp{method} - 1;
			$tp{method} = 1;
			ref( $tp{head} ) ? push( @{ $tp{head} }, ( Types::Standard::Any() ) x $excess ) : ( $tp{head} += $excess );
		}
	}
	
	$spec->{signature_spec} = \%tp
		if $tp{positional} || $tp{pos} || $tp{named} || $tp{multiple} || $tp{multi};
}

sub install_symmethod {
	my ( $class, $target, $name, %args ) = ( shift, @_ );
	$args{origin} = $target unless exists $args{origin};
	$args{method} = 1       unless exists $args{method};
	$args{name}   = $name;
	$args{order}  = 0       unless exists $args{order};
	
	$class->_extract_type_params_spec( $target, $name, \%args );
	
	if ( not is_CodeRef $args{code} ) {
		require Carp;
		Carp::croak('Cannot install symmethod with no valid code; stopped');
	}
	
	my $symmethods = $class->get_symmethods( $target, $name );
	push @$symmethods, \%args;
	$class->clear_cache($name);
	
	my $kind = 'Role::Hooks'->is_role($target) ? 'role' : 'class';
	
	if ( $kind eq 'class' and not $args{no_dispatcher} ) {
		$class->install_dispatcher( $target, $name );
	}
	
	if ( $kind eq 'role' and not $args{no_hook} ) {
		$class->install_hooks( $target );
	}
	
	return $class;
}


{
	my %KNOWN;
	sub is_dispatcher {
		my ( $class, $coderef, $set ) = ( shift, @_ );
		if ( @_ == 2 ) {
			$KNOWN{"$coderef"} = $set;
		}
		$KNOWN{"$coderef"};
	}
}

sub install_dispatcher {
	my ( $class, $target, $name ) = ( shift, @_ );
	
	if ( my $existing = $target->can($name) ) {
		return if $class->is_dispatcher( $existing );
		require Carp;
		Carp::carp("Symmethod $name overriding existing method for class $target");
	}
	
	if ( $name eq 'BUILD' or $name eq 'DEMOLISH' or $name eq 'new' ) {
		require Carp;
		Carp::carp("Symmethod $name should probably be a plain method");
	}
	
	my $coderef = $class->build_dispatcher( $target, $name );
	my $qname   = "$target\::$name";
	
	do {
		no strict 'refs';
		no warnings 'redefine';
		*$qname = set_subname( $qname, $coderef );
	};
	
	$class->is_dispatcher( $coderef, $qname );
	
	return $class;
}

sub build_dispatcher {
	my ( $class, $target, $name ) = ( shift, @_ );
	
	return sub {
		my $specs = $class->get_all_symmethods( $_[0], $name );
		my @results;
		SPEC: for my $spec ( @$specs ) {
			if ( $spec->{signature} or $spec->{signature_spec} ) {
				$class->compile_signature($spec) unless is_CodeRef $spec->{signature};
				my @orig = @_;
				my @new;
				{
					local $@;
					eval{ @new = $spec->{signature}(@orig); 1 }
						or next SPEC;
				}
				push @results, scalar $spec->{code}( @new );
				next SPEC;
			}
			
			push @results, scalar $spec->{code}( @_ );
		}
		return @results;
	};
}

sub dispatch {
	my ( $class, $invocant, $name ) = ( shift, shift, shift, @_ );
	my $invocant_class = blessed($invocant) || $invocant;
	
	my $dispatcher = $class->build_dispatcher( $invocant_class, $name );
	unshift @_, $invocant;
	goto $dispatcher;
}

{
	my %HOOKED;
	
	sub install_hooks {
		my ( $class, $target ) = ( shift, @_ );
		
		return if $HOOKED{$target}++;
		
		'Role::Hooks'->before_apply( $target, sub {
			my ( $role, $consumer ) = @_;
			
			if ( not 'Role::Hooks'->is_role($consumer) ) {
				push @{ $class->get_roles_for_class($consumer) }, $target;
				
				for my $name ( $class->get_symmethod_names($target) ) {
					$class->install_dispatcher( $consumer, $name );
				}
			}
			
			$class->clear_cache( $class->get_symmethod_names($target) );
		} );
		
		return $class;
	}
}

{
	# %ROLES is a hash keyed on {classname} where the values
	# are an arrayref of rolenames of roles the class is known to consume.
	# We only care about roles which define symmethods.
	my %ROLES;
	
	sub get_roles_for_class {
		my ( $class, $target ) = ( shift, @_ );
		$ROLES{$target} ||= [];
	}
}

{
	# %CACHE is a hash of hashrefs keyed on {subname}->{invocantclass}
	# to avoid needing to crawl MRO for each method call.
	# The values are arrayrefs of specs	
	my %CACHE;
	
	sub clear_cache {
		my ( $class ) = ( shift );
		delete $CACHE{$_} for @_;
		return $class;
	}
	
	sub get_all_symmethods {
		my ( $class, $invocant, $name ) = ( shift, @_ );
		my $invocant_class = blessed($invocant) || $invocant;
		
		if ( not $CACHE{$name}{$invocant_class} ) {
			use sort 'stable';
			$CACHE{$name}{$invocant_class} = [
				sort { $a->{order} <=> $b->{order} }
				map @{ $class->get_symmethods( $_, $name ) },
				map +( @{ $class->get_roles_for_class($_) }, $_ ),
				reverse @{ mro::get_linear_isa( $invocant_class ) || [] }
			];
			Internals::SvREADONLY($CACHE{$name}{$invocant_class}, 1);
		}
		
		$CACHE{$name}{$invocant_class};
	}
}

sub compile_signature {
	my ( $class, $spec ) = ( shift, @_ );
	require Type::Params;
	$class->_extract_type_params_spec( $spec->{origin}, $spec->{name}, $spec )
		unless $spec->{signature_spec};
	$spec->{signature} = Type::Params::signature( %{ $spec->{signature_spec} } )
		if keys %{ $spec->{signature_spec} || {} };
	return $class;
}

sub _generate_symmethod {
	my ( $class, undef, undef, $globals ) = ( shift, @_ );
	
	my $target = $globals->{into};
	ref($target) and die 'Cannot export to non-package';
	
	return sub {
		splice(@_, -1, 0, 'code') unless @_ % 2;
		my ( $name, %args ) = @_;
		$class->install_symmethod( $target, $name, %args );
		return;
	};
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Sub::SymMethod - symbiotic methods; methods that act a little like BUILD and DEMOLISH

=head1 SYNOPSIS

  use strict;
  use warnings;
  use feature 'say';
  
  {
    package Local::Base;
    use Class::Tiny;
    use Sub::SymMethod;
    
    symmethod foo => sub { say __PACKAGE__ };
  }
  
  {
    package Local::Role;
    use Role::Tiny;
    use Sub::SymMethod;
    
    symmethod foo => sub { say __PACKAGE__ };
  }
  
  {
    package Local::Derived;
    use parent -norequire, 'Local::Base';
    use Role::Tiny::With; with 'Local::Role';
    use Sub::SymMethod;
    
    symmethod foo => sub { say __PACKAGE__ };
  }
  
  'Local::Derived'->foo();
  # Local::Base
  # Local::Role
  # Local::Derived

=head1 DESCRIPTION

Sub::SymMethod creates hierarchies of methods so that when you call one,
all the methods in the inheritance chain (including ones defined in roles)
are invoked.

They are invoked from the most basal class to the most derived class.
Methods defined in roles are invoked before methods defined in the class
they were composed into.

This is similar to how the C<BUILD> and C<DEMOLISH> methods are invoked
in L<Moo>, L<Moose>, and L<Mouse>. (You should I<not> use this module to
define C<BUILD> and C<DEMOLISH> methods though, as Moo/Moose/Mouse already
includes all the plumbing to ensure that they are called correctly. This
module is instead intended to allow you to define your own methods which
behave similarly.)

You can think of "symmethod" as being short for "symbiotic method",
"syncretic method", or "synarchy of methods".

If you are familiar with L<multi methods|Sub::MultiMethod>, you can think
of a symmethod as a multi method where instead of picking one "winning"
candidate to dispatch to, the dispatcher dispatches to as many candidates
as it can find!

=head2 Use Cases

Symmethods are useful for "hooks". For example, the following pseudocode:

  class Message {
    method send () {
      $self->on_send();
      $self->do_smtp_stuff();
    }
    
    symmethod on_send () {
      # do nothing
    }
  }
  
  role LoggedMessage {
    symmethod on_send () {
      print STDERR "Sending message\n";
    }
  }
  
  class ImportantMessage {
    extends Message;
    with LoggedMessage;
    
    symmethod on_send () {
      $self->add_to_archive( "Important" );
    }
  }

When the C<send> method gets called on an ImportantMessage object, the
inherited C<send> method from Message will get invoked. This will call
C<on_send>, which will call every C<on_send> definition in the inheritance
hierarchy for ImportantMessage, ensuring the sending of the important
message gets logged to STDERR and the message gets archived.

=head2 Functions

Sub::SymMethod exports one function, but which may be called in two
different ways.

=over

=item C<< symmethod $name => $coderef >>

Creates a symmethod.

=item C<< symmethod $name => %spec >>

Creates a symmethod.

The specification hash must contain a C<code> key, which must be a coderef.
It may also include an C<order> key, which must be numeric. Any other
keys are passed to C<signature> from L<Type::Params> to build a signature for
the symmethod.

=back

=head2 Invoking Symmethods

Given the following pseudocode:

  class Base {
    symmethod foo () {
      say wantarray ? "List context" : "Scalar context";
      return "BASE";
    }
  }
  
  class Derived {
    extends Base;
    
    symmethod foo () {
      say wantarray ? "List context" : "Scalar context";
      return "DERIVED";
    }
  }
  
  my @r = Derived->foo();
  my $r = Derived->foo();

"Scalar context" will be said four times. Symmethods are always invoked in
scalar context even when they have been called in list context!

The C<< @r >> array will be C<< ( "BASE", "DERIVED" ) >>. When a symmethod
is called in list context, a list of the returned values will be returned.

The variable C<< $r >> will be C<< 2 >>. It is the count of the returned
values.

If a symmethod throws an exception this will not be caught, so any further
symmethods waiting to be invoked will not get invoked.

=head3 Invocation Order

It is possible to force a symmethod to run early by setting C<order> to
a negative number.

  symmethod foo => (
    order => -100,
    code  => sub { my $self = shift; ... },
  );

It is possible to force a symmethod to run late by setting order to a
positive number.

  symmethod foo => (
    order => 100,
    code  => sub { my $self = shift; ... },
  );

The default C<order> is 0 for all symmethods, and in most cases this will
be fine.

Where symmethods have the same order (the usual case!) symmethods are invoked
from most basal class to most derived class -- i.e. from parent to child.
Where a class consumes symmethods from roles, a symmethods defined in a role
will be invoked before a symmethod defined in the class, but after any
inherited from base/parent classes.

=head2 Symmethods and Signatures

When defining symmethods, you can define a signature using the same
options supported by C<signature> from L<Type::Params>.

  use Types::Standard 'Num';
  use Sub::SymMethod;
  
  symmethod foo => (
    positional => [ Num ],
    code       => sub {
      my ( $self, $num ) = @_;
      print $num, "\n";
    },
  );
  
  symmethod foo => (
    named => [ mynum => Num ],
    code  => sub {
      my ( $self, $arg ) = @_;
      print $arg->mynum, "\n";
    },
  );

When the symmethod is called, any symmethods where the arguments do not match
the signature are simply skipped.

The invocant ($self or $class or whatever) is I<not> included in the
signature.

The coderef given in C<code> receives the list of arguments I<after> they've
been passed through the signature, which may coerce them, etc.

Using a signature requires L<Type::Params> to be installed.

=head2 API

Sub::SymMethod has an object oriented API for metaprogramming.

When describing it, we'll borrow the terms I<dispatcher> and I<candidate>
from L<Sub::MultiMethod>. The candidates are the coderefs you gave to
Sub::SymMethod -- so there might be a candidate defined in your parent
class and a candidate defined in your child class. The dispatcher is the
method that Sub::SymMethod creates for you (probably just in the base
class, but theoretically perhaps also in the child class) which is responsible
for finding the candidates and calling them.

The Sub::SymMethod API offers the following methods:

=over

=item C<< install_symmethod( $target, $name, %spec ) >>

Installs a candidate method for a class or role.

C<< $target >> is the class or role the candidate is being defined for.
C<< $name >> is the name of the method. C<< %spec >> must include a
C<code> key and optionally an C<order> key. Any keys not directly supported
by Sub::SymMethod will be passed through to Type::Params to provide a
signature for the method.

If C<< $target >> is a class, this will also install a dispatcher into
the class. Passing C<< no_dispatcher => 1 >> in the spec will avoid this.

If C<< $target >> is a role, this will also install hooks to the role to
notify Sub::SymMethod whenever the role gets consumed by a class. Passing
C<< no_hooks => 1 >> in the spec will avoid this.

This will also perform any needed cache invalidation.

=item C<< build_dispatcher( $target, $name ) >>

Builds a coderef that could potentially be installed into
C<< *{"$target\::$name"} >> to be used as a dispatcher.

=item C<< install_dispatcher( $target, $name ) >>

Builds a coderef that could potentially be installed into
C<< *{"$target\::$name"} >> to be used as a dispatcher, and
actually installs it.

This complains if it notices it's overwriting an existing
method which isn't a dispatcher. (It also remembers the coderef
being installed is a dispatcher, which can later be checked
using C<is_dispatcher>.)

=item C<< is_dispatcher( $coderef ) >>

Checks to see if C<< $coderef >> is a dispatcher.

Can also be called as C<< is_dispatcher( $coderef, 0 ) >> or
C<< is_dispatcher( $coderef, 1 ) >> to teach it about a coderef.

=item C<< dispatch( $invocant, $name, @args ) >>

Equivalent to calling C<< $invocant->$name(@args) >> except doesn't use
the dispatcher installed into the invocant's class, instead building a
new dispatcher and using that.

=item C<< install_hooks( $rolename ) >>

Given a role, sets up the required hooks which ensure that when the role
is composed with a class, dispatchers will be installed into the class to
handle all of the role's symmethods, and Sub::SymMethod will know that the
class consumed the role.

Also performs cache invalidation.

=item C<< get_roles_for_class ( $classname ) >>

Returns an arrayref containing a list of roles the class is known to
consume. We only care about roles that define symmethods.

If you need to manually specify that a class consumes a role, you can
push the role name onto the arrayref. This would usually only be necessary
if you were using an unsupported role implementation. (Supported role
implementations include L<Role::Tiny>, L<Role::Basic>, L<Moo::Role>,
L<Moose::Role>, and L<Mouse::Role>.)

=item C<< clear_cache( $name ) >>

Clears all caches associated with any symmethods with a given name.
The target class is irrelevent because symmethods can be created in
roles which may be consumed by multiple unrelated classes.

=item C<< get_symmethod_names( $target ) >>

For a given class or role, returns a list of the names of symmethods defined
directly in that class or role, not considering inheritance and composition.

=item C<< get_symmethods( $target, $name ) >>

For a given class or role and a method name, returns an arrayref of spec
hashrefs for that symmethod, not considering inheritance and composition.

This arrayref can be pushed onto to define more candidates, though this
bypasses setting up hooks, installing dispatches, and performing cache
invalidation, so C<install_symmethod> is generally preferred unless you're
doing something unusual.

=item C<< get_all_symmethods( $target, $name ) >>

Like C<get_symmethods>, but I<does> consider inheritance and composition.
Returns the arrayref of the spec hashrefs in the order they will be called
when dispatching.

=item C<< compile_signature( \%spec ) >>

Does the job of finding keys within the spec to compile into a signature.

=item C<< _generate_symmethod( $name, \%opts, \%globalopts ) >>

This method is used by C<import> to generate a coderef that will be installed
into the called as C<symmethod>.

=back

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-sub-symmethod/issues>.

=head1 SEE ALSO

L<Sub::MultiMethod>, L<Type::Params>, L<NEXT>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020, 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
