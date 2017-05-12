####################################################################
#
#   ContractClosure - An alternative implementation av Sub::Contract, using closures instead of dynamic compilation
#
#   $Id: ContractClosure.pm,v 1.1 2008/04/28 12:46:20 erwan_lemonnier Exp $
#

package ContractClosure;

use strict;
use warnings;
use Carp qw(confess);
use Data::Dumper;
use lib "../lib/", "t/", "lib/";
use Symbol;

# default cache size
my $DEFAULT_CACHE_SIZE = 250;
my $CACHE_STATS_ON = 0;
my %CACHE_STATS;

# skip all form of contract
my $CONTRACT_OFF = 0;

# contracted subs per module
my %CONTRACTED_SUBS_PER_MODULE;

####################################################################
#
#
#   RESULT CACHING
#
#
####################################################################

# caches
my %CACHE_RESULTS;
my %CACHE_SIZES;
my %CACHE_MAX_SIZES;

#-------------------------------------------------------------------
#
#   _init_cache
#

sub _init_cache {
    my $target = shift;
    my $size = shift;

    # TODO: asserts?

    $CACHE_RESULTS{$target} = {};
    $CACHE_SIZES{$target} = 0;
    $CACHE_MAX_SIZES{$target} = $size;

    if ($CACHE_STATS_ON) {
	$CACHE_STATS{$target} = { calls => 0, hits => 0 };
    }
}

#-------------------------------------------------------------------
#
#   flush_function_cache - as the name says
#

sub flush_function_cache {
    my @funcs = @_;
    my $pkg = caller;

    foreach my $func (@funcs) {
	if (!defined $func) {
	    confess("ERROR: flush_function_cache called with no function name");
	}

	my $target = $pkg."::".$func;

	if (!exists $CACHE_SIZES{$target}) {
	    confess "ERROR: function [$target] has no cache. cannot flush its cache";
	}

	_flush_target_cache($target);
    }
}

sub _flush_target_cache {
    my $target = shift;

    # this is slightly hughly looking, but it's really just a fast way to empty
    delete @{$CACHE_RESULTS{$target}}{keys %{$CACHE_RESULTS{$target}}};
    $CACHE_SIZES{$target} = 0;
}

#-------------------------------------------------------------------
#
#   add_to_function_cache - store a result in cache
#

sub add_to_function_cache {
    my ($func,$ref_args,$ref_result) = @_;
    my $pkg = caller;
    my $target    = $pkg."::".$func;

    if (ref $ref_args ne 'ARRAY' || ref $ref_result ne 'ARRAY') {
	confess "ERROR: expecting references to arrays as 2nd and 3rd argument";
    }

    if (!exists $CACHE_SIZES{$target}) {
	confess "ERROR: function [$target] has no cache. cannot add result to its cache";
    }

    my $key = _generate_cache_key($func,"array",@{$ref_args});
    _add_to_cache($target,$key,$ref_result);
}

####################################################################
#
#
#   WARNING: the following cache subs are used INTENSIVELY
#            they must be REALLY FAST
#
#
####################################################################

#-------------------------------------------------------------------
#
#   _add_to_cache - store a result in cache
#

sub _add_to_cache {
    my ($target,$key,$ref_result) = @_;

    if ($CACHE_SIZES{$target} >= $CACHE_MAX_SIZES{$target}) {
	_flush_target_cache($target);
    }

    $CACHE_RESULTS{$target}->{$key} = $ref_result;
    $CACHE_SIZES{$target}++;
}

#-------------------------------------------------------------------
#
#   _get_from_cache - retrieve a cached result from function's cache
#

sub _get_from_cache {
    my ($target,$key) = @_;

    if (exists $CACHE_RESULTS{$target}->{$key}) {

	if ($CACHE_STATS_ON) {
	    $CACHE_STATS{$target}->{hits}++;
	    $CACHE_STATS{$target}->{calls}++;
	}

	return $CACHE_RESULTS{$target}->{$key};

    } elsif ($CACHE_STATS_ON) {
	$CACHE_STATS{$target}->{calls}++;
    }

    return undef;
}

#-------------------------------------------------------------------
#
#   _generate_cache_key - generate a unique cache key from a list of function arguments
#

sub _generate_cache_key {
    my ($func,@args) = @_;

    # NOTE: previously, we used Dumper(@args) as the key, but Dumper is quite
    # slow, hence the use of join() here. But join will replace references
    # with an adress code while concatening to the string. 2 series of input
    # arguments with the same scalar reference, but for which the refered scalar
    # had different values will therefore yield the same key, though the
    # results will be different.
    # therefore we want to forbid the use of contract's cache whith references
    # but we have to think of speed...

    if (grep({ ref $_; } @args)) {
	confess "ERROR: cache cannot handle input arguments that are references. function [$func] called with arguments:\n".Dumper(@args);
    }

    @args = map { (defined $_) ? $_ : "undef"; } @args;

    return join(":",@args);
}

#-------------------------------------------------------------------
#
#   generate cache statistics
#

END {
    if ($CACHE_STATS_ON) {
	print "------------------------------------------------------\n";
	print "Statistics from ContractClosure's function cache:\n";
	foreach my $func (sort keys %CACHE_STATS) {
	    my $hits = $CACHE_STATS{$func}->{hits};
	    my $calls = $CACHE_STATS{$func}->{calls};
	    if ($calls) {
		my $rate = int(1000*$hits/$calls)/10;
		print "  ".sprintf("%-60s:",$func)."  $rate % hits (calls: $calls, hits: $hits)\n";
	    }
	}
	print "------------------------------------------------------\n";
    }
}

####################################################################
#
#
#   ARGUMENTS AND RESULTS VALIDATION
#
#
####################################################################

#-------------------------------------------------------------------
#
#   _check_constraints - check that the constraint declaration looks good
#

sub _check_constraints {
    my($key,%args) = @_;

    return if (scalar @_ == 1);

    if (ref $args{$key} ne "HASH") {
	confess("BUG: invalid data type for key \'$key\' (should be a hash): ".Dumper(%args));
    }

    my %hash = %{$args{$key}};

    if (exists $hash{count}) {
	if (ref $hash{count} ne "") {
	    confess("BUG: invalid data type for option 'count' (must be an integer): ".Dumper(%hash));
	}
	if ($hash{count} !~ /^\d+$/) {
	    confess("BUG: invalid value for option 'count' (must be an integer): ".Dumper(%hash));
	}
	delete $hash{count};
    }

    if (exists $hash{defined}) {
	if (ref $hash{defined} ne "") {
	    confess("BUG: invalid data type for option 'defined' (must be 0 or 1): ".Dumper(%hash));
	}
	if ($hash{defined} !~ /^(0|1)+$/) {
	    confess("BUG: invalid value for option 'defined' (must be 0 or 1): ".Dumper(%hash));
	}

	delete $hash{defined};
    }

    my $check;
    if (exists $hash{check}) {
	if (ref $hash{check} eq "ARRAY") {
	    # expecting an array of undef or closures
	    foreach my $e (@{$hash{check}}) {
		if (defined $e && ref $e ne "CODE") {
		    confess("BUG: option 'check' with an array requires that the array contains only undefs and coderefs: ".Dumper(%hash));
		}
	    }
	} elsif (ref $hash{check} eq "HASH") {
	    # expecting hash of closures
	    foreach my $k (keys %{$hash{check}}) {
		if (!defined $hash{check}->{$k}) {
		    next;
		} elsif (ref $hash{check}->{$k} ne "CODE") {
		    confess("BUG: option 'check' with a hash requires that the hash's values are all either undef or coderefs: ".Dumper(%hash));
		}
	    }
	} else {
	    confess("BUG: invalid data type for option 'check' (must be an array of coderef or a hash of coderef): ".Dumper(%hash));
	}

	$check = $hash{check};
	delete $hash{check};
    }

    if (exists $hash{optional}) {
	if (ref $hash{optional} ne "ARRAY") {
	    confess("BUG: option 'optional' requires an anonymous array");
	}

	if (!defined $check) {
	    confess("BUG: option 'optional' requires that a 'check' hash is defined".Dumper(%hash));
	}

	if (ref $check ne "HASH") {
	    confess("BUG: option 'optional' requires that 'check' defines an anonymous hash");
	}

	foreach my $k (@{$hash{optional}}) {
	    if (!exists $check->{$k}) {
		confess "BUG: key [$k] is defined in 'optional' but not in 'check'";
	    }
	}
	delete $hash{optional};
    }

    if (scalar keys %hash) {
	confess("BUG: unknown options in constraint arguments: ".Dumper(%hash));
    }
}

#-------------------------------------------------------------------
#
#   _check_cache_settings - validate the settings for the cache
#

sub _check_cache_settings {
    my %hash = @_;

    if (exists $hash{size}) {
	if (!defined $hash{size}) {
	    confess("BUG: non defined value for option 'size' (must be an integer larger than 100): ".Dumper(%hash));
	}
	if ($hash{size} !~ /^\d+$/) {
	    confess("BUG: invalid value for option 'size' (must be an integer larger than 100): ".Dumper(%hash));
	}
	if ($hash{size} < 100) {
	    confess("BUG: this cache size is too small, set a larger size: ".Dumper(%hash));
	}
    }
}


#-------------------------------------------------------------------
#
#   do_check_arguments - control a list of arguments against some constraints
#                        (REM: name should start with _, but would be hard to test...)
#

sub do_check_arguments {
    my($constraints,@args) = @_;

    my $caller = $constraints->{caller};
    my $type = $constraints->{type};

    # check number of arguments
    if (exists $constraints->{count}) {
	if (scalar @args != $constraints->{count}) {
	    confess("ERROR: function [$caller] ".(($type eq 'in') ? 'received' : 'returned' )." a wrong number of arguments");
	}
    }

    # check for undefined arguments
    if ($constraints->{defined}) {
	foreach my $arg (@args) {
	    if (!defined $arg) {
		confess("ERROR: function [$caller] ".(($type eq 'in') ? 'received' : 'returned' )." some undefined arguments");
	    }
	}
    }

    return if (!exists $constraints->{check});

    # check each argument by position (array) or key (hash)
    if (ref $constraints->{check} eq 'ARRAY') {

	#-------------------------------------------------------------------
	#
	#   check arguments passed in array style
	#

	my $i = 0;
	foreach my $check (@{$constraints->{check}}) {
	    next if (!defined $check);
	    my $arg = $args[$i];
	    if (!&$check($arg)) {
		confess("ERROR: argument number [$i] ".(($type eq 'in') ? 'received' : 'returned' )." by function [$caller] does not validate its constraint");
	    }
	    $i++;
	}
    } else {

	#-------------------------------------------------------------------
	#
	#   check arguments passed in hash style
	#

	my %checks = %{$constraints->{check}};

	# did we get the proper number of arguments to fill a hash?
	if ((scalar @args)/2 - int((scalar @args)/2)) {
	    confess("ERROR: function [$caller] ".(($type eq 'in') ? 'received' : 'returned' )." a non odd number of arguments in hash style passing");
	}

	my $optionals = "";
	if (exists $constraints->{optional}) {
	    $optionals = " ".join(" ",@{$constraints->{optional}})." ";
	}

	my %args = @args;
	foreach my $k (keys %checks) {
	    my $check = $checks{$k};

	    # is this key mandatory but missing from the argument list?
	    if (!exists $args{$k}) {
		if ($optionals eq "" || $optionals !~ / $k /) {
		    confess("ERROR: no argument with key [$k] ".(($type eq 'in') ? 'received' : 'returned' )." by function [$caller]");
		}
		next;
	    }

	    # skip checking key if check is undefined
	    next if (!defined $check);

	    # does the argument passed for this key pass its check?
	    if (!&$check($args{$k})) {
		confess("ERROR: argument with key [$k] ".(($type eq 'in') ? 'received' : 'returned' )." by function [$caller] does not validate its constraint");
	    }
	}

	# is each passed argument declared in the constraint hash?
	foreach my $k (keys %args) {
	    if (!exists $checks{$k}) {
		confess("ERROR: argument with key [$k] was ".(($type eq 'in') ? 'received' : 'returned' )." by function [$caller] but is not declared in the function's constraints");
	    }
	}
    }
}

#-------------------------------------------------------------------
#
#   list_contractors - return a list of all contracted subs in a given module
#

sub list_contractors {
    my $pkg = shift;
    confess "ERROR: got undefined package name" if (!defined $pkg);
    return () if (!exists $CONTRACTED_SUBS_PER_MODULE{$pkg});
    return @{$CONTRACTED_SUBS_PER_MODULE{$pkg}};
}

#-------------------------------------------------------------------
#
#   contract - add constraint controls on input arguments and output results of a function, do caching
#

sub contract {
    my($func,%hash) = @_;
    my $pkg = caller;

    # don't fiddle with contracted functions if contract if off...
    return if ($CONTRACT_OFF);

    my $check_in  = exists $hash{in};
    my $check_out = exists $hash{out};
    my $do_cache  = exists $hash{cache};
    my $target    = $pkg."::".$func;

    # keep track of contracted subs in each module
    if (!exists $CONTRACTED_SUBS_PER_MODULE{$pkg}) {
	$CONTRACTED_SUBS_PER_MODULE{$pkg} = [];
    }
    push @{$CONTRACTED_SUBS_PER_MODULE{$pkg}}, $func;

    if ($check_in) {
	_check_constraints('in',%hash);
	$hash{in}->{caller}  = $target;
	$hash{in}->{type}  = 'in';
    }

    if ($check_out) {
	_check_constraints('out',%hash);
	$hash{out}->{caller} = $target;
	$hash{out}->{type} = 'out';
    }

    if ($do_cache) {
	_check_cache_settings(%{$hash{cache}});
	my $size = $hash{cache}->{size} || $DEFAULT_CACHE_SIZE;
	_init_cache($target, $size);
    }

    # no need to wrap if no constraints set
    return if (!$check_in && !$check_out && !$do_cache);

    # NOTE: in a first version of this module, $hijacked_function was defined by:
    #    my $hijacked_func = *{ qualify_to_ref($func,$pkg) }{CODE};
    # but qualify_to_ref in perl 5.6 failed to return a ref of functions whose name begins with '_'
    # this bug was corrected in perl 5.8 (erwan 2007-01)

    my $hijacked_func;

    {
	no strict 'refs';
	$hijacked_func = *{ *{$pkg."::".$func} }{CODE};
    }

    if (!defined $hijacked_func) {
	confess "BUG: failed to identify the code of function [$func] in package [$pkg]. a private function?\n";
    }

    # NOTE: the following closure MUST be very fast. since contract,
    # and expecialy caching, is used heavily in pluto, this closure
    # will be called a huge amount of time and become a speed bottleneck
    # if not fast enough. hence the massive use of if/else, no call
    # to debug(), etc.
    # WARNING: when editing here, be sure that your change is speed effective

    my $check = sub {
	my(@args) = @_;
	my $wantarray = wantarray();

	# TODO: looking at source for Hook::WrapSub, it might be a good idea to copy/paste some of its code here, to build valid caller stack

	if ($wantarray) {

	    # NOTE: we query the cache before checking the arguments! to improve performance
	    my $key;
	    if ($do_cache) {
		$key = _generate_cache_key($target,"array",@args);
		if (my $ref_result = _get_from_cache($target,$key)) {
		    return @$ref_result;
		}
	    }

	    if ($check_in) {
		do_check_arguments($hash{in},@args);
	    }

	    my @res = $hijacked_func->(@args);

	    if ($check_out) {
		do_check_arguments($hash{out},@res);
	    }

	    if ($do_cache) {
		_add_to_cache($target,$key,\@res);
	    }

	    return @res;

	} else {

	    my $key;
	    if ($do_cache) {
		$key = _generate_cache_key($target,"scalar",@args);
		if (my $ref_result = _get_from_cache($target,$key)) {
		    return $$ref_result;
		}
	    }

	    if ($check_in) {
		do_check_arguments($hash{in},@args);
	    }

	    my $res = $hijacked_func->(@args);

	    if ($check_out) {
		do_check_arguments($hash{out},$res);
	    }

	    if ($do_cache) {
		_add_to_cache($target,$key,\$res);
	    }

	    return $res;
	}
    };

    # replace $func by $check in $pkg
    no strict 'refs';
    no warnings;
    *{ qualify($func,$pkg) } = $check;
}

1;

__END__

=head1 NAME

ContractClosure - An alternative implementation av Sub::Contract, using closures instead of dynamic compilation

=head1 SYNOPSIS

to control arguments passed in array style, and cache the results:

   use ContractClosure;

   contract('foo',
	    in => { # define constraints on input arguments
		    count => 3,           # there must be exactly 3 input arguments
		    defined => 1,         # they must all be defined
		    check => [ undef,                              # no constraint on first argument
			       \&is_integer,                       # argument ok if is_integer(<arg>) returns true
			       sub { return (ref $_[0] eq ""); },  # ok if argument is a scalar
			     ],
		   },
	    out => { # define constraints on output arguments
		     count => 2,
		   },
	    cache => { size => 10000 },
	   );

   sub foo {
       my($a,$b,$c) = @_;
       return (1,undef);
   }

and to control arguments passed in hash style:

   contract('foo',
	    in => { count => 4,     # must be 4 input arguments
				    # do not need to be all defined ('defined => 0' is the default)
		    check => { bib => \&is_year,      # if key 'bib' exists, its value must pass is_year()
			       bob => \&is_shortdate, # if key 'bob' exists, its value must pass is_shortdate()
			       bub => undef,          # no constraint on bub except that this key must exist (but can be 'undef')
			     },
		    optional => ['bib']               # allow key 'bib' to be non existing (but if it exists, it must pass 'is_year')
		  },
	    out => { count => 1,
		     defined => 1,
		   },
	   );

   sub foo {
       my(%hash) = @_;
       print "arg1: ".$hash{bib};
       print "arg2: ".$hash{bob};
       return $b;
   }

=cut
