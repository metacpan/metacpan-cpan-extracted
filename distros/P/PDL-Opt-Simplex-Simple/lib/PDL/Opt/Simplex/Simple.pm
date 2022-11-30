#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Library General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#  Copyright (C) 2021- eWheeler, Inc. L<https://www.linuxglobal.com/>
#  Originally written by Eric Wheeler, KJ7LNW
#  All rights reserved.
#
#  All tradmarks, product names, logos, and brands are property of their
#  respective owners and no grant or license is provided thereof.

package PDL::Opt::Simplex::Simple;
$VERSION = '1.7';

use 5.010;
use strict;
use warnings;

use Math::Round qw/nearest/;
use Time::HiRes qw/time/;
#use Data::Dumper;

use PDL;
use PDL::Opt::Simplex;

sub new
{
	my ($class, %args) = @_;

	my %valid_opts = map { $_ => 1 }
		qw/f log vars ssize nocache max_iter tolerance srand
			stagnant_minima_count stagnant_minima_tolerance
			reduce_search/;

	foreach my $k (keys %args)
	{
		next if $k =~ /^_/;
		die "invalid option: $k" if !$valid_opts{$k};
	}

	my $self = bless(\%args, $class);

	$self->{tolerance}                 //=  1e-6;
	$self->{max_iter}                  //=  1000;
	$self->{ssize}                     //=  1;
	$self->{stagnant_minima_tolerance} //= $self->{tolerance};
	
	if ($self->{srand})
	{
		srand($self->{srand});
	}
	else 
	{
		# Generate a 15-digit random seed.  This is necessary because
		# PDL::srand does not return the seed---so we generate one, set
		# it, and keep it for the calling application if they are
		# interested.  Note that this is not meant to be
		# cryptographically strong, just a way to set a known seed to
		# replay the same simplex cycle for testing.  If you get a good
		# result and it is dependent on this value then you might want
		# to keep it around.
		#
		# See this issue for detail:
		# 	https://github.com/PDLPorters/pdl/issues/398
		$self->{srand} = int(rand() * (10**15));
		srand($self->{srand});
	}

	# _ssize is the array for multiple simplex retries.
	if (ref($self->{ssize}) eq 'ARRAY')
	{
		$self->{_ssize} = $self->{ssize};

		$self->{ssize} = $self->{ssize}[0];
	}
	else
	{
		$self->{_ssize} = [ $self->{ssize} ];
	}

	$self->set_vars($self->{vars});

	# vars, ssize, tolerance, max_iter, f, log
	return $self;
}

sub optimize
{
	my $self = shift;

	$self->{optimization_pass} = 1;
	$self->{log_count} = 0;

	delete $self->{best_minima};
	delete $self->{best_vars};
	delete $self->{best_vec};
	delete $self->{best_pass};

	if (@{ $self->{_ssize} } == 1)
	{
		return $self->_optimize;
	}

	# Iterate multiple ssize passes if {ssize} was passed as an array:
	my $result;
	foreach my $ssize (@{ $self->{_ssize} })
	{
		$self->set_ssize($ssize);
		$result = $self->_optimize;
		$self->set_vars($result);
		$self->{optimization_pass}++;
		$self->{log_count} = 0;
	}

	return $result;
}

sub _optimize
{
	my $self = shift;

	my $vec_initial = $self->_build_simplex_vars();

	$self->{cancel} = 0;

	delete $self->{prev_minima};
	delete $self->{prev_minima_count};

	# Make an initial call if this is the first pass to create a basis for
	# {best_vars} in case the starting point is better than all other
	# simplex attempts.  The result will be cached so if Simplex calls with
	# the same value then it will not waste an iteration (unless nocache is
	# flagged).
	#
	# Also call the log function in case it is useful:
	if ($self->{optimization_pass} == 1)
	{
		my $vec_result = $self->_simplex_f($vec_initial);
		$self->_simplex_log($vec_initial, $vec_result, pdl $self->{ssize});
	}

	my ( $vec_optimal, $opt_ssize, $optval );

	# Catch early cancellation
	eval {
		($vec_optimal, $opt_ssize, $optval) = simplex($vec_initial,
			$self->{ssize},
			$self->{tolerance},
			$self->{max_iter},

			# We need to lambda $self into place for the f() and log() callbacks:
			sub {
				my ($vec) = @_;
				return $self->_simplex_f($vec);
			},

			# log callback
			sub {
				my ($vec, $vals, $ssize) = @_;
				$self->_simplex_log(@_);
			}
		);
	};
	my $err = $@;

	if (!$err)
	{
		$self->{vec_optimal} = $vec_optimal;
		$self->{opt_ssize} = $opt_ssize;
		$self->{minima} = $optval->sclr;
	}
	elsif (!$self->{cancel})
	{
		# re-die if it died for a reason other than cancellation:
		die $err;
	}
	else
	{
		# Log the cancellation:
		$self->_simplex_log(
			$self->{best_vec},
			$self->_simplex_f($self->{best_vec}),
			$self->{prev_ssize}
			);
	}

	# Return the result in the original vars format that was
	# passed to new(vars => {...}) so it matches what the user
	# is expecting by converting it from simple to expanded
	# and finally to original:


	# Using {best_vec} might end up using a value from a previous pass,
	# completely disregarding the current pass best of $vec_optimal.  This
	# should be OK because we make sure that {best_vars} is always populed
	# by the minimum value returned by f().
	my $result = $self->{best_vars};

	$result = _simple_to_expanded($result);

	$result = $self->_expanded_to_original($result);

	# Round final values if any vars have round_result defined:
	_vars_round_result($result);

	# Store the result in the user's format:
	$self->{result} = $result;

	return $result;
}

# This is the simplex callback to evaluate the function "f()"
# based on the content of $self->{vars}:
sub _simplex_f
{
	my ($self, $vec) = @_;

	my @vars = $self->_get_simplex_vars($vec);

	die "BUG: _vars_are_pdl but \@vars > 1!" if $self->{_vars_are_pdl} and @vars > 1;

	# @f_ret is accumulated with iterations over f() when
	# vars are not PDL's because simplex may provide f() with an
	# array of values to test even though the caller's {f}->() may
	# not support PDLs.
	#
	# However, if the caller's vars are all PDLs then _get_simplex_vars
	# will return a single-element array.
	my @f_ret;

	# Sometimes PDL provides multiple variable sets to calculate.  If 'reduce_search'
	# is flagged then treat them as the same and only evaluate the first variable set.
	# This speeds up the optimization but may provide suboptimal results.
	if ($self->{reduce_search})
	{
		# Call the user's function and pass their vars.
		my $ret = $self->call_f($vars[0]);

		# @f_ret is the resulting weight, which is the same for _all_ vars:
		push @f_ret, $ret foreach @vars;
	}
	else
	{
		foreach my $vars (@vars)
		{
			# Call the user's function and pass their vars.
			# @f_ret is the resulting weight for _each_ var:
			push @f_ret, $self->call_f($vars);
		}
	}

	# We could always `pdl \@f_ret` but it creates a double-nested single
	# dimension array pdl.  Better to leave things as they are and only
	# create a PDL from the array if it wasn't a PDL to begin with
	# (ie, when !$self->{_vars_are_pdl}).
	my $f_ret;

	if ($self->{_vars_are_pdl})
	{
		die "BUG: _vars_are_pdl but \@f_ret > 1!" if @f_ret > 1;
		$f_ret = $f_ret[0];
	}
	else
	{
		$f_ret = pdl \@f_ret;
	}

	# $f_ret is guaranteed to be PDL here.  Find the minimum result,
	# that is our best index for this iteration:
	my $min_ind = minimum_ind($f_ret);
	die "best_minima: min_ind > 1: $f_ret" if ($min_ind->nelem > 1);

	my $best_minima = $f_ret->index($min_ind);
	my $best_vars = $vars[$min_ind->sclr]; # better way to unpdl?
	if (!defined($self->{best_minima}) || $best_minima < $self->{best_minima})
	{
		$self->{best_minima} = $best_minima;
		$self->{best_vec} = $vec;
		$self->{best_vars} = $best_vars;
		$self->{best_pass} = $self->{optimization_pass};
	}

	return $f_ret;
}

sub _simplex_log
{
	# $vec is the array of values being optimized
	# $vals is f($vec)
	# $ssize is the simplex size, or roughly, how close to being converged.
	my ($self, $vec, $vals, $ssize) = @_;

	$self->{prev_ssize} = $ssize;
	return unless (defined($self->{log}));

	my $elapsed;
	if ($self->{prev_time})
	{
		$elapsed = time() - $self->{prev_time};
	}
	$self->{prev_time} = time();

	$self->{log_count}++;

	my $minima = $self->{best_minima};

	# Cancel early if stagnated:
	if (defined($self->{stagnant_minima_count}) &&
		defined($self->{prev_minima}) && $self->{prev_minima} < $minima &&
		abs($self->{prev_minima} - $minima) < $self->{stagnant_minima_tolerance})
	{
		$self->{prev_minima_count}++;
		if (!$self->{cancel} && $self->{prev_minima_count} > $self->{stagnant_minima_count})
		{
			$self->{cancel} = 1;
			die "CANCEL";
		}
	}
	elsif (!$self->{cancel})
	{
		# Record the minima for the previous iteration
		# to see if it needs to cancel (above).
		$self->{prev_minima} = $minima; 
		$self->{prev_minima_count} = 0;
	}


	my @log_vars = $self->_get_simplex_vars($vec);
	$self->{log}->($log_vars[0], {
		ssize => $ssize->sclr,
		minima => $minima,
		elapsed => $elapsed,
		srand => $self->{srand},
		optimization_pass => $self->{optimization_pass},

		num_passes => scalar( @{ $self->{_ssize} }),
		best_pass => $self->{best_pass},
		best_minima => $self->{best_minima}->sclr,
		best_vars => $self->{best_vars},
		log_count => $self->{log_count},
		cancel => $self->{cancel},
		prev_minima_count => $self->{prev_minima_count},
		cache_hits => $self->{cache_hits},
		cache_misses => $self->{cache_misses},
		all_vars => \@log_vars
		});
}


sub get_vars_expanded
{
	my $self = shift;

	return $self->{vars};
}

sub get_vars_orig
{
	my $self = shift;

	return $self->{_vars_orig};
}


sub get_vars_simple
{
	my $self = shift;

	return _expanded_to_simple($self->{vars});
}

sub get_result_expanded
{
	my $self = shift;

	return $self->{result};
}

sub get_result_simple
{
	my $self = shift;

	return _expanded_to_simple($self->{result});
}

sub set_vars
{
	my ($self, $vars) = @_;

	# _simple_to_expanded will die if invalid:
	$self->{_vars_orig} = $vars;
	$self->{vars} = _simple_to_expanded($vars);
}

sub set_ssize
{
	my ($self, $ssize) = @_;

	$self->{ssize} = $ssize;
}

sub scale_ssize
{
	my ($self, $scale) = @_;

	$self->{ssize} *= $scale;
}



# build a pdl for use by simplex()
sub _build_simplex_vars 
{
	my ($self) = @_;

	my $vars = $self->{vars};

	my @pdl_vars;

	my $any_pdl;
	my $any_scalar;
	foreach my $var_name (sort keys(%$vars))
	{
		my $var = $vars->{$var_name};

		my $n = scalar(@{ $var->{values} });

		for (my $i = 0; $i < $n; $i++)
		{
			# var is enabled for simplex if enabled[$i] == 1
			if ($var->{enabled}->[$i])
			{
				my $val = $var->{values}->[$i];
				$any_pdl++ if ref($val) eq 'PDL';
				$any_scalar++ if !ref($val);
				push(@pdl_vars, $val / $var->{perturb_scale}->[$i]);
			}
		}
	}

	die "Your {vars} must be either all scalar or all PDL's" if ($any_pdl && $any_scalar);

	$self->{_vars_are_pdl} = 1 if ($any_pdl);

	my $pdl = pdl \@pdl_vars;
	return $pdl;
}

sub _simple_to_expanded
{
	my ($vars) = @_;

	my %valid_opts = map { $_ => 1 } qw/values enabled minmax perturb_scale round_each round_result/;

	my %exp;
	foreach my $var_name (keys(%$vars))
	{
		my $var = $vars->{$var_name};

		# Copy the structure from what was passed into the %exp
		# hash so we can modify it without changing the orignal.
		if (is_numeric($var))
		{
			$var = $exp{$var_name} = { values => [ $vars->{$var_name} ] }
		}
		elsif (ref($var) eq 'ARRAY')
		{
			$var = $exp{$var_name} = { values => $vars->{$var_name} }
		}
		elsif (ref($var) eq 'HASH')
		{
			my $newvar = $exp{$var_name} = {};

			foreach my $opt (keys %$var)
			{
				die "invalid option for $var_name: $opt" if (!$valid_opts{$opt});
			}

			foreach my $opt (keys %valid_opts)
			{
				$newvar->{$opt} = $var->{$opt} if exists($var->{$opt});
			}

			$var = $newvar;
		}
		else
		{
			die "invalid type for $var_name: " . ref($var);
		}

		# Make sure values is valid:
		if (!defined($var->{values}) ||
			(ref($var->{values}) eq 'ARRAY' && !@{$var->{values}}))
		{
			die "$var_name\-\>{values} must be defined"
		}

		if (ref($var->{values}) eq 'ARRAY')
		{
			# make a copy to release the original reference: 
			$var->{values} = [ @{ $var->{values} } ];
		}
		elsif (is_numeric($var->{values}))
		{
			$var->{values} = [ $var->{values} ];
		}
		else
		{
			die "invalid type for $var_name\-\>{values}: " . ref($var->{values});
		}

		my $n = scalar(@{ $var->{values} });


		# If enabled is missing or a non-scalar (ie =1 or =0) then form it properly
		# as either all 1's or all 0's:
		if (!defined($var->{enabled}) || (is_numeric($var->{enabled}) && $var->{enabled}))
		{
			$var->{enabled} = [ map { 1 } (1..$n) ] 
		}
		elsif (defined($var->{enabled}) && is_numeric($var->{enabled}) && !$var->{enabled})
		{
			$var->{enabled} = [ map { 0 } (1..$n) ] 
		}

		if (ref($var->{minmax}) eq 'ARRAY' && is_numeric($var->{minmax}->[0]) && @{$var->{minmax}} == 2)
		{
			$var->{minmax} = [ map { $var->{minmax} } (1..$n) ];
		}

		# Default the perturb_scale to 1x
		$var->{perturb_scale} //= [ map { 1 } (1..$n) ];

		# Make it an array the of length $n:
		if (is_numeric($var->{perturb_scale}))
		{
			$var->{perturb_scale} = [ map { $var->{perturb_scale} } (1..$n) ] 
		}

		if (defined($var->{round_each}) && is_numeric($var->{round_each}))
		{
			$var->{round_each} = [ map { $var->{round_each} } (1..$n) ] 
		}

		if (defined($var->{round_result}) && is_numeric($var->{round_result}))
		{
			$var->{round_result} = [ map { $var->{round_result} } (1..$n) ] 
		}

		# Sanity checks
		if (defined($var->{enabled}) && $n != scalar(@{ $var->{enabled} }))
		{
			die "variable $var_name must have the same length array for 'values' as for 'enabled'"
		}

		if (defined($var->{perturb_scale}) && $n != scalar(@{ $var->{perturb_scale} }))
		{
			die "variable $var_name must have the same length array for 'values' as for 'perturb_scale'"
		}

		if (defined($var->{minmax}))
		{
			if ($n != scalar(@{ $var->{minmax} }))
			{
				die "variable $var_name must have the same length array for 'values' as for 'minmax'"
			}

			for (my $i = 0; $i < $n; $i++)
			{
				my $mm = $var->{minmax}->[$i];

				if (ref($mm) ne 'ARRAY' || @$mm != 2)
				{
					die "$var_name\-\>{minmax} is not a 2-dimensional arrayref with [min,max] for each.";
				}

				my ($min, $max) = @$mm;

				if ($var->{values}->[$i] < $min)
				{
					die "initial value for $var_name\[$i] beyond constraint: $var->{values}->[$i] < $min " 
				}

				if ($var->{values}->[$i] > $max)
				{
					die "initial value for $var_name\[$i] beyond constraint: $var->{values}->[$i] > $max " 
				}
			}
		}
	}

	return \%exp;
}

# Return vars as documented below in POD:
sub _expanded_to_simple
{
	my $vars = shift;

	my %h;

	foreach my $var (keys %$vars)
	{
		if (ref($vars->{$var}) eq 'HASH')
		{
			defined($vars->{$var}->{values}) or die "undefined 'values' array for var: $var";
			$h{$var} = $vars->{$var}->{values};
		}
		elsif (ref($vars->{$var}) eq 'ARRAY')
		{
			$h{$var} = $vars->{$var};
		}
		elsif (is_numeric($vars->{$var}))
		{
			$h{$var} = [ $vars->{$var} ];
		}
		else
		{
			die "unknown ref for var=$var: " . ref($vars->{$var});
		}

		if (ref($h{$var}) eq 'ARRAY' && scalar(@{ $h{$var} } ) == 1)
		{
			$h{$var} = $h{$var}->[0];
		}
	}

	return \%h;
}


# Return the $exp vars in the same original format as defined by $orig.  This is called as follows:
#   $self->_expanded_to_original($self->{vars})
#
sub _expanded_to_original
{
	my ($self, $exp) = @_;

	my $orig = $self->{_vars_orig};

	my %result;
	foreach my $var_name (keys(%$orig))
	{
		if (is_numeric($orig->{$var_name}))
		{
			$result{$var_name} = $exp->{$var_name}->{values}->[0];
		}
		elsif (ref($orig->{$var_name}) eq 'ARRAY')
		{
			$result{$var_name} = [ @{ $exp->{$var_name}->{values} } ];
		}
		elsif (ref($orig->{$var_name}) eq 'HASH')
		{
			my $origvar = $orig->{$var_name};
			my $newvar = {};

			if (ref($orig->{$var_name}->{values}) eq 'ARRAY')
			{
				$newvar->{values} = [ @{ $exp->{$var_name}->{values} } ];
			}
			else
			{
				$newvar->{values} = $exp->{$var_name}->{values}->[0];
			}

			foreach my $opt (qw/enabled minmax perturb_scale round_each round_result/)
			{
				$newvar->{$opt} = $origvar->{$opt} if exists($origvar->{$opt});
			}

			$result{$var_name} = $newvar;
		}
	}

	return \%result;
}

# Use the round_result attribute of each var (if defined) to round
# the var to its nearest value.  $vars must be in expanded format.
sub _vars_round_result
{
	my ($vars) = @_;

	foreach my $var_name (keys(%$vars))
	{
		my $var = $vars->{$var_name};
		my @round_result;

		next if ref($var) ne 'HASH';
		next unless defined $var->{round_result};

		# In case values it not an array:
		if (is_numeric($var->{values}))
		{
			$var->{values} = pdl_nearest($var->{round_result}, $var->{values}, 'round_result');
			next;
		}

		my $n = @{ $var->{values} };

		# use temp var @round_result so we don't mess with the $vars structure.
		if (is_numeric($var->{round_result}))
		{
			@round_result = map { $var->{round_result} } (1..$n);
		}
		else 
		{
			@round_result = @{ $var->{round_result} };
		}

		# Round to a precision if defined:
		foreach (my $i = 0; $i < $n; $i++)
		{
			$var->{values}->[$i] = pdl_nearest($round_result[$i], $var->{values}->[$i], 'round_result');
		}
	}

}

# get a var by name from $self->{vars} but get the value from the pdl if
# the var is enabled for optimization. Also minmax/perturb_scale as if defined.
# Returns an array of values representing the variable vector, even if the
# variable is single-valued.
sub _get_simplex_var
{
	my ($self, $pdl, $var_name) = @_;

	my $vars = $self->{vars};

	my @ret;
	
	my $var = $vars->{$var_name};

	my $pdl_idx = 0;

	# skip ahead to where the pdl_idx that we need is located if $var_name
	# is not the first $var we find in the list:
	foreach my $vn (sort keys(%$vars))
	{
		my $var = $vars->{$vn};

		# done if we find it:
		last if $vn eq $var_name;

		# Increment pdl_idx for each element of the {enabled} array
		# that is enabled because that is how it is packed into the pdl.
		# The value of $_ in grep{} is either 1 or 0:
		$pdl_idx++ foreach (grep { $_ } @{ $var->{enabled} });
	}

	# Iterate each value and pull it in from the simplex vector 
	# if that particular array index is enabled:
	my $n = scalar(@{ $var->{values} });

	for (my $i = 0; $i < $n; $i++)
	{
		my $val;

		# use the pdl index if it is enabled for optimization
		# otherwise use the original index in $var.
		if ($var->{enabled}->[$i])
		{
			$val = $pdl->slice("($pdl_idx)");
			$val *= $var->{perturb_scale}->[$i];
			$pdl_idx++;
		}
		else
		{
			$val = $var->{values}->[$i];
		}

		# Modify the resulting value depending on these rules:
		if (defined($var->{minmax}))
		{
			my ($min, $max) = @{ $var->{minmax}->[$i] };
			$val = clamp_minmax($val, $min => $max, $var_name);
		}

		# Round to the nearest value on each iteration.
		# It is probably best to round at the end to keep
		# precision during each iteration, but the option
		# is available:
		if (defined($var->{round_each}))
		{
			$val = pdl_nearest($var->{round_each}->[$i], $val, $var_name);
		}

		push @ret, $val; 
	}

	return \@ret;
}

sub pdl_nearest
{
	my ($nearest, $val, $noun) = @_;

	$noun //= 'round_each/round_result';

	if (ref($val) ne 'PDL')
	{
		$val = nearest($nearest, $val);
	}
	else
	{
		# Is there a better way? This assumes the round_each array is not a pdl.
		# The problem is that simplex will give us a piddle of piddles: we might be
		# passed a PDL with several sliceable values and we need to call nearest on
		# each element of each element.
		#
		# It would be helpful if PDL had a native nearest() impelementation.

		my $idx = 0;
		$val = pdl_map(sub { nearest($nearest, $_[0]) }, $val);
	}

	return $val;
}

sub pdl_map
{
	my ($sub, $val) = @_;
	my @slices;
	for (my $slice_idx = 0; $slice_idx < $val->nelem; $slice_idx++)
	{
		my $s = $val->slice("($slice_idx)");

		my $idx = 0;
		if ($s->nelem > 1) 
		{
			die "BUG: PDLs with more than one value do not work with the pdl_map function."
		}

		$s = $sub->(@{ unpdl $s });
		push @slices, $s;
	}

	# Avoid the PDL of "123" becoming "[123]":
	if (@slices > 1)
	{
		$val = pdl \@slices;
	}
	else
	{
		$val = pdl $slices[0];
	}

	return $val;
}

sub clamp_minmax
{
	my ($val, $min, $max) = @_;

	if (ref($val) eq 'PDL')
	{
		$val .= $val->clip($min, $max);
	}
	elsif ($val < $min)
	{
			$val = $min;
	}
	elsif ($val > $max)
	{
		$val = $max;
	}

	return $val;
}

# get all vars replaced with resultant simplex values if enabled=>1 for that var.
sub _get_simplex_vars
{
	my ($self, $pdl) = @_;	
	
	my $vars = $self->{vars};

	my %h;

	# Get values by name from _get_simplex_var: each of these will be ARRAY-ref's
	# even if there is only one value:
	foreach my $var_name (keys %$vars)
	{
		$h{$var_name} = $self->_get_simplex_var($pdl, $var_name);
	}

	# If all the input variables are PDL's, then f() must support PDL's as inputs.
	#
	# else: If all the input variables are _not_ PDLs, then break the PDL's into
	#       an array of var-hashes and _optimize() will evaluate them iteratively.
	my @ret;
	if ($self->{_vars_are_pdl})
	{
		@ret = (\%h);
	}
	else
	{
		# Note: Many of the foreach loops below are dependent on the previous loop
		# finishing.  It is not possible to merge all loops into one as currently
		# implemented.

		# First find the $pdl->nelem that was passed by simplex.  This is the number of
		# entries that must be evaluated, and any non-PDL items that exist when
		# `!$vars->{$var_name}->{enabled}->[$i]` need to be turned into PDLs
		# of the same number of elements so simplex is happy.
		#
		# Really we should be able to `last` at the first PDL we find, but 
		# we iterate all of them to sanity-check the code and trigger a `die` below
		# if they differ, because that means our assumption about how simplex works is wrong:
		my $pdl_size;
		foreach my $var_name (keys %h)
		{
			foreach my $a (grep { ref($_) eq 'PDL' } @{ $h{$var_name} })
			{
					my $nelem = $a->nelem;

					if (defined($pdl_size) && $pdl_size != $nelem)
					{
							die "BUG: $var_name\->nelem differs from previous vars ($pdl_size != $nelem)";
					}
					else
					{
							$pdl_size //= $nelem;
					}
			}
		}

		if (!$pdl_size)
		{
			die "pdl_size is undefined or zero, are you using any zero-dimension variable arrays?"
		}

		# Now that we know the $pdl_size, make PDLs of the right size for any non-PDLs
		# so we can slice them into multiple var sets.
		foreach my $var_name (keys %h)
		{
			my @a;
			foreach my $a (@{ $h{$var_name} })
			{
				if (ref($a) eq 'PDL')
				{
					push @a, $a;
				}
				elsif (ref($a) eq '')
				{
					push @a, pdl [ map { $a } (1..$pdl_size ) ]
				}
				else
				{
					die "$var_name: unhandled ref type: " . ref($a);
				}
			}
			$h{$var_name} = \@a;
		}


		# At this point all elements to pass to f() should be PDLs.
		# Break them into an independent vars hash and place each in
		# @ret.  Note that each of $h{$var_name} is still an ARRAY-ref
		# even if there is a single element:
		foreach my $var_name (keys %h)
		{
			my $a_idx = 0;
			foreach my $a (@{ $h{$var_name} })
			{
				my $pdl_idx = 0;
				foreach my $e ($a->list)
				{
					$ret[$pdl_idx]->{$var_name}->[$a_idx] = $e;
					$pdl_idx++;
				}
				$a_idx++;
			}
		}
	}

	# Collapse single-element arrays as scalars so f() doesn't need to
	# do something like $vars->{x}[0] and can just use $vars->{x} directly:
	foreach my $r (@ret)
	{
		foreach my $var_name (keys %$r)
		{
			if (scalar(@{ $r->{$var_name} }) == 1)
			{
				$r->{$var_name} = $r->{$var_name}->[0];
			}
		}
	}

	die "BUG: _get_simplex_vars: !wantarray but \@ret > 1: pdl=$pdl" if @ret > 1 and !wantarray;

	return $ret[0] if (!wantarray);

	return @ret;
}

sub get_best_simplex_vars
{
	my $self = shift;

	return $self->_get_simplex_vars($self->{best_vec});
}

sub var_cache
{
	my ($self, $vars, $value) = @_;

	return undef if ($self->{nocache});

	my $key = '';
	foreach my $var_name (sort keys(%$vars))
	{
		$key .= "$var_name=";
		if (is_numeric($vars->{$var_name}))
		{
			$key .= $vars->{$var_name}
		}
		elsif (ref $vars->{$var_name} eq 'ARRAY')
		{
			$key .= join(',', @{ $vars->{$var_name} });
		}
		else
		{
			die "$var_name: invalid ref: " . ref($vars->{$var_name});
		}

		$key .= ';'
	}

	if (defined($value) && !defined($self->{_var_cache}{$key}))
	{
		$self->{_var_cache}{$key} = $value;
		return $value;
	}
	elsif (defined($self->{_var_cache}{$key}))
	{
		$self->{cache_hits}++;
		return $self->{_var_cache}{$key};
	}
	else
	{
		$self->{cache_misses}++;

		return undef;
	}
}

sub call_f
{
	my ($self, $vars) = @_;

	# Try to use a cached result:
	my $result = $self->var_cache($vars);

	if (!defined($result))
	{
		$result = $self->{f}->($vars);
		$self->var_cache($vars => $result);
	}

	return $result;
}

sub is_numeric
{
	my $var = shift;
	return (!ref($var) || ref($var) eq 'PDL')
}

# This is for debugging:
#
# Builds a tree from $h that is suitable for passing to Data::Dumper.
# This is neccesary because PDL's need to be stringified since Dumper()
# will dump at the object itself.
sub dumpify
{
	my $h = shift;

	return "(undef)" if (!defined($h));
	return "scalar:$h" if (ref($h) eq '');
	return "PDL:$h" if (ref($h) eq 'PDL');

	return { map { $_ => dumpify($h->{$_}) } keys(%$h) } if (ref($h) eq 'HASH');
	return [ map { dumpify($_) } @$h ] if (ref($h) eq 'ARRAY');

	die 'dumpify: unhandled reference: ' . ref($h);
}

1;

__END__

=head1 NAME

PDL::Opt::Simplex::Simple - A simplex optimizer for the rest of us
(who may not know PDL).


=head1 SYNOPSIS

	use PDL::Opt::Simplex::Simple;

	# Simple single-variable invocation

	$simpl = PDL::Opt::Simplex::Simple->new(
		vars => {
			# initial guess for x
			x => 1 
		},
		f => sub { 
				# Parabola with minima at x = -3
				return (($_->{x}+3)**2 - 5) 
			}
	);

	$simpl->optimize();
	$result_vars = $simpl->get_result_simple();

	print "x=" . $result_vars->{x} . "\n";  # x=-3


	# Multi-vector Optimization and other settings:

	$simpl = PDL::Opt::Simplex::Simple->new(
		vars => {
			# initial guess for arbitrarily-named vectors:
			vec1 => { values => [ 1, 2, 3 ], enabled => [1, 1, 0] }
			vec2 => { values => [ 4, 5 ],    enabled => [0, 1] }
		},
		f => sub { 
				my ($vec1, $vec2) = ($_->{vec1}, $_->{vec2});
				
				# do something with $vec1 and $vec2
				# and return() the result to be minimized by simplex.
			},
		log => sub { }, # log callback
		ssize => 0.1,   # initial simplex size, smaller means less perturbation
		max_iter => 100 # max iterations
	);


	$result_vars = $simpl->optimize();

	use Data::Dumper;

	print Dumper($result_vars);


=head1 DESCRIPTION

This class uses L<PDL::Opt::Simplex> to find the values for C<vars>
that cause the C<f> coderef to return the minimum value.  The difference
between L<PDL::Opt::Simplex> and L<PDL::Opt::Simplex::Simple> is that
L<PDL::Opt::Simplex> expects all data to be in PDL format and it is
more complicated to manage, whereas, L<PDL::Opt::Simplex:Simple> uses
all scalar Perl values. (PDL values are supported, too, see the PDL use case
note below.)

With the original L<PDL::Opt::Simplex> module, a single vector array
had to be sliced into the different variables represented by the array.
This was non-intuitive and error-prone.  This class attempts to improve
on that by defining data structure of variables, values, and whether or
not a value is enabled for optimization.

This means you can selectively disable a particular value and it will be
excluded from optimization but still included when passed to the user's
callback function C<f>.  Internal functions in this class compile the state
of this variable structure into the vector array needed by simplex,
and then extract values into a usable format to be passed to the user's
callback function.

=head1 FUNCTIONS

=over 4 

=item * $self->new(%args) - Instantiate class

=item * $self->optimize() - Run the optimization

=item * $self->get_vars_expanded() - Returns the original C<vars> in a fully expanded format

=item * $self->get_vars_simple() - Returns C<vars> in the simplified format

This format is suitable for passing into your C<f> callback.

=item * $self->get_vars_orig() - Returns C<vars> in originally passed format

=item * $self->get_result_expanded() - Returns the optimization result in expanded format.

=item * $self->get_result_simple() - Returns the optimization result in the simplified format

This format is suitable for passing into your C<f> callback.

=item * $self->set_vars(\%vars) - Set C<vars> as if passed to the constructor.

This can be used to feed a result from $self->get_result_expanded() into
a new refined simplex iteration.

=item * $self->set_ssize($ssize) - Set C<ssize> as if passed to the constructor.

Useful for calling simplex again with refined values

=item * $self->scale_ssize($scale) - Multiply the current C<ssize> by C<$scale>

=back

=head1 ARGUMENTS

=head2 * C<vars> - Hash of variables to optimize: the answer to your question.

=head3 - Simple C<vars> Format

Thes are the variables being optimized to find a minimized result.
The simplex() function returns minimized set of C<vars>. In its Simple
Format, the C<vars> setting can assign values for vars directly as in the
synopsis above:

	vars => {
		# initial guesses:
		x => 1,
		y => 2, ...
	}

or as vectors of (possibly) different lengths:

	vars => {
		# initial guess for x
		u => [ 4, 5, 6 ],
		v => [ 7, 8 ], ...
	}

=head3 - Expanded C<vars> Format

You may find during optimization that it would
be convenient to disable certain elements of the vector being optimized
if, for example, you know that one value is already optimal but that it
needs to be available to the f() callback.  The expanded format shows
that the 4th element is excluded from optimization by setting enabled=0
for that index.

Expanded format:  

	vars => {
		varname => {
			"values"         =>  [...],
			"minmax"         =>  [ [min=>max],  ...
			"perturb_scale"  =>  [...],
			"enabled"        =>  [...],
		},  ...
	}

=over 4

=item C<varname>: the name of the variable being used.

=item C<values>:  an arrayref of values to be optimized

=item C<minmax>:  a double-array of min-max pairs (per index for vectors)

Min-max pairs are clamped before being evaluated by simplex.

=item C<round_result>:  Round the value to the nearest increment of this value upon completion

You may need to round the final output values to a real-world limit after optimization
is complete.  Setting round_result will round after optimization finishes, but leave 
full precision while iterating.  See also: C<round_each>.

This function uses L<Math::Round>'s C<nearest> function:

	nearest(10, 44)    yields  40
	nearest(10, 46)            50
	nearest(10, 45)            50
	nearest(25, 328)          325
	nearest(.1, 4.567)          4.6
	nearest(10, -45)          -50

=item C<round_each>:  Round the value to the nearest increment of this value on each iteration.

It is probably best to round at the end (C<round_result>) to keep precision
during each iteration, but the option is available in case you wish to
use it.

=item C<perturb_scale>:  Scale parameter before being evaluated by simplex (per index for vectors)

This is useful because Simplex's C<ssize> parameter is the same for all
values and you may find that some values need to be perturbed more or
less than others while simulating.  User interaction with C<f> and the
result of C<optimize> will use the normally scaled values supplied by
the user, this is just an internal scale for simplex.

=over 4

=item Bigger value:  perturb more

=item Smaller value:  perturb less

=back

Internal details: The value passed to simplex is divided by perturb_scale
parameter before being passed and multiplied by perturb_scale when
returned.  Thus, perturb_scale=0.1 would make simplex see the value as
being 10x larger effectively perturbing it less, whereas, perturb_scale=10
would make it 10x smaller and perturb it more.

=item C<enabled>: 1 or 0: enabled a specific index to be optimized (per index for vectors)

=over 4

=item * If 'enabled' is undefined then all values are enabled.

=item * If 'enabled' is not an array, it can be a scalar 0 or 1 to
indicate that all values are enabled/disabled.  In this case your original
structure will be replaced with an arrayref of all 0/1 values.

=item * Enabling or disabling a variable may be useful in testing
certain geometry charactaristics during optimization.

Internally, all values are vectors, even if the vectors are of length 1,
but you can pass them as singletons like C<spaces> as shorthand shown below instead
of writing "spaces => [5]".  In that example you can see that C<spaces> is disabled
as well, so simplex will not optimize that value.  

    spaces => [ 5 ]

    # Element lengths                                                
    vars => {
        lengths => {                                                     
            values         =>  [  1.038,       0.955,        0.959 ],
            minmax         =>  [  [0.5=>1.5],  [0.3=>1.2],  [0.2=>1.1] ],
            perturb_scale  =>  [  10,          100,          1 ],
            enabled        =>  [  1,           1,            1 ],
        },                                                       
        spaces => {
            values => 5, 
            enabled => 0
        },
        ...
    }

=back

=back

=head2 * C<f> - Callback function to operate upon C<vars>

The C<f> argument is a coderef that is called by the optimizer.  It is passed a hashref of C<vars> in 
the Simple Format and must return a scalar result:

	f->({ lengths => [ 1.038, 0.955, 0.959, 0.949, 0.935 ], spaces => 5 });

Note that a single-length vector will always be passed as a scalar to C<f>:

	vars => { x => [5] } will be passed as f->({ x => 5 })

The Simplex algorithm will work to minimize the return value of your C<f> coderef, so return 
smaller values as your variables change to produce a (more) desired outcome.

=head2 * C<log> - Callback function log status for each iteration.

	log => sub { 
			my ($vars, $state) = @_;
		
			print "LOG: " . Dumper($vars, $state);
		}

The log() function is passed the current state of C<vars> in the
same format as the C<f> callback.  A second C<$state> argument is passed
with information about the The return value is ignored.  The following 
values are available in the C<$state> hashref:

    {
	'ssize' => '704.187123721893',  # current ssize during iteration
	'minima' => '53.2690700664067', # current minima returned by f()
	'elapsed' => '3.12',            # elapsed time in seconds since last log() call.
	'srand' => 55294712,            # the random seed for this run
	'log_count' => 5,               # how many times _log has been called
	'optimization_pass' => 3,       # pass# if multiple ssizes are used
	'num_passes' => 6,              # total number of passes
	'best_pass' =>  3,              # the pass# that had the best goal result
	'best_minima' => 0.2345         # The least value so far, returned by "f"
	'best_vars' => { x=>1, ...}     # The vars associated with "best_minima"
	'log_count' => 22,              # number of times log has been called
	'prev_minima_count' => 10,      # number of same minima's in a row
	'cancel' =>     0,              # true if the simplex iteration is being cancelled
	'all_vars' => [{x=>1},...],     # multiple var options from simplex are logged here
	'cache_hits' => 100,            # Number of times simplex asked to try the same vars
	'cache_misses' => 1000,         # Number of times simplex asked to try unique vars
    }


=head2 * C<ssize> - Initial simplex size, see L<PDL::Opt::Simplex>

Think of this as "step size" but not really, a bigger value makes larger
jumps but the value doesn't translate to a unit.  (It actually stands
for simplex size, and it initializes the size of the simplex tetrahedron.)

You will need to scale the C<ssize> argument depending on your search
space.  Smaller C<ssize> values will search a smaller space of possible
values provided in C<vars>.  This is problem-space dependent and may
require some trial and error to tune it where you need it to be.

Example for optimizing geometry in an EM simulation: Because it is
proportional to wavelength, lower frequencies need a larger value and
higher frequencies need a lower value.

The C<ssize> parameter may be an arrayref:  If an arrayref is specified
then it will run simplex to completion using the first ssize and then
restart with the next C<ssize> value in the array.  Each iteration uses
the best result as the input to the next simplex iteration in an attempt
to find increasingly better results.  For example, 4 iterations with each
C<ssize> one-half of the previous:

	ssize => [ 4, 2, 1, 0.5 ]


Default: 1

=head2 * C<nocache> - Disable result caching

By default we try not to re-calculate the same values.  This is particularly
useful when C<round_each> is used because it will round values from before
passing them to C<f>, which increases the chance of a cache hit.

If you wish to disable caching then set "nocache => 1"

Default: undef (cache enabled)

=head2 * C<max_iter> - Maximim number of Simplex iterations

Note that one Simplex iteration may call C<f> multiple times.

Default: 1000

=head2 * C<tolerance> - Conversion tolerance for Simplex

The default is 1e-6.  It tells Simplex to stop before C<max_iter> if 
very little change is being made between iterations.

Default: 1e-6

=head2 * C<srand> - Value to seed srand

Simplex makes use of random perturbation, so setting this value will make
the simulation deterministic from run to run.

The default when not defined is to call srand() without arguments and use
a randomly generated seed.  If set, it will call srand($self->{srand})
to initialize the initial seed.  The result of this seed (whether passed
or generated) is available in the status structure defined above.

Default: system generated.

=head2 * C<stagnant_minima_count> - Abort the simplex iteration if the minima is not changing

This is the maximum number of iterations that can return a worse minima
than the previous minima. Once reaching this limit the current iteration
is cancelled due to stagnation. Setting this too low will provide poor
results, setting it too high will just take longer to iterate when it
gets stuck.

Note: This value may be somewhat dependent on the number of variables
you are optimizing.  The more variables, the bigger the value.  A value
of 30 seems to work well for 10 variables, so adjust if necessary.

Simplex will not cancel due to stagnation when C<stagnant_minima_count> is
undefined.

Default: undef

=head2 * C<stagnant_minima_tolerance> - threshold to count toward C<stagnant_minima_count>

When C<abs($prev_minima - $cur_minima) < $stagnant_minima_count> then the
iteration will be counted toward stagnation when C<stagnant_minima_count> is
defined (see above).  Otherwise, we assume progress is being made and the
stagnation count is reset.

Default: same as C<tolerance> (see above)

=head2 C<reduce_search> - Reduce the search space

Sometimes PDL provides multiple variable sets to calculate during an iteration.
If C<reduce_search =E<gt> 1> is flagged then treat all variable sets as the
same by only evaluating the first variable set and returning that result for
all sets.  This speeds up the optimization but may provide sub-optimal results.

This was the original behavior in back in Version 1.1, so newer versions are (probably) more
accurate but will take longer to complete.  However, it is still useful if you have a slow
computation (C<f>) and want to converge sooner for an initial first pass.  It is still recommended
to run a final pass without C<reduce_search>.

=head1 BEST PRACTICES AND USE CASES

=head2 Antenna Geometry: Use an array for the C<ssize> parameter from coarse to fine perturbation.

This C<PDL::Opt::Simplex::Simple> module was originally written to optimize
antenna geometries in conjunction with the "Optimizer Output" feature of the
xnec2c (L<https://www.xnec2c.org>) antenna simulator. The behavior is best
described by Neoklis Kyriazis, 5B4AZ who originally wrote xnec2c:
L<http://www.5b4az.org/pages/antenna_designs.html>

	"Xnec2c monitors its .nec input file for changes and re-runs the
	frequency stepping loop which recalculates new data and prints to the
	.csv file. It is therefore possible to arrange the optimizer program to
	read the .csv data file, recalculate antenna parameters and save them
	to the .nec input file.

	Xnec2c will then recalculate and save new frequency-dependent data to
	the .csv file.  If the optimizer program is arranged to monitor changes
	to the .csv file, then a continuous loop can be created in which new
	antenna parameters are calculated and saved to the .nec file, new
	frequency dependent data are calculated and saved to the .csv file and
	the loop repeated until the desired results (optimization) are
	obtained."

We find that a coarse "first pass" value for C<ssize> may not produce optimal
results, so C<PDL::Opt::Simplex::Simple> will perform additional simplex
iterations if you specify C<ssize> with multiple values to retry once a
previous iteration finds a "good" (but not "great") result; the best minima
from across all simplex passes is kept as the final result in case latter passes
do not perform as well:

	ssize => [ 0.090, 0.075, 0.050, 0.025, 0.012 ]

This allows us to optimize antenna gain from 10.2 dBi with a single pass to
11.3 dBi after 5 passes, in addition to a much improved VSWR value.

See L<https://github.com/KJ7LNW/xnec2c-optimize> for sample graphs and more
information, including documentation to setup the demo so you can see
C<PDL::Opt::Simplex::Simple> in action as the graphs update in real-time during
the optimization process.


=head2 PID Controller: Set ssize to 1 and scale perturb_scale for each variable.

We were using a proportional-integral-derivative ("PID") controller to
optimize antenna motion for tracking orbiting satellites like the International
Space Station.  The goal is to minimize rotor overshoot and increase accuracy
for the azimuth and elevation axis.  Without getting into the PID controller
implementation, just know that there are 3 primary terms in a PID controller
that define its behavior (Kp, Ki, and Kd),  and the satellite tracking is
"good" if the overshoot is minimal.  Here is a trivial implementation:

	$simpl = PDL::Opt::Simplex::Simple->new(
		vars => {
			# initial guess for kp, ki, kd:
			kp => 150,
			ki => 120,
			kd => 5
		},
		ssize => 1,
		f => sub { 
				my $vars = shift;
				
				return track_satellite_get_overshoot(
					kp => $vars->{kp},
					ki => $vars->{ki},
					kd => $vars->{kd});
			}
	);

	print Dumper $simpl->optimize();

Note that C<ssize=1> so simplex will purturb the kp/ki/kd values in the range of about 1.  This 
is great if you are already close to a solution, but in our case kp, ki, and kd need perturbed 
different amounts.  It turns out that kd is quite small, while the optimal kp and ki values
need a larger search space.

You might consider increasing C<ssize>, to C<ssize=20> but then kd will scale too quickly.  To achieve
this we used the extended variable format as follows:

	$simpl = PDL::Opt::Simplex::Simple->new(
		vars => {
			# initial guess for kp, ki, kd:
			kp => {
				values => 150,
				perturb_scale => 20,
			},

			ki => {
				values => 120,
				perturb_scale => 15,
			},

			kd => {
				values => 5,
				perturb_scale => 1,
			},
		},
		ssize => 1, # <- ssize is still set to 1 !
		f => sub { 
				my $vars = shift;
				
				return track_satellite_get_overshoot(
					kp => $vars->{kp},
					ki => $vars->{ki},
					kd => $vars->{kd});
			}
	);

	print Dumper $simpl->optimize();

As you can see above, the C<perturb_scale> value is different for each value;
you could think of C<perturb_scale> as a "local ssize".  Note that C<ssize>
will still scale everything so if you wish to leave the relative scales defiend
by C<perturb_scale> but double the search space, then set C<ssize=2>.  

Ultimately simplex found the values to work best around Kp=190.90, Ki=166.33,
and Kd=1.02.  These values are specific to our hardware implementation
(rotational mass, motor speed, etc) so the procedure is what is important here,
not the values.  Typically simplex is used against mathematical models, and it
was interesting to run simplex against a real physical machine to calculate
ideal values for its control.  

If you are interested, here is a video about the antenna construction: 
L<https://youtu.be/Ab_oJHlENwo>

=head2 PDL variable considerations

You can use pdl's as vars in your code, but at the moment those pdl's must be singletons.

This will work:

	->new({
		vars => { x => pdl(5) }
	}, ...)

but this will not:

	->new({
		vars => { x => pdl([1,2,3]) }
	}, ...)

If you need PDL vectors in your C<f()> call then this could work because
L<PDL::Opt::Simplex::Simple> can optimize perl ARRAY ref's:

	->new({
		vars => { x => [1,2,3] }
	}, 
	f => sub {
		my $vars = shift;
		my $x = pdl $vars->{x};

		# do stuff here, maybe return the sum:

		return unpdl(sum $x);
	},
	...)

Future support for this is possible, but there is one major consideration: PDLs
need to be generically decomposed into a 1-dimensionaly PDL before passing it
to simplex() and then convert it back to the original N-dimensional form before
passing it to the user's C<f()> call.  This would then enable hash-named
N-dimensional pdl optimization.

Patches welcome ;)


=head1 SEE ALSO

=head2 Upstream modules:

=over 4

=item Video about how optimization algorithms like Simplex work, visually: L<https://youtu.be/NI3WllrvWoc>

=item Wikipedia Article: L<https://en.wikipedia.org/wiki/Simplex_algorithm>,

=item PDL Implementation of Simplex: L<PDL::Opt::Simplex>, L<http://pdl.perl.org/>

=item This modules github repository: L<https://github.com/KJ7LNW/perl-PDL-Opt-Simplex-Simple>

=back

=head2 Example links:

=over 4

=item Antenna Geometry Optimization: L<https://github.com/KJ7LNW/xnec2c-optimize>

=item PID Controller Optimization: L<https://github.com/KJ7NLL/space-ham/blob/master/optimize-pid.pl>

=back


=head1 AUTHOR

Originally written at eWheeler, Inc. dba Linux Global Eric Wheeler to
optimize antenna geometry for the L<https://www.xnec2c.org> project.


=head1 COPYRIGHT

Copyright (C) 2022 eWheeler, Inc. L<https://www.linuxglobal.com/>

This module is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation, either version 3 of the License, or (at your
option) any later version.

This module is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along
with this module. If not, see <http://www.gnu.org/licenses/>.

