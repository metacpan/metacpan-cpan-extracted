package Rope;

use 5.006; use strict; use warnings;
our $VERSION = '0.26';
use Rope::Object;
my (%META, %PRO);
our @ISA;

BEGIN {
	%PRO = (
		keyword => sub {
			my ($caller, $method, $cb) = @_;
			no strict 'refs';
			*{"${caller}::${method}"} = $cb;
		},
		scope => sub {
			my ($caller, $self, %props) = @_;
			for my $prop (keys %{$props{properties}}) {
				if ($props{properties}{$prop}{value} && ref $props{properties}{$prop}{value} eq 'CODE') {
					my $cb = $props{properties}{$prop}{value};
					$props{properties}{$prop}{value} = sub { $cb->($META{initialised}{$caller}{${$self}->{identifier}}, @_) };
				}
				for (qw/predicate clearer/) {	
					if ($props{properties}->{$prop}->{$_}) {
						my $prep = $_ eq 'predicate' ? 'has_' : 'clear_';
						my $pred = $props{properties}->{$prop}->{$_};
						my $ref = ref($pred);
						if ( !$ref ) {
							$props{properties}->{$pred =~ m/^\d+$/ ? "$prep$prop" : $pred} = {
								value => $_ eq 'predicate' 
									? sub { return defined $META{initialised}{$caller}{${$self}->{identifier}}->{$prop} ? 1 : '' }
									: sub { $META{initialised}{$caller}{${$self}->{identifier}}->{$prop} = undef; 1; }
							};
						} elsif ($ref eq 'CODE') {
							$props{properties}->{"$prep$prop"} = {
								value => sub { $pred->($META{initialised}{$caller}{${$self}->{identifier}}, $prop) }
							};
						} elsif ($ref eq 'HASH') {
							my $cb = $pred->{value};
							$pred->{value} = sub { $cb->($META{initialised}{$caller}{${$self}->{identifier}}, $prop) };
							$props{properties}->{$pred->{name} || "$prep$prop"} = $pred;
						}
					}
				}
				for (qw/trigger delete_trigger/) {
					my $trigger = $props{properties}{$prop}{$_};
					if (defined $trigger) {
						$props{properties}{$prop}{$_} = sub { 
							$trigger->($META{initialised}{$caller}{${$self}->{identifier}}, @_) 
						};
					}
				}
				for (qw/before after/) {
					my $mod = $props{properties}{$prop}{$_};
					if (defined $mod && scalar @{$mod}) {
						my $cb = sub {
							my $cb = shift;
							$cb->($META{initialised}{$caller}{${$self}->{identifier}}, @_);
						};
						$props{properties}{$prop}{$_} = sub {
							my (@params) = @_;
							for (my $i = 0; $i < scalar @{$mod} - 1; $i++) {
								my @new_params = ($cb->($mod->[$i], @params));
								@params = @new_params if @new_params;
							}
							return $cb->($mod->[-1], @params);
						};
					}
				}
				my $mod = $props{properties}{$prop}{around};
				if (defined $mod && scalar @{$mod}) {
					my $cb = sub {
						my $cb = shift;
						$cb->($META{initialised}{$caller}{${$self}->{identifier}}, @_);
					};
					$props{properties}{$prop}{around} = sub {
						my ($orig, @params) = @_;
						my $code = (ref($orig) || "") eq 'CODE';
						@params = ($orig) if (!$code);
						my @stack;
						for (my $i = 0; $i < scalar @{$mod}; $i++) {
							my $current = $mod->[$i];
							my $next = $stack[-1] ? $stack[-1] : $code ? $orig : sub { $_[0] };
							my $calling = sub {
								return $cb->($current, $next, @_); 
							};
							push @stack, $calling;
						}
						return $stack[-1]->(@params);
					};
				}
			}
			return \%props;
		},
		clone => sub {
			my $obj = shift;
			my $ref = ref $obj;
			return $obj if !$ref;
			return [ map { $PRO{clone}->($_) } @{$obj} ] if $ref eq 'ARRAY';
			return { map { $_ => $PRO{clone}->($obj->{$_}) } keys %{$obj} } if $ref eq 'HASH';
			return $obj;
		},
		set_prop => sub {
			my ($caller, $prop, %options) = @_;
			if (exists $META{$caller}{properties}{$prop}) {
				defined $options{$_} && do { $META{$caller}{properties}{$prop}{$_} = $options{$_} } for qw/builder trigger delete_trigger/;
				if ($META{$caller}{properties}{$prop}{writeable}) {
					$META{$caller}{properties}{$prop}{value} = $options{value} if exists $options{value};
					$META{$caller}{properties}{$prop}{class} = $caller;
				} elsif ($META{$caller}{properties}{$prop}{configurable}) {
					if ((ref($META{$caller}{properties}{$prop}{value}) || "") eq (ref($options{value}) || "")) {
						$META{$caller}{properties}{$prop}{value} = $options{value} if exists $options{value};
						$META{$caller}{properties}{$prop}{class} = $caller;
					} else {
						die "Cannot inherit $META{$caller}{properties}{$prop}{class} and change property $prop type";
					}
				} else {
					die "Cannot inherit $META{$caller}{properties}{$prop}{class} and change property $prop type";
				}
			} else {
				$META{$caller}{properties}{$prop} = {
					class => $options{class} || $caller,
					index => ++$META{$caller}{keys},	
					%options
				};
			}
		},
		requires => sub {
			my ($caller) = shift;
			return sub {
				shift @_ if $_[0] && $_[0] eq $caller;
				my (@requires) = @_;
				$META{$caller}{requires}{$_}++ for (@requires);
			};
		},
		function => sub {
			my ($caller) = shift;
			return sub {
				shift @_ if $_[0] eq $caller;
				my ($prop, @options) = @_;
				$prop = shift @options if ( @options > 1 );
				$PRO{set_prop}(
					$caller,
					$prop,
					value => $options[0],
					enumerable => 0,
					writeable => 0,
					initable => 0,
					configurable => 0
				);
			};
		},
		properties => sub {
			my ($caller) = shift;
			return sub {
				shift @_ if $_[0] eq $caller;
				my (@properties) = @_;
				while (@properties) {
					my ($prop, $options) = (shift @properties, shift @properties);
					my $ref = ref $options;					
					if (!$ref || $ref ne 'HASH' || ! grep { defined $options->{$_} } 
						qw/initable writeable builder enumerable configurable trigger clearer predicate delete_trigger value/
					) {
						$options = {
							initable => 1,
							enumerable => 1,
							writeable => 1,
							configurable => 1,
							value => $options 
						};
					}
					$PRO{set_prop}(
						$caller,
						$prop,
						%{$options}
					);
				}
			};
		},
		property => sub {
			my ($caller) = shift;
			return sub {
				shift @_ if $_[0] eq $caller;
				my ($prop, @options) = @_;
				if (scalar @options % 2) {
					$prop = shift @options;
				}
				$PRO{set_prop}(
					$caller,
					$prop,
					@options
				);
			};
		},
		prototyped => sub {
			my ($caller) = shift;
			return sub {
				shift @_ if $_[0] eq $caller;
				my (@proto) = @_;
				while (@proto) {
					my ($prop, $value) = (shift @proto, shift @proto);
					$PRO{set_prop}(
						$caller,
						$prop,
						enumerable => 1,
						writeable => 1,
						configurable => 1,
						initable => 1,
						value => $value
					);
				}
			}
		},
		with => sub {
			my ($caller) = shift;
			return sub {
				shift @_ if $_[0] eq $caller;
				my (@withs) = @_;
				for my $with (@withs) {
					if (!$META{$with}) {
						(my $name = $with) =~ s!::!/!g;
						$name .= ".pm";
						CORE::require($name);
					}
					my $initial = $META{$caller};
					my $merge = $PRO{clone}($META{$with});
					push @{$merge->{with}}, $merge->{name};
					$merge->{name} = $initial->{name};
					$merge->{locked} = $initial->{locked};
					for my $prop (keys %{$initial->{properties}}) {
						$merge->{properties}->{$prop}->{index} = ++$merge->{keys};
						my $modifier;
						for (qw/before around after/) {
							if ($initial->{properties}->{$prop}->{$_}) {
								$modifier = 1;
								unshift @{$merge->{properties}->{$prop}->{$_}}, @{$initial->{properties}->{$prop}->{$_}} 
							}
						}
						next if $modifier;
						next if grep { $META{$with}->{properties}->{$prop}->{$_} } qw/before around after/;
						use Data::Dumper;
						warn Dumper $modifier;
						warn Dumper $merge->{properties}->{$prop};
						warn Dumper $prop;
						if (scalar keys %{$merge->{properties}->{$prop}} > 1) {
							if ($merge->{properties}->{writeable}) {
								$merge->{properties}->{$prop} = $initial->{properties}->{$prop};
							} elsif ($merge->{properties}->{configurable}) {
								if ((ref($merge->{properties}->{$prop}->{value}) || "") eq (ref($initial->{properties}->{$prop}->{value} || ""))) {
									$merge->{properties}->{$prop} = $initial->{properties}->{$prop};
								} else {
									die "Cannot include $with and change property $prop type";
								}
							} else {
								die "Cannot include $with and override property $prop";
							}
						} else {
							$merge->{properties}->{$prop} = $initial->{properties}->{$prop};
						}
					}
					$merge->{requires} = {%{$merge->{requires}}, %{$initial->{requires}}};
					$META{$caller} = $merge;
				}
			}
		},
		extends => sub {
			my ($caller) = shift;
			return sub {
				shift @_ if $_[0] eq $caller;
				my (@extends) = @_;
				for my $extend (@extends) {
					if (!$META{$extend}) {
						(my $name = $extend) =~ s!::!/!g;
						$name .= ".pm";
						CORE::require($name);
					}
					my $initial = $META{$caller};
					my $merge = $PRO{clone}($META{$extend});
					push @{$merge->{extends}}, $merge->{name};
					$merge->{name} = $initial->{name};
					$merge->{locked} = $initial->{locked};
					for my $prop (keys %{$initial->{properties}}) {
						$initial->{properties}->{$prop}->{index} = ++$merge->{keys};
						for (qw/before around after/) {
							unshift @{$merge->{properties}->{$prop}->{$_}}, @{$initial->{properties}->{$prop}->{$_}} if $initial->{properties}->{$prop}->{$_};
						}	
						if ($merge->{properties}->{$prop}) {
							if ($merge->{properties}->{writeable}) {
								$merge->{properties}->{$prop} = $initial->{properties}->{$prop};
							} elsif ($merge->{properties}->{configurable}) {
								if ((ref($merge->{properties}->{$prop}->{value}) || "") eq (ref($initial->{properties}->{$prop}->{value} || ""))) {
									$merge->{properties}->{$prop} = $initial->{properties}->{$prop};
								} else {
									die "Cannot inherit $extend and change property $prop type";
								}
							} else {
								die "Cannot inherit $extend and override property $prop";
							}
						} else {
							$merge->{properties}->{$prop} = $initial->{properties}->{$prop};
						}
					}
					$merge->{requires} = {%{$merge->{requires}}, %{$initial->{requires}}};
					my $isa = '@' . $caller . '::ISA';
					eval "push $isa, '$extend'";
					$META{$caller} = $merge;
				}
			}
		},
		before => sub {
			my ($caller) = shift;
			return sub {
				shift @_ if $_[0] eq $caller;
				my ($prop, $cb) = @_;
				push @{$META{$caller}{properties}{$prop}{before}}, $cb;
			};
		},
		around => sub {
			my ($caller) = shift;
			return sub {
				shift @_ if $_[0] eq $caller;
				my ($prop, $cb) = @_;
				push @{$META{$caller}{properties}{$prop}{around}}, $cb;
			};
		},
		after => sub {
			my ($caller) = shift;
			return sub {
				shift @_ if $_[0] eq $caller;
				my ($prop, $cb) = @_;
				push @{$META{$caller}{properties}{$prop}{after}}, $cb;
			};
		},
		locked => sub {
			my ($caller) = shift;
			return sub {
				my ($self, $locked) = @_;
				if (ref $self) {
					$self->{locked} = $locked;
					return;
				} else {
					$META{$caller}{locked} = 1;
				}
			};
		},
		destroy => sub {
			my ($caller) = shift;
			return sub {
				my ($self, $locked) = @_;
				if (ref $self) {
					return $self->DESTROY;
				}
			};
		},
		DESTROY => sub {
			my ($caller) = shift;
			return sub {
				my ($self, $locked) = @_;
				if (ref $self) {
					delete $META{initialised}{$caller}{${$self}->{identifier}};
					return;
				}
			};
		},
		new => sub {
			my ($caller) = shift;
			return sub {
				my ($class, %params) = (shift, scalar @_ == 1 ? %{$_[0]} : @_);
				my $self = \{
					prototype => {},
					identifier => $META{initialised}{$caller}{identifier}++
				};
				$self = bless $self, $caller;
				my $build = $PRO{clone}($META{$caller});
				for (keys %params) {
					if ($build->{properties}->{$_}) {
						if ($build->{properties}->{$_}->{initable}) {
							$build->{properties}->{$_}->{value} = $params{$_};
						} else {
							die "Cannot initalise Object ($caller) property ($_) as initable is not set to true.";
						}
					} else {
						$build->{properties}->{$_} = {
							value => $params{$_},
							initable => 1,
							writeable => 1,
							enumerable => 1,
							configurable => 1,
							index => ++$META{$caller}{keys}
						};
					}
				}
				for ( sort { $build->{properties}->{$a}->{index} <=> $build->{properties}->{$b}->{index} } keys %{ $build->{properties} } ) {
					if ( !defined $build->{properties}->{$_}->{value} && defined $build->{properties}->{$_}->{builder}) {
						my $builder = $build->{properties}->{$_}->{builder};
						$build->{properties}->{$_}->{value} = ref $builder ? $builder->($build) : $caller->$builder($build);
					}
				}
				tie %{${$self}->{prototype}}, 'Rope::Object', $PRO{scope}($caller, $self, %{$build});
				$META{initialised}{$caller}->{${$self}->{identifier}} = $self;
				$self->{ROPE_init}->();
				return $self;
			};
		}
	);
}

sub import {
	my ($pkg, $options, $caller) = (shift, {@_}, caller());
	return if $options->{no_import};
	$caller = $options->{caller} if $options->{caller};
	if (!$META{$caller}) {
		$META{$caller} = {
			name => $caller,
			locked => 0,
			properties => {},
			requires => {},
			keys => 0
		};
	}
	$PRO{keyword}($caller, 'can', sub { ref $_[0] and ($_[0]->{$_[1]} || $META{$caller}->{properties}->{$_[1]}) || $_[0]->CORE::can($_[1]) });
	$PRO{keyword}($caller, '(bool', sub { 1; });
	$PRO{keyword}($caller, '((', sub { });
	$PRO{keyword}($caller, '(%{}', sub {
		${$_[0]}->{prototype};
	});
	$PRO{keyword}($caller, $_, $PRO{$_}($caller))
		for $options->{import} 
			? @{$options->{import}} 
			: qw/function property properties prototyped extends with requires before around after locked destroy DESTROY new/;
}

sub new {
	my ($pkg, $meta, %params) = @_;

	my $name = $meta->{name} || 'Rope::Anonymous' . $META{ANONYMOUS}++;

	if (!$META{$name}) {
		$META{$name} = {
			name => $name,
			locked => 0,
			properties => {},
			requires => {},
			keys => 0
		};
		
		my $use = 'use Rope;';
		$use .= "use ${_};" for (@{$meta->{use}});

		my $c = sprintf(q|
			package %s;
			%s
			1;
		|, $name, $use);
		eval $c;
	}

	$pkg->set_meta($meta, $name);

	if (grep { $_ eq 'Rope::Monkey' } @{$meta->{use}}) {
		$meta->{name}->monkey();
	}

	return $PRO{new}($name)($name, %params);
}

sub from_data {
	my ($pkg, $data, $meta) = @_;

	$meta ||= {};
	$meta->{name} ||= 'Rope::Anonymous' . $META{ANONYMOUS}++;

	for (keys %{$data}) {
		$meta->{properties}->{$_} = {
			value => $data->{$_},
			writeable => 1,
			enumerable => 1
		};
	}

	return $pkg->new($meta)->new();
}

sub from_nested_data {
	my ($pkg, $data, $meta) = @_;

	$data = $PRO{clone}($data);

	for my $d (keys %{$data}) {
		my $ref = ref $data->{$d};
		if ($ref eq 'HASH') {
			$data->{$d} = $pkg->from_nested_data($data->{$d}, $meta);
		} elsif ($ref eq 'ARRAY') {
			for (my $i = 0; $i < scalar @{$data->{$d}}; $i++) {
				my $val = $data->{$d}->[$i];
				my $rref = ref $val || "";
				if ($rref eq 'HASH') {
					$val = $pkg->from_nested_data(
						$val,
						$meta
					);
					$data->{$d}->[$i] = $val;
				}
			}
		}
	}

	return $pkg->from_data($data, $meta);
}

sub get_initialised {
	my ($self, $caller, $init) = @_;
	return $META{initialised}{$caller}{$init};
}

sub get_meta {
	my ($self, $caller) = @_;
	return $PRO{clone}($META{$caller || ref $self});
}

sub set_meta {
	my ($self, $meta, $name) = @_;
	$name = $meta->{name} if ! $name;
	$META{$name}{locked} = $meta->{locked} if (defined $meta->{locked});
	$PRO{requires}($name)(ref $meta->{requires} eq 'ARRAY' ? @{$meta->{requires}} : keys %{$meta->{requires}}) if ($meta->{requires});
	$PRO{extends}($name)(@{$meta->{extends}}) if ($meta->{extends});
	$PRO{with}($name)(@{$meta->{with}}) if ($meta->{with});
	$PRO{properties}($name)(ref $meta->{properties} eq 'ARRAY' ? @{$meta->{properties}} : %{$meta->{properties}}) if ($meta->{properties})
}

sub clear_meta {
	my ($self, $name) = @_;
	$META{$name} = {
		name => $name,
		locked => 0,
		properties => {},
		requires => {},
		keys => 0
	};
}

sub clear_property {
	my ($self, $name, $prop) = @_;
	delete $META{$name}{properties}{$prop};
}

1;

__END__

=head1 NAME

Rope - Tied objects

=head1 VERSION

Version 0.26

=cut

=head1 SYNOPSIS

	package Knot;

	use Rope;

	prototyped (
		bend_update_count => 0,
		loops => 1,
		hitches => 10,
		...

	);

	properties (
		bends => {
			type => sub { $_[0] =~ m/^\d+$/ ? $_[0] : die "$_[0] != integer" },
			value => 10,
			initable => 1,
			configurable => 1,
			enumerable => 1,
			required => 1,
			trigger => sub {
				my ($self, $value) = @_;
				$self->{bend_update_count}++;
				return $value;
			}
			delete_trigger => sub { ... }
		},
		...
	);

	function add_loops => sub {
		my ($self, $loop) = @_;
		$self->{loops} += $loop;
	};

	1;

...

	my $k = Knot->new();

	say $k->{loops}; # 1;
	
	$k->{add_loops}(5);

	say $k->{loops}; # 6;

	$k->{add_loops} = 5; # errors


=head1 DESCRIPTION

C<Rope> is an Object Orientation system that is built on top of perls core hash tying implementation. It extends the functionality which is available with all the modern features you would expect from an modern OO system. This includes clear class and role definitions. With Rope you also get out of the box sorted objects, where the order you define persists.

=head1 CONFIGURE PROPERTIES

=head2 initable

If set to a true value then this property can be initialised during the object creationg, when calling ->new(%params). If set to false then on initialisation the code will die with a relevant error when you try to initialise it. (Cannot initalise Object ($name) property ($key) as initable is not set to true.)

=head2 writeable

If set to a true value then this property value can be updated after initialisation with any other value. If set to false then the code will die with a relevant error. If writeable is true then configurable is not checked and redundent. (Cannot set Object ($name) property ($key) it is only readable)

=head2 configurable

If set to a true value then this property value can be updated after initialisation with a value that matches the type of the existing. If you try to set a value which is not of the same type the code will die with a relevant error. (Cannot change Object ($name) property ($key) type). If you set to false and writeable is also false you will get the same error as writeable false.

=head2 enumerable

If set to a true value then the property will be enumerable when you itterate the object for example when you call keys %{$self}. If set to false then the property will be hidden from any itteration. Note also that when itterating your object keys are already ordered based on the order they were assigned.

=head2 private

If set to a true value then the property will be private, If you try to access the property from outside of the object definition then an error will be thrown. (Cannot access Object (Custom) property ($key) as it is private)

=head2 required

If set to a true value then this property is required at initialisation, either by a value key being set or via passing into ->new. I would suggest using this in conjunction with initable when you require a value is passed. If no value is passed and required is set to true then the code will die with a relevant error. (Required property ($key) in object ($object) not set)

=head2 type

The type property/key expects a code ref to be passed, all values that are then set either during initialisation or writing will run through this ref. Rope expects that you return the final value from this ref so you can use coercion via a type.

=head2 builder

The buidler property/key expects either a code ref or a scalar that represents the name of a sub routine in your class (currently not functions/properties but may extend in the future). It expects the value for that property to be returned from either the code ref or sub routine. Within a builder you can also add new properties to your object by extending the passed defintion, when extending this way I would suggest using ++$_[0]->{keys} to set the index so that sorting is persistent further down the line.

=head2 trigger

The trigger property/key expects a code ref that expects the value for that property to be returned so it can also be used for coecion on setting of a property. Two values are passed into a trigger the first being $self which allows you to access and manipulate the existing objects other properties, the second is the value that is being set for the property being called.

=head2 delete_trigger

A delete trigger works the same as a trigger but is called on delete instead of set. The second param is the last set value for that property.

=head2 predicate

A predicate allows you to define an accessor to check whether a property is set. You have a few options, you can pass a positive integer or code reference and that will default the predicate to "has_$prop". You can also pass a string to name the accessor like "has_my_thing" or finally if you would like more customisation  you can pass a hash that defines the object properties. You cannot create triggers or hooks on predicates directly.

=head2 clearer

A clearer allows you to define an accessor to clear a property (set it to undef).  You have a few options, you can pass a positive integer or code reference and that will default the clearer to "clear_$prop". You can also pass a string to name the accessor like "clear_my_thing" or finally if you would like more customisation you can pass a hash that defines the object properties. You cannot create triggers or hooks on clearers. when using clearers and type checking in conjuction you need to ensure the type supports undef or you need to create your own custom clearer using a code ref or hash ref.

=head2 index

The index property/key expects an integer, if you do not set then this integer it's automatically generated and associated to the property. You will only want to set this is you always want to have a property last when itterating

=head1 KEYWORDS

=head2 property

Extends the current object definition with a single new property

	property one => (
		initable => 1,
		writeable => 0,
		enumerable => 1,
		builder => sub {
			return 200;
		}
	);


=head2 properties

Extends the current object definition with multiple new properties

	properties (
		two => {
			type => sub { $_[0] =~ m/^\d+$/ ? $_[0] : die "$_[0] != integer" },
			value => 10,
			initable => 1,
			configurable => 1,
			enumerable => 1,
			required => 1
		},
		...
	);

=head2 prototyped

Extends the current object definition with multiple new properties where initable, writable and enumerable are all set to a true value.

	prototyped (
		two => 10
		...
	);

=head2 function

Extends the current object definition with a new property that acts as a function. A function has initable, writeable, enumerable and configurable all set to false so it cannot be changed/set once the object is instantiated.

	function three => sub {
		my ($self, $param) = @_;
		...
	};

NOTE: traditional sub routines work and should be inherited also.	

	sub three {
		my ($self, $param) = @_;
		...
	}

=head2 extends

The extends keyword allows you to extend your current definition with another object, your object will inherit all the properties of that extended object.

	package Ping;
	use Rope;
	extends 'Pong';

=head2 with

The with keyword allows you to include roles in your current object definition, your object will inherit all the properties of that role.

	package Ping;
	use Rope;
	with 'Pong';

=head2 requires

The requires keyword allows you to define properties which are required for either a role or an object, it works in both directions.

	package Pong;
	use Rope::Role;
	requires qw/host/;
	function ping => sub { ... };
	function pong => sub { ... };

	package Ping;
	use Rope;
	requires qw/ping pong/;
	with 'Pong';
	prototyped (
		host => '...'
	);

=head2 before

The before keyword allows you to hook in before you call a sub routine or setting a value. If a defined response is returned it will be carried through to any subsequent calls including the setting of a property.

	package Locked;

	use Rope;
	use Rope::Autoload;

	property count => (
		value => 0,
		configurable => 1,
		enumerable => 1
	);

	function two => sub {
		my ($self, $count) = @_;
		$self->count = $count;
		return $self->count;
	};

	1;

	package Load;

	use Rope;
	extends 'Locked';

	before count => sub {
		my ($self, $val) = @_;
		$val = $val * 2;
		return $val;
	};

	before two => sub {
		my ($self, $count) = @_;
		... do something that doesn't return a value ...
		return;
	};

	1;

=head2 around

The around keyword allows you to hook in around the calling of a sub routine or setting a value. If a defined response is returned it will be carried through to any subsequent calls including the setting of a property. To chain you must use the second param as a code reference.

	package Loading;

	use Rope;
	extends 'Load';

	around two => sub {
		my ($self, $cb, $val) = @_;
		$val = $val * 4;
		return $cb->($val);
	};

	1;

=head2 after

The after keyword allows you to hook in after the calling of a sub routine or setting a value. If a defined response is returned it will be carried through to any subsequent calls including the setting of a property.

	package Loaded;

	use Rope;
	extends 'Loading';

	after two => sub {
		my ($self, $val) = @_;
		$val = $val * 4;
		return $val;
	};
	
	1;

=head2 locked

The locked keyword can be used to lock your Object so that it can no longer be extended with new properties/keys.

	package Locked;

	use Rope;

	property one => ( ... );

	locked;

	1;

Once you have an object initialised you can toggle whether it is locked by calling 'locked' with either a true or false value.

	$obj->locked(1);

	$obj->locked(0);


=head1 METHODS

=head2 new

Along with class definitions you can also generate object using Rope itself, the options are the same as described above.

	my $knot = Rope->new({
		name => 'Knot',
		properties => [
			loops => 1,
			hitches => {
				type => Int,
				value => 10,
				initable => 0,
				configurable => 0,
			},
			add_loops => sub {
				my ($self, $loop) = @_;
				$self->{loops} += $loop;
			}
		]
	});

	my $with = Rope->new({
		use => [ 'Rope::Autoload' ],
		with => [ 'Knot' ],
		requires => [ qw/loops hitches add_loops/ ],
		properties => [ bends => { type => Int, initable => 1, configurable => 1 }, ... ]
	}, bends => 5);

	$knot->{loops};
	$with->loops;

=head2 destroy

For objects that are running in a long process, like under a web server, you will want to explicitly call destroy on your objects as to achieve the correct scoping a reference has to be held in memory. If running under a script the problem will not exists as destruction happens when that script ends.

	$knot->destroy();

=head2 get_initialised

This returns an existing initialised object by index set in order of initialisation, as long as it has not been destroyed by scope or calling the ->destroy explicitly, it will return undef in those cases.

	Rope->get_initialised('Knot', 0);

=head2 get_meta

This returns the existing META definition for an object. 

	Rope->get_meta('Knot');

NOTE: this is now read only

=head2 clear_meta

	Rope->clear_meta('Knot');

=head2 set_meta

Extend or redefine an object meta definition.

	package Knot;

	use Rope;

	prototyped (
		one => 1,
		two => 2,
		three =>3
	);

	1;

	package Hitch

	extends 'Knot';

	1;

	my $meta = Ropt->get_meta('Hitch');

	Rope->clear_meta('Hitch');

	delete $meta->{properties};

	Rope->set_meta($meta);

	Hitch->new->one;

=head2 from_data

Initialise a Rope object from a perl hash struct.

	my $obj = Rope::Object->from_data({
		one => 1,
		two => {
			a => 1,
			b => 2
		},
		three => [
			{
				a => 1,
				b => 2	
			}
		]
	}, { use => 'Rope::Monkey' });

	...

	$obj->one;
	$obj->two->{a};
	$obj->three->[0]->{a};


=head2 from_nested_data

Initialise a Rope object from a nested perl hash struct.

	my $obj = Rope::Object->from_nested_data({
		one => 1,
		two => {
			a => 1,
			b => 2
		},
		three => [
			{
				a => 1,
				b => 2	
			}
		]
	}, { use => 'Rope::Autoload' });

	...

	$obj->one;
	$obj->two->a;
	$obj->three->[0]->a;

NOTE: this generates an object definition per array item so in many cases it is better you define your object definitions yourself and then write the relevant logic to initialise them. I will eventually look into perhaps itterating all items finding all unique keys and then initialiasing, that will just take a bit more time though.

=head1 OBJECT CLASS DEFINITION

	package Builder;

	use Rope;

	property one => (
		initable => 1,
		writeable => 0,
		enumerable => 1,
		builder => sub {
			return 200;
		}	
	);

	property two => (
		writeable => 0,
		enumerable => 0,
		builder => sub {
			$_[0]->{properties}->{three} = {
				value => 'works',
				writeable => 0,
				index => ++$_[0]->{keys}
			};
			return $_[0]->{properties}->{one}->{value} + 11;
		}
	);

	1;

=head1 OBJECT ROLE DEFINITION

	package Builder::Role;

	use Rope::Role;

	property one => (
		initable => 1,
		writeable => 0,
		enumerable => 1,
		builder => sub {
			return 200;
		}	
	);

	1;

=head2 FACTORY AND CHAINS

With Rope you can also create chained and factory properties. A chained property is where you define several code blocks to be called in order that you define, they effectively hook into the Rope cores 'after' callback. A factory sub allows you to define a property which will react based upon the passed in parameters. Factories and Chains can be used in conjunction, the following is and example of a factory into a chain.

	package Church;

	use Rope;
	use Rope::Autoload;
	use Rope::Factory qw/Str/;
	use Rope::Chain;

	prototyped (
		been_cannot_find => [],
		found => []
	);

	function reset => sub {
		$_[0]->been_cannot_find = [];
		$_[0]->found = [];	
	};

	factory add => (
		[Str] => sub {
			$_[0]->reset() if $_[1] eq 'reset';
		},
		[Str, Str] => sub {
			$_[0]->reset() if $_[1] eq 'reset';
			push @{$_[0]->found}, $_[2];
		},
		sub { return 'fallback' }
	);

	chain add => 'ephesus' => sub {
		push @{ $_[0]->been_cannot_find }, 'Ephesus';
		return;
	};
 
	chain add => 'smyrna' => sub {
		push @{ $_[0]->been_cannot_find }, 'Smyrna';
		return;
	};
	 
	chain add => 'pergamon' => sub {
		push @{ $_[0]->been_cannot_find }, 'Pergamon';
		return;
	};

	chain add => 'thyatira' => sub {
		push @{ $_[0]->been_cannot_find }, 'Thyatira';
		return $_[0]->been_cannot_find;
	};

	...

	my $asia = Church->new();

	$asia->add('reset');

	$asia->add('reset', 'House of Mary');

	$asia->reset();

	$asia->thyatira();

Notes: If you chain into a factory, the factory will accept not the passed params but the response from the 'last' chain. Returning undef is a hack that only works when chaining a chain, your first defined chain in this approach should return either the passed request params or some valid response.  If you define multiple factories with the same name, the initial will be extended not re-written, so extending a factory or chain should work accross inheritance. If you would like to extend and existing et chain two factories together you can by passing an integer to the factory you would like to create or extend, you must understand the order they are instantiated for this to work as expected.

	factory add => 1 => ( # using the index 0 would extend the existing this extends after a new 'factory'
		[ArrayRef] => sub {
			push @{$_[1]}, 'Sardis';
			return $_[1];
		},
	);

=head1 AUTOLOADING

If you do not enjoy accessing properties as hash keys and would instead like to access them as package routines then you can simply include C<Rope::Autoload> and this will use perls internal AUTOLOAD functionality to expose your properties as routines.

	package Builder;

	use Rope;
	use Rope::Autoload;

	...

	1;

So you can write

	$builder->thing = 10;

Instead of

	$builder->{thing} = 10;

=head2 MONKEY PATCHING

If for some reason you do not like the Autoload approach then Rope also has support for monkey patching the package routines.

	package Builder;

	use Rope;
	use Rope::Monkey;

	...

	monkey;

	1;

	$builder->thing = 10;

=head1 TYPES

Rope also includes additional helpers for defining properties with fixed types, see C<Rope::Type> for more information. ( internally that uses C<Type::Standard> for the actual type checking. )

	package Knot;
	 
	use Rope;
	use Rope::Type qw/int/;
	 
	int loops => 1;
	int hitches => 10;

	1;

=head1 CAVEATS

before, around and after hooks will work on any property regardless of configuration unless the value is a code reference, here the property must be readonly (you get this by using the function keyword). This is to prevent unexpected behaviour when trying if you have code which sets the property with a new code ref.

If you have a long running process I would suggest calling ->destroy() directly, i hook into the actual DESTROY method however this may or may not be called if Rope keeps the variable in scope.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rope at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Rope>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Rope

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Rope>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Rope>

=item * Search CPAN

L<https://metacpan.org/release/Rope>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Rope
