package Rope::Object;

use strict;
use warnings;

sub TIEHASH {
        my ($class, $obj) = @_;
        my $self = bless $obj || {}, $class;
	$self->{properties}->{ROPE_init} = {
		value => sub { $self->init }
	};
	return $self;
}

sub init {
	my ($self) = @_;
	$self->set_value(
		$_,
		$self->{properties}->{$_}->{value},
		$self->{properties}->{$_}
	) for keys %{$self->{properties}};
	$self->compile();
	delete $self->{properties}->{ROPE_init};
	$self;
}

sub compile {
	my ($self) = @_;
	$self->{keys} = scalar keys %{$self->{properties}};
	$self->{sort_keys} = [sort {
		$self->{properties}->{$a}->{index} <=> $self->{properties}->{$b}->{index}
	} grep { $self->{properties}->{$_}->{enumerable} } keys %{$self->{properties}}];
	if ($self->{requires}) {
		for (keys %{$self->{requires}}) {
			die sprintf "Failed to instantiate %s object requires property %s", $self->{name}, $_
				unless $self->{properties}->{$_} 
					&& defined $self->{properties}->{$_}->{value};
		}
	}
	return $self;
}

sub set_value {
	my ($self, $key, $value, $spec) = @_;
	if ($spec->{trigger}) {
		$value = $spec->{trigger}->($value);
	}
	if (ref($value || "") ne 'CODE') {
		for (qw/before around after/) {
			if ($spec->{$_}) {
				my $val = $spec->{$_}->($value);
				if (defined $val) {
					$value = $val;
				}
			}
		}
	}
	if ($spec->{type} && defined $value) {
		$value = eval {
			$spec->{coerce_type} 
				? $spec->{type}->coerce($value)
				: $spec->{type}->($value);
		};
		if ($@) {
			my @caller = caller(1);
			if ($caller[0] eq 'Rope::Object') {
				die sprintf("Failed to instantiate object (%s) property (%s) failed type validation. %s", $self->{name}, $key, $@);
			}
			die sprintf("Cannot set property (%s) in object (%s) failed type validation on line %s file %s: %s", $key, $self->{name}, $caller[2], $caller[1], $@);
		}
	}

	if ($spec->{handles_via}) {
		eval "require $spec->{handles_via}";
		my $href = ref $value;
		$spec->{value} = $spec->{handles_via}->new($href eq 'ARRAY' ? @{$value} : $href eq 'HASH' ? %{$value} : $value);
	} else {
		$spec->{value} = $value;
	}
	if ($spec->{required} && ! defined $spec->{value}) {
		die sprintf "Required property (%s) in object (%s) not set", $key, $self->{name};
	}
	return $spec->{value};
}
 
sub STORE {
        my ($self, $key, $value) = @_;

	if ($key eq 'locked') {
		$self->{locked} = $value;
		return;
	}
	my $k = $self->{properties}->{$key};

	if ($k) {
		if ($k->{private}) {
			my $priv = $self->private_names;
			if ( $self->current_caller !~ m/^($priv)$/) {
				die "Cannot access Object ($self->{name}) property ($key) as it is private";
			}
		}

		if ($k->{writeable}) {
			$self->set_value($key, $value, $k);
		} elsif ($k->{configurable}) {
			if ((ref($value) || "") eq (ref($k->{value}) || "")) {
				$self->set_value($key, $value, $k);
			} else {
				die "Cannot change Object ($self->{name}) property ($key) type";
			}
		} else {
			die "Cannot set Object ($self->{name}) property ($key) it is only readable";
		}
        } elsif (! $self->{locked}) {
                $self->{properties}->{$key} = {
                        ((ref $value || "") eq 'HASH' && grep { defined $value->{$_} } qw/initable writeable configurable enumerable/) ? (
				index => ++$self->{keys},
				%{$value}
			) : (
				value => $value,
				initable => 1,
				writeable => 1,
				configurable => 1,
				enumerable => 1,
				index => ++$self->{keys}
                	)
		};
		push @{$self->{sort_keys}}, $key;
        } else {
		die "Object ($self->{name}) is locked you cannot extend with new properties";
	}
        return $self;
}
 
sub FETCH {
        my ($self, $key) = @_;
        my $k = $self->{properties}->{$key} || $self->{handles}->{$key} && $self->{properties}->{$self->{handles}->{$key}};
	return undef unless defined $k->{value};
	if ($k->{private}) {
		my $priv = $self->private_names;
		if ( $self->current_caller !~ m/^($priv)$/) {
			die "Cannot access Object ($self->{name}) property ($key) as it is private";
		}
	}
	
	if (!$k->{writeable} && !$k->{configurable} && (ref($k->{value}) || '') eq 'CODE') {
		if ($k->{before} || $k->{after} || $k->{around}) {
			return sub {
				my (@params) = @_;
				my @new_params;
				@new_params = $k->{before}->(@params) if $k->{before};
				@params = @new_params if scalar @new_params;
				if ($k->{around}) {
					@params = $k->{around}->($k->{value}, @params);
				} else {
					@params = $k->{value}->(@params);	
				}
				if ($k->{after}) {
					@new_params = ($k->{after}->(@params));
					@params = @new_params if scalar @new_params;
				}
				return wantarray ? @params : $params[0];
			};
		}
	}
	
	if ($self->{handles}->{$key} && !$self->{properties}->{ROPE_init}) {
		my $meth = $k->{handles}->{$key};
		if ($k->{value}) {
			return sub { $k->{value}->$meth(@_) };
		}
	}

        return $k->{value};
}
 
sub FIRSTKEY {
	goto &NEXTKEY;
}
 
sub NEXTKEY {
	return (each @{$_[0]->{sort_keys}})[1];
}
 
sub EXISTS {
       	exists $_[0]->{properties}->{$_[1]};
}
 
sub DELETE { 
        my $k = $_[0]->{properties}->{$_[1]};
	if ($k->{delete_trigger}) {
		$k->{delete_trigger}->($k->{value});
	}
	my $del = !$_[0]->{locked} && $k->{writeable} ? delete $_[0]->{properties}->{$_[1]} : undef;
	$_[0]->compile() if $del;
	return $del;
}
 
sub CLEAR {
	return;
        #%{$_[0]->{properties}} = () 
}
 
sub SCALAR { 
        scalar keys %{$_[0]->{properties}}
}

sub DESTROY { }

sub private_names {
	my $self = shift;
	return $self->{name} . ($self->{with} ? ('|' . join('|', @{$self->{with}})) : '') . ($self->{extends} ? ('|' . join('|', @{$self->{extends}})) : ''); 
}

sub current_caller {
	my ($n, $caller) = (0, '');
	while (my $call = scalar caller($n)) {
		if ($call !~ m/Rope(::(Object|Autoload|Monkey))?/) {
			return $call;
		}
		$n++;
	}
}

1;

__END__ 
