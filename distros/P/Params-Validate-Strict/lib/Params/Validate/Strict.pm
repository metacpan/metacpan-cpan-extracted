package Params::Validate::Strict;

use strict;
use warnings;

use Carp;
use List::Util qw(any);	# Required for memberof validation
use Exporter qw(import);	# Required for @EXPORT_OK
use Params::Get 0.13;
use Scalar::Util;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(validate_strict);

=head1 NAME

Params::Validate::Strict - Validates a set of parameters against a schema

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

    my $schema = {
        username => { type => 'string', min => 3, max => 50 },
        age => { type => 'integer', min => 0, max => 150 },
    };

    my $args = {
         username => 'john_doe',
         age => '30',	# Will be coerced to integer
    };

    my $validated_args = validate_strict(schema => $schema, args => $args);

    if (defined $validated_args) {
        print "Example 1: Validation successful!\n";
        print 'Username: ', $validated_args->{username}, "\n";
        print 'Age: ', $validated_args->{age}, "\n";	# It's an integer now
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

=item * C<args>

A reference to a hash containing the parameters to be validated.  The keys of the hash are the parameter names, and the values are the parameter values.

=back

It takes one optional argument:

=over 4

=item * C<unknown_parameter_handler>

This parameter describes what to do when a parameter is given that is not in the schema of valid parameters.
It must be one of C<die> (the default), C<warn>, or C<ignore>.

=back

The schema can define the following rules for each parameter:

=over 4

=item * C<type>

The data type of the parameter.
Valid types are C<string>, C<integer>, C<number>, C<hashref>, C<arrayref>, C<object> and C<coderef>.

=item * C<can>

The parameter must be an object which understands the method C<can>.

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

=item * C<nomatch>

A regular expression that the parameter value must not match.

=item * C<callback>

A code reference to a subroutine that performs custom validation logic.
The subroutine should accept the parameter value as an argument and return true if the value is valid, false otherwise.

=item * C<optional>

A boolean value indicating whether the parameter is optional.
If true, the parameter is not required.
If false or omitted, the parameter is required.

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
        age  => { type => SCALAR, regex => qr/^\d+$/ }
    });

    # New style
    validate_strict(
        schema => {
            name => 'string',
            age  => { type => 'integer', min => 0 }
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
	my $args = $params->{'args'};
	my $unknown_parameter_handler = $params->{'unknown_parameter_handler'} || 'die';

	# Check if schema and args are references to hashes
	if(ref($schema) ne 'HASH') {
		croak 'validate_strict: schema must be a hash reference';
	}

	if(exists($params->{'args'}) && (!defined($args))) {
		$args = {};
	} elsif(ref($args) ne 'HASH') {
		croak 'validate_strict: args must be a hash reference';
	}

	foreach my $key (keys %{$args}) {
		if(!exists($schema->{$key})) {
			if($unknown_parameter_handler eq 'die') {
				croak(__PACKAGE__, "::validate_strict: Unknown parameter '$key'");
			} elsif($unknown_parameter_handler eq 'warn') {
				carp(__PACKAGE__, "::validate_strict: Unknown parameter '$key'");
				next;
			} elsif($unknown_parameter_handler eq 'ignore') {
				next;
			} else {
				croak(__PACKAGE__, "::validate_strict: '$unknown_parameter_handler' unknown_parameter_handler must be one of die, warn, ignore");
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
		if((ref($rules) eq '') || !defined(ref($rules))) {
			$rules = { type => $rules };
		}

		# Handle optional parameters
		if((ref($rules) eq 'HASH') && $rules->{optional}) {
			if(!exists($args->{$key})) {
				next;	# optional and missing
			}
		} elsif(!exists($args->{$key})) {
			# The parameter is required
			croak(__PACKAGE__, "::validate_strict: Required parameter '$key' is missing");
		}

		# Validate based on rules
		if(ref($rules) eq 'HASH') {
			if((my $min = $rules->{'min'}) && (my $max = $rules->{'max'})) {
				if($min > $max) {
					croak(__PACKAGE__, "::validate_strict($key): min must be <= max ($min > $max)");
				}
			}
			foreach my $rule_name (keys %$rules) {
				my $rule_value = $rules->{$rule_name};

				if($rule_name eq 'type') {
					my $type = lc($rule_value);

					if($type eq 'string') {
						if(ref($value)) {
							croak(__PACKAGE__, "::validate_strict: Parameter '$key' must be a string");
						}
						unless((ref($value) eq '') || (defined($value) && ($value =~ /^.*$/))) { # Allow undef for optional strings
							croak(__PACKAGE__, "::validate_strict: Parameter '$key' must be a string");
						}
					} elsif($type eq 'integer') {
						if($value !~ /^\s*[+\-]?\d+\s*$/) {
							croak "validate_strict: Parameter '$key' ($value) must be an integer";
						}
						$value = int($value); # Coerce to integer
					} elsif($type eq 'number') {
						if(!defined($value)) {
							next;	# Skip if string is undefined
						}
						if(!Scalar::Util::looks_like_number($value)) {
							croak(__PACKAGE__, "::validate_strict: Parameter '$key' must be a number");
						}
						# $value = eval $value; # Coerce to number (be careful with eval)
						$value = 0 + $value;	# Numeric coercion
					} elsif($type eq 'arrayref') {
						if(ref($value) ne 'ARRAY') {
							croak(__PACKAGE__, "::validate_strict: Parameter '$key' must be an arrayref");
						}
					} elsif($type eq 'hashref') {
						if(ref($value) ne 'HASH') {
							croak(__PACKAGE__, "::validate_strict: Parameter '$key' must be an hashref");
						}
					} elsif($type eq 'coderef') {
						if(ref($value) ne 'CODE') {
							croak(__PACKAGE__, "::validate_strict: Parameter '$key' must be a coderef");
						}
					} elsif($type eq 'object') {
						if(!Scalar::Util::blessed($value)) {
							croak(__PACKAGE__, "::validate_strict: Parameter '$key' must be an object");
						}
					} else {
						croak "validate_strict: Unknown type '$type'";
					}
				} elsif($rule_name eq 'min') {
					if($rules->{'type'} eq 'string') {
						if(!defined($value)) {
							next;	# Skip if string is undefined
						}
						if(length($value) < $rule_value) {
							croak("validate_strict: String parameter '$key' too short, must be at least length $rule_value");
						}
					} elsif($rules->{'type'} eq 'arrayref') {
						if(!defined($value)) {
							next;	# Skip if array is undefined
						}
						if(scalar(@{$value}) < $rule_value) {
							croak("validate_strict: Parameter '$key' must be at least length $rule_value");
						}
					} elsif($rules->{'type'} eq 'hashref') {
						if(!defined($value)) {
							next;	# Skip if hash is undefined
						}
						if(scalar(keys(%{$value})) < $rule_value) {
							croak("validate_strict: Parameter '$key' must contain at least $rule_value keys");
						}
					} elsif(($rules->{'type'} eq 'integer') || ($rules->{'type'} eq 'number')) {
						if(!defined($value)) {
							next;	# Skip if hash is undefined
						}
						if($value < $rule_value) {
							croak(__PACKAGE__, "::validate_strict: Parameter '$key' must be at least $rule_value");
						}
					} else {
						croak(__PACKAGE__, "::validate_strict: Parameter '$key' has meaningless min value $rule_value");
					}
				} elsif($rule_name eq 'max') {
					if($rules->{'type'} eq 'string') {
						if(!defined($value)) {
							next;	# Skip if string is undefined
						}
						if(length($value) > $rule_value) {
							croak("validate_strict: String parameter '$key' too long, must be no longer than $rule_value");
						}
					} elsif($rules->{'type'} eq 'arrayref') {
						if(!defined($value)) {
							next;	# Skip if string is undefined
						}
						if(scalar(@{$value}) > $rule_value) {
							croak("validate_strict: Parameter '$key' must contain no more than $rule_value items");
						}
					} elsif($rules->{'type'} eq 'hashref') {
						if(!defined($value)) {
							next;	# Skip if hash is undefined
						}
						if(scalar(keys(%{$value})) > $rule_value) {
							croak("validate_strict: Parameter '$key' must contain no more than $rule_value keys");
						}
					} elsif(($rules->{'type'} eq 'integer') || ($rules->{'type'} eq 'number')) {
						if(!defined($value)) {
							next;	# Skip if hash is undefined
						}
						if($value > $rule_value) {
							croak(__PACKAGE__, "::validate_strict: Parameter '$key' must be no more than $rule_value");
						}
					} else {
						croak(__PACKAGE__, "::validate_strict: Parameter '$key' has meaningless max value $rule_value");
					}
				} elsif($rule_name eq 'matches') {
					if(!defined($value)) {
						next;	# Skip if string is undefined
					}
					eval {
						unless($value =~ $rule_value) {
							croak "validate_strict: Parameter '$key' ($value) must match pattern '$rule_value'";
						}
					};
					if($@) {
						croak(__PACKAGE__, "::validate_strict: Parameter '$key' invalid regex '$rule_value': $@");
					}
				} elsif($rule_name eq 'nomatch') {
					if($value =~ $rule_value) {
						croak "validate_strict: Parameter '$key' ($value) must not match pattern '$rule_value'";
					}
				} elsif($rule_name eq 'memberof') {
					if(ref($rule_value) eq 'ARRAY') {
						if(($rules->{'type'} eq 'integer') || ($rules->{'type'} eq 'number')) {
							unless(List::Util::any { $_ == $value } @{$rule_value}) {
								croak "validate_strict: Parameter '$key' ($value) must be one of ", join(', ', @{$rule_value});
							}
						} else {
							unless(List::Util::any { $_ eq $value } @{$rule_value}) {
								croak "validate_strict: Parameter '$key' ($value) must be one of ", join(', ', @{$rule_value});
							}
						}
					} else {
						croak("validate_strict: Parameter '$key' rule ($rule_value) must be an array reference");
					}
				} elsif ($rule_name eq 'callback') {
					unless (defined &$rule_value) {
						croak(__PACKAGE__, "::validate_strict: callback for '$key' must be a code reference");
					}
					my $res = $rule_value->($value);
					unless ($res) {
						croak "validate_strict: Parameter '$key' failed custom validation";
					}
				} elsif($rule_name eq 'isa') {
					if($rules->{'type'} eq 'object') {
						if(!$value->isa($rule_value)) {
							croak(__PACKAGE__, "::validate_strict: Parameter '$key' must be a '$rule_value' object");
						}
					} else {
						croak(__PACKAGE__, "::validate_strict: Parameter '$key' has meaningless isa value $rule_value");
					}
				} elsif($rule_name eq 'can') {
					if($rules->{'type'} eq 'object') {
						if(!$value->can($rule_value)) {
							croak(__PACKAGE__, "::validate_strict: Parameter '$key' must be an object that understands the $rule_value method");
						}
					} else {
						croak(__PACKAGE__, "::validate_strict: Parameter '$key' has meaningless can value $rule_value");
					}
				} elsif($rule_name eq 'optional') {
					# Already handled at the beginning of the loop
				} else {
					croak "validate_strict: Unknown rule '$rule_name'";
				}
			}
		} elsif(ref($rules)) {
			croak('rules must be hash reference or string');
		}

		$validated_args{$key} = $value;
	}

	return \%validated_args;
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
