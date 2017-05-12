#
#   Sub::Contract::Compiler - Compile, enable and disable a contract
#
#   $Id: Compiler.pm,v 1.22 2009/06/16 12:23:58 erwan_lemonnier Exp $
#

package Sub::Contract::Compiler;

use strict;
use warnings;
use Carp qw(croak confess);
use Data::Dumper;
use Sub::Contract::Debug qw(debug);
use Sub::Name;

our $VERSION = '0.12';

#---------------------------------------------------------------
#
#   enable - recompile contract and reenable it
#

sub enable {
    my $self = shift;

    debug(1,"Sub::Contract: enabling contract for [".$self->contractor."]");

    $self->disable if ($self->{is_enabled});

    # list all variables with same names in enable() as in _generate_code()
    my $contractor    = $self->contractor;
    my $validator_in  = $self->{in};
    my $validator_out = $self->{out};
    my $check_in      = $self->{pre};
    my $check_out     = $self->{post};
    my $invariant     = $self->{invariant};
    my $cache         = $self->{cache};

    my @list_checks_in;
    my %hash_checks_in;
    if (defined $validator_in) {
	@list_checks_in = @{$validator_in->list_checks};
	%hash_checks_in = %{$validator_in->hash_checks};
    }

    my @list_checks_out;
    my %hash_checks_out;
    if (defined $validator_out) {
	@list_checks_out = @{$validator_out->list_checks};
	%hash_checks_out = %{$validator_out->hash_checks};
    }

    # compile code to validate pre and post constraints
    my $str_pre  = _generate_code('before',
				  $contractor,
				  $validator_in,
				  $check_in,
				  $invariant,
				  # a mapping to local variable names
				  {
				      contractor => "contractor",
				      validator  => "validator_in",
				      check      => "check_in",
				      invariant  => "invariant",
				      list_check => "list_checks_in",
				      hash_check => "hash_checks_in",
				  },
				  );

    my $str_post = _generate_code('after',
				  $contractor,
				  $validator_out,
				  $check_out,
				  $invariant,
				  # a mapping to local variable names
				  {
				      contractor => "contractor",
				      validator  => "validator_out",
				      check      => "check_out",
				      invariant  => "invariant",
				      list_check => "list_checks_out",
				      hash_check => "hash_checks_out",
				  },
				  );

    my $str_call_pre = "";
    my $str_call_post = "";

    if ($str_pre) {
	$str_call_pre = q{
	    &$cref_pre();
	};
    }

    if ($str_post) {
	$str_call_post = q{
	    &$cref_post();
	};
    }

    # find contractor's code ref
    my $cref = $self->contractor_cref;

    # add caching
    my $str_cache_enter         = "";
    my $str_cache_return_array  = "";
    my $str_cache_return_scalar = "";

    if ($cache) {
	$str_cache_enter = sprintf q{
	    if (!defined $Sub::Contract::wantarray) {
		_croak "calling memoized subroutine %s in void context";
	    }

	    if (grep({ ref $_; } @_)) {
		_croak "cannot memoize result of %s when input arguments contain references";
	    }

	    my $key = join(":", map( { (defined $_) ? $_ : "undef"; } ( ($Sub::Contract::wantarray) ? "array":"scalar"),@_));
	    if ($cache->has($key)) {
		%s
                if ($Sub::Contract::wantarray) {
		    return @{$cache->get($key)};
		} else {
		    return $cache->get($key);
		}
	    }
	    %s
	},
	$contractor,
	$contractor,
	(Sub::Contract::Memoizer::_is_profiler_on()) ? "Sub::Contract::Memoizer::_incr_hit(\"$contractor\");" : "",
	(Sub::Contract::Memoizer::_is_profiler_on()) ? "Sub::Contract::Memoizer::_incr_miss(\"$contractor\");" : "";

	$str_cache_return_array = sprintf q{
	    $cache->set($key,\@Sub::Contract::results);
            %s
	},
	(Sub::Contract::Memoizer::_is_profiler_on()) ? "Sub::Contract::Memoizer::_incr_max_reached(\"$contractor\");" : "";

	$str_cache_return_scalar = sprintf q{
	    $cache->set($key,$s);
            %s
	},
	(Sub::Contract::Memoizer::_is_profiler_on()) ? "Sub::Contract::Memoizer::_incr_max_reached(\"$contractor\");" : "";
    }

    # the context in which the contracted sub is called depends on
    # whether we have conditions on return values
    my $str_call;

    if (!defined $validator_out) {
	# there are no constraints on return arguments so we can't assume
	# anything on the context the sub expects to be called in
	# we therefore propagate the same context as the call to the contract

	$str_call = sprintf q{

	    local $Sub::Contract::wantarray = wantarray;

	    %s

	    # TODO: this code is not re-entrant. use local variables for args/wantarray/results. is local enough?

	    local @Sub::Contract::args = @_;
	    local @Sub::Contract::results = ();

	    if (!defined $Sub::Contract::wantarray) {
		# void context
		%s
		&$cref(@Sub::Contract::args);
		@Sub::Contract::results = ();
		%s
		return ();

	    } elsif ($Sub::Contract::wantarray) {
		# array context
		%s
		@Sub::Contract::results = &$cref(@Sub::Contract::args);
		%s
		%s
		return @Sub::Contract::results;

	    } else {
		# scalar context
		%s
		my $s = &$cref(@Sub::Contract::args);
		@Sub::Contract::results = ($s);
		%s
		%s
		return $s;
	    }
	},
	$str_cache_enter,
	$str_call_pre,
	$str_call_post,
	$str_call_pre,
	$str_call_post,
	$str_cache_return_array,
	$str_call_pre,
	$str_call_post,
	$str_cache_return_scalar;

    } else {
	# we have conditions set on the return values
	# we have 3 cases:
	my @checks = (@list_checks_out,%hash_checks_out);

	if (scalar @checks == 0) {
	    # the sub returns nothing. therefore it should
	    # only be called in void context. anything else
	    # is an error.

	    # we shouldn't try caching this sub
	    if ($cache) {
		croak "trying to cache a sub that returns nothing (according to ->out())";
	    }

	    $str_call = sprintf q{

		local $Sub::Contract::wantarray = wantarray;

		if (defined $Sub::Contract::wantarray) {
		    _croak "calling %s in scalar or array context when its contract says it has no return values";
		}

		local @Sub::Contract::args = @_;
		local @Sub::Contract::results = ();

		# void context, but we call the sub in array context to check if we get something back
		# (if we do, it's an error)
		%s
		@Sub::Contract::results = &$cref(@Sub::Contract::args);
		%s
		return;
	    },
	    $contractor,
	    $str_call_pre,
	    $str_call_post;

	} elsif (scalar @checks == 1) {
	    # the sub returns only 1 element.
	    # we don't know though whether it returns a scalar
	    # (most likely) or an array with just 1 element.
	    # returning a 1-element array instead of a scalar
	    # is a sign of bad programming so we just forbid
	    # this case by raising an error if called in array
	    # context.
	    # otherwise, we call the sub in scalar context,
	    # check the result and return it.

	    $str_call = sprintf q{

		local $Sub::Contract::wantarray = wantarray;

		%s

		# TODO: this code is not re-entrant. use local variables for args/wantarray/results. is local enough?

		if ($Sub::Contract::wantarray) {
		    _croak "calling %s in array context when its contract says it returns a scalar";
		}

		local @Sub::Contract::args = @_;
		local @Sub::Contract::results = ();

		# call in scalar context, even if called from void context
		%s
		my $s = &$cref(@Sub::Contract::args);
		@Sub::Contract::results = ($s);
		%s
		%s
		return $s;

	    },
	    $str_cache_enter,
	    $contractor,
	    $str_call_pre,
	    $str_call_post,
	    $str_cache_return_scalar;

	} else {
	    # the sub returns an array. we call it in array context,
	    # check the conditions and return an array as well

	    $str_call = sprintf q{

		local $Sub::Contract::wantarray = wantarray;

		%s

		# TODO: this code is not re-entrant. use local variables for args/wantarray/results. is local enough?

		local @Sub::Contract::args = @_;
		local @Sub::Contract::results = ();

		# call in array context, even if called from void or scalar context
		%s
		@Sub::Contract::results = &$cref(@Sub::Contract::args);
		%s
		%s
		return @Sub::Contract::results;

	    },
	    $str_cache_enter,
	    $str_call_pre,
	    $str_call_post,
	    $str_cache_return_array;
	}
    }

    my $str_contract = sprintf q{
	use Carp;

	my $cref_pre = sub {
	    %s
	};

	my $cref_post = sub {
	    %s
	};

	$contract = sub {
	    %s
	}
    },
    $str_pre,
    $str_post,
    $str_call;

    # compile code
    $str_contract =~ s/^\s+//gm;

    debug(2,join("\n",
		 "Sub::Contract: wrapping this code around [".$self->contractor."]:",
		 "-------------------------------------------------------",
		 $str_contract,
		 "-------------------------------------------------------"));

    my $contract;
    eval $str_contract;

    if (defined $@ and $@ ne "") {
	confess "BUG: failed to compile contract ($@)";
    }

    # replace contractor with contract sub
    $^W = 0;
    no strict 'refs';
    no warnings;
    *{ $self->contractor } = $contract;

    my $name = $self->contractor;
    $name =~ s/::([^:]+)$/::contract_$1/;
    subname $name, $contract;

    $self->{is_enabled} = 1;

    return $self;
}

sub disable {
    my $self = shift;
    if ($self->{is_enabled}) {
	debug(1,"Sub::Contract: disabling contract on [".$self->contractor."]");

	# restore original sub
	$^W = 0;
	no strict 'refs';
	no warnings;
	*{ $self->contractor } = $self->{contractor_cref};

	# TODO: remove memoization
	$self->{is_enabled} = 0;
    }
    return $self;

}

sub is_enabled {
    return $_[0]->{is_enabled};
}

#---------------------------------------------------------------
#
#   _compile - generate the code to validate the contract before
#              or after a call to the contractor function
#

# TODO: insert _croak inline in compiled code
# croak from contract code, with proper stack level
sub _croak {
    my $msg = shift;
    local $Carp::CarpLevel = 2;
    confess "contract failed: $msg";
}

# TODO: insert _run inline in compiled code
# run a condition, with proper stack level if croak
sub _run {
    my ($func,@args) = @_;
    local $Carp::CarpLevel = 4;
    my $res = $func->(@args);
    local $Carp::CarpLevel = 0; # is this needed? isn't local doing its job?
    return $res;
}

# The strategy we use for building the contract validation sub is to
# to (quite horribly) build a string containing the code of the validation sub,
# then compiling this code with eval. We could instead use a closure,
# but that would mean that many things we can test at compile time would
# end up being tested each time the closure is called which would be a
# waste of cpu.

sub _generate_code {
    my ($state,$contractor,$validator,$check_condition,$check_invariant,$varnames) = @_;
    my (@list_checks,%hash_checks);

    croak "BUG: wrong state" if ($state !~ /^before|after$/);

    # the code validating the pre or post-call part of the contract, as a string
    my $str_code = "";

    # code validating the contract invariant
    if (defined $check_invariant) {
	$str_code .= sprintf q{
	    if (!_run($%s,@Sub::Contract::args)) {
		_croak "invariant fails %s calling $%s";
	    }
	}, $varnames->{invariant}, $state, $varnames->{contractor};
    }

    # code validating the contract pre/post condition
    if (defined $check_condition) {
	if ($state eq 'before') {
	    $str_code .= sprintf q{
		if (!_run($%s,@Sub::Contract::args)) {
		    _croak "pre-condition fails before calling $%s";
		}
	    }, $varnames->{check}, $varnames->{contractor};
	} else {
	    # if the contractor is called without context, the result is set to ()
	    # so we can't validate the returned arguments. maybe we should issue a warning?
	    $str_code .= sprintf q{
		if (!_run($%s,@Sub::Contract::results)) {
		    _croak "post-condition fails after calling $%s";
		}
	    }, $varnames->{check}, $varnames->{contractor};
	}
    }

    # compile the arguments validation code
    if (defined $validator) {

	@list_checks = @{$validator->list_checks};
	%hash_checks = %{$validator->hash_checks};

	# get args/@_ from right source
	if ($state eq 'before') {
	    $str_code .= q{ my @args = @Sub::Contract::args; };
	} else {
	    $str_code .= q{ my @args = @Sub::Contract::results; };
	}

	# if arguments are list style only, check their count
	if (!$validator->has_hash_args) {
	    my $count = scalar @list_checks;
	    if ($state eq 'before') {
		$str_code .= sprintf q{
		    _croak "$%s expected %s input arguments but got ".(scalar @args) if (scalar @args != %s);
		},
		$varnames->{contractor},
		($count == 0) ? "no" : "exactly $count",
		$count;
	    } else {
		$str_code .= sprintf q{
		    _croak "$%s should return %s values but returned ".(scalar @args) if (scalar @args != %s);
		},
		$varnames->{contractor},
		($count == 0) ? "no" : "exactly $count",
		$count;
	    }
	}

	# do we have arguments to validate?
	if ($validator->has_list_args || $validator->has_hash_args) {

	    # add code validating heading arguments passed in list style
	    my $pos = 1;
	    for (my $i=0; $i<scalar(@list_checks); $i++) {
		if (defined $list_checks[$i]) {
		    $str_code .= sprintf q{
			_croak "%s number %s of $%s fails its constraint: ".((defined $args[0])?$args[0]:"undef") if (!_run($%s[%s], $args[0]));
		    },
		    ($state eq 'before') ? 'input argument' : 'return value',
		    $pos,
		    $varnames->{contractor},
		    $varnames->{list_check},
		    $i;
		}

		$str_code .= q{
		    shift @args;
		};
		$pos++;
	    }

	    # add code validating trailing arguments passed in hash style
	    if ($validator->has_hash_args) {

		# croak if odd number of elements
		$str_code .= sprintf q{
		    _croak "odd number of hash-style %s in $%s" if (scalar @args %% 2);
		    my %%args = @args;
		},
		($state eq 'before') ? 'input arguments' : 'return values',
		$varnames->{contractor};

		# check the value of each key in the argument hash
		while (my ($key,$check) = each %hash_checks) {
		    if (defined $check) {
			$str_code .= sprintf q{
			    _croak "%s of $%s with key \'%s\' fails its constraint: %s = ".((defined $args{%s})?$args{%s}:"undef") if (!_run($%s{%s}, $args{%s}));
			},
			($state eq 'before') ? 'input argument' : 'return value',
			$varnames->{contractor},
			$key,
			$key,
			$key,
			$key,
			$varnames->{hash_check},
			$key,
			$key;
		    }

		    $str_code .= sprintf q{
			delete $args{%s};
		    }, $key;
		}
	    }
	}

	# there should be no arguments left
	if ($validator->has_hash_args) {
	    $str_code .= sprintf q{
		_croak "$%s %s: ".join(" ",keys %%args) if (%%args);
	    },
	    $varnames->{contractor},
	    ($state eq 'before') ? 'got unexpected hash-style input arguments' : 'returned unexpected hash-style return values';
	}
    }

    return $str_code;
}

1;

__END__

=head1 NAME

Sub::Contract::Compiler - Compile, enable and disable a contract

=head1 SYNOPSIS

See 'Sub::Contract'.

=head1 DESCRIPTION

Subroutine contracts defined with Sub::Contract must be compiled
and enabled in order to start applying on the contractor. A
contract can be enabled then disabled, or recompiled after
changes. Those methods are implemented in Sub::Contract::Compiler
and inherited by Sub::Contract.

=head1 API

See 'Sub::Contract'.

=over 4

=item enable()

See 'Sub::Contract'.

=item disable()

See 'Sub::Contract'.

=item is_enabled()

See 'Sub::Contract'.

=back

=head1 SEE ALSO

See 'Sub::Contract'.

=head1 VERSION

$Id: Compiler.pm,v 1.22 2009/06/16 12:23:58 erwan_lemonnier Exp $

=head1 AUTHOR

Erwan Lemonnier C<< <erwan@cpan.org> >>

=head1 LICENSE

See Sub::Contract.

=cut

