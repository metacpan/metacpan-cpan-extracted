use 5.008001;
use strict;
use warnings;

package Sub::MultiMethod;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '1.000';

use B ();
use Eval::TypeTiny qw( set_subname );
use Exporter::Shiny qw(
	multimethod   monomethod
	multifunction monofunction
);
use Role::Hooks;
use Scalar::Util qw( refaddr );
use Type::Params ();
use Types::Standard qw( -types -is );

# Options other than these will be passed through to
# Type::Params.
#
my %KNOWN_OPTIONS = (
	alias              => 1,
	code               => 1,
	compiled           => 1,
	copied             => 1,
	declaration_order  => 1,
	height             => 1,
	is_monomethod      => 1,
	method             => 1,
	named              => 'legacy',
	no_dispatcher      => 1,
	score              => 1,
	signature          => 'legacy',
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

{
	my %CANDIDATES;
	sub _get_multimethods_ref {
		my ($me, $target) = @_;
		if ( not $CANDIDATES{$target} ) {
			$CANDIDATES{$target} = {};
		}
		$CANDIDATES{$target};
	}
}

sub get_multimethods {
	my ($me, $target) = @_;
	sort keys %{ $me->_get_multimethods_ref($target) };
}

sub _get_multimethod_candidates_ref {
	my ($me, $target, $method_name) = @_;
	my ( $package_key, $method_key ) = ref( $method_name )
		? ( '__CODE__', refaddr( $method_name ) )
		: ( $target, $method_name );
	my $mm = $me->_get_multimethods_ref( $package_key );
	$mm->{$method_key} ||= [];
}

sub _clear_multimethod_candidates_ref {
	my ( $me, $target, $method_name ) = ( shift, @_ );
	my ( $package_key, $method_key ) = ref( $method_name )
		? ( '__CODE__', refaddr( $method_name ) )
		: ( $target, $method_name );
	my $mm = $me->_get_multimethods_ref( $package_key );
	delete $mm->{$method_key};
	return $me;
}
	
sub get_multimethod_candidates {
	my ($me, $target, $method_name) = @_;
	@{ $me->_get_multimethod_candidates_ref($target, $method_name) };
}

sub has_multimethod_candidates {
	my ($me, $target, $method_name) = @_;
	scalar @{ $me->_get_multimethod_candidates_ref($target, $method_name) };
}

sub _add_multimethod_candidate {
	my ($me, $target, $method_name, $spec) = @_;
	my $mmc = $me->_get_multimethod_candidates_ref($target, $method_name);
	no warnings 'uninitialized';
	if ( @$mmc and $spec->{method} != $mmc->[0]{method} ) {
		require Carp;
		Carp::carp(sprintf(
			"Added multimethod candidate for %s with method=>%d but expected method=>%d",
			$method_name,
			$spec->{method},
			$mmc->[0]{method},
		));
	}
	push @$mmc, $spec;
	$me;
}

sub get_all_multimethod_candidates {
	my ($me, $target, $method_name, $is_method) = @_;
	
	# Figure out which packages to consider when finding candidates.
	my (@packages, $is_coderef_method);
	if (is_Int $method_name or is_ScalarRef $method_name) {
		@packages = '__CODE__';
		$is_coderef_method = 1;
	}
	else {
		@packages = $is_method
			? @{ mro::get_linear_isa($target) }
			: $target;
	}
	
	my $curr_height = @packages;
	
	# Find candidates from each package
	my @candidates;
	my $final_fallback = undef;
	PACKAGE: while (@packages) {
		my $p = shift @packages;
		my @c;
		my $found = $me->has_multimethod_candidates($p, $method_name);
		if ($found) {
			@c = $me->get_multimethod_candidates($p, $method_name);
		}
		elsif (not $is_coderef_method) {
			no strict 'refs';
			if (exists &{"$p\::$method_name"}) {
				# We found a potential monomethod.
				my $coderef = \&{"$p\::$method_name"};
				if (!$me->known_dispatcher($coderef)) {
					# Definite monomethod. Stop falling back.
					$final_fallback = $coderef;
					last PACKAGE;
				}
			}
			@c = ();
		}
		# Record their height in case we need it later
		$_->{height} = $curr_height for @c;
		push @candidates, @c;
		--$curr_height;
	}
	
	# If a monomethod was found, use it as last resort
	if (defined $final_fallback) {
		push @candidates, {
			signature => sub { @_ },
			code      => $final_fallback,
		};
	}
	
	return @candidates;
}

{
	my %DISPATCHERS;
	
	sub known_dispatcher {
		my ($me, $coderef) = @_;
		$DISPATCHERS{refaddr($coderef)};
	}
	
	sub _mark_as_dispatcher {
		my ($me, $coderef) = @_;
		$DISPATCHERS{refaddr($coderef)} = 1;
		$me;
	}
	
	sub _unmark_as_dispatcher {
		my ($me, $coderef) = @_;
		$DISPATCHERS{refaddr($coderef)} = 0;
		$me;
	}
}

sub _generate_exported_function {
	my ( $me, $name, $args, $globals ) = ( shift, @_ );
	
	my $target = $globals->{into};
	if ( ref $target or not defined $target ) {
		require Carp;
		Carp::croak( "Function $name can only be installed into a package by package name" );
	}
	
	my %defaults = %{ $args->{defaults} || {} };
	my $api_call = $args->{api_call} || 'install_candidate';
	
	return sub {
		my ( $sub_name, %spec ) = @_;
		if ( $defaults{no_dispatcher} eq 'auto' ) {
			$defaults{no_dispatcher} = 0+!! 'Role::Hooks'->is_role( $target );
		}
		$me->$api_call(
			$target,
			$sub_name,
			%defaults,
			'package' => $target,
			'subname' => ( ref($sub_name) ? '__ANON__' : $sub_name ),
			%spec,
		);
	};
}

sub _generate_multimethod {
	my ( $me, $name, $args, $globals ) = ( shift, @_ );
	$args->{defaults}{no_dispatcher} = 'auto';
	$args->{defaults}{method} = 1;
	return $me->_generate_exported_function( $name, $args, $globals );
}

sub _generate_monomethod {
	my ( $me, $name, $args, $globals ) = ( shift, @_ );
	$args->{defaults}{no_dispatcher} = 1;
	$args->{defaults}{method} = 1;
	$args->{api_call} = 'install_monomethod';
	return $me->_generate_exported_function( $name, $args, $globals );
}

sub _generate_multifunction {
	my ( $me, $name, $args, $globals ) = ( shift, @_ );
	$args->{defaults}{no_dispatcher} = 'auto';
	$args->{defaults}{method} = 0;
	return $me->_generate_exported_function( $name, $args, $globals );
}

sub _generate_monofunction {
	my ( $me, $name, $args, $globals ) = ( shift, @_ );
	$args->{defaults}{no_dispatcher} = 1;
	$args->{defaults}{method} = 0;
	$args->{api_call} = 'install_monomethod';
	return $me->_generate_exported_function( $name, $args, $globals );
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
			my $excess = $tp{method} - 1;
			$tp{method} = 1;
			ref( $tp{head} ) ? push( @{ $tp{head} }, Any ) : ( $tp{head} += $excess );
		}
		if ( $tp{method} == 1 ) {
			$tp{method} = Any;
		}
	}
	
	$spec->{signature_spec} = \%tp;
}

my %delete_while_copying = (
	_id            => '_id should be unique',
	alias          => 'alias should only be installed into package where originally declared',
	copied         => 'this will be set after copying',
	height         => 'this should never be kept anyway',
	is_monomethod  => 'if it has been copied, it is no longer mono!',
	no_dispatcher  => 'after a candidate gets copied from a role to a class, there SHOULD be a dispatcher',
);
sub copy_package_candidates {
	my $me = shift;
	my (@sources) = @_;
	my $target = pop @sources;
	
	for my $source (@sources) {
		for my $method_name ($me->get_multimethods($source)) {
			for my $candidate ($me->get_multimethod_candidates($source, $method_name)) {
				my %new = map {
					$delete_while_copying{$_}
						? ()
						: ( $_ => $candidate->{$_} )
				} keys %$candidate;
				$new{copied} = 1;
				$me->_add_multimethod_candidate($target, $method_name, \%new);
			}
		}
	}
}

sub install_missing_dispatchers {
	my $me = shift;
	my ($target) = @_;
	
	for my $method_name ($me->get_multimethods($target)) {
		my ($first) = $me->get_multimethod_candidates($target, $method_name);
		$me->install_dispatcher(
			$target,
			$method_name,
			$first ? $first->{'method'} : 0,
		);
	}
}

sub install_monomethod {
	my ( $me, $target, $sub_name, %spec ) = ( shift, @_ );
	
	$spec{alias} ||= [];
	$spec{alias} = [$spec{alias}] if !ref $spec{alias};
	unshift @{$spec{alias}}, $sub_name;
	
	$me->install_candidate($target, undef, no_dispatcher => 1, %spec, is_monomethod => 1);
}

my %hooked;
my $DECLARATION_ORDER = 0;
sub install_candidate {
	my ( $me, $target, $sub_name, %spec ) = ( shift, @_ );
	$me->_extract_type_params_spec( $target, $sub_name, \%spec );

	my $is_method = $spec{method};
	
	$spec{declaration_order} = ++$DECLARATION_ORDER;
	
	$me->_add_multimethod_candidate($target, $sub_name, \%spec)
		if defined $sub_name;
	
	if ($spec{alias}) {
		my @aliases = is_ArrayRef( $spec{alias} )
			? @{ $spec{alias} }
			: $spec{alias};
		
		my ($check, @sig);
		if (is_CodeRef $spec{signature}) {
			$check = $spec{signature};
		}
		
		my %sig_spec = (
			%{ $spec{signature_spec} },
			goto_next => $spec{code} || die('NO CODE???'),
		);
		my $code = sprintf(
			q{
				package %s;
				sub {
					$check ||= Type::Params::signature( %%sig_spec );
					goto $check;
				}
			},
			$target,
		);
		my $coderef = do {
			local $@;
			eval $code or die $@,
		};
		for my $alias (@aliases) {
			my $existing = do {
				no strict 'refs';
				exists(&{"$target\::$alias"})
					? \&{"$target\::$alias"}
					: undef;
			};
			if ($existing) {
				my $kind = ($spec{is_monomethod} && ($alias eq $aliases[0]))
					? 'Monomethod'
					: 'Alias';
				require Carp;
				Carp::croak("$kind conflicts with existing method $target\::$alias, bailing out");
			}
			$me->_install_coderef( $target, $alias, $coderef );
		}
	}
	
	$me->install_dispatcher($target, $sub_name, $is_method)
		if defined $sub_name && !$spec{no_dispatcher};
	
	if ( !$hooked{$target} and 'Role::Hooks'->is_role($target) ) {
		'Role::Hooks'->after_apply($target, sub {
			my ($rolepkg, $consumerpkg) = @_;
			$me->copy_package_candidates($rolepkg => $consumerpkg);
			$me->install_missing_dispatchers($consumerpkg)
				unless 'Role::Hooks'->is_role($consumerpkg);
		});
		$hooked{$target}++;
	}
}

{
	my %CLEANUP;
	
	sub _install_coderef {
		my $me = shift;
		my ($target, $sub_name, $coderef) = @_;
		if (is_ScalarRef $sub_name) {
			if (is_Undef $$sub_name) {
				set_subname("$target\::__ANON__", $coderef);
				bless( $coderef, $me );
				$CLEANUP{"$coderef"} = [ $target, refaddr($sub_name) ];
				return( $$sub_name = $coderef );
			}
			elsif (is_CodeRef $$sub_name or is_Object $$sub_name) {
				if ( $me->known_dispatcher($$sub_name) ) {
					return $$sub_name;
				}
				else {
					require Carp;
					Carp::croak(sprintf(
						'Sub name was a reference to an unknown coderef or object: %s',
						$$sub_name,
					));
				}
			}
		}
		elsif (is_Str $sub_name) {
			no strict 'refs';
			my $qname = "$target\::$sub_name";
			*$qname = set_subname($qname, $coderef);
			return $coderef;
		}
		require Carp;
		Carp::croak(sprintf(
			'Expected string or reference to coderef as sub name, but got: %s %s',
			$sub_name,
		));
	}
	
	sub DESTROY {
		my $blessed_coderef = shift;
		my ( $target, $sub_name ) = @{ $CLEANUP{"$blessed_coderef"} or [] };
		if ( $target and $sub_name ) {
			$blessed_coderef->_clear_multimethod_candidates_ref($target, $sub_name);
		}
		return;
	}
}

sub install_dispatcher {
	my $me = shift;
	my ($target, $sub_name, $is_method) = @_;
	
	exists &mro::get_linear_isa
		or eval { require mro }
		or do { require MRO::Compat };
	
	my $existing = do {
		no strict 'refs';
		exists(&{"$target\::$sub_name"})
			? \&{"$target\::$sub_name"}
			: undef;
	};
	
	return if !defined $sub_name;
	
	if ($existing and $me->known_dispatcher($existing)) {
		return $me;   # already installed
	}
	elsif ($existing) {
		require Carp;
		Carp::croak("Multimethod conflicts with monomethod $target\::$sub_name, bailing out");
	}
	
	my $code = sprintf(
		q{
			package %s;
			sub {
				my $next = %s->can('dispatch');
				@_ = (%s, %s, %s, %d, [@_]);
				goto $next;
			}
		},
		$target,                     # package %s
		B::perlstring($me),          # %s->can('dispatch')
		B::perlstring($me),          # $_[0]
		B::perlstring($target),      # $_[1]
		ref($sub_name)               # $_[2]
			? refaddr($sub_name)
			: B::perlstring("$sub_name"),
		$is_method || 0,             # $_[3]
	);
	
	my $coderef = do {
		local $@;
		eval $code or die $@;
	};
	
	$me->_install_coderef($target, $sub_name, $coderef);
	$me->_mark_as_dispatcher($coderef);
	return $coderef;
}

sub dispatch {
	my $me = shift;
	my ($pkg, $method_name, $is_method, $argv) = @_;
	
	if ( $is_method and is_Object $argv->[0] ) {
		# object method; reset package search from invocant class
		$pkg = ref $argv->[0];
	}
	elsif ( $is_method and is_ClassName $argv->[0] ) {
		# class method; reset package search from invocant class
		$pkg = $argv->[0];
	}
	
	my ($winner, $new_argv) = $me->pick_candidate(
		[ $me->get_all_multimethod_candidates($pkg, $method_name, $is_method) ],
		$argv,
	) or do {
		require Carp;
		Carp::croak('Multimethod could not find candidate to dispatch to, stopped');
	};
	
	my $next = $winner->{code};
	@_ = @$new_argv;
	goto $next;
}

sub pick_candidate {
	my ( $me, $candidates, $argv ) = ( shift, @_ );
	
	my @remaining = @{ $candidates };
	
	# Compile signatures into something useful. (Cached.)
	#
	
	for my $candidate (@remaining) {
		next if $candidate->{compiled};
		if ( is_CodeRef $candidate->{signature} ) {
			$candidate->{compiled}{closure} = $candidate->{signature};
			$candidate->{compiled}{min_args} = 0;
			$candidate->{compiled}{max_args} = undef;
		}
		else {
			$candidate->{compiled} = Type::Params::signature(
				%{ $candidate->{signature_spec} },
				want_details => 1,
			);
		}
	}
	
	# Weed out signatures that cannot match because of
	# argument count.
	#
	
	my $argc = @$argv;
	
	@remaining = grep {
		my $candidate = $_;
		if (defined $candidate->{compiled}{min_args} and $candidate->{compiled}{min_args} > $argc) {
			0;
		}
		elsif (defined $candidate->{compiled}{max_args} and $candidate->{compiled}{max_args} < $argc) {
			0;
		}
		else {
			1;
		}
	} @remaining;
	
	# Weed out signatures that cannot match because
	# they fail type checks, etc
	#
	
	my %returns;
	
	@remaining = grep {
		my $code = $_->{compiled}{closure};
		eval {
			$returns{"$code"} = [ $code->(@$argv) ];
			1;
		};
	} @remaining;
	
	# Various techniques to cope with @remaining > 1...
	#
	
	if (@remaining > 1) {
		no warnings qw(uninitialized numeric);
		# Calculate signature constrainedness score. (Cached.)
		for my $candidate (@remaining) {
			next if defined $candidate->{score};
			my $sum = 0;
			my @sig = map {
				is_ArrayRef( $candidate->{signature_spec}{$_} ) ? @{ $candidate->{signature_spec}{$_} } : ();
			} qw(positional pos named);
			foreach my $type ( @sig ) {
				next unless is_Object $type;
				my @real_parents = grep !$_->_is_null_constraint, $type, $type->parents;
				$sum += @real_parents;
			}
			$candidate->{score} = $sum;
		}
		# Only keep those with (equal) highest score
		@remaining = sort { $b->{score} <=> $a->{score} } @remaining;
		my $max_score = $remaining[0]->{score};
		@remaining = grep { $_->{score} == $max_score } @remaining;
	}
	
	if (@remaining > 1) {
		# Only keep those from the most derived class
		no warnings qw(uninitialized numeric);
		@remaining = sort { $b->{height} <=> $a->{height} } @remaining;
		my $max_score = $remaining[0]->{height};
		@remaining = grep { $_->{height} == $max_score } @remaining;
	}
	
	if (@remaining > 1) {
		# Only keep those from the most non-role-like packages
		no warnings qw(uninitialized numeric);
		@remaining = sort { $a->{copied} <=> $b->{copied} } @remaining;
		my $min_score = $remaining[0]->{copied};
		@remaining = grep { $_->{copied} == $min_score } @remaining;
	}
	
	if (@remaining > 1) {
		# Argh! Still got multiple candidates! Just choose whichever
		# was declared first...
		no warnings qw(uninitialized numeric);
		@remaining = sort { $a->{declaration_order} <=> $b->{declaration_order} } @remaining;
		@remaining = ($remaining[0]);
	}
	
	# This is filled in each call. Clean it up, just in case.
	delete $_->{height} for @$candidates;
	
	wantarray or die 'MUST BE CALLED IN LIST CONTEXT';
	
	return unless @remaining;
	
	my $sig_code  = $remaining[0]{compiled}{closure};
	return ( $remaining[0], $returns{"$sig_code"} );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Sub::MultiMethod - yet another implementation of multimethods

=head1 SYNOPSIS

How to generate JSON (albeit with very naive string quoting) using
multimethods:

  use v5.20;
  use strict;
  use warnings;
  use experimental 'signatures';
  
  package My::JSON {
    use Moo;
    use Sub::MultiMethod qw(multimethod);
    use Types::Standard -types;
    
    multimethod stringify => (
      positional => [ Undef ],
      code       => sub ( $self, $undef ) {
        return 'null';
      },
    );
    
    multimethod stringify => (
      positional => [ ScalarRef[Bool] ],
      code       => sub ( $self, $bool ) {
        return $$bool ? 'true' : 'false';
      },
    );
    
    multimethod stringify => (
      alias      => "stringify_str",
      positional => [ Str ],
      code       => sub ( $self, $str ) {
        return sprintf( q<"%s">, quotemeta($str) );
      },
    );
    
    multimethod stringify => (
      positional => [ Num ],
      code       => sub ( $self, $n ) {
        return $n;
      },
    );
    
    multimethod stringify => (
      positional => [ ArrayRef ],
      code       => sub ( $self, $arr ) {
        return sprintf(
          q<[%s]>,
          join( q<,>, map( $self->stringify($_), @$arr ) )
        );
      },
    );
    
    multimethod stringify => (
      positional => [ HashRef ],
      code       => sub ( $self, $hash ) {
        return sprintf(
          q<{%s}>,
          join(
            q<,>,
            map sprintf(
              q<%s:%s>,
              $self->stringify_str($_),
              $self->stringify( $hash->{$_} )
            ), sort keys %$hash,
          )
        );
      },
    );
  }
  
  my $json = My::JSON->new;
  
  say $json->stringify( {
    foo  => 123,
    bar  => [ 1, 2, 3 ],
    baz  => \1,
    quux => { xyzzy => 666 },
  } );

While this example requires Perl 5.20+, Sub::MultiMethod is tested and works
on Perl 5.8.1 and above.

=head1 DESCRIPTION

Sub::MultiMethod focusses on implementing the dispatching of multimethods
well and is less concerned with providing a nice syntax for setting them
up. That said, the syntax provided is inspired by Moose's C<has> keyword
and hopefully not entirely horrible.

Sub::MultiMethod has much smarter dispatching than L<Kavorka>, but the
tradeoff is that this is a little slower. Overall, for the JSON example
in the SYNOPSIS, Kavorka is about twice as fast. (But with Kavorka, it
would quote the numbers in the output because numbers are a type of string,
and that was declared first!)

=head2 Functions

Sub::MultiMethod exports nothing by default. You can import the functions
you want by listing them in the C<use> statement:

  use Sub::MultiMethod "multimethod";

You can rename functions:

  use Sub::MultiMethod "multimethod" => { -as => "mm" };

You can import everything using C<< -all >>:

  use Sub::MultiMethod -all;

Sub::MultiMethod also offers an API for setting up multimethods for a
class, in which case, you don't need to import anything.

=head3 C<< multimethod $name => %spec >>

The specification supports the same options as L<Type::Params> v2
to specify a signature for the method, plus a few Sub::MultiMethod-specific
options. Any options not included in the list below are passed through to
Type::Params. (The options C<goto_next>, C<on_die>, C<message>, and
C<want_*> are not supported.)

=over

=item C<< code >> I<< (CodeRef) >>

Required.

The sub to dispatch to. It will receive parameters in C<< @_ >> as you
would expect, but these parameters have been passed through the signature
already, so will have had defaults and coercions applied.

An example for positional parameters:

  code => sub ( $self, $prefix, $match, $output ) {
    print { $output } $prefix;
    ...;
  },

An example for named parameters:

  code => sub ( $self, $arg ) {
    print { $arg->output } $arg->prefix;
    ...;
  },

Note that C<< $arg >> is an object with methods for each named parameter.

Corresponding examples for older versions of Perl without signature support.

  code => sub {
    my ( $self, $prefix, $match, $output ) = @_;
    print { $output } $prefix;
    ...;
  },

And:

  code => sub {
    my ( $self, $arg ) = @_;
    print { $arg->output } $arg->prefix;
    ...;
  },

=item C<< signature >> I<< (CodeRef) >>

Optional.

If C<signature> is set, then Sub::MultiMethod won't use L<Type::Params>
to build a signature for this multimethod candidate. It will treat the
coderef as an already-built signature.

A coderef signature is expected to take C<< @_ >>, throw an exception if
the arguments cannot be handled, and return C<< @_ >> (possibly after some
manipulation).

=item C<< alias >> I<< (Str|ArrayRef[Str]) >>

Optional.

Installs an alias for the candidate, bypassing multimethod dispatch. (But not
bypassing the checks, coercions, and defaults in the signature!)

=item C<< method >> I<< (Bool) >>

Optional, defaults to 1.

Indicates whether the multimethod should be treated as a method (i.e. with an
implied C<< $self >>). Defaults to true, but C<< method => 0 >> can be
given if you want multifuncs with no invocant.

Multisubs where some candidates are methods and others are non-methods are
not currently supported! (And probably never will be.)

=item C<< score >> I<< (Int) >>

Optional.

Overrides the constrainedness score calculated as described in the dispatch
technique. Most scores calculated that way will typically between 0 and 100.
Setting a score manually to something very high (e.g. 9999) will pretty much
guarantee that it gets chosen over other candidates when multiple signatures
match. Setting it to something low (e.g. -1) will mean it gets avoided.

=item C<< no_dispatcher >> I<< (Bool) >>

Optional. Defaults to true in roles, false otherwise.

If set to true, Sub::MultiMethods will register the candidate method
but won't install a dispatcher. You should mostly not worry about this
and accept the default.

=back

=head3 C<< monomethod $name => %spec >>

C<< monomethod($name, %spec) >> is basically just a shortcut for
C<< multimethod(undef, alias => $name, %spec) >> though with error
messages which don't mention it being an alias.

=head3 C<< multifunction $name => %spec >>

Like C<multimethod> but defaults to C<< method => 0 >>.

=head3 C<< monofunction $name => %spec >>

Like C<monomethod> but defaults to C<< method => 0 >>.

=head2 Dispatch Technique

When a multimethod is called, a list of packages to inspect for candidates
is obtained by crawling C<< @ISA >>. (For multifuncs, C<< @ISA >> is ignored.)

All candidates for the invoking class and all parent classes are considered.

If any parent class includes a mono-method (i.e. not a multimethod) of the
same name as this multimethod, then it is considered to have override any
candidates further along the C<< @ISA >> chain. (With multiple inheritance,
this could get confusing though!) Those further candidates will not be
considered, however the mono-method will be considered to be a candidate,
albeit one with a very low score. (See scoring later.)

Any candidates where it is clear they will not match based on parameter
count will be discarded immediately.

After that, the signatures of each are tried. If they throw an error, that
candidate will be discarded.

If there are still multiple possible candidates, they will be sorted based
on how constrained they are.

To determine how constrained they are, every type constraint in their
signature is assigned a score. B<Any> is 0. B<Defined> inherits from
B<Any>, so has score 1. B<Value> inherits from B<Defined>, so has score 2.
Etc. Some types inherit from a parent but without further constraining
the parent. (For example, B<Item> inherits from B<Any> but doesn't place
any additional constraints on values.) In these cases, the child type
has the same score as its parent. All these scores are added together
to get a single score for the candidate. For candidates where the
signature is a coderef, this is essentially a zero score for the
signature unless a score was specified explicitly.

If multiple candidates are equally constrained, child class candidates
beat parent class candidates; class candidates beat role candidates;
and the candidate that was declared earlier wins.

Method-resolution order (DFS/C3) is respected, though in Perl 5.8 under
very contrived conditions (calling a sub as a function when it was
defined as a method, but not passing a valid invocant as the first
parameter), MRO may not always work correctly.

Note that invocants are not part of the signature, so not taken into
account when calculating scores, but because child class candidates
beat parent class candidates, they should mostly behave as expected.

After this, there should be one preferred candidate or none. If there is
none, an error occurs. If there is one, that candidate is dispatched to
using C<goto> so there is no trace of Sub::MultiMethod in C<caller>. It
gets passed the result from checking the signature earlier as C<< @_ >>.

=head3 Roles

As far as I'm aware, Sub::MultiMethod is the only multimethod implementation
that allows multimethods imported from roles to integrate into a class.

  use v5.12;
  use strict;
  use warnings;
  
  package My::RoleA {
    use Moo::Role;
    use Sub::MultiMethod qw(multimethod);
    use Types::Standard -types;
    
    multimethod foo => (
      positional => [ HashRef ],
      code       => sub { return "A" },
      alias      => "foo_a",
    );
  }
  
  package My::RoleB {
    use Moo::Role;
    use Sub::MultiMethod qw(multimethod);
    use Types::Standard -types;
    
    multimethod foo => (
      positional => [ ArrayRef ],
      code       => sub { return "B" },
    );
  }
  
  package My::Class {
    use Moo;
    use Sub::MultiMethod qw(multimethod);
    use Types::Standard -types;
    
    with qw( My::RoleA My::RoleB );
    
    multimethod foo => (
      positional => [ HashRef ],
      code       => sub { return "C" },
    );
  }
  
  my $obj = My::Class->new;
  
  say $obj->foo_a( {} );  # A (alias defined in RoleA)
  say $obj->foo( [] );    # B (candidate from RoleB)
  say $obj->foo( {} );    # C (Class overrides candidate from RoleA)

All other things being equal, candidates defined in classes should
beat candidates imported from roles.

=head2 CodeRef multimethods

The C<< $name >> of a multimethod may be a scalarref, in which case
C<multimethod> will install the multimethod as a coderef into the
scalar referred to. Example:

  my ($coderef, $otherref);
  
  multimethod \$coderef => (
    method     => 0,
    positional => [ ArrayRef ],
    code       => sub { say "It's an arrayref!" },
  );
  
  multimethod \$coderef => (
    method     => 0,
    alias      => \$otherref,
    positional => [ HashRef ],
    code       => sub { say "It's a hashref!" },
  );
  
  $coderef->( [] );
  $coderef->( {} );
  
  $otherref->( {} );

The C<< $coderef >> and C<< $otherref >> variables will actually end up
as blessed coderefs so that some tidy ups can take place in C<DESTROY>.

=head2 API

Sub::MultiMethod avoids cute syntax hacks because those can be added by
third party modules. It provides an API for these modules.

Brief note on terminology: when you define multimethods in a class,
each possible signature+coderef is a "candidate". The method which
makes the decision about which candidate to call is the "dispatcher".
Roles will typically have candidates but no dispatcher. Classes will
need dispatchers setting up for each multimethod.

=over

=item C<< Sub::MultiMethod->install_candidate($target, $sub_name, %spec) >>

C<< $target >> is the class (package) name being installed into.

C<< $sub_name >> is the name of the method.

C<< %spec >> is the multimethod spec. If C<< $target >> is a role, you
probably want to include C<< no_dispatcher => 1 >> as part of the spec.

=item C<< Sub::MultiMethod->install_dispatcher($target, $sub_name, $is_method) >>

C<< $target >> is the class (package) name being installed into.

C<< $sub_name >> is the name of the method.

C<< $is_method >> is an integer/boolean.

This rarely needs to be manually called as C<install_candidate> will do it
automatically.

=item C<< Sub::MultiMethod->install_monomethod($target, $sub_name, %spec) >>

Installs a regular (non-multimethod) method into the target.

=item C<< Sub::MultiMethod->copy_package_candidates(@sources => $target) >>

C<< @sources >> is the list of packages to copy candidates from.

C<< $target >> is the class (package) name being installed into.

Sub::MultiMethod will use L<Role::Hooks> to automatically copy candidates
from roles to consuming classes if your role implementation is supported.
(Supported implementations include Role::Tiny, Role::Basic, Moo::Role,
Moose::Role, and Mouse::Role, plus any role implementations that extend
those. If your role implementation is something else, then when you consume
a role into a class you may need to copy the candidates from the role to
the class.)

=item C<< Sub::MultiMethod->install_missing_dispatchers($target) >>

Should usually be called after C<copy_package_candidates>, unless
C<< $target >> is a role. 

Again, this is unnecessary if your role implementation is supported
by Role::Hooks.

=item C<< Sub::MultiMethod->get_multimethods($target) >>

Returns the names of all multimethods declared for a class or role,
not including any parent classes.

=item C<< Sub::MultiMethod->has_multimethod_candidates($target, $method_name) >>

Indicates whether the class or role has any candidates for a multimethod.
Does not include parent classes.

=item C<< Sub::MultiMethod->get_multimethod_candidates($target, $method_name) >>

Returns a list of candidate spec hashrefs for the method, not including
candidates from parent classes.

=item C<< Sub::MultiMethod->get_all_multimethod_candidates($target, $method_name, $is_method) >>

Returns a list of candidate spec hashrefs for the method, including candidates
from parent classes (unless C<< $is_method >> is false, because non-methods
shouldn't be inherited).

=item C<< Sub::MultiMethod->known_dispatcher($coderef) >>

Returns a boolean indicating whether the coderef is known to be a multimethod
dispatcher.

=item C<< Sub::MultiMethod->pick_candidate(\@candidates, \@args) >>

Returns a list of two items: first the winning candidate from an array of specs,
given the args and invocants, and second the modified args after coercion has
been applied.

This is basically how the dispatcher for a method works:

  my $pkg = __PACKAGE__;
  if ( $ismethod ) {
    $pkg = Scalar::Util::blessed( $_[0] ) || $_[0];
  }
  
  my ( $winner, $new_args ) = 'Sub::MultiMethod'->pick_candidate(
    [
      'Sub::MultiMethod'->get_all_multimethod_candidates(
        $pkg,
        $sub,
        $ismethod,
      )
    ],
    \@_,
  );
  
  $winner->{code}->( @$new_args );

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Sub-MultiMethod>.

=head1 SEE ALSO

L<Class::Multimethods> - uses Perl classes and ref types to dispatch.
No syntax hacks but the fairly nice syntax shown in the pod relies on
C<use strict> being switched off! Need to quote a few more things otherwise.

L<Class::Multimethods::Pure> - similar to Class::Multimethods but with
a more complex type system and a more complex dispatch method.

L<Logic> - a full declarative programming framework. Overkill if all
you want is multimethods. Uses source filters.

L<Dios> - object oriented programming framework including multimethods.
Includes a full type system and Keyword::Declare-based syntax. Pretty
sensible dispatch technique which is almost identical to
Sub::MultiMethod. Much much slower though, at both compile time and
runtime.

L<MooseX::MultiMethods> - uses Moose type system and Devel::Declare-based
syntax. Not entirely sure what the dispatching method is.

L<Kavorka> - I wrote this, so I'm allowed to be critical. Type::Tiny-based
type system. Very naive dispatching; just dispatches to the first declared
candidate that can handle it rather than trying to find the "best". It is
fast though.

L<Sub::Multi::Tiny> - uses Perl attributes to declare candidates to
be dispatched to. Pluggable dispatching, but by default uses argument
count.

L<Sub::Multi> - syntax wrapper around Class::Multimethods::Pure?

L<Sub::SmartMatch> - kind of abandoned and smartmatch is generally seen
as teh evilz these days.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

