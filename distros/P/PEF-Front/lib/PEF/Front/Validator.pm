package PEF::Front::Validator;
use strict;
use warnings;
use utf8;
use Encode;
use YAML::XS;
use Data::Dumper;
use Carp qw(cluck croak);
use Regexp::Common 'RE_ALL';
use PEF::Front::Captcha;
use PEF::Front::Config;
use PEF::Front::Model;
use Sub::Name;
use base 'Exporter';
our @EXPORT = qw{
	validate
	get_model
	get_method_attrs
};

our %model_cache;

sub _collect_base_rules {
	my ($method, $mr, $pr) = @_;
	my %seen;
	my %ret;
	substr($mr, 0, 1, '') if substr($mr, 0, 1) eq '$';
	my $entry = $mr;
	while (!exists $seen{$entry}) {
		$seen{$entry} = undef;
		croak {
			result      => 'INTERR',
			answer      => 'Internal server error',
			answer_args => [],
			message     => "Validation $method error: unknown base rule '$entry' for '$pr'",
			}
			unless exists $model_cache{'-base-'}{rules}{params}{$entry};
		my $rules = $model_cache{'-base-'}{rules}{params}{$entry};
		last if not defined $rules or (not ref $rules and $rules eq '');
		if (not ref $rules) {
			if (substr($rules, 0, 1) eq '$') {
				$entry = substr($rules, 1);
			} else {
				%ret = (regex => $rules, %ret);
			}
		} else {
			%ret = (%$rules, %ret);
			if (exists $ret{base}) {
				if (defined $ret{base} and $ret{base} ne '') {
					$entry = $ret{base};
					substr($entry, 0, 1, '') if substr($entry, 0, 1) eq '$';
				}
				delete $ret{base};
			}
		}
	}
	\%ret;
}

sub _build_validator {
	my $rules             = $_[0];
	my $method_params     = $rules->{params} || {};
	my $extra_params_rule = $rules->{extra_params} || 'ignore';
	my %known_params      = (method => undef, ip => undef);
	my %must_params       = (method => undef);
	my $jsn               = '$_[0]->';
	my $def               = '$_[1]->';
	my $pr;
	my $mr;
	my $session_required = 0;
	my $make_default_sub = sub {
		my ($default) = @_;
		my $check_defaults = '';
		if ($default !~ /^($RE{num}{int}|$RE{num}{real})$/) {
			if ($default =~ /^context\.([\w\d].*)/) {
				$default        = "$def {$1}";
				$check_defaults = "exists($def {$1})";
			} elsif ($default =~ /^defaults\.([\w\d].*)/) {
				$default        = "$def {$1}";
				$check_defaults = "exists($def {$1})";
			} elsif ($default =~ /^headers\.(.*)/) {
				my $h = $1;
				$h =~ s/\s*$//;
				$h       = _quote_var($h);
				$default = "$def {headers}->get_header($h)";
			} elsif ($default =~ /^notes\.(.*\S)/) {
				my $h = $1;
				$h       = _quote_var($h);
				$default = "$def {request}->note($h)";
			} elsif ($default =~ /^cookies\.(.*)/) {
				my $c = $1;
				$c =~ s/\s*$//;
				$c              = _quote_var($c);
				$default        = "$def {cookies}->{$c}";
				$check_defaults = "exists($def {cookies}->{$c})";
			} elsif ($default =~ /^form\.(.*)/) {
				my $p = $1;
				$p =~ s/\s*$//;
				$p              = _quote_var($p);
				$default        = "$def {form}->{$p}";
				$check_defaults = "exists($def {form}->{$p})";
			} elsif ($default =~ /^session\.(.*)/) {
				my $s = $1;
				$s =~ s/\s*$//;
				$s                = _quote_var($s);
				$default          = "$def {session}->data->{$s}";
				$check_defaults   = "exists($def {session}->data->{$s})";
				$session_required = 1;
			} elsif ($default =~ /^config\.(.*)/) {
				my $c = $1;
				$c =~ s/\s*$//;
				$c       = _quote_var($c);
				$default = "PEF::Front::Config::cfg($c)";
			} else {
				$default =~ s/\s*$//;
				$default = _quote_var($default);
			}
		}
		($default, $check_defaults);
	};
	my %attr_sub = (
		regex => sub {
			my $re = ref($mr) ? $mr->{regex} : $mr;
			return '' if !defined($re) || $re eq '';
			<<ATTR;
		croak {
			result => 'BADPARAM',
			answer => 'Bad parameter \$1',
			answer_args => ['$pr']
		} unless $jsn {$pr} =~ m/$re/;
ATTR
		},
		captcha => sub {
			return '' if !defined($mr->{captcha}) || $mr->{captcha} eq '';
			<<ATTR;
			if($jsn {$pr} ne 'nocheck') {
				croak {
					result => 'BADPARAM', 
					answer => 'Bad captcha: \$1', 
					answer_args => [$jsn {$pr}]
				} unless PEF::Front::Captcha::check_captcha($jsn {$pr}, $jsn {$mr->{captcha}});
			}
ATTR
		},
		type => sub {
			return '' if !defined($mr->{type}) || $mr->{type} eq '';
			my $type = uc(substr($mr->{type}, 0, 1)) eq 'F' ? 'PEF::Front::File' : uc $mr->{type};
			<<ATTR;
			croak {
				result => 'BADPARAM', 
				answer => 'Bad type parameter \$1', 
				answer_args => ['$pr']
			} unless ref ($jsn {$pr}) eq '$type';
ATTR
		},
		'max-size' => sub {
			return '' if !defined($mr->{'max-size'}) || $mr->{'max-size'} eq '';
			<<ATTR;
			croak {
				result => 'BADPARAM', 
				answer => 'Parameter \$1 is too long', 
				answer_args => ['$pr']
			} if (
				!ref($jsn {$pr})
				? length($jsn {$pr})
				: ref($jsn {$pr}) eq 'HASH'
				? scalar(keys \%{$jsn {$pr}})
				: ref($jsn {$pr}) eq 'PEF::Front::File'
				? $jsn {$pr} ->size
				: scalar(\@{$jsn {$pr}})
				) >  $mr->{'max-size'};
ATTR
		},
		'min-size' => sub {
			return '' if !defined($mr->{'min-size'}) || $mr->{'min-size'} eq '';
			<<ATTR;
			croak {
				result => 'BADPARAM', 
				answer => 'Parameter \$1 is too short', 
				answer_args => ['$pr']
			} if (
				!ref($jsn {$pr})
				? length($jsn {$pr})
				: ref($jsn {$pr}) eq 'HASH'
				? scalar(keys \%{$jsn {$pr}})
				: ref($jsn {$pr}) eq 'PEF::Front::File'
				? $jsn {$pr} ->size
				: scalar(\@{$jsn {$pr}})
				) <  $mr->{'min-size'};
ATTR
		},
		can => sub {
			my $can = exists($mr->{can}) ? $mr->{can} : $mr->{can_string};
			return '' if !defined($can);
			my @can = ref($can) ? @{$can} : ($can);
			return '' if !@can;
			my $can_list = join ", ", map {_quote_var($_)} @can;
			<<ATTR;
			{
				my \$found = 0;
				local \$_;
				for($can_list) {
					if(\$_ eq $jsn {$pr}) {
						\$found = 1;
						last;
					} 
				}
				croak {
					result => 'BADPARAM',
					answer => 'Parameter \$1 has not allowed value',
					answer_args => ['$pr']
				} unless \$found;
			}
ATTR
		},
		can_number => sub {
			return '' if !defined($mr->{can_number}) || $mr->{can_number} eq '';
			my @can = ref($mr->{can_number}) ? @{$mr->{can_number}} : ($mr->{can_number});
			return '' if !@can;
			my $can_list = join ", ", map {_quote_var($_)} @can;
			<<ATTR;
			{
				my \$found = 0;
				local \$_;
				for($can_list) {
					if(\$_ == $jsn {$pr}) {
						\$found = 1;
						last;
					} 
				}
				croak {
					result => 'BADPARAM',
					answer => 'Parameter \$1 has not allowed value',
					answer_args => ['$pr']
				} unless \$found;
			}
ATTR
		},
		'max' => sub {
			return '' if !defined($mr->{'max'}) || $mr->{'max'} eq '';
			<<ATTR;
			croak {
				result => 'BADPARAM', 
				answer => 'Parameter \$1 is too big', 
				answer_args => ['$pr']
			} if $jsn {$pr} >  $mr->{'max'};
ATTR
		},
		'min' => sub {
			return '' if !defined($mr->{'min'}) || $mr->{'min'} eq '';
			<<ATTR;
			croak {
				result => 'BADPARAM', 
				answer => 'Parameter \$1 is too small', 
				answer_args => ['$pr']
			} if $jsn {$pr} < $mr->{'min'};
ATTR
		},
		default => sub {
			my ($default, $check_defaults) = $make_default_sub->($mr->{default});
			$check_defaults .= ' and' if $check_defaults;
			<<ATTR;
			$jsn {$pr} = $default if $check_defaults not exists $jsn {$pr};
ATTR
		},
		value => sub {
			my ($default, $check_defaults) = $make_default_sub->($mr->{value});
			if ($check_defaults) {
				<<ATTR;
			$jsn {$pr} = $default if $check_defaults;
ATTR
			} else {
				<<ATTR;
			$jsn {$pr} = $default;
ATTR
			}
		},
		filter => sub {
			return '' if !defined($mr->{filter}) || $mr->{filter} eq '';
			my $filter_sub = '';
			if ($mr->{filter} =~ /^\w+::/) {
				my $fcall = cfg_app_namespace . "InFilter::$mr->{filter}($jsn {$pr}, \$_[1]);";
				$filter_sub .= <<ATTR;
		if(exists $jsn {$pr}) {
			eval { $jsn {$pr} = $fcall };
			if(\$\@) {
				if(ref \$\@ and 'HASH' eq ref \$\@ and exists \$\@->{answer}) {
					my \$response = {
						result => 'BADPARAM',
						\%{\$\@}
					};
					cfg_log_level_info()
					&& $def {request}->logger->({
						level => "info", 
						message => "parameter $pr was not validate by input filter: " . Dumper(\$\@)
					});
					croak \$response;
				} else {
ATTR
				if (exists($mr->{optional}) && $mr->{optional}) {
					$filter_sub .= <<ATTR;
					delete $jsn {$pr}; 
					cfg_log_level_info()
					&& $def {request}->logger->({
						level => "info", 
						message => "dropped optional parameter $pr: input filter: " . Dumper(\$\@)
					});
ATTR
				} else {
					$filter_sub .= <<ATTR;
					cfg_log_level_error()
					&& $def {request}->logger->({
						level => "error", 
						message => "input filter: " . Dumper(\$\@)
					});
					croak {
						result => 'BADPARAM', 
						answer => 'Bad parameter \$1', 
						answer_args => ['$pr']
					};
ATTR

				}
				$filter_sub .= <<ATTR;
				}
			}
		}
ATTR
				my $cl = cfg_app_namespace . "InFilter::$mr->{filter}";
				my $use_module = substr($cl, 0, rindex($cl, "::"));
				eval "use $use_module";
				if ($@) {
					croak {
						result      => 'INTERR',
						answer      => 'Error loading method in filter module $1 for method $2: $3',
						answer_args => [$use_module, $rules->{method}, $@]
					};
				}
			} else {
				my $rearr
					= ref($mr->{filter}) eq 'ARRAY' ? $mr->{filter}
					: ref($mr->{filter})            ? []
					:                                 [$mr->{filter}];
				for my $re (@$rearr) {
					if ($re =~ /^(s|tr|y)\b/) {
						$filter_sub .= <<ATTR;
				$jsn {$pr} =~ $re;
ATTR
					}
				}
			}
			$filter_sub;
		},
		optional => sub {
			"";
		},
		base => sub {
			"";
		}
	);
	$attr_sub{can_string} = $attr_sub{can};
	my @validator_checks;
	for my $par (
		sort {$a eq cfg_session_request_field() ? -1 : $b eq cfg_session_request_field() ? 1 : $a cmp $b}
		keys %$method_params
		)
	{
		$pr = $par;
		$mr = $method_params->{$pr};
		$mr = '' if not defined $mr;
		my $last_sym = substr($pr, -1, 1);
		if ($last_sym eq '%' || $last_sym eq '@' || $last_sym eq '*') {
			my $type = $last_sym eq '%' ? 'HASH' : $last_sym eq '@' ? 'ARRAY' : 'FILE';
			if (ref($mr)) {
				$mr->{type} = $type;
			} else {
				$mr = {type => $type};
			}
			substr($pr, -1, 1, '');
		}
		$known_params{$pr} = undef;
		if (!ref($mr) and length $mr > 0 and substr($mr, 0, 1) eq '$') {
			$mr = _collect_base_rules($rules->{method}, $mr, $pr);
		}
		if (    ref $mr
			and exists $mr->{base}
			and defined $mr->{base}
			and $mr->{base} ne '')
		{
			my $bmr = _collect_base_rules($rules->{method}, $mr->{base}, $pr);
			$mr = {%$bmr, %$mr};
		}
		if (not ref $mr) {
			if ($mr eq '') {
				$mr = {};
			} else {
				$mr = {regex => $mr};
			}
		}
		my $sub_test       = '';
		my $validator_test = '';
		for my $attr (sort {$a eq 'filter' ? 1 : $b eq 'filter' ? -1 : $a cmp $b} keys %$mr) {
			substr($attr, 0, 1, '') if substr($attr, 0, 1) eq '^';
			if (exists($attr_sub{$attr})) {
				if ($attr eq 'default' || $attr eq 'value') {
					$validator_test .= $attr_sub{$attr}();
				} else {
					$sub_test .= $attr_sub{$attr}();
				}
			} else {
				croak {
					result      => 'INTERR',
					answer      => 'Unknown attribute $1 for paramter $2 method $3',
					answer_args => [$attr, $pr, $rules->{method}]
				};
			}
		}
		if (exists($mr->{optional}) && $mr->{optional} eq 'empty') {
			$validator_test .= <<ATTR;
			if(exists($jsn {$pr}) and $jsn {$pr} ne '') {
$sub_test
			}
ATTR
		} elsif (exists($mr->{optional}) && $mr->{optional}) {
			$validator_test .= <<ATTR;
			if(exists($jsn {$pr})) {
$sub_test
			}
ATTR
		} else {
			$must_params{$pr} = undef;
			$validator_test .= <<ATTR;
		    croak {
		    	result => 'BADPARAM', 
		    	answer => 'Mandatory parameter \$1 is absent', 
		    	answer_args => ['$pr']
		    } unless exists $jsn {$pr} ;
ATTR
			$validator_test .= $sub_test;
		}
		push @validator_checks, $validator_test;
	}
	if ($session_required && @validator_checks) {
		my $session_load = <<SESSION;
		$def {session} = PEF::Front::Session->new(\$_[0]);
SESSION
		splice @validator_checks, 1, 0, $session_load;
	}
	my $validator_sub = "sub { \n";
	$validator_sub .= join "", @validator_checks;
	if ($extra_params_rule ne 'pass') {
		my $known_params_list = join ", ", map {_quote_var($_) . " => undef"} keys %known_params;
		$validator_sub .= <<PARAM;
		    {
				my \%known_params = ($known_params_list);
				for my \$pr(keys \%{\$_[0]}) {
PARAM
		if ($extra_params_rule eq 'ignore') {
			$validator_sub .= <<PARAM;
					delete $jsn {\$pr} if !exists(\$known_params {\$pr});
PARAM
		} elsif ($extra_params_rule eq 'disallow') {
			$validator_sub .= <<PARAM;
					croak {
						result => 'BADPARAM', 
						answer => 'Parameter \$1 is not allowed here', 
						answer_args => ['\$pr']
					} if !exists(\$known_params {\$pr});
PARAM
		}
		$validator_sub .= <<PARAM;
		  		}
		    }
PARAM
	}
	$validator_sub .= "\$_[0]\n}";
	$validator_sub;
}

sub _quote_var {
	my $s = $_[0];
	my $d = Data::Dumper->new([$s]);
	$d->Terse(1);
	my $qs = $d->Dump;
	substr($qs, -1, 1, '') if substr($qs, -1, 1) eq "\n";
	return $qs;
}

sub make_value_parser {
	my $value = $_[0];
	my $ret   = _quote_var($value);
	if (substr($value, 0, 3) eq 'TT ') {
		my $exp = substr($value, 3);
		$exp = _quote_var($exp);
		if (substr($exp, 0, 1) eq "'") {
			substr($exp, 0,  1, '');
			substr($exp, -1, 1, '');
		}
		$ret = <<VP;
		do {
			my \$tmpl = '[% $exp %]';
			my \$out;
			\$tt->process_simple(\\\$tmpl, \$stash, \\\$out) 
			or
				cfg_log_level_error()
				&& 
				\$logger->({level => "error", message => 'error: $exp - ' . \$tt->error});\n
			\$out;
		}
VP
	}
	return $ret;
}

sub _make_cookie_parser {
	my ($name, $value) = @_;
	$value = {value => $value} if not ref $value;
	$name = _quote_var($name);
	$value->{path} = '/' if not $value->{path};
	my $ret = <<CP;
	\$http_response->set_cookie($name, {
CP
	for my $pn (qw/value expires domain path secure max-age httponly/) {
		if (exists $value->{$pn}) {
			my $qvpn = _quote_var($pn);
			my $pv   = make_value_parser($value->{$pn});
			$ret .= <<CP;
		$qvpn => $pv,
CP
		}
	}
	if (not exists $value->{secure}) {
		$ret .= <<CP;
		(\$context->{scheme} eq 'https'?(secure => 1): ()),
CP
	}
	$ret .= <<CP;
	});
CP
	return $ret;
}

sub _make_rules_parser {
	my ($start) = @_;
	$start = {redirect => $start} if not ref $start or 'ARRAY' eq ref $start;
	my $sub_int = "sub {\n";
	for my $cmd (keys %$start) {
		if ($cmd eq 'redirect') {
			my $redir = $start->{$cmd};
			$redir = [$redir] if 'ARRAY' ne ref $redir;
			my $rw = "\t{\n";
			for my $r (@$redir) {
				$rw .= "\t\t\$new_location = " . make_value_parser($r) . ";\n\t\tlast if \$new_location;\n";
			}
			$rw      .= "\t}\n";
			$sub_int .= "\tif(\$context->{src} ne 'ajax') { $rw }";
		} elsif ($cmd eq 'set-cookie') {
			for my $c (keys %{$start->{$cmd}}) {
				$sub_int .= _make_cookie_parser($c => $start->{$cmd}{$c});
			}
		} elsif ($cmd eq 'unset-cookie') {
			my $unset = $start->{$cmd};
			if (ref($unset) eq 'HASH') {
				for my $c (keys %$unset) {
					my $ca = {%{$start->{$cmd}{$c}}};
					$ca->{expires} = cfg_cookie_unset_negative_expire
						if not exists $ca->{expires};
					$ca->{value} = '' if not exists $ca->{value};
					$sub_int .= _make_cookie_parser($c => $ca);
				}
			} else {
				$unset = [$unset] if not ref $unset;
				for my $c (@$unset) {
					$sub_int .= _make_cookie_parser(
						$c => {
							value   => '',
							expires => cfg_cookie_unset_negative_expire
						}
					);
				}
			}
		} elsif ($cmd eq 'add-header') {
			for my $h (keys %{$start->{$cmd}}) {
				my $value = make_value_parser($start->{$cmd}{$h});
				$sub_int .= "\t\$http_response->add_header(" . _quote_var($h) . ", $value);\n";
			}
		} elsif ($cmd eq 'set-header') {
			for my $h (keys %{$start->{$cmd}}) {
				my $value = make_value_parser($start->{$cmd}{$h});
				$sub_int .= "\t\$http_response->set_header(" . _quote_var($h) . ", $value);\n";
			}
		} elsif ($cmd eq 'filter') {
			my $full_func;
			my $use_class;
			if (index($start->{$cmd}, 'PEF::Front::') == 0) {
				$full_func = $start->{$cmd};
				$use_class = substr($full_func, 0, rindex($full_func, "::"));
				$sub_int .= "\teval {use $use_class; $full_func(\$response, \$context)};\n";
			} else {
				$full_func = cfg_app_namespace . "OutFilter::" . $start->{$cmd};
				$use_class = substr($full_func, 0, rindex($full_func, "::"));
				eval "use $use_class;";
				croak {
					result  => 'INTERR',
					answer  => 'Internal server error',
					message => $@,
					}
					if $@;
				$sub_int .= "\teval {$full_func(\$response, \$context)};\n";
			}
			$sub_int .= <<MRP;
			if (\$\@) {
				cfg_log_level_error()
				&& \$logger->({level => "error", message => "output filter: " . Dumper(\$\@)});
				\$response = {result => 'INTERR', answer => 'Bad output filter'};
				return;
			}
MRP
		} elsif ($cmd eq 'answer') {
			$sub_int .= "\t\$response->{answer} = " . make_value_parser($start->{$cmd}) . ";\n";
		}
	}
	$sub_int .= "\t}";
	return $sub_int;
}

sub _build_result_processor {
	my $result_rules = $_[0];
	my $result_sub   = <<RSUB;
	sub {
		my (\$response, \$context, \$stash, \$http_response, \$tt, \$logger) = \@_;
		my \$new_location;
		my \%rc = (
RSUB
	my %rc_array;
	for my $rc (keys %{$result_rules}) {
		my $qrc = _quote_var($rc);
		my $rsub = _make_rules_parser($result_rules->{$rc} || {});
		$result_sub .= <<RSUB;
		  $qrc => $rsub,
RSUB
	}
	$result_sub .= <<RSUB;
		);
		my \$rc;
		if (not exists \$rc{\$response->{result}}) {
			if(exists \$rc{DEFAULT}) { 
				\$rc = 'DEFAULT';
			} else {
				cfg_log_level_error()
				&& \$logger->({level => "error", 
					message => "error: Unexpected result code: '\$response->{result}'"});
				return (undef, {result => 'INTERR', answer => 'Bad result code'});
			}
		} else {
			\$rc = \$response->{result};
		}
		\$rc{\$rc}->();
		return (\$new_location, \$response);
	}
RSUB
	#print $result_sub;
	return eval $result_sub;
}

sub load_validation_rules {
	my ($method) = @_;
	my $mrf = $method;
	$mrf =~ s/ ([[:lower:]])/\u$1/g;
	$mrf = ucfirst($mrf);
	my $rules_file = cfg_model_dir . "/$mrf.yaml";
	my @stats;
	if (cfg_model_rules_reload || !exists($model_cache{$method})) {
		@stats = stat($rules_file);
		croak {
			result => 'INTERR',
			answer => 'Unknown rules file'
		} if !@stats;
	} else {
		$stats[9] = $model_cache{$method}{modified};
	}
	my $base_file = cfg_model_dir . "/-base-.yaml";
	my @bfs;
	if (cfg_model_rules_reload || !exists($model_cache{'-base-'})) {
		@bfs = stat($base_file);
	} else {
		$bfs[9] = $model_cache{'-base-'}{modified};
	}
	if (@bfs
		&& (!exists($model_cache{'-base-'}) || $model_cache{'-base-'}{modified} != $bfs[9]))
	{
		%model_cache = ('-base-' => {modified => $bfs[9]});
		open my $fi, "<",
			$base_file
			or croak {
			result      => 'INTERR',
			answer      => 'cant read base rules file: $1',
			answer_args => ["$!"],
			};
		my $raw_rules;
		read($fi, $raw_rules, -s $fi);
		close $fi;
		my @new_rules = eval {Load $raw_rules};
		if ($@) {
			cluck $@;
			croak {
				result      => 'INTERR',
				answer      => 'Base rules validation error: $1',
				answer_args => ["$@"]
			};
		} else {
			my $new_rules = $new_rules[0];
			$model_cache{'-base-'}{rules} = $new_rules;
		}
	}
	if (!exists($model_cache{$method}) || $model_cache{$method}{modified} != $stats[9]) {
		open my $fi, "<",
			$rules_file
			or croak {
			result      => 'INTERR',
			answer      => 'cant read rules file: $1',
			answer_args => ["$!"],
			};
		my $raw_rules;
		read($fi, $raw_rules, -s $fi);
		close $fi;
		my @new_rules = eval {Load $raw_rules};
		croak {
			result      => 'INTERR',
			answer      => 'Validator $1 description error: $2',
			answer_args => [$method, "$@"]
			}
			if $@;
		my $new_rules = $new_rules[0];
		$new_rules->{method} = $method;
		my $validator_sub = _build_validator($new_rules);
		$model_cache{$method}{code_text} = $validator_sub;
		my $vsubname = "validate$mrf";
		eval "\$model_cache{\$method}{code} = subname $vsubname => $validator_sub";
		croak {
			result        => 'INTERR',
			answer        => 'Validator $1 error: $2',
			answer_args   => [$method, "$@"],
			validator_sub => $validator_sub
			}
			if $@;

		for (keys %$new_rules) {
			$model_cache{$method}{$_} = $new_rules->{$_} if $_ ne 'code';
		}
		my ($model, $model_sub) = PEF::Front::Model::make_model_call($method, $new_rules->{model});
		$model_cache{$method}{model}     = $model;
		$model_cache{$method}{model_sub} = $model_sub;
		if (exists $new_rules->{result}) {
			my $rsubname = "result$mrf";
			$model_cache{$method}{result_sub} = subname $rsubname => _build_result_processor($new_rules->{result} || {});
		}
		$model_cache{$method}{modified} = $stats[9];
	}
}

sub validate {
	my ($request, $context) = @_;
	my $method = $request->{method}
		or croak(
		{   result => 'INTERR',
			answer => 'Unknown method'
		}
		);
	load_validation_rules($method);
	$model_cache{$method}{code}->($request, $context);
}

sub get_method_attrs {
	my $request = $_[0];
	my $method = ref($request) ? $request->{method} : $request;
	if (exists $model_cache{$method}{$_[1]}) {
		return $model_cache{$method}{$_[1]};
	} else {
		return;
	}
}

sub get_model {
	get_method_attrs($_[0] => 'model');
}
1;
