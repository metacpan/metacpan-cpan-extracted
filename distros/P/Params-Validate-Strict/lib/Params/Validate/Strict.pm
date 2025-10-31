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

Version 0.23

=cut

our $VERSION = '0.23';

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

Upon first reading this may seem overly complex and full of scope creep in a sledgehammer to crack a nut sort of way,
however two use cases make use of the extensive logic that comes with this code
and I have a couple of other reasons for writing it.

=over 4

=item * Black Box Testing

The schema can be plumbed into L<App::Test::Generator> to automatically create a set of black-box test cases.

=item * WAF

The schema can be plumbed into a WAF to protect from random user input.

=item * Improved API Documentation

Even if you don't use this module,
the specification syntax can help with documentation.

=item * I like it

I find it fun to write this,
even if nobody else finds it useful,
though I hope you will.

=back

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

It takes three optional arguments:

=over 4

=item * C<unknown_parameter_handler>

This parameter describes what to do when a parameter is given that is not in the schema of valid parameters.
It must be one of C<die> (the default), C<warn>, or C<ignore>.

=item * C<logger>

A logging object that understands messages such as C<error> and C<warn>.

=item * C<custom_types>

A reference to a hash that defines reusable custom types.
Custom types allow you to define validation rules once and reuse them throughout your schema,
making your validation logic more maintainable and readable.

Each custom type is defined as a hash reference containing the same validation rules available for regular parameters
(C<type>, C<min>, C<max>, C<matches>, C<memberof>, C<notmemberof>, C<callback>, etc.).

  my $custom_types = {
    email => {
      type => 'string',
      matches => qr/^[\w\.\-]+@[\w\.\-]+\.\w+$/,
      error_message => 'Invalid email address format'
    }, phone => {
      type => 'string',
      matches => qr/^\+?[1-9]\d{1,14}$/,
      min => 10,
      max => 15
    }, percentage => {
      type => 'number',
      min => 0,
      max => 100
    }, status => {
      type => 'string',
      memberof => ['draft', 'published', 'archived']
    }
  };

  my $schema = {
    user_email => { type => 'email' },
    contact_number => { type => 'phone', optional => 1 },
    completion => { type => 'percentage' },
    post_status => { type => 'status' }
  };

  my $validated = validate_strict(
    schema => $schema,
    input => $input,
    custom_types => $custom_types
  );

Custom types can be extended or overridden in the schema by specifying additional constraints:

  my $schema = {
    admin_username => {
      type => 'username',  # Uses custom type definition
      min => 5,            # Overrides custom type's min value
      max => 15            # Overrides custom type's max value
    }
  };

Custom types work seamlessly with nested schema, optional parameters, and all other validation features.

=back

The schema can define the following rules for each parameter:

=over 4

=item * C<type>

The data type of the parameter.
Valid types are C<string>, C<integer>, C<number>, C<float> C<boolean>, C<hashref>, C<arrayref>, C<object> and C<coderef>.

A type can be an arrayref when a parameter could have different types (e.g. a string or an object).

  $schema = {
    username => [
      { type => 'string', min => 3, max => 50 },	# Name
      { type => 'integer', 'min' => 1 },	# UID that isn't root
    ]
  };

=item * C<can>

The parameter must be an object that understands the method C<can>.
C<can> can be a simple scalar string of a method name,
or an arrayref of a list of method names, all of which must be supported by the object.

=item * C<isa>

The parameter must be an object of type C<isa>.

=item * C<memberof>

The parameter must be a member of the given arrayref.

  status => {
    type => 'string',
    memberof => ['draft', 'published', 'archived']
  }

  priority => {
    type => 'integer',
    memberof => [1, 2, 3, 4, 5]
  }

For string types, the comparison is case-sensitive by default. Use the C<case_sensitive>
flag to control this behavior:

  # Case-sensitive (default) - must be exact match
  code => {
    type => 'string',
    memberof => ['ABC', 'DEF', 'GHI']
    # 'abc' will fail
  }

  # Case-insensitive - any case accepted
  code => {
    type => 'string',
    memberof => ['ABC', 'DEF', 'GHI'],
    case_sensitive => 0
    # 'abc', 'Abc', 'ABC' all pass, original case preserved
  }

For numeric types (C<integer>, C<number>, C<float>), the comparison uses numeric
equality (C<==> operator):

  rating => {
    type => 'number',
    memberof => [0.5, 1.0, 1.5, 2.0]
  }

Note that C<memberof> cannot be combined with C<min> or C<max> constraints as they
serve conflicting purposes - C<memberof> defines an explicit whitelist while C<min>/C<max>
define ranges.

=item * C<notmemberof>

The parameter must not be a member of the given arrayref (blacklist).
This is the inverse of C<memberof>.

  username => {
    type => 'string',
    notmemberof => ['admin', 'root', 'system', 'administrator']
  }

  port => {
    type => 'integer',
    notmemberof => [22, 23, 25, 80, 443]  # Reserved ports
  }

Like C<memberof>, string comparisons are case-sensitive by default but can be controlled
with the C<case_sensitive> flag:

  # Case-sensitive (default)
  username => {
    type => 'string',
    notmemberof => ['Admin', 'Root']
    # 'admin' would pass, 'Admin' would fail
  }

  # Case-insensitive
  username => {
    type => 'string',
    notmemberof => ['Admin', 'Root'],
    case_sensitive => 0
    # 'admin', 'ADMIN', 'Admin' all fail
  }

The blacklist is checked after any C<transform> rules are applied, allowing you to
normalize input before checking:

  username => {
    type => 'string',
    transform => sub { lc($_[0]) },  # Normalize to lowercase
    notmemberof => ['admin', 'root', 'system']
  }

C<notmemberof> can be combined with other validation rules:

  username => {
    type => 'string',
    notmemberof => ['admin', 'root', 'system'],
    min => 3,
    max => 20,
    matches => qr/^[a-z0-9_]+$/
  }

=item * C<case_sensitive>

A boolean value indicating whether string comparisons should be case-sensitive.
This flag affects the C<memberof> and C<notmemberof> validation rules.
The default value is C<1> (case-sensitive).

When set to C<0>, string comparisons are performed case-insensitively, allowing values
with different casing to match. The original case of the input value is preserved in
the validated output.

  # Case-sensitive (default)
  status => {
    type => 'string',
    memberof => ['Draft', 'Published', 'Archived'] # Input 'draft' will fail - must match exact case
  }

  # Case-insensitive
  status => {
    type => 'string',
    memberof => ['Draft', 'Published', 'Archived'],
    case_sensitive => 0 # Input 'draft', 'DRAFT', or 'DrAfT' will all pass
  }

  country_code => {
    type => 'string',
    memberof => ['US', 'UK', 'CA', 'FR'],
    case_sensitive => 0  # Accept 'us', 'US', 'Us', etc.
  }

This flag has no effect on numeric types (C<integer>, C<number>, C<float>) as numbers
do not have case.

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

=item * C<position>

For routines and methods that take positional args,
this integer value defines which position the argument will be in.
If this is set for all arguments,
C<validate_strict> will return a reference to an array, rather than a reference to a hash.

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
        user => {	# 'user' is a hashref
            type => 'hashref',
            schema => {	# Specify what the elements of the hash should be
                name => { type => 'string' },
                age => { type => 'integer', min => 0 },
                hobbies => {	# 'hobbies' is an array ref that this user has
                    type => 'arrayref',
                    schema => { type => 'string' }, # Validate each hobby
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
                        matches => qr/^[a-z]+$/	# Or you can say matches => '^[a-z]+$'
                    }
                }
            }
        }
    };

=item * C<validate>

A snippet of code that validates the input.
It's passed the input arguments,
and return a string containing a reason for rejection,
or undef if it's allowed.

    my $schema = {
      user => {
        type => 'string',
	validate => sub {
	  if($_[0]->{'password'} eq 'bar') {
	    return undef;
	  }
	  return 'Invalid password, try again';
	}
      }, password => {
         type => 'string'
      }
    };

=item * C<transform>

A code reference to a subroutine that transforms/sanitizes the parameter value before validation.
The subroutine should accept the parameter value as an argument and return the transformed value.
The transformation is applied before any validation rules are checked, allowing you to normalize
or clean data before it is validated.

Common use cases include trimming whitespace, normalizing case, formatting phone numbers,
sanitizing user input, and converting between data formats.

  # Simple string transformations
  username => {
    type => 'string',
    transform => sub { lc(trim($_[0])) },  # lowercase and trim
    matches => qr/^[a-z0-9_]+$/
  }

  email => {
    type => 'string',
    transform => sub { lc(trim($_[0])) },  # normalize email
    matches => qr/^[\w\.\-]+@[\w\.\-]+\.\w+$/
  }

  # Array transformations
  tags => {
    type => 'arrayref',
    transform => sub { [map { lc($_) } @{$_[0]}] },  # lowercase all elements
    element_type => 'string'
  }

  keywords => {
    type => 'arrayref',
    transform => sub {
      my @arr = map { lc(trim($_)) } @{$_[0]};
      my %seen;
      return [grep { !$seen{$_}++ } @arr];  # remove duplicates
    }
  }

  # Numeric transformations
  quantity => {
    type => 'integer',
    transform => sub { int($_[0] + 0.5) },  # round to nearest integer
    min => 1
  }

  # Sanitization
  slug => {
    type => 'string',
    transform => sub {
      my $str = lc(trim($_[0]));
      $str =~ s/[^\w\s-]//g;  # remove special characters
      $str =~ s/\s+/-/g;      # replace spaces with hyphens
      return $str;
    },
    matches => qr/^[a-z0-9-]+$/
  }

  phone => {
    type => 'string',
    transform => sub {
      my $str = $_[0];
      $str =~ s/\D//g;  # remove all non-digits
      return $str;
    },
    matches => qr/^\d{10}$/
  }

The C<transform> function is applied to the value before any validation checks (C<min>, C<max>,
C<matches>, C<callback>, etc.), ensuring that validation rules are checked against the cleaned data.

Transformations work with all parameter types including nested structures:

  user => {
    type => 'hashref',
    schema => {
      name => {
        type => 'string',
        transform => sub { trim($_[0]) }
      },
      email => {
        type => 'string',
        transform => sub { lc(trim($_[0])) }
      }
    }
  }

Transformations can also be defined in custom types for reusability:

  my $custom_types = {
    email => {
      type => 'string',
      transform => sub { lc(trim($_[0])) },
      matches => qr/^[\w\.\-]+@[\w\.\-]+\.\w+$/
    }
  };

Note that the transformed value is what gets returned in the validated result and is what
subsequent validation rules will check against. If a transformation might fail, ensure it
handles edge cases appropriately.
It is the responsibility of the transformer to ensure that the type of the returned value is correct,
since that is what will be validated.

Many validators also allow a code ref to be passed so that you can create your own, conditional validation rule, e.g.:

  $schema = {
    age => {
      type => 'integer',
      min => sub {
          my ($value, $all_params) = @_;
          return $all_params->{country} eq 'US' ? 21 : 18;
      }
    }
  }

=item * C<cross_validation>

A reference to a hash that defines validation rules that depend on more than one parameter.
Cross-field validations are performed after all individual parameter validations have passed,
allowing you to enforce business logic that requires checking relationships between different fields.

Each cross-validation rule is a key-value pair where the key is a descriptive name for the validation
and the value is a code reference that accepts a hash reference of all validated parameters.
The subroutine should return C<undef> if the validation passes, or an error message string if it fails.

  my $schema = {
    password => { type => 'string', min => 8 },
    password_confirm => { type => 'string' }
  };

  my $cross_validation = {
    passwords_match => sub {
      my $params = shift;
      return $params->{password} eq $params->{password_confirm}
        ? undef : "Passwords don't match";
    }
  };

  my $validated = validate_strict(
    schema => $schema,
    input => $input,
    cross_validation => $cross_validation
  );

Common use cases include password confirmation, date range validation, numeric comparisons,
and conditional requirements:

  # Date range validation
  my $cross_validation = {
    date_range_valid => sub {
      my $params = shift;
      return $params->{start_date} le $params->{end_date}
        ? undef : "Start date must be before or equal to end date";
    }
  };

  # Price range validation
  my $cross_validation = {
    price_range_valid => sub {
      my $params = shift;
      return $params->{min_price} <= $params->{max_price}
        ? undef : "Minimum price must be less than or equal to maximum price";
    }
  };

  # Conditional required field
  my $cross_validation = {
    address_required_for_delivery => sub {
      my $params = shift;
      if ($params->{shipping_method} eq 'delivery' && !$params->{delivery_address}) {
        return "Delivery address is required when shipping method is 'delivery'";
      }
      return undef;
    }
  };

Multiple cross-validations can be defined in the same hash, and they are all checked in order.
If any cross-validation fails, the function will C<croak> with the error message returned by the validation:

  my $cross_validation = {
    passwords_match => sub {
      my $params = shift;
      return $params->{password} eq $params->{password_confirm}
        ? undef : "Passwords don't match";
    },
    emails_match => sub {
      my $params = shift;
      return $params->{email} eq $params->{email_confirm}
        ? undef : "Email addresses don't match";
    },
    age_matches_birth_year => sub {
      my $params = shift;
      my $current_year = (localtime)[5] + 1900;
      my $calculated_age = $current_year - $params->{birth_year};
      return abs($calculated_age - $params->{age}) <= 1
        ? undef : "Age doesn't match birth year";
    }
  };

Cross-validations receive the parameters after individual validation and transformation have been applied,
so you can rely on the data being in the correct format and type:

  my $schema = {
    email => {
      type => 'string',
      transform => sub { lc($_[0]) }  # Lowercased before cross-validation
    },
    email_confirm => {
      type => 'string',
      transform => sub { lc($_[0]) }
    }
  };

  my $cross_validation = {
    emails_match => sub {
      my $params = shift;
      # Both emails are already lowercased at this point
      return $params->{email} eq $params->{email_confirm}
        ? undef : "Email addresses don't match";
    }
  };

Cross-validations can access nested structures and optional fields:

  my $cross_validation = {
    guardian_required_for_minors => sub {
      my $params = shift;
      if ($params->{user}{age} < 18 && !$params->{guardian}) {
        return "Guardian information required for users under 18";
      }
      return undef;
    }
  };

All cross-validations must pass for the overall validation to succeed.

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
	my $custom_types = $params->{'custom_types'};

	# Check if schema and args are references to hashes
	if(ref($schema) ne 'HASH') {
		_error($logger, 'validate_strict: schema must be a hash reference');
	}

	if(exists($params->{'args'}) && (!defined($args))) {
		$args = {};
	} elsif((ref($args) ne 'HASH') && (ref($args) ne 'ARRAY')) {
		_error($logger, 'validate_strict: args must be a hash or array reference');
	}

	if(ref($args) eq 'HASH') {
		# Named args
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
	}

	# Find out if this routine takes positional arguments
	my $are_positional_args = -1;
	foreach my $key (keys %{$schema}) {
		if(defined(my $rules = $schema->{$key})) {
			if(ref($rules) eq 'HASH') {
				if(!defined($rules->{'position'})) {
					if($are_positional_args == 1) {
						_error($logger, "::validate_strict: $key is missing position value");
					}
					$are_positional_args = 0;
					last;
				}
				$are_positional_args = 1;
			} else {
				$are_positional_args = 0;
				last;
			}
		} else {
			$are_positional_args = 0;
			last;
		}
	}

	my %validated_args;
	my %invalid_args;
	foreach my $key (keys %{$schema}) {
		my $rules = $schema->{$key};
		my $value = ($are_positional_args == 1) ? @{$args}[$rules->{'position'}] : $args->{$key};

		if(!defined($rules)) {	# Allow anything
			$validated_args{$key} = $value;
			next;
		}

		# If rules are a simple type string
		if(ref($rules) eq '') {
			$rules = { type => $rules };
		}

		my $is_optional = 0;

		if(ref($rules) eq 'HASH') {
			if($rules->{'transform'} && defined($value)) {
				if(ref($rules->{'transform'}) eq 'CODE') {
					$value = &{$rules->{'transform'}}($value);
				} else {
					_error($logger, 'validate_strict: transforms must be a code ref');
				}
			}
			if(exists($rules->{optional})) {
				if(ref($rules->{'optional'}) eq 'CODE') {
					$is_optional = &{$rules->{optional}}($value, $args);
				} else {
					$is_optional = $rules->{'optional'};
				}
			}
		}

		# Handle optional parameters
		if((ref($rules) eq 'HASH') && $is_optional) {
			my $look_for_default = 0;
			if($are_positional_args == 1) {
				if(!defined(@{$args}[$rules->{'position'}])) {
					$look_for_default = 1;
				}
			} else {
				if(!exists($args->{$key})) {
					$look_for_default = 1;
				}
			}
			if($look_for_default) {
				if($are_positional_args == 1) {
					if(scalar(@{$args}) < $rules->{'position'}) {
						# arg array is too short, so it must be missing
						_error($logger, "validate_strict: Required parameter '$key' is missing");
						next;
					}
				}
				if(exists($rules->{'default'})) {
					# Populate missing optional parameters with the specified output values
					$validated_args{$key} = $rules->{'default'};
				}

				if($rules->{'schema'}) {
					$value = _apply_nested_defaults({}, $rules->{'schema'});
					next unless scalar(%{$value});
					# The nested schema has a default value
				} else {
					next;	# optional and missing
				}
			}
		} elsif((ref($args) eq 'HASH') && !exists($args->{$key})) {
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

				if((ref($rule_value) eq 'CODE') && ($rule_name ne 'validate') && ($rule_name ne 'callback')) {
					$rule_value = &{$rule_value}($value, $args);
				}

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
						if(($value eq 'true') || ($value eq 'on') || ($value eq 'yes')) {
							$value = 1;
						} elsif(($value eq 'false') || ($value eq 'off') || ($value eq 'no')) {
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
						if(!defined($value)) {
							next;	# Skip if code is undefined
						}
						if(ref($value) ne 'CODE') {
							if($rules->{'error_message'}) {
								_error($logger, $rules->{'error_message'});
							} else {
								_error($logger, "validate_strict: Parameter '$key' must be a coderef");
							}
						}
					} elsif($type eq 'object') {
						if(!defined($value)) {
							next;	# Skip if object is undefined
						}
						if(!Scalar::Util::blessed($value)) {
							if($rules->{'error_message'}) {
								_error($logger, $rules->{'error_message'});
							} else {
								_error($logger, "validate_strict: Parameter '$key' must be an object");
							}
						}
					} elsif(my $custom_type = $custom_types->{$type}) {
						if($custom_type->{'transform'}) {
							# The custom type has a transform embedded within it
							if(ref($custom_type->{'transform'}) eq 'CODE') {
								$value = &{$custom_type->{'transform'}}($value);
							} else {
								_error($logger, 'validate_strict: transforms must be a code ref');
								next;
							}
						}
						validate_strict({ input => { $key => $value }, schema => { $key => $custom_type }, custom_types => $custom_types });
					} else {
						_error($logger, "validate_strict: Unknown type '$type'");
					}
				} elsif($rule_name eq 'min') {
					if(!defined($rules->{'type'})) {
						_error($logger, "validate_strict: Don't know type of '$key' to determine its minimum value $rule_value");
					}
					my $type = lc($rules->{'type'});
					if(exists($custom_types->{$type}->{'min'})) {
						$rule_value = $custom_types->{$type}->{'min'};
						$type = $custom_types->{$type}->{'type'};
					}
					if($type eq 'string') {
						if(!defined($value)) {
							next;	# Skip if string is undefined
						}
						if(length($value) < $rule_value) {
							if($rules->{'error_message'}) {
								_error($logger, $rules->{'error_message'});
							} else {
								_error($logger, "validate_strict: String parameter '$key' too short (" . length($value) . "), must be at least length $rule_value");
							}
							$invalid_args{$key} = 1;
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
							$invalid_args{$key} = 1;
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
							$invalid_args{$key} = 1;
						}
					} elsif(($type eq 'integer') || ($type eq 'number') || ($type eq 'float')) {
						if(!defined($value)) {
							next;	# Skip if hash is undefined
						}
						if(Scalar::Util::looks_like_number($value)) {
							if($value < $rule_value) {
								if($rules->{'error_message'}) {
									_error($logger, $rules->{'error_message'});
								} else {
									_error($logger, "validate_strict: Parameter '$key' ($value) must be at least $rule_value");
								}
								$invalid_args{$key} = 1;
								next;
							}
						} else {
							if($rules->{'error_message'}) {
								_error($logger, $rules->{'error_message'});
							} else {
								_error($logger, "validate_strict: Parameter '$key' ($value) must be a number");
							}
							next;
						}
					} else {
						_error($logger, "validate_strict: Parameter '$key' of type '$type' has meaningless min value $rule_value");
					}
				} elsif($rule_name eq 'max') {
					if(!defined($rules->{'type'})) {
						_error($logger, "validate_strict: Don't know type of '$key' to determine its maximum value $rule_value");
					}
					my $type = lc($rules->{'type'});
					if(exists($custom_types->{$type}->{'max'})) {
						$rule_value = $custom_types->{$type}->{'max'};
						$type = $custom_types->{$type}->{'type'};
					}
					if($type eq 'string') {
						if(!defined($value)) {
							next;	# Skip if string is undefined
						}
						if(length($value) > $rule_value) {
							if($rules->{'error_message'}) {
								_error($logger, $rules->{'error_message'});
							} else {
								_error($logger, "validate_strict: String parameter '$key' too long, (" . length($value) . " characters), must be no longer than $rule_value");
							}
							$invalid_args{$key} = 1;
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
							$invalid_args{$key} = 1;
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
							$invalid_args{$key} = 1;
						}
					} elsif(($type eq 'integer') || ($type eq 'number') || ($type eq 'float')) {
						if(!defined($value)) {
							next;	# Skip if hash is undefined
						}
						if(Scalar::Util::looks_like_number($value)) {
							if($value > $rule_value) {
								if($rules->{'error_message'}) {
									_error($logger, $rules->{'error_message'});
								} else {
									_error($logger, "validate_strict: Parameter '$key' ($value) must be no more than $rule_value");
								}
								$invalid_args{$key} = 1;
								next;
							}
						} else {
							if($rules->{'error_message'}) {
								_error($logger, $rules->{'error_message'});
							} else {
								_error($logger, "validate_strict: Parameter '$key' ($value) must be a number");
							}
							next;
						}
					} else {
						_error($logger, "validate_strict: Parameter '$key' of type '$type' has meaningless max value $rule_value");
					}
				} elsif($rule_name eq 'matches') {
					if(!defined($value)) {
						next;	# Skip if string is undefined
					}
					eval {
						my $re = (ref($rule_value) eq 'Regexp') ? $rule_value : qr/\Q$rule_value\E/;
						if($rules->{'type'} eq 'arrayref') {
							my @matches = grep { $_ =~ $re } @{$value};
							if(scalar(@matches) != scalar(@{$value})) {
								if($rules->{'error_message'}) {
									_error($logger, $rules->{'error_message'});
								} else {
									_error($logger, "validate_strict: All members of parameter '$key' [", join(', ', @{$value}), "] must match pattern '$rule_value'");
								}
							}
						} elsif($value !~ $re) {
							if($rules->{'error_message'}) {
								_error($logger, $rules->{'error_message'});
							} else {
								_error($logger, "validate_strict: Parameter '$key' ($value) must match pattern '$re'");
							}
						}
						1;
					};
					if($@) {
						if($rules->{'error_message'}) {
							_error($logger, $rules->{'error_message'});
						} else {
							_error($logger, "validate_strict: Parameter '$key' regex '$rule_value' error: $@");
						}
						$invalid_args{$key} = 1;
					}
				} elsif($rule_name eq 'nomatch') {
					if(!defined($value)) {
						next;	# Skip if string is undefined
					}
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
						$invalid_args{$key} = 1;
					}
				} elsif($rule_name eq 'memberof') {
					if(!defined($value)) {
						next;	# Skip if string is undefined
					}
					if(ref($rule_value) eq 'ARRAY') {
						my $ok = 1;
						if(($rules->{'type'} eq 'integer') || ($rules->{'type'} eq 'number') || ($rules->{'type'} eq 'float')) {
							unless(List::Util::any { $_ == $value } @{$rule_value}) {
								$ok = 0;
							}
						} else {
							my $l = lc($value);
							unless(List::Util::any { (!defined($rules->{'case_sensitive'}) || ($rules->{'case_sensitive'} == 1)) ? $_ eq $value : lc($_) eq $l } @{$rule_value}) {
								$ok = 0;
							}
						}

						if(!$ok) {
							if($rules->{'error_message'}) {
								_error($logger, $rules->{'error_message'});
							} else {
								_error($logger, "validate_strict: Parameter '$key' ($value) must be one of ", join(', ', @{$rule_value}));
							}
							$invalid_args{$key} = 1;
						}
					} else {
						if($rules->{'error_message'}) {
							_error($logger, $rules->{'error_message'});
						} else {
							_error($logger, "validate_strict: Parameter '$key' rule ($rule_value) must be an array reference");
						}
					}
				} elsif($rule_name eq 'notmemberof') {
					if(!defined($value)) {
						next;	# Skip if string is undefined
					}
					if(ref($rule_value) eq 'ARRAY') {
						my $ok = 1;
						if(($rules->{'type'} eq 'integer') || ($rules->{'type'} eq 'number') || ($rules->{'type'} eq 'float')) {
							if(List::Util::any { $_ == $value } @{$rule_value}) {
								$ok = 0;
							}
						} else {
							my $l = lc($value);
							if(List::Util::any { (!defined($rules->{'case_sensitive'}) || ($rules->{'case_sensitive'} == 1)) ? $_ eq $value : lc($_) eq $l } @{$rule_value}) {
								$ok = 0;
							}
						}

						if(!$ok) {
							if($rules->{'error_message'}) {
								_error($logger, $rules->{'error_message'});
							} else {
								_error($logger, "validate_strict: Parameter '$key' ($value) must not be one of ", join(', ', @{$rule_value}));
							}
							$invalid_args{$key} = 1;
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
						$invalid_args{$key} = 1;
					}
				} elsif($rule_name eq 'isa') {
					if($rules->{'type'} eq 'object') {
						if(!$value->isa($rule_value)) {
							_error($logger, "validate_strict: Parameter '$key' must be a '$rule_value' object");
							$invalid_args{$key} = 1;
						}
					} else {
						_error($logger, "validate_strict: Parameter '$key' has meaningless isa value $rule_value");
					}
				} elsif($rule_name eq 'can') {
					if(!defined($value)) {
						next;	# Skip if object not given
					}
					if($rules->{'type'} eq 'object') {
						if(ref($rule_value) eq 'ARRAY') {
							# List of methods
							foreach my $method(@{$rule_value}) {
								if(!$value->can($method)) {
									_error($logger, "validate_strict: Parameter '$key' must be an object that understands the $method method");
									$invalid_args{$key} = 1;
								}
							}
						} elsif(!ref($rule_value)) {
							if(!$value->can($rule_value)) {
								_error($logger, "validate_strict: Parameter '$key' must be an object that understands the $rule_value method");
								$invalid_args{$key} = 1;
							}
						} else {
							_error($logger, "validate_strict: 'can' rule for Parameter '$key must be either a scalar or an arrayref");
						}
					} else {
						_error($logger, "validate_strict: Parameter '$key' has meaningless can value $rule_value");
					}
				} elsif($rule_name eq 'element_type') {
					if($rules->{'type'} eq 'arrayref') {
						my $type = $rule_value;
						my $custom_type = $custom_types->{$rule_value};
						if($custom_type && $custom_type->{'type'}) {
							$type = $custom_type->{'type'};
						}
						foreach my $member(@{$value}) {
							if($custom_type && $custom_type->{'transform'}) {
								# The custom type has a transform embedded within it
								if(ref($custom_type->{'transform'}) eq 'CODE') {
									$member = &{$custom_type->{'transform'}}($member);
								} else {
									_error($logger, 'validate_strict: transforms must be a code ref');
									last;
								}
							}
							if($type eq 'string') {
								if(ref($member)) {
									if($rules->{'error_message'}) {
										_error($logger, $rules->{'error_message'});
									} else {
										_error($logger, "$key can only contain strings");
									}
									$invalid_args{$key} = 1;
								}
							} elsif($type eq 'integer') {
								if(ref($member) || ($member =~ /\D/)) {
									if($rules->{'error_message'}) {
										_error($logger, $rules->{'error_message'});
									} else {
										_error($logger, "$key can only contain integers (found $member)");
									}
									$invalid_args{$key} = 1;
								}
							} elsif(($type eq 'number') || ($rule_value eq 'float')) {
								if(ref($member) || ($member !~ /^[-+]?(\d*\.\d+|\d+\.?\d*)$/)) {
									if($rules->{'error_message'}) {
										_error($logger, $rules->{'error_message'});
									} else {
										_error($logger, "$key can only contain numbers (found $member)");
									}
									$invalid_args{$key} = 1;
								}
							} else {
								_error($logger, "BUG: Add $type to element_type list");
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
					# Handled inline
				} elsif($rule_name eq 'transform') {
					# Handled before the loop
				} elsif($rule_name eq 'case_sensitive') {
					# Handled inline
				} elsif($rule_name eq 'schema') {
					# Nested schema Run the given schema against each element of the array
					if($rules->{'type'} eq 'arrayref') {
						if(ref($value) eq 'ARRAY') {
							foreach my $member(@{$value}) {
								if(!validate_strict({ input => { $key => $member }, schema => { $key => $rule_value }, custom_types => $custom_types })) {
									$invalid_args{$key} = 1;
								}
							}
						} elsif(defined($value)) {	# Allow undef for optional values
							_error($logger, "validate_strict: nested schema: Parameter '$value' must be an arrayref");
						}
					} elsif($rules->{'type'} eq 'hashref') {
						if(ref($value) eq 'HASH') {
							# Apply nested defaults before validation
							my $nested_with_defaults = _apply_nested_defaults($value, $rule_value);
							if(scalar keys(%{$value})) {
								if(my $new_args = validate_strict({ input => $nested_with_defaults, schema => $rule_value, custom_types => $custom_types })) {
									$value = $new_args;
								} else {
									$invalid_args{$key} = 1;
								}
							}
						} else {
							_error($logger, "validate_strict: nested schema: Parameter '$value' must be an hashref");
						}
					} else {
						_error($logger, "validate_strict: Parameter '$key': 'schema' only supports arrayref and hashref, not $rules->{type}");
					}
				} elsif($rule_name eq 'validate') {
					if(ref($rule_value) eq 'CODE') {
						if(my $error = &{$rule_value}($args)) {
							_error($logger, "validate_strict: $key not valid: $error");
							$invalid_args{$key} = 1;
						}
					} else {
						# _error($logger, "validate_strict: Parameter '$key': 'validate' only supports coderef, not $value");
						_error($logger, "validate_strict: Parameter '$key': 'validate' only supports coderef, not " . ref($rule_value) // $rule_value);
					}
				} elsif($rule_name eq 'position') {
					if($rule_value =~ /\D/) {
						_error($logger, "validate_strict: Parameter '$key': 'position' must be an integer");
					}
					if($rule_value < 0) {
						_error($logger, "validate_strict: Parameter '$key': 'position' must be a positive integer, not $value");
					}
				} else {
					_error($logger, "validate_strict: Unknown rule '$rule_name'");
				}
			}
		} elsif(ref($rules) eq 'ARRAY') {
			if(scalar(@{$rules})) {
				# An argument can be one of several different type
				my $rc = 0;
				my @types;
				foreach my $rule(@{$rules}) {
					if(ref($rule) ne 'HASH') {
						_error($logger, "validate_strict: Parameter '$key' rules must be a hash reference");
						next;
					}
					if(!defined($rule->{'type'})) {
						_error($logger, "validate_strict: Parameter '$key' is missing a type in an alternative");
						next;
					}
					push @types, $rule->{'type'};
					eval {
						validate_strict({ input => { $key => $value }, schema => { $key => $rule }, logger => undef, custom_types => $custom_types });
					};
					if(!$@) {
						$rc = 1;
						last;
					}
				}
				if(!$rc) {
					_error($logger, "validate_strict: Parameter: '$key': must be one of " . join(', ', @types));
					$invalid_args{$key} = 1;
				}
			} else {
				_error($logger, "validate_strict: Parameter: '$key': schema is empty arrayref");
			}
		} elsif(ref($rules)) {
			_error($logger, 'rules must be a hash reference or string');
		}

		$validated_args{$key} = $value;
	}

	if(my $cross_validation = $params->{'cross_validation'}) {
		foreach my $validator_name(keys %{$cross_validation}) {
			my $validator = $cross_validation->{$validator_name};
			if((!ref($validator)) || (ref($validator) ne 'CODE')) {
				_error($logger, "validate_strict: cross_validation $validator is not a code snippet");
				next;
			}
			if(my $error = &{$validator}(\%validated_args, $validator)) {
				_error($logger, $error);
				# We have no idea which parameters are still valid, so let's invalidate them all
				return;
			}
		}
	}

	foreach my $key(keys %invalid_args) {
		delete $validated_args{$key};
	}

	if($are_positional_args == 1) {
		my @rc;
		foreach my $key (keys %{$schema}) {
			if(my $value = delete $validated_args{$key}) {
				my $position = $schema->{$key}->{'position'};
				if(defined($rc[$position])) {
					_error($logger, "validate_strict: $key: position $position appears twice");
				}
				$rc[$position] = $value;
			}
		}
		return \@rc;
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
		carp(__PACKAGE__, ": $message");
	}
}

sub _apply_nested_defaults {
	my ($input, $schema) = @_;
	my %result = %$input;

	foreach my $key (keys %$schema) {
		my $rules = $schema->{$key};

		if (ref $rules eq 'HASH' && exists $rules->{default} && !exists $result{$key}) {
			$result{$key} = $rules->{default};
		}

		# Recursively handle nested schema
		if((ref $rules eq 'HASH') && $rules->{schema} && (ref $result{$key} eq 'HASH')) {
			$result{$key} = _apply_nested_defaults($result{$key}, $rules->{schema});
		}
	}

	return \%result;
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
        notmemberof: seq VALUE;
        callback: FUNCTION;
        isa: TYPE_NAME;
        can: METHOD_NAME
    ]

    Schema == PARAM_NAME ⇸ ValidationRule

    Arguments == PARAM_NAME ⇸ VALUE

    ValidatedResult == PARAM_NAME ⇸ VALUE

    ∀ rule: ComplexRule •
      rule.min ≤ rule.max ∧
      ¬(rule.memberof ∧ rule.min) ∧
      ¬(rule.memberof ∧ rule.max) ∧
      ¬(rule.notmemberof ∧ rule.min) ∧
      ¬(rule.notmemberof ∧ rule.max)

    ∀ schema: Schema; args: Arguments •
      dom(validate_strict(schema, args)) ⊆ dom(schema) ∪ dom(args)

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

=item * L<App::Test::Generator>

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
