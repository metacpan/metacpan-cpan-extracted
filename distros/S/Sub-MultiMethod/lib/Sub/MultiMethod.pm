use 5.008000;
use strict;
use warnings;

package Sub::MultiMethod;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.007';

use B ();
use Exporter::Shiny qw( multimethod multimethods_from_roles monomethod );
use Type::Params ();
use Types::Standard -types;

*_set_subname =
	eval { require Sub::Util;  \&Sub::Util::set_subname } ||
	eval { require Sub::Name;  \&Sub::Name::subname }     ||
	do   { sub { pop } } ;

{
	my %CANDIDATES;
	
	sub get_multimethods {
		my ($me, $target) = @_;
		sort keys %{ $CANDIDATES{$target} || {} };
	}
	
	sub get_multimethod_candidates {
		my ($me, $target, $method_name) = @_;
		@{ $CANDIDATES{$target}{$method_name} || [] };
	}
	
	sub has_multimethod_candidates {
		my ($me, $target, $method_name) = @_;
		scalar @{ $CANDIDATES{$target}{$method_name} || [] };
	}
	
	sub _add_multimethod_candidate {
		my ($me, $target, $method_name, $spec) = @_;
		push @{ $CANDIDATES{$target}{$method_name} ||= [] }, $spec;
		if ($spec->{method} != $CANDIDATES{$target}{$method_name}[0]{method}) {
			require Carp;
			Carp::carp(sprintf(
				"Added multimethod candidate for %s with method=>%d but expected method=>%d",
				$method_name,
				$spec->{method},
				$CANDIDATES{$target}{$method_name}[0]{method},
			));
		}
		$me;
	}
	
	sub get_all_multimethod_candidates {
		my ($me, $target, $method_name, $is_method) = @_;
		
		# Figure out which packages to consider when finding candidates.
		my @packages = $is_method
			? @{ mro::get_linear_isa($target) }
			: $target;
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
			else {
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
}

{
	my %DISPATCHERS;
	
	sub known_dispatcher {
		my ($me, $coderef) = @_;
		$DISPATCHERS{"$coderef"};
	}
	
	sub _mark_as_dispatcher {
		my ($me, $coderef) = @_;
		$DISPATCHERS{"$coderef"} = 1;
		$me;
	}
}

sub _generate_multimethod {
	my ($me, $name, $args, $globals) = (shift, @_);
	
	my $target = $globals->{into};
	!defined $target and die;
	ref $target and die;
	
	my $is_role = 0+!!$globals->{role};
	
	return sub {
		my ($sub_name, %spec) = @_;
		$me->install_candidate($target, $sub_name, no_dispatcher => $is_role, %spec);
	};
}

sub _generate_multimethods_from_roles {
	my ($me, $name, $args, $globals) = (shift, @_);
	
	my $target = $globals->{into};
	!defined $target and die;
	ref $target and die;
	
	my $is_role = 0+!!$globals->{role};
	
	return sub {
		my @roles = @_;
		$me->copy_package_candidates(@roles => $target);
		$me->install_missing_dispatchers($target) unless $is_role;
	};
}

sub _generate_monomethod {
	my ($me, $name, $args, $globals) = (shift, @_);
	
	my $target = $globals->{into};
	!defined $target and die;
	ref $target and die;
	
	my $is_role = 0+!!$globals->{role};
	
	return sub {
		my ($sub_name, %spec) = @_;
		$me->install_monomethod($target, $sub_name, no_dispatcher => 1, %spec);
	};
}

my %keep_while_copying = qw(
	method                  1
	declaration_order       1
	signature               1
	code                    1
	score                   1
	named                   1
);
sub copy_package_candidates {
	my $me = shift;
	my (@sources) = @_;
	my $target = pop @sources;
	
	for my $source (@sources) {
		for my $method_name ($me->get_multimethods($source)) {
			for my $candidate ($me->get_multimethod_candidates($source, $method_name)) {
				my %new = map {
					$keep_while_copying{$_}
						? ( $_ => $candidate->{$_} )
						: ()
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
	my $me = shift;
	my ($target, $sub_name, %spec) = @_;
	
	$spec{alias} ||= [];
	$spec{alias} = [$spec{alias}] if !ref $spec{alias};
	unshift @{$spec{alias}}, $sub_name;
	
	$me->install_candidate($target, undef, no_dispatcher => 1, %spec, is_monomethod => 1);
}

my $DECLARATION_ORDER = 0;
sub install_candidate {
	my $me = shift;
	my ($target, $sub_name, %spec) = @_;
	$spec{method} = 1 unless defined $spec{method};
	
	my $is_method = $spec{method};
	
	$spec{declaration_order} = ++$DECLARATION_ORDER;
	
	$me->_add_multimethod_candidate($target, $sub_name, \%spec)
		if defined $sub_name;
	
	if ($spec{alias}) {
		$spec{alias} = [$spec{alias}] unless ref $spec{alias};
		my @aliases = @{$spec{alias}};
		my $next    =   $spec{code} or die "NO CODE???";
		
		my ($check, @sig);
		if (CodeRef->check($spec{signature})) {
			$check = $spec{signature};
		}
		else {
			@sig = @{$spec{signature}};
			if (HashRef->check($sig[0]) and not $sig[0]{slurpy}) {
				my %new_opts = %{$sig[0]};
				delete $new_opts{want_source};
				delete $new_opts{want_details};
				$sig[0] = \%new_opts;
			}
		}
		
		my $code = sprintf(
			q{
				package %s;
				sub {
					my @invocants = splice(@_, 0, %d);
					$check ||= %s(@sig);
					@_ = (@invocants, &$check);
					goto $next;
				}
			},
			$target,
			$spec{method},
			$spec{named}
				? 'Type::Params::compile_named_oo'
				: 'Type::Params::compile',
		);
		my $coderef = _set_subname(
			"$target\::$aliases[0]",
			eval($code)||die($@),
		);
		for my $alias (@aliases) {
			no strict 'refs';
			my $existing = do {
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
			*{"$target\::$alias"} = $coderef;
		}
	}
	
	$me->install_dispatcher($target, $sub_name, $is_method)
		if defined $sub_name && !$spec{no_dispatcher};
}

sub install_dispatcher {
	my $me = shift;
	my ($target, $sub_name, $is_method) = @_;
	
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
			sub %s {
				my $next = %s->can('dispatch');
				@_ = (%s, %s, %s, %d, [@_]);
				goto $next;
			}
		},
		$target,                   # package %s
		$sub_name,                 # sub %s
		B::perlstring($me),        # %s->can('dispatch')
		B::perlstring($me),        # $_[0]
		B::perlstring($target),    # $_[1]
		B::perlstring($sub_name),  # $_[2]
		$is_method,                # $_[3]
	);
	
	eval "$code; 1" or die($@);
	
	exists &mro::get_linear_isa
		or eval { require mro }
		or do { require MRO::Compat };
	
	my $coderef = do {
		no strict 'refs';
		\&{"$target\::$sub_name"};
	};
	
	$me->_mark_as_dispatcher($coderef);
	
	return $coderef;
}

sub dispatch {
	my $me = shift;
	my ($pkg, $method_name, $is_method, $argv) = @_;
	
	# Steal invocants because we don't want them to be considered
	# as part of the signature.
	my @invocants;
	push @invocants, splice(@$argv, 0, $is_method);
	
	my ($winner, $new_argv, $new_invocants) = $me->pick_candidate(
		[ $me->get_all_multimethod_candidates($pkg, $method_name, $is_method) ],
		$argv,
		\@invocants,
	) or do {
		require Carp;
		Carp::croak('Multimethod could not find candidate to dispatch to, stopped');
	};
	
	my $next = $winner->{code};
	@_ = (@$new_invocants, @$new_argv);
	goto $next;
}

# Type which when given \@_ determines if it could potentially
# be named parameters.
#
my $Named = CycleTuple->of(Str, Any) | Tuple->of(HashRef);

sub pick_candidate {
	my $me = shift;
	my ($candidates, $argv, $invocants) = @_;
	
	my @remaining = @{ $candidates };
	
	# Compile signatures into something useful. (Cached.)
	#
	
	for my $candidate (@remaining) {
		next if $candidate->{compiled};
		if (CodeRef->check($candidate->{signature})) {
			$candidate->{compiled}{closure} = $candidate->{signature};
			$candidate->{compiled}{min_args} = 0;
			$candidate->{compiled}{max_args} = undef;
		}
		else {
			my @sig = @{ $candidate->{signature} };
			my $opt = (HashRef->check($sig[0]) && !$sig[0]{slurpy}) ? shift(@sig) : {};
			$opt->{want_details} = 1;
			
			$candidate->{compiled} = $candidate->{named}
				? Type::Params::compile_named_oo($opt, @sig)
				: Type::Params::compile($opt, @sig);
		}
	}
	
	# Weed out signatures that cannot match because of
	# argument count.
	#
	
	my $argc = @$argv;
	my $argv_maybe_named = $Named->check($argv);
	
	@remaining = grep {
		my $candidate = $_;
		if ($candidate->{named} && !$argv_maybe_named) {
			0;
		}
		elsif (defined $candidate->{compiled}{min_args} and $candidate->{compiled}{min_args} > $argc) {
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
			if (ArrayRef->check($candidate->{signature})) {
				foreach my $type (@{ $candidate->{signature} }) {
					next unless Object->check($type);
					my @real_parents = grep !$_->_is_null_constraint, $type, $type->parents;
					$sum += @real_parents;
				}
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
		@remaining = sort { $a->{height} <=> $b->{height} } @remaining;
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
	return ( $remaining[0], $returns{"$sig_code"}, $invocants||[] );
}

sub dump_sig {
	no warnings qw(uninitialized numeric);
	my $candidate = shift;
	my $types_etc = join ",", map "$_", @{$candidate->{signature}};
	my $r = sprintf('%s:%s', $candidate->{named} ? 'NAMED' : 'POSITIONAL', $types_etc);
	$r .= sprintf('{score:%d+%d}', $candidate->{score}, $candidate->{height})
		if defined($candidate->{score})||defined($candidate->{height});
	return $r;
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

  use v5.12;
  use strict;
  use warnings;
  
  package My::JSON {
    use Moo;
    use Sub::MultiMethod qw(multimethod);
    use Types::Standard -types;
    
    multimethod stringify => (
      signature => [ Undef ],
      code      => sub {
        my ($self, $undef) = (shift, @_);
        'null';
      },
    );
    
    multimethod stringify => (
      signature => [ ScalarRef[Bool] ],
      code      => sub {
        my ($self, $bool) = (shift, @_);
        $$bool ? 'true' : 'false';
      },
    );
    
    multimethod stringify => (
      alias     => "stringify_str",
      signature => [ Str ],
      code      => sub {
        my ($self, $str) = (shift, @_);
        sprintf(q<"%s">, quotemeta($str));
      },
    );
    
    multimethod stringify => (
      signature => [ Num ],
      code      => sub {
        my ($self, $n) = (shift, @_);
        $n;
      },
    );
    
    multimethod stringify => (
      signature => [ ArrayRef ],
      code      => sub {
        my ($self, $arr) = (shift, @_);
        sprintf(
          q<[%s]>,
          join(q<,>, map($self->stringify($_), @$arr))
        );
      },
    );
    
    multimethod stringify => (
      signature => [ HashRef ],
      code      => sub {
        my ($self, $hash) = (shift, @_);
        sprintf(
          q<{%s}>,
          join(
            q<,>,
            map sprintf(
              q<%s:%s>,
              $self->stringify_str($_),
              $self->stringify($hash->{$_})
            ), sort keys %$hash,
          )
        );
      },
    );
  }
  
  my $json = My::JSON->new;
  
  say $json->stringify({
    foo => 123,
    bar => [1,2,3],
    baz => \1,
    quux => { xyzzy => 666 },
  });

=head1 DESCRIPTION

Sub::Multimethod focusses on implementing the dispatching of multimethods
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

  use Sub::MultiMethod "multimethod", "multimethods_from_roles";

You can rename functions:

  use Sub::MultiMethod "multimethod" => { -as => "mm" };

If you are using Sub::MultiMethod in a role, make sure you include
the C<< -role >> option:

  use Sub::MultiMethod -role, "multimethod";

You can import everything using C<< -all >>:

  use Sub::MultiMethod -all;
  use Sub::MultiMethod -role, -all;

Sub::MultiMethod also offers an API for setting up multimethods for a
class, in which case, you don't need to import anything.

=head3 C<< multimethod $name => %spec >>

The following options are supported in the specification for the
multimethod.

=over

=item C<< named >> I<< (Bool) >>

Optional, defaults to false.

Indicates whether this candidate uses named parameters. The default is
positional parameters.

=item C<< signature >> I<< (ArrayRef|CodeRef) >>

Required.

For positional parameters, an ordered list of type constraints suitable
for passing to C<compile> from L<Type::Params>.

  signature => [ Str, RegexpRef, Optional[FileHandle] ],

For named parameters, a list suitable for passing to C<compile_named_oo>.

  signature => [
    prefix  => Str,
    match   => RegexpRef,
    output  => FileHandle, { default => sub { \*STDOUT } },
  ],

Sub::MultiMethods is designed to handle multi I<methods>, so  C<< $self >>
at the start of all signatures is implied.

C<signature> I<may> be a coderef instead, which should die if it gets
passed a C<< @_ >> that it cannot handle, or return C<< @_ >> (perhaps
after some processing) if it is successful. Using coderef signatures
may make deciding which candidate to dispatch to more difficult though,
in cases where more than one candidate matches the given parameters.

=item C<< code >> I<< (CodeRef) >>

Required.

The sub to dispatch to. It will receive parameters in C<< @_ >> as you
would expect, but these parameters have been passed through the signature
already, so will have had defaults and coercions applied.

An example for positional parameters:

  code => sub {
    my ($self, $prefix, $match, $output) = (shift, @_);
    print {$output} $prefix;
    ...;
  },

An example for named parameters:

  code => sub {
    my ($self, $arg) = (shift, @_);
    print {$arg->output} $arg->prefix;
    ...;
  },

Note that C<< $arg >> is an object with methods for each named parameter.

=item C<< alias >> I<< (Str|ArrayRef[Str]) >>

Optional.

Installs an alias for the candidate, bypassing multimethod dispatch. (But not
bypassing the checks, coercions, and defaults in the signature!)

=item C<< method >> I<< (Int) >>

Optional, defaults to 1.

Indicates whether the multimethod should be treated as a method (i.e. with an
implied C<< $self >>). Defaults to true, but C<< method => 0 >> can be
given if you want multifuncs with no invocant.

Multisubs where some candidates are methods and others are non-methods are
not currently supported! (And probably never will be.)

(Yes, this is technically an integer rather than a boolean. This allows
for subs to have, say, two logical invocants. For example, in Catalyst,
you might want to treat the context object as a second invocant.)

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

As a convenience, you can use Sub::MultiMethod to install normal methods.
Why do this instead of using Perl's plain old C<sub> keyword? Well, it gives
you the same signature checking.

Supports the following options:

=over

=item C<< named >> I<< (Bool) >>

=item C<< signature >> I<< (ArrayRef|CodeRef) >>

=item C<< code >> I<< (CodeRef) >>

=item C<< method >> I<< (Int) >>

=back

C<< monomethod($name, %spec) >> is basically just a shortcut for
C<< multimethod(undef, alias => $name, %spec) >> though with error
messages which don't mention it being an alias.

=head3 C<< multimethods_from_roles @roles >>

Imports any multimethods defined in roles, and adds them to the
current package as if they were defined locally. See the section on
roles below.

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
    use Sub::MultiMethod -role, qw(multimethod);
    use Types::Standard -types;
    
    multimethod foo => (
      signature  => [ HashRef ],
      code       => sub { return "A" },
      alias      => "foo_a",
    );
  }
  
  package My::RoleB {
    use Moo::Role;
    use Sub::MultiMethod -role, qw(multimethod);
    use Types::Standard -types;
    
    multimethod foo => (
      signature  => [ ArrayRef ],
      code       => sub { return "B" },
    );
  }
  
  package My::Class {
    use Moo;
    use Sub::MultiMethod qw(multimethod multimethods_from_roles);
    use Types::Standard -types;
    
    with qw( My::RoleA My::RoleB );
    
    multimethods_from_roles qw( My::RoleA My::RoleB );
    
    multimethod foo => (
      signature  => [ HashRef ],
      code       => sub { return "C" },
    );
  }
  
  my $obj = My::Class->new;
  
  say $obj->foo_a( {} );  # A (alias defined in RoleA)
  say $obj->foo( [] );    # B (candidate from RoleB)
  say $obj->foo( {} );    # C (Class overrides candidate from RoleA)

Sub::MultiMethods doesn't try to be clever about detecting whether your
package is a role or a class. If you want to use it in a role, simply
do:

  use Sub::MultiMethod -role, qw(multimethod);

The main difference this makes is that the exported C<multimethod>
function will default to C<< no_dispatcher => 1 >>, so any multimethods
you define in the role won't be seen by Moose/Mouse/Moo/Role::Tiny as
part of the role's API, and won't be installed with the C<with> keyword.

Sub::MultiMethods doesn't try to detect what roles your class has
consumed, so in classes that consume roles with multimethods, do this:

  use Sub::MultiMethod qw(multimethods_from_roles);
  
  multimethods_from_roles qw( My::RoleA My::RoleB );

The list of roles should generally be the same as from C<with>.
This function only copies multimethods across from roles; it does not
copy their aliases. However, C<with> should find and copy the aliases.

If consuming one role into another role, remember to import
C<multimethods_from_roles> into the consumer with the C<< -role >>
tag so it knows not to set up the dispatchers in the role.

All other things being equal, candidates defined in classes should
beat candidates imported from roles.

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

Useful if C<< @sources >> are a bunch of roles (like Role::Tiny).

=item C<< Sub::MultiMethod->install_missing_dispatchers($target) >>

Should usually be called after C<copy_package_candidates>, unless
C<< $target >> is a role.

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

=item C<< Sub::MultiMethod->pick_candidate(\@candidates, \@args, \@invocants) >>

Returns a list of three items: first the winning candidate from an array of specs,
given the args and invocants, second the modified args after coercion has been 
applied, and third the modified invocants.

This is basically how the dispatcher for a method works:

  my @invocants = splice(@_, 0, $ismethod);
  my $pkg       = __PACKAGE__;
  
  my $mm = 'Sub::MultiMethod';
  my @candidates =
    $smm->get_all_multimethod_candidates($pkg, $sub, $ismethod);
  my ($winner, $new_args, $new_invocants) =
    $smm->pick_candidate(\@candidates, \@_, \@invocants);
  
  my $coderef = $winner->{code};
  @_ = (@$new_invocants, @$new_args);
  goto $coderef;

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

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

