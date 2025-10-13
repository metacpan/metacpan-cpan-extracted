package Params::Validate::Strict;

use strict;
use warnings;

use Carp;
use List::Util 1.33 qw(any);	# Required for memberof validation
use Exporter qw(import);	# Required for @EXPORT_OK
use Params::Get 0.13;
use Scalar::Util;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(validate_strict);

=head1 NAME

Params::Validate::Strict - Validates a set of parameters against a schema

=head1 VERSION

Version 0.15

=cut

our $VERSION = '0.15';

=head1 SYNOPSIS

    my $schema = {
        username => { type => 'string', min => 3, max => 50 },
        age => { type => 'integer', min => 0, max => 150 },
    };

    my $input = {
         username => 'john_doe',
         age => '30',	# Will be coerced to integer
    };

    my $validated_input = validate_strict(schema => $schema, input => $input);

    if(defined($validated_input)) {
        print "Example 1: Validation successful!\n";
        print 'Username: ', $validated_input->{username}, "\n";
        print 'Age: ', $validated_input->{age}, "\n";	# It's an integer now
    } else {
        print "Example 1: Validation failed: $@\n";
    }

=head1	METHODS

=head2 validate_strict

Validates a set of parameters against a schema.

This function takes two mandatory arguments:

=over 4

=item * C<schema>

A reference to a hash that defines the validation rules for each parameter.
The keys of the hash are the parameter names, and the values are either a string representing the parameter type or a reference to a hash containing more detailed rules.

=item * C<args> || C<input>

A reference to a hash containing the parameters to be validated.
The keys of the hash are the parameter names, and the values are the parameter values.

=back

It takes two optional arguments:

=over 4

=item * C<unknown_parameter_handler>

This parameter describes what to do when a parameter is given that is not in the schema of valid parameters.
It must be one of C<die> (the default), C<warn>, or C<ignore>.

=item * C<logger>

A logging object that understands messages such as C<error> and C<warn>.

=back

The schema can define the following rules for each parameter:

=over 4

=item * C<type>

The data type of the parameter.
Valid types are C<string>, C<integer>, C<number>, C<float> C<boolean>, C<hashref>, C<arrayref>, C<object> and C<coderef>.

=item * C<can>

The parameter must be an object that understands the method C<can>.
C<can> can be a simple scalar string of a method name,
or an arrayref of a list of method names, all of which must be supported by the object.

=item * C<isa>

The parameter must be an object of type C<isa>.

=item * C<memberof>

The parameter must be a member of the given arrayref.

=item * C<min>

The minimum length (for strings), value (for numbers) or number of keys (for hashrefs).

=item * C<max>

The maximum length (for strings), value (for numbers) or number of keys (for hashrefs).

=item * C<matches>

A regular expression that the parameter value must match.
Checks all members of arrayrefs.

=item * C<nomatch>

A regular expression that the parameter value must not match.
Checks all members of arrayrefs.

=item * C<callback>

A code reference to a subroutine that performs custom validation logic.
The subroutine should accept the parameter value as an argument and return true if the value is valid, false otherwise.

=item * C<optional>

A boolean value indicating whether the parameter is optional.
If true, the parameter is not required.
If false or omitted, the parameter is required.

=item * C<default>

Populate missing optional parameters with the specified value.
Note that this value is not validated.

  username => {
    type => 'string',
    optional => 1,
    default => 'guest'
  }

=item * C<element_type>

Extends the validation to individual elements of arrays.

  tags => {
    type => 'arrayref',
    element_type => 'number',	# Float means the same
    min => 1,	# this is the length of the array, not the min value for each of the numbers. For that, add a C<schema> rule
    max => 5
  }

=item * C<error_message>

The custom error message to be used in the event of a validation failure.

  age => {
    type => 'integer',
    min => 18,
    error_message => 'You must be at least 18 years old'
  }

=item * C<schema>

You can validate nested hashrefs and arrayrefs using the C<schema> property:

    my $schema = {
        user => {
            type => 'hashref',
            schema => {
                name => { type => 'string' },
                age => { type => 'integer', min => 0 },
                hobbies => {
                    type => 'arrayref',
                    schema => { type => 'string' }, # Validate each element
                    min => 1 # At least one hobby
                }
            }
        },
        metadata => {
            type => 'hashref',
            schema => {
                created => { type => 'string' },
                tags => {
                    type => 'arrayref',
                    schema => {
                        type => 'string',
                        matches => qr/^[a-z]+$/
                    }
                }
            }
        }
    };

=back

If a parameter is optional and its value is C<undef>,
validation will be skipped for that parameter.

If the validation fails, the function will C<croak> with an error message describing the validation failure.

If the validation is successful, the function will return a reference to a new hash containing the validated and (where applicable) coerced parameters.  Integer and number parameters will be coerced to their respective types.

=head1 MIGRATION FROM LEGACY VALIDATORS

=head2 From L<Params::Validate>

    # Old style
    validate(@_, {
        name => { type => SCALAR },
        age => { type => SCALAR, regex => qr/^\d+$/ }
    });

    # New style
    validate_strict(
        schema => {
            name => 'string',
            age => { type => 'integer', min => 0 }
        },
        args => { @_ }
    );

=head2 From L<Type::Params>

    # Old style
    my ($name, $age) = validate_positional \@_, Str, Int;

    # New style - requires converting to named parameters first
    my %args = (name => $_[0], age => $_[1]);
    my $validated = validate_strict(
        schema => { name => 'string', age => 'integer' },
        args => \%args
    );

=cut

sub validate_strict
{
	my $params = Params::Get::get_params(undef, \@_);

	my $schema = $params->{'schema'};
	my $args = $params->{'args'} || $params->{'input'};
	my $unknown_parameter_handler = $params->{'unknown_parameter_handler'} || 'die';
	my $logger = $params->{'logger'};

	# Check if schema and args are references to hashes
	if(ref($schema) ne 'HASH') {
		_error($logger, 'validate_strict: schema must be a hash reference');
	}

	if(exists($params->{'args'}) && (!defined($args))) {
		$args = {};
	} elsif(ref($args) ne 'HASH') {
		_error($logger, 'validate_strict: args must be a hash reference');
	}

	foreach my $key (keys %{$args}) {
		if(!exists($schema->{$key})) {
			if($unknown_parameter_handler eq 'die') {
				_error($logger, "::validate_strict: Unknown parameter '$key'");
			} elsif($unknown_parameter_handler eq 'warn') {
				_warn($logger, "::validate_strict: Unknown parameter '$key'");
				next;
			} elsif($unknown_parameter_handler eq 'ignore') {
				if($logger) {
					$logger->debug(__PACKAGE__ . "::validate_strict: Unknown parameter '$key'");
				}
				next;
			} else {
				_error($logger, "::validate_strict: '$unknown_parameter_handler' unknown_parameter_handler must be one of die, warn, ignore");
			}
		}
	}

	my %validated_args;
	foreach my $key (keys %{$schema}) {
		my $rules = $schema->{$key};
		my $value = $args->{$key};

		if(!defined($rules)) {	# Allow anything
			$validated_args{$key} = $value;
			next;
		}

		# If rules are a simple type string
		if(ref($rules) eq '') {
			$rules = { type => $rules };
		}

		# Handle optional parameters
		if((ref($rules) eq 'HASH') && $rules->{optional}) {
			if(!exists($args->{$key})) {
				if($rules->{'default'}) {
					# Populate missing optional parameters with the specfied output values
					$validated_args{$key} = $rules->{'default'};
				}
				next;	# optional and missing
			}
		} elsif(!exists($args->{$key})) {
			# The parameter is required
			_error($logger, "validate_strict: Required parameter '$key' is missing");
		}

		# Validate based on rules
		if(ref($rules) eq 'HASH') {
			if((my $min = $rules->{'min'}) && (my $max = $rules->{'max'})) {
				if($min > $max) {
					_error($logger, "validate_strict($key): min must be <= max ($min > $max)");
				}
			}

			if($rules->{'memberof'}) {
				if(my $min = $rules->{'min'}) {
					_error($logger, "validate_strict($key): min ($min) makes no sense with memberof");
				}
				if(my $max = $rules->{'max'}) {
					_error($logger, "validate_strict($key): max ($max) makes no sense with memberof");
				}
			}

			foreach my $rule_name (keys %$rules) {
				my $rule_value = $rules->{$rule_name};

				if($rule_name eq 'type') {
					my $type = lc($rule_value);

					if($type eq 'string') {
						if(ref($value)) {
							if($rules->{'error_message'}) {
								_error($logger, $rules->{'error_message'});
							} else {
								_error($logger, "validate_strict: Parameter '$key' must be a string");
							}
						}
						unless((ref($value) eq '') || (defined($value) && length($value))) {	# Allow undef for optional strings
							if($rules->{'error_message'}) {
								_error($logger, $rules->{'error_message'});
							} else {
								_error($logger, "validate_strict: Parameter '$key' must be a string");
							}
						}
					} elsif($type eq 'integer') {
						if(!defined($value)) {
							next;	# Skip if number is undefined
						}
						if($value !~ /^\s*[+\-]?\d+\s*$/) {
							if($rules->{'error_message'}) {
								_error($logger, $rules->{'error_message'});
							} else {
								_error($logger, "validate_strict: Parameter '$key' ($value) must be an integer");
							}
						}
						$value = int($value); # Coerce to integer
					} elsif(($type eq 'number') || ($type eq 'float')) {
						if(!defined($value)) {
							next;	# Skip if number is undefined
						}
						if(!Scalar::Util::looks_like_number($value)) {
							if($rules->{'error_message'}) {
								_error($logger, $rules->{'error_message'});
							} else {
								_error($logger, "validate_strict: Parameter '$key' must be a number");
							}
						}
						# $value = eval $value; # Coerce to number (be careful with eval)
						$value = 0 + $value;	# Numeric coercion
					} elsif($type eq 'arrayref') {
						if(!defined($value)) {
							next;	# Skip if arrayref is undefined
						}
						if(ref($value) ne 'ARRAY') {
							if($rules->{'error_message'}) {
								_error($logger, $rules->{'error_message'});
							} else {
								_error($logger, "validate_strict: Parameter '$key' must be an arrayref, not " . ref($value));
							}
						}
					} elsif($type eq 'hashref') {
						if(!defined($value)) {
							next;	# Skip if hashref is undefined
						}
						if(ref($value) ne 'HASH') {
							if($rules->{'error_message'}) {
								_error($logger, $rules->{'error_message'});
							} else {
								_error($logger, "validate_strict: Parameter '$key' must be an hashref");
							}
						}
					} elsif($type eq 'boolean') {
						if(!defined($value)) {
							next;	# Skip if bool is undefined
						}
						if(($value eq 'true') || ($value eq 'on')) {
							$value = 1;
						} elsif(($value eq 'false') || ($value eq 'off')) {
							$value = 0;
						}
						if(($value ne '1') && ($value ne '0')) {	# Do string compare
							if($rules->{'error_message'}) {
								_error($logger, $rules->{'error_message'});
							} else {
								_error($logger, "validate_strict: Parameter '$key' ($value) must be a boolean");
							}
						}
						$value = int($value);	# Coerce to integer
					} elsif($type eq 'coderef') {
						if(ref($value) ne 'CODE') {
							if($rules->{'error_message'}) {
								_error($logger, $rules->{'error_message'});
							} else {
								_error($logger, "validate_strict: Parameter '$key' must be a coderef");
							}
						}
					} elsif($type eq 'object') {
						if(!Scalar::Util::blessed($value)) {
							if($rules->{'error_message'}) {
								_error($logger, $rules->{'error_message'});
							} else {
								_error($logger, "validate_strict: Parameter '$key' must be an object");
							}
						}
					} else {
						_error($logger, "validate_strict: Unknown type '$type'");
					}
				} elsif($rule_name eq 'min') {
					if(!defined($rules->{'type'})) {
						_error($logger, "validate_strict: Don't know type of '$key' to determine its minimum value $rule_value");
					}
					if($rules->{'type'} eq 'string') {
						if(!defined($value)) {
							next;	# Skip if string is undefined
						}
						if(length($value) < $rule_value) {
							if($rules->{'error_message'}) {
								_error($logger, $rules->{'error_message'});
							} else {
								_error($logger, "validate_strict: String parameter '$key' too short (" . length($value) . "), must be at least length $rule_value");
							}
						}
					} elsif($rules->{'type'} eq 'arrayref') {
						if(!defined($value)) {
							next;	# Skip if array is undefined
						}
						if(ref($value) ne 'ARRAY') {
							if($rules->{'error_message'}) {
								_error($logger, $rules->{'error_message'});
							} else {
								_error($logger, "validate_strict: Parameter '$key' must be an arrayref, not " . ref($value));
							}
						}
						if(scalar(@{$value}) < $rule_value) {
							if($rules->{'error_message'}) {
								_error($logger, $rules->{'error_message'});
							} else {
								_error($logger, "validate_strict: Parameter '$key' must be at least length $rule_value");
							}
						}
					} elsif($rules->{'type'} eq 'hashref') {
						if(!defined($value)) {
							next;	# Skip if hash is undefined
						}
						if(scalar(keys(%{$value})) < $rule_value) {
							if($rules->{'error_message'}) {
								_error($logger, $rules->{'error_message'});
							} else {
								_error($logger, "validate_strict: Parameter '$key' must contain at least $rule_value keys");
							}
						}
					} elsif(($rules->{'type'} eq 'integer') || ($rules->{'type'} eq 'number') || ($rules->{'type'} eq 'float')) {
						if(!defined($value)) {
							next;	# Skip if hash is undefined
						}
						if($value < $rule_value) {
							if($rules->{'error_message'}) {
								_error($logger, $rules->{'error_message'});
							} else {
								_error($logger, "validate_strict: Parameter '$key' must be at least $rule_value");
							}
						}
					} else {
						_error($logger, "validate_strict: Parameter '$key' has meaningless min value $rule_value");
					}
				} elsif($rule_name eq 'max') {
					if(!defined($rules->{'type'})) {
						_error($logger, "validate_strict: Don't know type of '$key' to determine its maximum value $rule_value");
					}
					if($rules->{'type'} eq 'string') {
						if(!defined($value)) {
							next;	# Skip if string is undefined
						}
						if(length($value) > $rule_value) {
							if($rules->{'error_message'}) {
								_error($logger, $rules->{'error_message'});
							} else {
								_error($logger, "validate_strict: String parameter '$key' too long, (" . length($value) . " characters), must be no longer than $rule_value");
							}
						}
					} elsif($rules->{'type'} eq 'arrayref') {
						if(!defined($value)) {
							next;	# Skip if string is undefined
						}
						if(ref($value) ne 'ARRAY') {
							if($rules->{'error_message'}) {
								_error($logger, $rules->{'error_message'});
							} else {
								_error($logger, "validate_strict: Parameter '$key' must be an arrayref, not " . ref($value));
							}
						}
						if(scalar(@{$value}) > $rule_value) {
							if($rules->{'error_message'}) {
								_error($logger, $rules->{'error_message'});
							} else {
								_error($logger, "validate_strict: Parameter '$key' must contain no more than $rule_value items");
							}
						}
					} elsif($rules->{'type'} eq 'hashref') {
						if(!defined($value)) {
							next;	# Skip if hash is undefined
						}
						if(scalar(keys(%{$value})) > $rule_value) {
							if($rules->{'error_message'}) {
								_error($logger, $rules->{'error_message'});
							} else {
								_error($logger, "validate_strict: Parameter '$key' must contain no more than $rule_value keys");
							}
						}
					} elsif(($rules->{'type'} eq 'integer') || ($rules->{'type'} eq 'number') || ($rules->{'type'} eq 'float')) {
						if(!defined($value)) {
							next;	# Skip if hash is undefined
						}
						if($value > $rule_value) {
							if($rules->{'error_message'}) {
								_error($logger, $rules->{'error_message'});
							} else {
								_error($logger, "validate_strict: Parameter '$key' ($value) must be no more than $rule_value");
							}
						}
					} else {
						_error($logger, "validate_strict: Parameter '$key' has meaningless max value $rule_value");
					}
				} elsif($rule_name eq 'matches') {
					if(!defined($value)) {
						next;	# Skip if string is undefined
					}
					eval {
						if($rules->{'type'} eq 'arrayref') {
							my @matches = grep { /$rule_value/ } @{$value};
							if(scalar(@matches) != scalar(@{$value})) {
								if($rules->{'error_message'}) {
									_error($logger, $rules->{'error_message'});
								} else {
									_error($logger, "validate_strict: All members of parameter '$key' [", join(', ', @{$value}), "] must match pattern '$rule_value'");
								}
							}
						} elsif($value !~ $rule_value) {
							if($rules->{'error_message'}) {
								_error($logger, $rules->{'error_message'});
							} else {
								_error($logger, "validate_strict: Parameter '$key' ($value) must match pattern '$rule_value'");
							}
						}
					};
					if($@) {
						_error($logger, "validate_strict: Parameter '$key' regex '$rule_value' error: $@");
					}
				} elsif($rule_name eq 'nomatch') {
					if($rules->{'type'} eq 'arrayref') {
						my @matches = grep { /$rule_value/ } @{$value};
						if(scalar(@matches)) {
							if($rules->{'error_message'}) {
								_error($logger, $rules->{'error_message'});
							} else {
								_error($logger, "validate_strict: No member of parameter '$key' [", join(', ', @{$value}), "] must match pattern '$rule_value'");
							}
						}
					} elsif($value =~ $rule_value) {
						if($rules->{'error_message'}) {
							_error($logger, $rules->{'error_message'});
						} else {
							_error($logger, "validate_strict: Parameter '$key' ($value) must not match pattern '$rule_value'");
						}
					}
				} elsif($rule_name eq 'memberof') {
					if(!defined($value)) {
						next;	# Skip if string is undefined
					}
					if(ref($rule_value) eq 'ARRAY') {
						if(($rules->{'type'} eq 'integer') || ($rules->{'type'} eq 'number') || ($rules->{'type'} eq 'float')) {
							unless(List::Util::any { $_ == $value } @{$rule_value}) {
								if($rules->{'error_message'}) {
									_error($logger, $rules->{'error_message'});
								} else {
									_error($logger, "validate_strict: Parameter '$key' ($value) must be one of ", join(', ', @{$rule_value}));
								}
							}
						} else {
							unless(List::Util::any { $_ eq $value } @{$rule_value}) {
								if($rules->{'error_message'}) {
									_error($logger, $rules->{'error_message'});
								} else {
									_error($logger, "validate_strict: Parameter '$key' ($value) must be one of ", join(', ', @{$rule_value}));
								}
							}
						}
					} else {
						if($rules->{'error_message'}) {
							_error($logger, $rules->{'error_message'});
						} else {
							_error($logger, "validate_strict: Parameter '$key' rule ($rule_value) must be an array reference");
						}
					}
				} elsif ($rule_name eq 'callback') {
					unless (defined &$rule_value) {
						_error($logger, "validate_strict: callback for '$key' must be a code reference");
					}
					my $res = $rule_value->($value);
					unless ($res) {
						if($rules->{'error_message'}) {
							_error($logger, $rules->{'error_message'});
						} else {
							_error($logger, "validate_strict: Parameter '$key' failed custom validation");
						}
					}
				} elsif($rule_name eq 'isa') {
					if($rules->{'type'} eq 'object') {
						if(!$value->isa($rule_value)) {
							_error($logger, "validate_strict: Parameter '$key' must be a '$rule_value' object");
						}
					} else {
						_error($logger, "validate_strict: Parameter '$key' has meaningless isa value $rule_value");
					}
				} elsif($rule_name eq 'can') {
					if($rules->{'type'} eq 'object') {
						if(ref($rule_value) eq 'ARRAY') {
							# List of methods
							foreach my $method(@{$rule_value}) {
								if(!$value->can($method)) {
									_error($logger, "validate_strict: Parameter '$key' must be an object that understands the $method method");
								}
							}
						} elsif(!ref($rule_value)) {
							if(!$value->can($rule_value)) {
								_error($logger, "validate_strict: Parameter '$key' must be an object that understands the $rule_value method");
							}
						} else {
							_error($logger, "validate_strict: 'can' rule for Parameter '$key must be either a scalar or an arrayref");
						}
					} else {
						_error($logger, "validate_strict: Parameter '$key' has meaningless can value $rule_value");
					}
				} elsif($rule_name eq 'element_type') {
					if($rules->{'type'} eq 'arrayref') {
						foreach my $member(@{$value}) {
							if($rule_value eq 'string') {
								if(ref($member)) {
									if($rules->{'error_message'}) {
										_error($logger, $rules->{'error_message'});
									} else {
										_error($logger, "$key can only contain strings");
									}
								}
							} elsif($rule_value eq 'integer') {
								if(ref($member) || ($member =~ /\D/)) {
									if($rules->{'error_message'}) {
										_error($logger, $rules->{'error_message'});
									} else {
										_error($logger, "$key can only contain numbers (found $member)");
									}
								}
							} elsif(($rule_value eq 'number') || ($rule_value eq 'float')) {
								if(ref($member) || ($member !~ /^[-+]?(\d*\.\d+|\d+\.?\d*)$/)) {
									if($rules->{'error_message'}) {
										_error($logger, $rules->{'error_message'});
									} else {
										_error($logger, "$key can only contain numbers (found $member)");
									}
								}
							}
						}
					} else {
						_error($logger, "validate_strict: Parameter '$key' has meaningless element_type value $rule_value");
					}
				} elsif($rule_name eq 'optional') {
					# Already handled at the beginning of the loop
				} elsif($rule_name eq 'default') {
					# Handled earlier
				} elsif($rule_name eq 'error_message') {
					# Handled in line
				} elsif($rule_name eq 'schema') {
					# Nested schema Run the given schema against each element of the array
					if($rules->{'type'} eq 'arrayref') {
						if(ref($value) eq 'ARRAY') {
							foreach my $member(@{$value}) {
								validate_strict({ input => { $key => $member }, schema => { $key => $rule_value } });
							}
						} elsif(defined($value)) {	# Allow undef for optional values
							_error($logger, "validate_strict: nested schema: Parameter '$value' must be an arrayref");
						}
					} elsif($rules->{'type'} eq 'hashref') {
						if(ref($value) eq 'HASH') {
							if(scalar keys(%{$value})) {
								validate_strict({ input => $value, schema => $rule_value });
							}
						} else {
							_error($logger, "validate_strict: nested schema: Parameter '$value' must be an hashref");
						}
					} else {
						_error($logger, "validate_strict: Parameter '$key': 'schema' only supports arrayref and hashref, not $rules->{type}");
					}
				} else {
					_error($logger, "validate_strict: Unknown rule '$rule_name'");
				}
			}
		} elsif(ref($rules)) {
			_error($logger, 'rules must be a hash reference or string');
		}

		$validated_args{$key} = $value;
	}

	return \%validated_args;
}

# Helper to log error or croak
sub _error
{
	my $logger = shift;
	my $message = join('', @_);

	my @call_details = caller(0);
	if($logger) {
		$logger->error(__PACKAGE__, ' line ', $call_details[2], ": $message");
	} else {
		croak(__PACKAGE__, ' line ', $call_details[2], ": $message");
	}
}

# Helper to log warning or carp
sub _warn
{
	my $logger = shift;
	my $message = join('', @_);

	if($logger) {
		$logger->warn(__PACKAGE__, ": $message");
	} else {
		carp(__PACKAGE__ . ": $message");
	}
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=encoding utf-8

=head1 FORMAL SPECIFICATION

    [PARAM_NAME, VALUE, TYPE_NAME, CONSTRAINT_VALUE]

    ValidationRule ::= SimpleType | ComplexRule

    SimpleType ::= string | integer | number | arrayref | hashref | coderef | object

    ComplexRule == [
        type: TYPE_NAME;
        min: ℕ₁;
        max: ℕ₁;
        optional: 𝔹;
        matches: REGEX;
        nomatch: REGEX;
        memberof: seq VALUE;
        callback: FUNCTION;
        isa: TYPE_NAME;
        can: METHOD_NAME
    ]

    Schema == PARAM_NAME ⇸ ValidationRule

    Arguments == PARAM_NAME ⇸ VALUE

    ValidatedResult == PARAM_NAME ⇸ VALUE

    │ ∀ rule: ComplexRule • rule.min ≤ rule.max
    │ ∀ schema: Schema; args: Arguments •
    │   dom(validate_strict(schema, args)) ⊆ dom(schema) ∪ dom(args)

    validate_strict: Schema × Arguments → ValidatedResult

    ∀ schema: Schema; args: Arguments •
      let result == validate_strict(schema, args) •
        (∀ name: dom(schema) ∩ dom(args) •
          name ∈ dom(result) ⇒
          type_matches(result(name), schema(name))) ∧
        (∀ name: dom(schema) •
          ¬optional(schema(name)) ⇒ name ∈ dom(args))

    type_matches: VALUE × ValidationRule → 𝔹

=head1 BUGS

=head1 SEE ALSO

=over 4

=item * Test coverage report: L<https://nigelhorne.github.io/Params-Validate-Strict/coverage/>

=item * L<Params::Get>

=item * L<Params::Validate>

=item * L<Return::Set>

=back

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-params-validate-strict at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Params-Validate-Strict>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Params::Validate::Strict

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/Params-Validate-Strict>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Params-Validate-Strict>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Params-Validate-Strict>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Params::Validate::Strict>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2025 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;

__END__
