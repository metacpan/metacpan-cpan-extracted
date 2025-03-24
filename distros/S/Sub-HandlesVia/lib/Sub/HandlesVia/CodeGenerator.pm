use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::CodeGenerator;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.050001';

use Sub::HandlesVia::Mite -all;

has toolkit => (
	is => ro,
);

has target => (
	is => ro,
);

has attribute => (
	is => ro,
);

has attribute_spec => (
	is => ro,
	isa => 'HashRef',
);

has isa => (
	is => ro,
);

has coerce => (
	is => ro,
	isa => 'Bool',
);

has env => (
	is => ro,
	isa => 'HashRef',
	default => \ '{}',
	default_is_trusted => true,
);

has sandboxing_package => (
	is => ro,
	isa => 'Str|Undef',
	default => sprintf( '%s::__SANDBOX__', __PACKAGE__ ),
	default_is_trusted => true,
);

has [ 'generator_for_slot', 'generator_for_get', 'generator_for_set', 'generator_for_default' ] => (
	is => ro,
	isa => 'CodeRef',
);

has generator_for_args => (
	is => ro,
	isa => 'CodeRef',
	builder => sub {
		return sub {
			'@_[1..$#_]';
		};
	},
	default_is_trusted => true,
);

has generator_for_arg => (
	is => ro,
	isa => 'CodeRef',
	builder => sub {
		return sub {
			@_==2 or die;
			my $n = pop;
			"\$_[$n]";
		};
	},
	default_is_trusted => true,
);

has generator_for_argc => (
	is => ro,
	isa => 'CodeRef',
	builder => sub {
		return sub {
			'(@_-1)';
		};
	},
	default_is_trusted => true,
);

has generator_for_currying => (
	is => ro,
	isa => 'CodeRef',
	builder => sub {
		return sub {
			@_==2 or die;
			my $arr = pop;
			"splice(\@_,1,0,$arr);";
		};
	},
	default_is_trusted => true,
);

has generator_for_usage_string => (
	is => ro,
	isa => 'CodeRef',
	builder => sub {
		return sub {
			@_==3 or die;
			shift;
			my $method_name = shift;
			my $guts = shift;
			"\$instance->$method_name($guts)";
		};
	},
	default_is_trusted => true,
);

has generator_for_self => (
	is => ro,
	isa => 'CodeRef',
	builder => sub {
		return sub {
			'$_[0]';
		};
	},
	default_is_trusted => true,
);

has generator_for_type_assertion => (
	is => ro,
	isa => 'CodeRef',
	builder => sub {
		return sub {
			my ( $gen, $env, $type, $varname ) = @_;
			my $i = 0;
			my $type_varname = sprintf '$shv_type_constraint_%d', $type->{uniq};
			$env->{$type_varname} = \$type;
			if ( $gen->coerce and $type->has_coercion ) {
				if ( $type->coercion->can_be_inlined ) {
					return sprintf '%s=%s;%s;',
						$varname,
						$type->coercion->inline_coercion($varname),
						$type->inline_assert( $varname, $type_varname );
				}
				else {
					return sprintf '%s=%s->assert_coerce(%s);',
						$varname, $type_varname, $varname;
				}
			}
			return $type->inline_assert( $varname, $type_varname );
		};
	},
	default_is_trusted => true,
);

has generator_for_error => (
	is => ro,
	isa => 'CodeRef',
	builder => sub {
		return sub {
			my ( $gen, $error ) = @_;
			sprintf 'do { require Carp; Carp::croak(%s) }', $error;
		};
	},
	default_is_trusted => true,
);

has generator_for_prelude => (
	is => ro,
	isa => 'CodeRef',
	builder => sub {
		return sub { '' };
	},
	default_is_trusted => true,
);

has method_installer => (
	is => rw,
	isa => 'CodeRef',
);

has _override => (
	is => rw,
	init_arg => undef,
);

has is_method => (
	is => ro,
	default => true,
);

has get_is_lvalue => (
	is => ro,
	default => false,
);

has set_checks_isa => (
	is => ro,
	default => false,
);

has set_strictly => (
	is => ro,
	default => true,
);

my $REASONABLE_SCALAR = qr/^
	\$                 # scalar access
	[^\W0-9]\w*        # normal-looking variable name (including $_)
	(?:                # then...
		(?:\-\>)?       #     dereference maybe
		[\[\{]          #     opening [ or {
		[\'\"]?         #     quote maybe
		\w+             #     word characters (includes digits)
		[\'\"]?         #     quote maybe
		[\]\}]          #     closing ] or }
	){0,3}             # ... up to thrice
	$/x;

my @generatable_things = qw(
	slot get set default arg args argc currying usage_string self
	type_assertion error prelude
);

for my $thing ( @generatable_things ) {
	my $generator = "generator_for_$thing";
	my $method_name = "generate_$thing";
	my $method = sub {
		my $gen = shift;
		local ${^GENERATOR} = $gen;
		
		if ( @{ $gen->_override->{$thing} || [] } ) {
			my $coderef = pop @{ $gen->_override->{$thing} };
			my $guard   = guard {
				push @{ $gen->_override->{$thing} ||= [] }, $coderef;
			};
			return $gen->$coderef( @_ );
		}
		
		return $gen->$generator->( $gen, @_ );
	};
	no strict 'refs';
	*$method_name = $method;
}

sub attribute_name {
	my $self = shift;
	my $attr = $self->attribute;
	
	return $attr
		if !ref $attr;
		
	return sprintf '$instance->%s', $attr->[0]
		if ref($attr) eq 'ARRAY';
	
	return '$attribute_value';
}

sub _start_overriding_generators {
	my $self = shift;
	$self->_override( {} );
	return guard {
		$self->_override( {} );
	};
}

{
	my %generatable_thing = map +( $_ => 1 ), @generatable_things;
	
	sub _add_generator_override {
		my ( $self, %overrides ) = @_;
		while ( my ( $key, $value ) = each %overrides ) {
			next if !defined $value;
			next if !$generatable_thing{$key};
			push @{ $self->_override->{$key} ||= [] }, $value;
		}
		return $self;
	}
}

sub generate_and_install_method {
	my ( $self, $method_name, $handler ) = @_;
	
	$self->install_method(
		$method_name,
		$self->generate_coderef_for_handler( $method_name, $handler ),
	);
}

{
	my $sub_rename;
	if ( eval { require Sub::Util } ) {
		$sub_rename = Sub::Util->can('set_subname');
	}
	elsif ( eval { require Sub::Name } ) {
		$sub_rename = Sub::Name->can('subname');
	}
	
	sub install_method {
		my ( $self, $method_name, $coderef ) = @_;
		my $target = $self->target;
		
		eval {
			$coderef = $sub_rename->( "$target\::$method_name", $coderef )
		} if ref $sub_rename;
		
		if ( $self->method_installer ) {
			$self->method_installer->( $method_name, $coderef );
		}
		else {
			no strict 'refs';
			*{"$target\::$method_name"} = $coderef;
		}
	}
}

sub generate_coderef_for_handler {
	my ( $self, $method_name, $handler ) = @_;
	
	my $ec_args = $self->_generate_ec_args_for_handler( $method_name, $handler );
	
#	warn "#### $method_name";
#	warn join("\n", @{$ec_args->{source}});
#	for my $key (sort keys %{$ec_args->{environment}}) {
#		warn ">> $key : ".ref($ec_args->{environment}{$key});
#		if ( ref($ec_args->{environment}{$key}) eq 'REF' and ref(${$ec_args->{environment}{$key}}) eq 'CODE' ) {
#			require B::Deparse;
#			warn B::Deparse->new->coderef2text(${$ec_args->{environment}{$key}});
#		}
#	}
	
	require Eval::TypeTiny;
	Eval::TypeTiny::eval_closure( %$ec_args );
}

sub _generate_ec_args_for_handler {
	my ( $self, $method_name, $handler ) = @_;
	
	# Later on, we might need to override the generators for
	# arg, argc, args, set, etc.
	#
	my $guard = $self->_start_overriding_generators;
	
	# Make a COPY of $self->env!
	#
	my $env = { %{$self->env} };
	
	# Preamble code.
	#
	my $code = [
		'sub {',
	];
	
	push @$code, sprintf( 'package %s;', $self->sandboxing_package )
		if $self->sandboxing_package;

	# Need to maintain state between following method calls. A proper
	# object might be nice, but a hashref will do for now.
	#
	my $state = {
		signature_check_needed  => true,  # hasn't been done yet
		final_type_check_needed => $handler->is_mutator,
		getter                  => scalar($self->generate_get),
		getter_is_lvalue        => $self->get_is_lvalue,
		template_wrapper        => undef, # nothing yet
		add_later               => undef, # nothing yet
		shifted_self            => false,
	};

#	use Hash::Util qw( lock_ref_keys );
#	lock_ref_keys( $state );
	
	my @args = (
		$method_name,  # Intended name for the coderef being generated
		$handler,      # Info about the functionality being delegated
		$env,          # Variables which need to be closed over
		$code,         # Lines of code in the method
		$state,        # Shared state while building method. (Minimal!)
	);
	$self
		->_handle_sigcheck( @args )               # check method sigs
		->_handle_prelude( @args )                # insert any prelude
		->_handle_shiftself( @args )              # $self = shift
		->_handle_currying( @args )               # push curried values to @_
		->_handle_additional_validation( @args )  # additional type checks
		->_handle_getter_code( @args )            # optimize calling getter
		->_handle_setter_code( @args )            # make calling setter safer
		->_handle_template( @args )               # perform code substitutes
		->_handle_chaining( @args );              # return $self if requested
	
	# Postamble code. Can't really do much here because the template
	# might want to be able to return something.
	#
	push @$code, "}";
	
	# Allow the handler to inject variables into the environment.
	# Rarely needed.
	#
	$handler->_tweak_env( $env );
	
	return {
		source      => $code,
		environment => $env,
		description => sprintf(
			"%s=%s",
			$method_name || '__ANON__',
			$handler->name,
		),
	};
}

sub _handle_sigcheck {
	my ( $self, $method_name, $handler, $env, $code, $state ) = @_;

	# If there's a proper signature for the method...
	#
	if ( @{ $handler->signature || [] } ) {
		
		# Generate code using Type::Params to check the signature.
		# We also need to close over the signature.
		#
		require Type::Params;
		unshift @$code, 'my $__sigcheck;';
		$env->{'@__sig'} = $handler->signature;
		if ( $state->{shifted_self} ) {
			push @$code, '$__sigcheck||=Type::Params::compile(@__sig);@_=&$__sigcheck;';
		}
		else {
			push @$code, '$__sigcheck||=Type::Params::compile(1, @__sig);@_=&$__sigcheck;';
		}
		
		# As we've now inserted a signature check, we can stop worrying
		# about signature checks.
		#
		$state->{signature_check_needed} = 0;
	}
	# There is no proper signature, but there's still check the
	# arity of the method.
	#
	else {
		# What is the arity?
		#
		my $min_args = $handler->min_args || 0;
		my $max_args = $handler->max_args;
		
		my $plus = 1;
		if ( $state->{shifted_self} ) {
			$plus = 0;
		}
		
		# What usage message do we want to print if wrong arity?
		#
		my $usg = $self->generate_error( sprintf(
			' "Wrong number of parameters; usage: " . %s ',
			B::perlstring( $self->generate_usage_string( $method_name, $handler->usage ) ),
		) );
		
		# Insert the check into the code.
		#
		if (defined $min_args and defined $max_args and $min_args==$max_args) {
			push @$code, sprintf('@_==%d or %s;', $min_args + $plus, $usg);
		}
		elsif (defined $min_args and defined $max_args) {
			push @$code, sprintf('(@_ >= %d and @_ <= %d) or %s;', $min_args + $plus, $max_args + $plus, $usg);
		}
		elsif (defined $min_args and $min_args > 0) {
			push @$code, sprintf('@_ >= %d or %s;', $min_args + $plus, $usg);
		}
		
		# We are still lacking a proper signature check though, so note
		# that in the state. The information can be used by
		# additional_validation coderefs.
		#
		$state->{signature_check_needed} = true;
	}
	
	return $self;
}

sub _handle_prelude {
	my ( $self, $method_name, $handler, $env, $code, $state ) = @_;
	push @$code, grep !!$_, $self->generate_prelude();
	return $self;
}

sub _handle_shiftself {
	my ( $self, $method_name, $handler, $env, $code, $state ) = @_;

	# Handlers which use @ARG will benefit from shifting $self
	# off @_, but for other handlers, this will just slow compilation
	# down (but not much).
	#
	return $self
		unless $handler->curried || $handler->prefer_shift_self;

	# Shift off the invocant.
	#
	push @$code, 'my $shv_self=shift;';
	
	$self->_add_generator_override(
	
		# Override $ARG[$n] because the array has been reindexed.
		#
		arg  => sub { my ($gen, $n) = @_; $gen->generate_arg( $n - 1 ) },
		
		# Overrride @ARG to point to the whole array. This is the
		# real speed-up!
		#
		args => sub { '@_' },
		
		# Override #ARG to no longer subtract 1.
		#
		argc => sub { 'scalar(@_)' },
		
		# $SELF is now '$shv_self'.
		#
		self => sub { '$shv_self' },
		
		# The default currying callback will splice the list into
		# @_ at index 1. Instead unshift the list at the start of @_.
		#
		currying => sub {
			my ($gen, $list) = @_;
			"CORE::unshift(\@_, $list);";
		},
	);
	
	# Getter was cached in $state and needs update.
	#
	$state->{getter} = $self->generate_get;
	$state->{shifted_self} = true;
	
	return $self;
}

# Insert code into method for currying.
#
sub _handle_currying {
	my ( $self, $method_name, $handler, $env, $code, $state ) = @_;
	
	if ( my $curried = $handler->curried ) {
		
		# If the curried values are non-simple, we close over an array
		# called @curry.
		#
		if ( grep ref, @$curried ) {
			
			# Note that generate_currying will generate code that unshifts whatever
			# parameters it is given onto @_.
			push @$code, $self->generate_currying('@curry');
			$env->{'@curry'} = $curried;
		}
		# If it's just strings, numbers, and undef, it should be pretty
		# trivial to hard-code the values into the generated Perl string.
		#
		else {
			require B;
			my $values = join(
				',',
				map { defined($_) ? B::perlstring($_) : 'undef' } @$curried,
			);
			push @$code, $self->generate_currying( "($values)" );
		}
	}
	
	return $self;
}

sub _handle_additional_validation {
	my ( $self, $method_name, $handler, $env, $code, $state ) = @_;
	
	# If the handler specifies no validation needed, or the attribute
	# simply has no type check, we don't need to check the type of the
	# final attribute value.
	#
	if ( $handler->no_validation_needed or not $self->isa ) {
		$state->{final_type_check_needed} = false;
	}
	
	# The handler can define some additional validation to be performed
	# on arguments either now or later, such that if this additional
	# validation is performed, the type check we were planning later
	# will be known to be unnecessary.
	#
	# An example for this is that is the attribute value is already an
	# arrayref of numbers, and we're pushing a new value onto it, by checking
	# up front that the INCOMING value is a number, it becomes unnecessary
	# to check the whole arrayref contains numbers after the push.
	#
	# Not all handlers define an additional_validation coderef to do
	# this, because in many cases it doesn't make sense to.
	#
	# Also if we've already decided a final type check isn't needed, we
	# can skip this step.
	#
	if ( $state->{final_type_check_needed}
	and  defined $handler->additional_validation ) {
		
		my $real_av_method = $handler->_real_additional_validation;
		
		# The additional_validation coderef is called as a method and takes
		# two additional parameters:
		#
		my $opt = $handler->$real_av_method(
			!$state->{signature_check_needed},  # $sig_was_checked
			$self,                              # $gen
		);
		$opt ||= {}; # can return undef
		
		# The additional_validation coderef will often generate code which
		# coerces incoming data, thus moving it from @_ to some other array.
		# This means that the generators for @ARG, $ARG, etc will need to
		# need to be overridden to point to the new array.
		#
		$self->_add_generator_override( %$opt );
		
		# The additional_validation coderef may supply extra variables
		# to close over.
		#
		$env->{$_} = $opt->{env}{$_}
			for keys %{ $opt->{env} || {} };
		
		# The additional_validation coderef will normally generate
		# new code.
		#
		if ( defined $opt->{code} ) {
			
			# Code can be inserted into the generated method straight away,
			# or may need to be inserted in a special placeholder position
			# later.
			#
			$opt->{add_later}
				? ( $state->{add_later} = $opt->{code} )
				: push( @$code, $opt->{code} );
			
			# Final type check is often no longer needed.
			#
			$state->{final_type_check_needed} = $opt->{final_type_check_needed} || false;
		}
	}
	
	return $self;
}

sub _handle_getter_code {
	my ( $self, $method_name, $handler, $env, $code, $state ) = @_;
	
	# If there's a complicated way to fetch the attribute value (perhaps
	# involving a lazy builder)...
	#
	if ( $state->{getter} !~ $REASONABLE_SCALAR ) {
		
		# And if it's definitely a reference anyway, then get it straight away,
		# and store it in $shv_ref_invocant so we don't have to keep doing the
		# complicated thing.
		#
		if ( $handler->name =~ /^(Array|Hash):/ ) {
			push @$code, "my \$shv_ref_invocant = do { $state->{getter} };";
			$state->{getter} = '$shv_ref_invocant';
			$state->{getter_is_lvalue} = true;
		}
		
		# Alternatively, unless the handler doesn't want us to, or the template
		# doesn't want to get the attribute value anyway, then we'll do something
		# similar. Here it can't be used as an lvalue though.
		#
		elsif ( $handler->allow_getter_shortcuts
		and $handler->template.($handler->lvalue_template||'') =~ /\$GET/ ) {
			( my $g = $state->{getter} ) =~ s/%/%%/g;
			$state->{template_wrapper} = "do { my \$shv_real_invocant = $g; %s }";
			$state->{getter} = '$shv_real_invocant';
		}
	}
	
	return $self;
}

sub _handle_setter_code {
	my ( $self, $method_name, $handler, $env, $code, $state ) = @_;
	
	# If a type check is needed, but the setter doesn't do type checks,
	# then override the setter. Now the setter does the type check, so
	# we no longer need to worry about it.
	#
	# XXX: I don't think any of the tests currently exercise this.
	#
	if ( $state->{final_type_check_needed} and not $self->set_checks_isa ) {
		$self->_add_generator_override( set => sub {
			my ( $me, $value_code ) = @_;
			$me->generate_set( sprintf(
				'do { my $shv_final_unchecked = %s; %s }',
				$value_code,
				$me->generate_type_assertion( $env, $me->isa, '$shv_final_unchecked' ),
			) );
		} );
		
		# In this case we can no longer use the getter as an lvalue, if we
		# ever could.
		#
		$state->{getter_is_lvalue} = false;
		
		# Stop worrying about the final type check. The setter does that now.
		#
		$state->{final_type_check_needed} = false;
	}
	
	return $self;
}

sub _handle_template {
	my ( $self, $method_name, $handler, $env, $code, $state ) = @_;
	
	my $template;
	
	# If the getter is an lvalue, the handler has a special template
	# for lvalues, we haven't been told to set strictly, and we have taken
	# care of any type checks, then use the special lvalue template.
	#
	if ( $state->{getter_is_lvalue}
	and  $handler->lvalue_template
	and  !$self->set_strictly
	and  !$state->{final_type_check_needed} ) {
		$template = $handler->lvalue_template;
	}
	else {
		$template = $handler->template;
	}
	
	# Perform substitutions of special codes in the template string.
	#
	$template =~ s/\$SLOT/$self->generate_slot()/eg;
	$template =~ s/\$GET/$state->{getter}/g;
	$template =~ s/\$ATTRNAME/$self->attribute_name()/eg;
	$template =~ s/\$ARG\[([0-9]+)\]/$self->generate_arg($1)/eg;
	$template =~ s/\$ARG/$self->generate_arg(1)/eg;
	$template =~ s/\#ARG/$self->generate_argc()/eg;
	$template =~ s/\@ARG/$self->generate_args()/eg;
	$template =~ s/⸨(.+?)⸩/$self->generate_error($1)/eg;
	$template =~ s/«(.+?)»/$self->generate_set($1)/eg;
	$template =~ s/\$DEFAULT/$self->generate_default($handler)/eg;
	$template =~ s/\$SELF/$self->generate_self()/eg;
	
	# Apply wrapper (if any). This wrapper is given
	# by _handle_getter_code (sometimes).
	#
	$template = sprintf( $state->{template_wrapper}, $template )
		if $state->{template_wrapper};
	
	# If validation needs to be added late...
	#
	$template =~ s/\"?____VALIDATION_HERE____\"?/$state->{add_later}/
		if defined $state->{add_later};
	
	push @$code, $template;
	
	return $self;
}

sub _handle_chaining {
	my ( $self, $method_name, $handler, $env, $code, $state ) = @_;
	
	# Will just insert a string like ';$_[0]' at the end
	#
	push @$code, ';' . $self->generate_self,
		if $handler->is_chainable;
	
	return $self;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Sub::HandlesVia::CodeGenerator - looks at a Handler and generates a string of Perl code for it

=head1 DESCRIPTION

B<< This module is part of Sub::HandlesVia's internal API. >>
It is mostly of interest to people extending Sub::HandlesVia.

Sub::HandlesVia toolkits create a code generator for each attribute they're
dealing with, and use the code generator to generate Perl code for one or
more delegated methods.

=head1 CONSTRUCTORS

=head2 C<< new( %attributes ) >>

Standard Moose-like constructor.

=head1 ATTRIBUTES

=head2 C<toolkit> B<Object>

The toolkit which made this code generator.

=head2 C<target> B<< ClassName|RoleName >>

The target package for generated methods.

=head2 C<sandboxing_package> B<< ClassName|RoleName|Undef >>

Package name to use as a sandbox; the default is usually fine.

=head2 C<attribute> B<< Str|ArrayRef >>

The attribute delegated to.

=head2 C<attribute_spec> B<< HashRef >>

Informational only.

=head2 C<is_method> B<< Bool >>

Indicates whether the generated code should be methods rather than functions.
This defaults to true, and false isn't really tested or well-defined.

=head2 C<env> B<< HashRef >>

Variables which need to be closed over when compiling coderefs.

=head2 C<isa> B<< Maybe[TypeTiny] >>

The type constraint for the attribute.

=head2 C<coerce> B<< Bool >>

Should the attribute coerce?

=head2 C<method_installer> B<CodeRef>

A coderef which can be called with C<< $method_name >> and C<< $coderef >>,
will install the method. Note that it isn't passed the package to install
into (which can be found in C<target>), so that would need to be closed
over.

=head2 C<generator_for_self> B<< CodeRef >>

A coderef which if called, generates a string like C<< '$_[0]' >>.

Has a sensible default.

All the C<generator_for_XXX> methods are called as methods, so have
the code generator object as an invocant.

=head2 C<generator_for_slot> B<< CodeRef >>

A coderef which if called, generates a string like C<< '$_[0]{attrname}' >>.

=head2 C<generator_for_get> B<< CodeRef >>

A coderef which if called, generates a string like C<< '$_[0]->attrname' >>.

=head2 C<generator_for_set> B<< CodeRef >>

A coderef which if called with a parameter, generates a string like
C<< "\$_[0]->_set_attrname( $parameter )" >>.

=head2 C<generator_for_simple_default> B<< CodeRef >>

A coderef which if called with a parameter, generates a string like
C<< 'undef' >> or C<< 'q[]' >> or C<< '{}' >>.

The parameter is a handler object, which offers a C<default_for_reset>
attribute which might be able to provide a useful fallback.

=head2 C<generator_for_args> B<< CodeRef >>

A coderef which if called, generates a string like C<< '@_[1..$#_]' >>.

Has a sensible default.

=head2 C<generator_for_argc> B<< CodeRef >>

A coderef which if called, generates a string like C<< '$#_' >>.

Has a sensible default.

=head2 C<generator_for_argc> B<< CodeRef >>

A coderef which if called with a parameter, generates a string like
C<< "\$_[$parameter + 1]" >>.

Has a sensible default.

=head2 C<generator_for_currying> B<< CodeRef >>

A coderef which if called with a parameter, generates a string like
C<< "splice(\@_,1,0,$parameter);" >>.

Has a sensible default.

=head2 C<generator_for_usage_string> B<< CodeRef >>

The default is this coderef:

  sub {
    @_==3 or die;
    shift;
    my $method_name = shift;
    my $guts = shift;
    return "\$instance->$method_name($guts)";
  }

=head2 C<generator_for_type_assertion> B<< CodeRef >>

Called as a method and passed a hashref compilation environment, a type
constraint, and a variable name. Generates code to assert that the variable
value meets the type constraint, with coercion if appropriate.

=head2 C<generator_for_error> B<< CodeRef >>

Called as a method and passed a Perl string which is an expression evaluating
to an error message. Generates code to throw the error.

=head2 C<generator_for_prelude> B<< CodeRef >>

By default is a coderef returning the empty string. Can be used to generate
some additional statements which will be inserted near the top of the
method being generated. (Typically after parameter checks but before
doing anything serious.) This can be used to unlock a read-only attribute,
for example.

=head2 C<get_is_lvalue> B<Bool>

Indicates wheter the code generated by C<generator_for_get>
will be suitable for used as an lvalue.

=head2 C<set_checks_isa> B<Bool>

Indicates wheter the code generated by C<generator_for_set>
will do type checks.

=head2 C<set_strictly> B<Bool>

Indicates wheter we want to ensure that the setter is always called,
and we should not try to bypass it, even if we have an lvalue getter.

=head1 METHODS

For each C<generator_for_XXX> attribute, there's a corresponding
C<generate_XXX> method to actually call the coderef, possibly including
additional processing.

=head2 C<< generate_and_install_method( $method_name, $handler ) >>

Given a handler and a method name, will generate a coderef for the handler
and install it into the target package.

=head2 C<< generate_coderef_for_handler( $method_name, $handler ) >>

As above, but just returns the coderef rather than installs it.

=head2 C<< install_method( $method_name, $coderef ) >>

Installs a coderef into the target package with the given name.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-sub-handlesvia/issues>.

=head1 SEE ALSO

L<Sub::HandlesVia>.

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
