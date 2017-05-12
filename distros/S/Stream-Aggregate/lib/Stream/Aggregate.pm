#
# TODO: what this can't handle right now is things like:
#
#	* how many different URLs were there on a per query basis?
#

package Stream::Aggregate;

use strict;
use warnings;
use Hash::Util qw(lock_keys);
use B::Deparse;
use List::Util qw(min max minstr maxstr);
use Config::Checker;
use Stream::Aggregate::Stats;
use Stream::Aggregate::Random;
use List::EvenMoreUtils qw(list_difference_position);
use Tie::Function::Examples qw(%line_numbers);
use Eval::LineNumbers qw(eval_line_numbers);
use Config::YAMLMacros::YAML;
use Carp qw(confess);
use List::MoreUtils qw(uniq);
use Clone qw(clone);

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(generate_aggregation_func);
our $VERSION = 0.406;

our $suppress_line_numbers = 0;

my $prototype_config = <<'END_PROTOTYPE';
max_stats_to_keep:      '?<4000>Maximum number of stats to keep for mean/stddev etc[INTEGER]'
context:                '?From $log, return an array describing the current context[CODE]'
context_config:         '%optional configuration hash for "context" code'
context2columns:        '?From @current_context, return a hash of columns[CODE]'
context2columns_config: '%optional configuration hash for "context2columns" code'
stringify_context:      '?Turn @currnet_context into an array of strings[CODE]'
stringify_context_config: '%optional configuration hash for "stringify_context" code'
finalize_result:        '?Final opportunity to adjust the return values[CODE]'
finalize_result_config: '%optional configuration has for "finalize_result" code'
filter:                 '?Should this result be saved for statistics and counted for counts?[CODE]'
filter_config:          '%optional configuration hash for "filter" code'
filter_early:           '?<0>Check the filter early (before figuring out contexts)?[BOOLEAN]'
passthrough:            '?Any additional items for the output?[CODE]'
passthrough_config:     '%optional configuration has for "passthrough" code'
ephemeral:              '%ephemeral columns (column -> code)'
ephemeral0:             '%ephemeral columns (column -> code, evaluated before "ephemeral")'
ephemeral2:             '%ephemeral columns (column -> code, evaluated after "ephemeral")'
ephemeral3:             '%ephemeral columns (column -> code, evaluated after crossproduct has set context (after "ephemeral2"))'
output:                 '%generated output columns (column -> code)'
counter:                '%counter columns (column -> code)'
percentage:             '%like a counter, but divided by the number of items'
sum:                    '%summation columns (column -> code)'
dominant:               '%most frequent (mode) value (column -> code)'
mean:                   '%mean value columns (column -> code)'
standard_deviation:     '%standard deviaton value columns (column -> code)'
median:                 '%median value columns (column -> code)'
min:                    '%min value columns (column -> code)'
max:                    '%max value columns (column -> code)'
minstr:                 '%minstr value columns (column -> code)'
maxstr:                 '%maxstr value columns (column -> code)'
keep:                   '%list of values to keep'
stat:                   '%statistical columns (using keep, column -> code)'
debug:                  '?<0>Print out the code for debugging'
strict:                 '?<0>enforce strict and warnings for user code'
preprocess:             '?Code to pre-process the input data[CODE]'
item_name:              '?<$log>Name of the item variable'
new_context:            '?Code that is run when there is a new context[CODE]'
new_context_config:     '%optional configuration hash for "new_context" code'
merge:                  '?Code that is run when merging a subcontext into a parent context[CODE]'
merge_config:           '%optional configuration hash for "merge" code'
reduce:                 '?Code that is run when reducing the saved data to save memory[CODE]'
merge_config:           '%optional configuration hash for "reduce" code'
crossproduct:           '%crossproduct context, keys are existing columns, values are size limits'
simplify:               '%code to choose new simpler values for over-full columns (column -> code)'
combinations:           '%code to decide if new crossproduct context ($row) is worth keeping[CODE]'
END_PROTOTYPE

sub nonblank
{
	my $value = shift;
	return undef unless defined $value;
	return undef if $value eq '';
	return $value;
}

sub resume_line_numbering
{
	my ($pkg, $file, $line) = caller(0);
	return sprintf(qq{#line %d "generated-code-interpoloated-after-%s-%d"\n}, $line, $file, $line);
}

sub generate_aggregation_func
{
	my ($agg_config, $extra, $user_extra) = @_;

	validate_aggregation_config($agg_config);

	my $renumber = ! $agg_config->{debug};

	# input data
	my $itemref;
	my $last_item;

	# 
	# if counting URLs, then the @current_context might be something like:
	#	'com', 'apple', '/movies', '/action'
	# If counting queries it might be something like:
	# 	'homocide',	'movies'
	#
	# @contexts is an array to state variables ($ps) that corrospond to the
	# elements of @current_context.   @context_strings is a string-ified 
	# copy of @current_context to handle contexts which are references.
	#
	# $count_this is return from &$filter_func;
	#
	my @contexts;
	my @context_strings;
	my @current_context;  
	my $ps;
	my $oldps;
	my $count_this = 1;
	my @items_seen = ( 0 );
	my %cross_context;
	my $cross_data = {};
	my @cross_keys;
	my $cross_limit = 1;
	my $cross_count = 0;
	my %cross_key_values;
	my %persist;
	my @combinations;

	# output
	my $row;
	my $suppress_result;

	# reduce data to limit memory use
	my @keepers;
	my @tossers;
	my $max_stats2keep = $agg_config->{max_stats_to_keep};
	my $do_reduce;

	# closures
	my $get_context_func;
	my $count_func;
	my $initialize_func;
	my $final_values_func;
	my $merge_func;
	my $context_columns_func;
	my $preprocess_func;
	my $filter_func;
	my $stringify_func;
	my $finalize_result_func;
	my $passthrough_func;
	my $user_merge_func;
	my $user_new_context_func;
	my $user_reduce_func;
	my $cross_reduce_func;
	my $new_ps_func;
	my $process_func;
	my $finish_context_func;
	my $finish_cross_func;
	my $add_context_component_func;
	my $cross_key_reduce_func;
	my $declarations = '';
	my %combination_funcs;
	my $do_combinations;

	my $strict = $agg_config->{strict}
		? "use strict; use warnings;"
		: "no strict; no warnings;";

	my $eval_line_numbers = $agg_config->{debug}
		? sub { $_[0] }
		: \&eval_line_numbers;

	if ($agg_config->{crossproduct} && keys %{$agg_config->{crossproduct}}) {
		@cross_keys = sort keys %{$agg_config->{crossproduct}};
		for my $k (@cross_keys) {
			$cross_limit *= $agg_config->{crossproduct}{$k};
		}
	}

	my $compile_config = sub {
		my %varname;
		my $reduce_func;
		my %s;
		my %var_types;
		my %var_value;

		my $deparse = B::Deparse->new("-p", "-sC");

		#
		# A more sophisticated approach would figure out the dependencies of one value on
		# another and order them appropriately.   What's going on here is kinda hit & miss.
		#
		my $alias_varname = sub {
			my ($cc, $value) = @_;
			$varname{"\$column_$cc"} = $value;
		};
		my $usercode_inner = sub {
			#
			# The {precount} undef statements may not be required.
			# They are there to be safe, just in case someone is referencing
			# a column that hasn't had its value assigned yet.  If so,
			# they'll always get undef rather than a left-over value from
			# a previous input record.
			# 
			my ($cctype, $cc, $cc_code) = @_;
			if (! defined($cc_code)) {
				$declarations	.= "my \$column_$cc;\n";
				$s{precount}	.= "\tundef \$column_$cc;\n";
				return;
			}
			return $alias_varname->($cc, $varname{$cc_code}) if $varname{$cc_code};
			my $original = $cc_code;
			return $alias_varname->($cc, $varname{$cc_code}) if $varname{$cc_code};
			$cc_code =~ s/(\$column_\w+)/defined($varname{$1}) ? $varname{$1} : $1/ge;
			if ($cc_code =~ /\breturn\b/) {
				$cc_code =~ s/^/\t\t/mg;
				$s{user}	.= qq{#line 3001 "FAKE-$extra->{name}-$cctype-$cc"\n} if $renumber;
				$s{user}	.= "my \$${cctype}_${cc}_func = sub {\n";
				$s{user}	.= $cc_code;
				$s{user}	.= "};\n\n";
				$s{precount}	.= "\tundef \$column_$cc;\n";
				$s{$cctype}	.= "\t\$column_$cc = ";
				$s{$cctype}	.= qq{\$${cctype}_${cc}_func->();\n};
			} elsif ($cc_code =~ /[;\n]/) {
				$cc_code =~ s/^/\t\t/mg;
				$s{precount}	.= "\tundef \$column_$cc;\n";
				$s{$cctype}	.= "\t\$column_$cc = ";
				$s{$cctype}	.= "do {\n";
				$s{$cctype}	.= qq{#line 4001 "FAKE-$extra->{name}-$cctype-$cc"\n} if $renumber;
				$s{$cctype}	.= $cc_code;
				$s{$cctype}	.= "\n\t};\n";
			} elsif ($cc_code =~ /\A\$(column_\w+)\Z/) {
				die "value of $cc_code isn't available yet, please compute it in an earlier step like 'ephemeral0'";
			} else {
				$s{$cctype}	.= qq{#line 5001 "FAKE-$extra->{name}-$cctype-$cc"\n} if $renumber;
				$s{precount}	.= "\tundef \$column_$cc;\n";
				$s{$cctype}	.= "\t\$column_$cc = $cc_code;\n";
			}
			$declarations		.= "my \$column_$cc;\n";

			my $te = eval "no strict; no warnings; sub { $cc_code }";
			die "eval $cctype/$cc: $original ($cc_code): $@" if $@;
			my $body = $deparse->coderef2text($te);
			return $varname{$body} if $varname{$body};
			$varname{$body} = $varname{$cc_code} = $varname{$original} = "\$column_$cc";
			$alias_varname->($cc, $varname{$cc_code});
		};
		my $usercode = sub {
			my ($cctype, $cc, $cc_code) = @_;
			my $value = $usercode_inner->(@_);
			$var_value{$cc} = $value;
			$var_types{$cc} = $cctype;
			return $value;
		};

		my %seen;
		my $cc;

		my @all_data	= qw(ephemeral0 ephemeral ephemeral2 ephemeral3 keep output counter percentage sum mean standard_deviation median dominant min minstr max maxstr stat);
		my @lock_data	= qw(                                           keep output counter percentage sum mean standard_deviation median dominant min minstr max maxstr stat);
		my @output_cols	= qw(                                                output counter percentage sum mean standard_deviation median dominant min minstr max maxstr stat);
		my @kept_cols	= qw(                                           keep                                    standard_deviation median dominant                           );
		my @stats_cols	= qw(                                                                                   standard_deviation median dominant                           );
		my @cross_cols	= qw(ephemeral0 ephemeral ephemeral2                                                                                                                 );
		my %cross_cols;
		@cross_cols{@cross_cols} = @cross_cols;

		#
		# Compile all the user code that for the various columns
		#
		for my $ucc (@all_data) {
			next unless $agg_config->{$ucc};
			for $cc (sort keys %{$agg_config->{$ucc}}) {
				die "column $cc is duplicated" if $seen{$cc}++;
				$usercode->($ucc, $cc, $agg_config->{$ucc}{$cc});
			}
		}

		#
		# 'keep' has to be first because 'stat' can't rewrite names
		#
		my %donekeep;
		my $has_keepers = 0;
		for my $keepers (@kept_cols) {
			for $cc (sort keys %{$agg_config->{$keepers}}) {
				next if $donekeep{$varname{$agg_config->{$keepers}{$cc}}};
				$donekeep{$varname{$agg_config->{$keepers}{$cc}}} = $cc;
				$s{initialize}	.= "\t\$ps->{keep}{$cc} = [];\n";
				$s{keeper2}	.= "\t\tpush(\@{\$ps->{keep}{$cc}}, $varname{$agg_config->{$keepers}{$cc}}) if \$count_this;\n";
				$s{merge}	.= "\tpush(\@{\$ps->{keep}{$cc}}, \@{\$oldps->{keep}{$cc}});\n";
				$s{reduce2}	.= "\t\@{\$ps->{keep}{$cc}} = \@{\$ps->{keep}{$cc}}[\@keepers];\n";
				$has_keepers++;
			}
		}
		if ($has_keepers) {
			$s{initialize}	.= "\t# has keepers\n";
			$s{initialize}  .= "\t\$ps->{numeric} = {};\n";

			$s{fv_setup}	.= "\t# has keepers\n";
			$s{fv_setup}	.= "\tlocal(\$Stream::Aggregate::Stats::ps) = \$ps;\n";

			$s{keeper1}	.= resume_line_numbering if $renumber;
			$s{keeper1}	.= "\t# has keepers\n";
			$s{keeper1}	.= "\tmy \$random = rand(1);\n";
			$s{keeper1}	.= "\tif (\@{\$ps->{random}} < $max_stats2keep || \$random < \$ps->{random}[0]) {\n";
			$s{keeper1}	.= "\t\tpush(\@{\$ps->{random}}, \$random);\n";

			$s{keeper3}	.= resume_line_numbering if $renumber;
			$s{keeper3}	.= "\t\t# has keepers\n";
			$s{keeper3}	.= "\t\t&\$reduce_func if \@{\$ps->{random}} > $max_stats2keep * 1.5;\n";
			$s{keeper3}	.= "\t}\n";

			$s{merge}	.= resume_line_numbering if $renumber;
			$s{merge}	.= "\t# has keepers\n";
			$s{merge}	.= "\tpush(\@{\$ps->{random}}, \@{\$oldps->{random}});\n";

			$s{merge2}	.= resume_line_numbering if $renumber;
			$s{merge2}	.= "\t# has keepers\n";
			$s{merge2}	.= "\t&\$reduce_func if \@{\$ps->{random}} > $max_stats2keep * 1.5;\n";

			$s{reduce}	.= $eval_line_numbers->(<<'END_REDUCE');
				# has keepers
				my $random = $ps->{random};
				@keepers = sort { $random->[$a] cmp $random->[$b] } 0..$#$random;
				@tossers = splice(@keepers, $max_stats2keep);
				@$random = @$random[@keepers];
END_REDUCE
			$s{reduce} .= resume_line_numbering if $renumber;
		}

		for $cc (sort keys %{$agg_config->{output}}) {
			$s{initialize} .= "\t\$ps->{output}{$cc} = 0;\n";
		}

		for $cc (sort keys %{$agg_config->{counter}}) {
			$s{initialize}	.= "\t\$ps->{counter}{$cc} = 0;\n";
			$s{count2}	.= "\t\$ps->{counter}{$cc}++ if $varname{$agg_config->{counter}{$cc}};\n";
			$s{merge}	.= "\t\$ps->{counter}{$cc} += \$oldps->{counter}{$cc};\n";
		}

		for $cc (sort keys %{$agg_config->{percentage}}) {
			$s{initialize}	.= "\t\$ps->{percentage}{$cc} = undef;\n";
			$s{stat}	.= "\t\$ps->{percentage}{$cc} = \$ps->{percentage_counter}{$cc} * 100 / (\$ps->{percentage_total}{$cc} || .001);\n";
			$s{initialize}	.= "\t\$ps->{percentage_counter}{$cc} = 0;\n";
			$s{initialize}	.= "\t\$ps->{percentage_total}{$cc} = 0;\n";
			$s{count2}	.= "\t\$ps->{percentage_counter}{$cc}++ if $varname{$agg_config->{percentage}{$cc}};\n"; 
			$s{count2}	.= "\t\$ps->{percentage_total}{$cc}++ if defined $varname{$agg_config->{percentage}{$cc}};\n"; 
			$s{merge}	.= "\t\$ps->{percentage_counter}{$cc} += \$oldps->{percentage_counter}{$cc};\n";
			$s{merge}	.= "\t\$ps->{percentage_total}{$cc} += \$oldps->{percentage_total}{$cc};\n";
		}

		for $cc (sort keys %{$agg_config->{sum}}) {
			$s{initialize}	.= "\t\$ps->{sum}{$cc} = 0;\n";
			$s{count2}	.= "\t\$ps->{sum}{$cc} += $varname{$agg_config->{sum}{$cc}};\n";
			$s{merge}	.= "\t\$ps->{sum}{$cc} += \$oldps->{sum}{$cc};\n";
		}

		for $cc (sort keys %{$agg_config->{mean}}) {
			$s{initialize}	.= "\t\$ps->{mean}{$cc} = undef;\n";
			$s{stat}	.= "\t\$ps->{mean}{$cc} = \$ps->{mean_sum}{$cc} / (\$ps->{mean_count}{$cc} || 100);\n";
			$s{initialize}	.= "\t\$ps->{mean_sum}{$cc} = 0;\n";
			$s{initialize}	.= "\t\$ps->{mean_count}{$cc} = 0;\n";
			$s{count2}	.= "\tif (defined($varname{$agg_config->{mean}{$cc}})) {\n";
			$s{count2}	.= "\t	\$ps->{mean_sum}{$cc} += $varname{$agg_config->{mean}{$cc}};\n";
			$s{count2}	.= "\t	\$ps->{mean_count}{$cc}++;\n";
			$s{count2}	.= "\t}\n";
			$s{merge}	.= "\t\$ps->{mean_sum}{$cc} += \$oldps->{mean_sum}{$cc};\n";
			$s{merge}	.= "\t\$ps->{mean_count}{$cc} += \$oldps->{mean_count}{$cc};\n";
		}

		for $cc (sort keys %{$agg_config->{min}}) {
			$s{initialize}	.= "\t\$ps->{min}{$cc} = undef;\n";
			$s{count2}	.= "\t\$ps->{min}{$cc} = min grep { defined } \$ps->{min}{$cc}, $varname{$agg_config->{min}{$cc}};\n";
			$s{merge}	.= "\t\$ps->{min}{$cc} = min grep { defined } \$ps->{min}{$cc}, \$oldps->{min}{$cc};\n";
		}

		for $cc (sort keys %{$agg_config->{minstr}}) {
			$s{initialize}	.= "\t\$ps->{minstr}{$cc} = undef;\n";
			$s{count2}	.= "\t\$ps->{minstr}{$cc} = minstr grep { defined } \$ps->{minstr}{$cc}, $varname{$agg_config->{minstr}{$cc}};\n";
			$s{merge}	.= "\t\$ps->{minstr}{$cc} = minstr grep { defined } \$ps->{minstr}{$cc}, \$oldps->{minstr}{$cc};\n";
		}

		for $cc (sort keys %{$agg_config->{max}}) {
			$s{initialize}	.= "\t\$ps->{max}{$cc} = undef;\n";
			$s{count2}	.= "\t\$ps->{max}{$cc} = max grep { defined } \$ps->{max}{$cc}, $varname{$agg_config->{max}{$cc}};\n";
			$s{merge}	.= "\t\$ps->{max}{$cc} = max grep { defined } \$ps->{max}{$cc}, \$oldps->{max}{$cc};\n";
		}

		for $cc (sort keys %{$agg_config->{maxstr}}) {
			$s{initialize}	.= "\t\$ps->{maxstr}{$cc} = undef;\n";
			$s{count2}	.= "\t\$ps->{maxstr}{$cc} = maxstr grep { defined } \$ps->{maxstr}{$cc}, $varname{$agg_config->{maxstr}{$cc}};\n";
			$s{merge}	.= "\t\$ps->{maxstr}{$cc} = maxstr grep { defined } \$ps->{maxstr}{$cc}, \$oldps->{maxstr}{$cc};\n";
		}

		for my $statc (@stats_cols) {
			for $cc (sort keys %{$agg_config->{$statc}}) {
				my $keepcc = $donekeep{$varname{$agg_config->{$statc}{$cc}}} || die;
				$s{initialize}	.= "\t\$ps->{$statc}{$cc} = undef;\n";
				$s{stat}	.= "\t\$ps->{$statc}{$cc} = $statc('$keepcc');\n";
			}
		}

		for $cc (sort keys %{$agg_config->{stat}}) {
			$s{stat}	.= "\t\$ps->{stat}{$cc} = $varname{$agg_config->{stat}{$cc}};\n";
			$s{initialize}	.= "\t\$ps->{stat}{$cc} = undef;\n";
		}

		for my $cc (sort keys %{$agg_config->{output}}) {
			$s{initialize}	.= "\t\$ps->{output}{$cc} = undef;\n";
			$s{stat}	.= "\t\$ps->{output}{$cc} = $varname{$agg_config->{output}{$cc}};\n";
		}

		for my $icol (@lock_data) {
			$s{initialize} .= "\tlock_keys(%{\$ps->{$icol}});\n"
				if keys %{$agg_config->{$icol}};
		}

		for my $ctype (@output_cols) {
			for $cc (sort keys %{$agg_config->{$ctype}}) {
				$s{final_values} .= "\t\$row->{$cc} = \$ps->{$ctype}{$cc};\n";
			}
		}
		$s{final_values} .= "\t&\$finalize_result_func;\n" if $agg_config->{finalize_result};

		my $code = $strict;
		$code .= qq{\n#line 1 "FAKE-all-code-for-$extra->{name}"\n} if $renumber;
		$code .= qq{\nmy $agg_config->{item_name};\n};
		$code .= $declarations;
		$code .= "{\n";

		$s{reduce} .= "\t&\$user_reduce_func;\n";

		my $assemble_code = sub {
			my ($func, @keys) = @_;
			my $something;
			my $c = "# ---------------------------------------------------------------\n";
			$c .= "\$${func}_func = sub {\n"
				if $func;
			for my $s (@keys) {
				next unless exists $s{$s};
				$c .= qq{\n#line 1001 "FAKEFUNC-$extra->{name}-$func-$s"\n} if $renumber;
				$c .= $s{$s};
				delete $s{$s};
				$something = 1;
			}
			$c .= "\t0\n" 
				if $func && ! $something;
			$c .= "};\n"
				if $func;
			return $c;
		};

		#
		# Cross product aggregation & counts
		#
		if (@cross_keys) {
			my $esub = '';
			my $newsub = '';
			my $oldsub = '';
			my $loop_in = '';
			my $loop_in2 = '';
			my $loop_in3 = '';
			my $loop_in3a = '';
			my $loop_out = '';
			my $loop_out2 = '';
			my $loop_indent = "";
			my $loop_head = '';
			my $loop_mid = '';
			my $loop_mid3 = '';
			my $loop_dbug_old = '';
			my $loop_dbug_new = '';
			for my $cc (@cross_keys) {
				die "Crossproduct column '$cc' doesn't exist" unless $var_types{$cc};
				die "Crossproduct column '$cc' ($var_types{$cc}) isn't a valid type (@cross_cols)" unless $cross_cols{$var_types{$cc}};

				my $cc_code = $agg_config->{simplify}{$cc} || 'return "*";';
				$s{user}	.= "my \$simplify_$cc = sub {\n";
				$s{user}	.= qq{#line 3001 "FAKE-$extra->{name}-simplify-$cc"\n} if $renumber;
				$s{user}	.= "\t".$cc_code;
				$s{user}	.= "\n};\n";

				$loop_head	.= "\tmy %key_count_$cc;\n";

				$loop_mid	.= "\tmy \$key_map_$cc = \$cross_key_reduce_func->('$cc', \\%key_count_$cc, \$simplify_$cc);\n";
				$loop_mid3	.= ", $cc => \$key_$cc";

				$loop_dbug_old	.= " $cc:\$key_$cc";
				$loop_dbug_new	.= " $cc:\$new_$cc";

				$loop_in2	.= "$loop_indent	for my \$key_$cc (keys %{\$cross_data$oldsub}) {\n"; 

				$loop_in	.= "$loop_indent	for my \$key_$cc (keys %{\$cross_data$oldsub}) {\n"; 
				$loop_in	.= "$loop_indent		my \$new_$cc = \$key_$cc;\n";
				$loop_in	.= "$loop_indent		my \$must_inc = 0;\n";
				$loop_in	.= "$loop_indent		if (exists \$key_map_${cc}->{\$key_$cc}) {\n";
				$loop_in	.= "$loop_indent			\$new_$cc = \$key_map_${cc}->{\$key_$cc};\n";
				$loop_in	.= "$loop_indent			\$must_inc = 1;\n";
				$loop_in	.= "$loop_indent			\$must_do++;\n";
				$loop_in	.= "$loop_indent		} else {\n";
				$loop_in	.= "$loop_indent			\$new_$cc = \$key_$cc;\n";
				$loop_in	.= "$loop_indent		}\n";

				$loop_in3a	.= "\$key_count_${cc}{\$key_$cc}++;\n";

				$loop_out	.= "$loop_indent	}\n";
				$loop_out	.= "$loop_indent		\$must_do -= \$must_inc;\n";
				$loop_out2	.= "$loop_indent	}\n";

				$loop_indent	.= "\t";

				$esub		.= "->{$var_value{$cc}}";
				$newsub		.= "->{\$new_$cc}";
				$oldsub		.= "->{\$key_$cc}";
			};
			for my $in3a (split(/\n/, $loop_in3a)) {
				$loop_in3 .= "$loop_indent		$in3a\n";
			}

			$loop_out = join("\n", reverse split(/\n/, $loop_out)) . "\n";
			$loop_out2 = join("\n", reverse split(/\n/, $loop_out2)) . "\n";

			#
			# Reduce the number of contexts
			#

			$cross_key_reduce_func = sub {
				my ($keyname, $valcounts, $simplify_func) = @_;
				my %ret;
				if (keys %$valcounts > $agg_config->{crossproduct}{$keyname}) {
					$do_reduce = 1;
					my $limit = $agg_config->{crossproduct}{$keyname};
					my $current = keys %$valcounts;
					my %seen;
					my %new;
					for my $val (sort { $valcounts->{$a} <=> $valcounts->{$b} } keys %$valcounts) {
						if ($current > $limit) {
							my $new = $simplify_func->($val, $keyname);
							next if $new eq $val;
							if ($seen{$new}++) {
								$current--;
							}
							$new{$new}++;
							if ($new{$val}) {
								# we can't throw this one away since we have new
								# users...  we may not be able to meet our contract.
								$current-- unless --$seen{$new};
								$new{$new}--;
								next;
							} else {
								$ret{$val} = $new;
							}
						}
					}
				}
				print STDERR YAML::Dump("reduce $keyname", \%ret) if $agg_config->{debug} > 2;
				return \%ret;
			};

			my $db1 = '';
			my $db2 = '';
			$db1 = qq{print STDERR "Merging\t$loop_dbug_old (\$cross_data${oldsub}->{item_counter})\tinto\t$loop_dbug_new\t\$cross_count\\n";} if $agg_config->{debug};
			$db2 = qq{print STDERR "Moving\t$loop_dbug_old (\$cross_data${oldsub}->{item_counter})\tto\t$loop_dbug_new\\n";} if $agg_config->{debug};
			$s{cross_reduce} .= resume_line_numbering if $renumber;

			$s{cross_reduce} .= "\t\$do_reduce = 0;\n";
			$s{cross_reduce} .= "\tmy \$must_do = 0;\n";
			$s{cross_reduce} .= $loop_head;
			$s{cross_reduce} .= $loop_in2;
			$s{cross_reduce} .= $loop_in3;
			$s{cross_reduce} .= $loop_out2;
			$s{cross_reduce} .= $loop_mid;
			$s{cross_reduce} .= $loop_in;
			$s{cross_reduce} .= $eval_line_numbers->(<<END_CR);
				# --------------- reduce -------------
				if (\$must_do) {
					if (\$cross_data$newsub) {
						\$cross_count--;
						$db1
						\$ps = \$cross_data$newsub;
						\$oldps = delete \$cross_data$oldsub;
						#
						# print STDERR "ABOUT TO MERGE: \$key_color \$key_size \$key_style \$oldps\\n";
						# print STDERR YAML::Dump("Pre-mege cross-data", \$cross_data);
						#
						&\$merge_func;
						\$ps = \$contexts[-1];
					} else {
						$db2
						\$cross_data$newsub = delete \$cross_data$oldsub;
					}
				}
				# --------------- reduce -------------
END_CR
			$s{cross_reduce} .= resume_line_numbering if $renumber;
			$s{cross_reduce} .= $loop_out;

			#
			# Add data to the right context
			#
			my $db3 = '';
			$db3 = qq{print STDERR "Cross-count: \$cross_count\\n";} if $agg_config->{debug} > 3;
			$s{crossproduct} .= $eval_line_numbers->(<<END_CP);
				if (\$cross_count > \$cross_limit * 2) {
					&\$cross_reduce_func;
				}
				if (\$cross_data$esub) {
					\$ps = \$cross_data$esub;
				} else {
					&\$new_ps_func;
					\$cross_data$esub = \$ps;
					\$cross_count++;
					$db3
				}
END_CP
			$s{crossproduct} .= resume_line_numbering if $renumber;

			#
			# handle combinations
			#
			$s{inner_combine} = '';
			$s{outer_combine} = '';
			if ($agg_config->{combinations}) {
				my $generate_combinations;
				my $combination_number = 0;
				my %mapping;
				$generate_combinations = sub {
					my ($output_field, $input_ps, $indent, $keys, $done, $loop_over) = @_;
					my $out = \$s{$output_field};
					my $loopout = '';
					my $x = '';
					my $y = '';
					my @loop_keys = grep { $agg_config->{combinations}{$_} && ! $done->{$_} } sort @$keys;
					my @delayed_call;
					if ($loop_over) {
						for my $k (@loop_keys) {
							$$out .= "$indent$x	for my \$ck_$k (keys %{$input_ps}) {\n";
							$loopout = "$indent$x	}\n$loopout";
							$x .= "\t";
							$input_ps .= "{\$ck_$k}";
						}
						$y = $x;
						if (! @loop_keys) {
							$y .= "\t";
							$$out .= "$indent$x	if ($input_ps) {\n";
						}
						$$out .= "$indent$y	\$row = ${input_ps}->{row};\n";
					}
					for my $cc (@loop_keys) {
						my @keeping = grep { $_ ne $cc } @loop_keys;
						if ($mapping{"@keeping"}++) {
							$$out .= "$indent$x	# we've already handled keeping '@keeping'\n";
							next;
						}

						my $accessor = @keeping
							? "{" . join("}{", map { "\$row->{'$_'}" } @keeping) . "}"
							: '';

						if ($loop_over && @keeping) {
							$accessor = "{" . join("}{", map { "\$ck_$_" } @keeping) . "}"
						}

						# yes, we're using auto-vivification.  It's ugly, but simplifies
						# the code.

						$$out .= "\n";
						$$out .= "$indent$x	# combine, dropping $cc";
						$$out .= 			", keeping: @keeping" if @keeping;
						$$out .= "\n";

						$$out .= "$indent$x	if (\$combination_funcs{'$cc'}->()) {\n";
						$$out .= "$indent$x		if (\$combinations[$combination_number]$accessor) {\n";
						$$out .= "$indent$x			local(\$Stream::Aggregate::Stats::ps)\n";
						$$out .= "$indent$x				= \$ps\n";
						$$out .= "$indent$x				= \$combinations[$combination_number]$accessor;\n";
						$$out .= "$indent$x			\$oldps = $input_ps;\n" if $input_ps ne '$oldps';
						$$out .= "$indent$x			&\$merge_func;\n";
						$$out .= "$indent$x		} else {\n";
						$$out .= "$indent$x			\$ps = \$combinations[$combination_number]$accessor = clone($input_ps);\n";
						$$out .= "$indent$x			\$ps->{row} = { %\$row };\n";
						$$out .= "$indent$x			delete \$ps->{row}{'$cc'};\n";
						$$out .= "$indent$x		}\n";
						$$out .= "$indent$x	}\n";

						my $pnum = $combination_number++;

						push(@delayed_call, sub {
							$generate_combinations->(
								outer_combine => "\$combinations[$pnum]", 
								"", 
								\@keeping, 
								{ %$done, $cc => 1 },
								$cc);
						});
					}
					if ($loop_over) {
						$$out .= "\n";
						$$out .= "$indent$y	# final values with '@loop_keys' keys\n";
						$$out .= "$indent$y	local(\$Stream::Aggregate::Stats::ps) = \$ps = ${input_ps};\n";
						$$out .= "$indent$y	\$suppress_result = 0;\n";
						$$out .= "$indent$y	\$final_values_func->();\n";
						$$out .= "$indent$y	push(\@\$retref, \$row) unless \$suppress_result;\n";
						$$out .= "\n";
						if (! @loop_keys) {
							$$out .= "$indent$x	}\n";
						}

						$$out .= $loopout;
					}
					while (my $dc = shift(@delayed_call)) {
						$dc->();
					}

				};
				$generate_combinations->(
					inner_combine => '$oldps', 
					"\t\t\t", 
					\@cross_keys, 
					{}, 
					undef);
			}

			#
			# Return the cross product results
			#
			$s{finish_cross} .= qq{print STDERR "Finish cross called\n";} if $agg_config->{debug} > 7;
			$s{finish_cross} .= qq{print STDERR YAML::Dump('cross_data-before',\$cross_data);\n} if $agg_config->{debug} > 8;
			$s{finish_cross} .= "\tmy (\$retref) = shift;\n";
			$s{finish_cross} .= "\tmy \$rowtmp;\n";
			$s{finish_cross} .= "\t&\$cross_reduce_func;\n";
			$s{finish_cross} .= qq{print STDERR YAML::Dump('cross_data-after',\$cross_data);\n} if $agg_config->{debug} > 8;
			$s{finish_cross} .= $loop_in2;
			$s{finish_cross} .= $eval_line_numbers->(<<END_FC);
				# --------------- finish cross -------------
				local(\$Stream::Aggregate::Stats::ps) 
					= \$ps
					= \$cross_data$oldsub;
				confess unless \$ps;
				\$suppress_result = 0;
				\$rowtmp = \$row = { &\$context_columns_func $loop_mid3 };
				&\$final_values_func;
				push(@\$retref, \$row) unless \$suppress_result;
				\$oldps = delete \$cross_data$oldsub;
				\$oldps->{row} = \$row;
				\$ps = \$contexts[-1];
				&\$merge_func if \$ps;
				\$cross_count--;
				$db3
END_FC
			$s{finish_cross} .= delete $s{inner_combine};
			$s{finish_cross} .= "\t\t\t\t# --------------- finish cross -------------\n";
			$s{finish_cross} .= resume_line_numbering if $renumber;
			$s{finish_cross} .= $loop_out2;
			$s{finish_cross} .= delete $s{outer_combine};
		} elsif ($agg_config->{combinations}) {
			die "combinations requires crossproduct which isn't defined";
		}

		$code .= $eval_line_numbers->(<<'END_FIELDS');

			my $compile_user_code = sub {
				my ($c, $field, $config_key, $default) = @_;
				return $default unless defined $c->{$field};
				my $config = $c->{$config_key} || {};   # maybe used by eval
				my $coderef;
				my $code = $strict;
				$code .= qq{\n#line 2001 "FAKE-$extra->{name}-$field"\n} if $renumber;
				$code .= qq{sub { $c->{$field} }; };
				my $sub = eval $code;
				die "Cannot compile user code for $extra->{name}/$field: $@\n$code" if $@;
				return $coderef if $coderef;
				return $sub;
			};

			$get_context_func	= $compile_user_code->($agg_config, 'context',			'context_config',		sub { return () });
			$context_columns_func	= $compile_user_code->($agg_config, 'context2columns',		'context2columns_config',	sub { return () });
			$filter_func	        = $compile_user_code->($agg_config, 'filter',			'filter_config',		sub { 1 });
			$preprocess_func	= $compile_user_code->($agg_config, 'preprocess',		'preprocess_config',		sub {});
			$stringify_func		= $compile_user_code->($agg_config, 'stringify_context',	'stringify_context_config',	sub { map { ref($_) ? Dump($_) : $_ } @_ });
			$finalize_result_func	= $compile_user_code->($agg_config, 'finalize_result',		'finalize_result_config',	sub {});
			$passthrough_func	= $compile_user_code->($agg_config, 'passthrough',		'passthrough_config',		sub { return () });
			$user_new_context_func	= $compile_user_code->($agg_config, 'new_context',		'new_context_config',		sub { return () });
			$user_merge_func	= $compile_user_code->($agg_config, 'merge',			'merge_config',			sub { return () });
			$user_reduce_func	= $compile_user_code->($agg_config, 'reduce',			'reduce_config',		sub { return () });

			if ($agg_config->{crossproduct} && $agg_config->{combinations}) {
				for my $crosskey (uniq(keys(%{$agg_config->{crossproduct}}), keys(%{$agg_config->{combinations}}))) {
					$combination_funcs{$crosskey} = $compile_user_code->($agg_config->{combinations}, $crosskey, "combine on $crosskey", sub { 0 });
				}
			}

END_FIELDS
		$code .= "\t\$itemref = \\$agg_config->{item_name};\n";
		$code .= "}\n";

		#
		# New context ($ps) allocator 
		#

		$s{new_ps} .= "\t\$ps = {};\n";
		$s{new_ps} .= "\t\$ps->{item_counter} = 0;\n";
		$s{new_ps} .= "\t\$ps->{heap} = {};\n" 
			if Dump($agg_config) =~ /\{heap\}/;
		if ($has_keepers) {
			$s{new_ps} .= "\t\$ps->{random} = [];\n";
			$s{new_ps} .= "\t\$ps->{sidestats} = {};\n"; # for Stream::Aggregate::Stats
		}
		$s{new_ps} .= "\t\$ps->{unfiltered_counter} = 0;\n"		if $agg_config->{filter};
		$s{new_ps} .= "\t&\$initialize_func;\n"				if $s{initialize};
		$s{new_ps} .= "\t&\$user_new_context_func;\n"			if $agg_config->{new_context};
		$s{new_ps} .= "\t\$ps->{row} = undef;\n";
		$s{new_ps} .= "\tlock_keys(%\$ps);\n";

		#
		# main processing loop, generated for execution efficiency
		#

		$s{process} .= "\t\$last_item = \$\$itemref;\n"
			if Dump($agg_config) =~ /\$last_item\b/;
		$s{process} .= $eval_line_numbers->(<<'END_P0');
			$last_item = $$itemref;
			($$itemref) = @_;
			my @ret;
			unless ($$itemref) {
				$finish_cross_func->(\@ret) if keys %$cross_data;
				$finish_context_func->(\@ret) 
					while @contexts;
				return @ret;
			}
END_P0
		$s{process} .= $eval_line_numbers->(<<'END_P1') if $agg_config->{preprocess};

			&$preprocess_func;

END_P1
		$s{process} .= $eval_line_numbers->(<<'END_P2') if $agg_config->{filter} && $agg_config->{filter_early};

			$count_this = &$filter_func;
END_P2
		$s{process} .= $eval_line_numbers->(<<'END_P3') if $agg_config->{passthrough};

			push(@ret, &$passthrough_func);

END_P3

		if ($agg_config->{context}) {
			$s{process} .= $eval_line_numbers->(<<'END_P4') if $agg_config->{filter} && $agg_config->{filter_early};

				if ($count_this) {

END_P4
			$s{process} .= $eval_line_numbers->(<<'END_P5');

					my @new_context = &$get_context_func;
					my @new_strings = $stringify_func->(@new_context);

					my $diffpos = list_difference_position(@new_strings, @context_strings);

					if (defined $diffpos) {
						$finish_context_func->(\@ret)
							while @current_context >= $diffpos;
					}

					while (@new_context > @current_context) {
						$add_context_component_func->($new_context[@current_context], $new_strings[@current_context]);
					}
END_P5

			$s{process} .= $eval_line_numbers->(<<'END_P7') if $agg_config->{filter} && $agg_config->{filter_early};
				}

END_P7
		}

		$s{process} .= $eval_line_numbers->(<<'END_P7A') if $agg_config->{filter} && ! $agg_config->{filter_early};

			$count_this = &$filter_func;
END_P7A

		$s{process} .= $eval_line_numbers->(<<'END_P7B') if $agg_config->{filter} && ! $agg_config->{context};
				if ($count_this) {
END_P7B
		
		$s{process} .= $eval_line_numbers->(<<'END_P8');
					&$count_func;
					$ps->{item_counter}++;
END_P8

		# this closes the if ($count_this) in P3 or in P7B 
		$s{process} .= $eval_line_numbers->(<<'END_P9') if $agg_config->{filter};  
				}
				$ps->{unfiltered_counter}++;
END_P9

		$s{process} .= $eval_line_numbers->(<<'END_P10');
			return @ret;
END_P10
		$s{process} .= resume_line_numbering if $renumber;

		#
		# Merge contexts func
		#

		$s{merge0} .= "print STDERR YAML::Dump('MERGE', \$ps, \$oldps);\n" if $agg_config->{debug} > 11;
		$s{merge0} .= resume_line_numbering if $renumber;
		$s{merge0} .= "\t\$ps->{item_counter} += \$oldps->{item_counter};\n";
		$s{merge0} .= "\t\$ps->{unfiltered_counter} += \$oldps->{unfiltered_counter};\n" if $agg_config->{filter};
		$s{merge3} .= resume_line_numbering if $renumber;
		$s{merge3} .= "\t&\$user_merge_func;\n";

		$s{fv_setup} .= "print STDERR YAML::Dump('final_values', \$ps);\n" if $agg_config->{debug} > 12;

		$code .= $assemble_code->('', qw(user));
		$code .= $assemble_code->('merge', qw(merge0 merge merge2 merge3));
		$code .= $assemble_code->('cross_reduce', qw(cross_reduce));
		$code .= $assemble_code->('finish_cross', qw(finish_cross));
		$code .= $assemble_code->('new_ps', qw(new_ps));
		$code .= $assemble_code->('process', qw(process));
		$code .= $assemble_code->('initialize', qw(initialize));
		$code .= $assemble_code->('final_values', qw(fv_setup output stat final_values));
		$code .= $assemble_code->('count', qw(precount count ephemeral0 ephemeral ephemeral2 crossproduct ephemeral3 keep standard_deviation median dominant counter percentage sum mean median min minstr max maxstr count2 keeper1 keeper2 keeper3 ));
		$code .= $assemble_code->('reduce', qw(reduce reduce2));
		die "INTERNAL ERROR: ".join(' ', keys %s) if keys %s;

		if ($suppress_line_numbers) {
			$code =~ s/^#line \d+ ".*"\s*?\n//mg;
		}

		print STDERR $line_numbers{$code}."\n" if $agg_config->{debug};

		eval $code;
		die "$@\n$line_numbers{$code}" if $@;

	};

	&$compile_config;

	$add_context_component_func = sub {
		my ($component, $component_string) = @_;

		&$new_ps_func;

		# keep @contexts and @current_context together
		push(@current_context, $component);
		push(@context_strings, $component_string);
		push(@contexts, $ps);

		$items_seen[$#contexts] += 1;
		$#items_seen = $#contexts;
		push(@items_seen, 0);
	};

	$finish_context_func = sub {
		my ($retref) = @_;

		die unless @contexts;

		print STDERR "about to call finish cross\n" if $agg_config->{debug} > 5;
		$finish_cross_func->($retref);

		die unless @contexts;

		confess unless ref $ps;

		$suppress_result = 0;
		$row = {
			&$context_columns_func,
		};
		&$final_values_func;

		# keep @contexts and @current_context together
		$oldps = pop(@contexts);
		pop(@current_context);
		pop(@context_strings);

		$ps = $contexts[-1];

		&$merge_func if $ps;

		push (@$retref, $row) unless $suppress_result;
	};

	return $process_func;

}

sub validate_aggregation_config
{
	my ($agg_config) = @_;
	my $checker = eval config_checker_source;
	die $@ if $@;
	$checker->($agg_config, $prototype_config, '- Stream::Aggregate config');
}

1;

