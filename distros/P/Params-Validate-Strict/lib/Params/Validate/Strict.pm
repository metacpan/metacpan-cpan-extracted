package Params::Validate::Strict;

use strict;
use warnings;
use Carp;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(validate_strict);

=head1 NAME

Params::Validate::Strict - Validates a set of parameters against a schema

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

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

=item * C<$schema>

A reference to a hash that defines the validation rules for each parameter.  The keys of the hash are the parameter names, and the values are either a string representing the parameter type or a reference to a hash containing more detailed rules.

=item * C<$args>

A reference to a hash containing the parameters to be validated.  The keys of the hash are the parameter names, and the values are the parameter values.

=back

It takes one optional argument:

=over 4

=item * C<$unknown_parameter_handler>

This parameter describes what to do when a parameter is given that is not in the schema of valid parameters.
It must be one of C<die> (the default), C<warn>, or C<ignore>.

=back

The schema can define the following rules for each parameter:

=over 4

=item * C<type>

The data type of the parameter.  Valid types are C<string>, C<integer>, and C<number>.

=item * C<min>

The minimum length (for strings) or value (for numbers).

=item * C<max>

The maximum length (for strings) or value (for numbers).

=item * C<matches>

A regular expression that the parameter value must match.

=item * C<callback>

A code reference to a subroutine that performs custom validation logic. The subroutine should accept the parameter value as an argument and return true if the value is valid, false otherwise.

=item * C<optional>

A boolean value indicating whether the parameter is optional. If true, the parameter is not required.  If false or omitted, the parameter is required.

=back

If a parameter is optional and its value is C<undef>,
validation will be skipped for that parameter.

If the validation fails, the function will C<croak> with an error message describing the validation failure.

If the validation is successful, the function will return a reference to a new hash containing the validated and (where applicable) coerced parameters.  Integer and number parameters will be coerced to their respective types.

=cut

sub validate_strict
{
	my $params = _get_params(undef, @_);

	my $schema = $params->{'schema'};
	my $args = $params->{'args'};
	my $unknown_parameter_handler = $params->{'unknown_parameter_handler'} || 'die';

	# Check if schema and args are references to hashes
	unless((ref($schema) eq 'HASH') && (ref($args) eq 'HASH')) {
		croak 'validate_strict: schema and args must be hash references';
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
				croak(__PACKAGE__, "::validate_strict: unrecognized value for unknown_parameter_handler '$unknown_parameter_handler'");
			}
		}
	}

	my %validated_args;
	foreach my $key (keys %{$schema}) {
		my $rules = $schema->{$key};
		my $value = $args->{$key};

		if(!defined($rules)) {	# Allow anything
			next;
		}

		# Check if the parameter is required
		if((ref($rules) eq 'HASH') && (!exists($rules->{optional})) && (!exists($args->{$key}))) {
			croak(__PACKAGE__, "::validate_strict: Required parameter '$key' is missing");
		}

		# Handle optional parameters
		next if((ref($rules) eq 'HASH') && exists($rules->{optional}) && !defined($value));

		# If rules are a simple type string
		if((ref($rules) eq '') || !defined(ref($rules))) {
			$rules = { type => $rules };
		}

		# Validate based on rules
		if(ref($rules) eq 'HASH') {
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
						if($value !~ /^-?\d+$/) {
							croak "validate_strict: Parameter '$key' must be an integer";
						}
						$value = int($value); # Coerce to integer
					} elsif($type eq 'number') {
						if($value !~ /^-?\d+(?:\.\d+)?$/) {
							croak(__PACKAGE__, "::validate_strict: Parameter '$key' must be a number");
						}
						$value = eval $value; # Coerce to number (be careful with eval)

					} else {
						croak "validate_strict: Unknown type '$type'";
					}
				} elsif($rule_name eq 'min') {
					if($rules->{'type'} eq 'string') {
						if(!defined($value)) {
							next;	# Skip if string is undefined
						}
						if(length($value) < $rule_value) {
							croak("validate_strict: Parameter '$key' must be at least length $rule_value");
						}
					} elsif(($rules->{'type'} eq 'integer') || ($rules->{'type'} eq 'number')) {
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
							croak("validate_strict: Parameter '$key' must be no longer than $rule_value");
						}
					} elsif(($rules->{'type'} eq 'integer') || ($rules->{'type'} eq 'number')) {
						if($value > $rule_value) {
							croak(__PACKAGE__, "::validate_strict: Parameter '$key' must be no more than $rule_value");
						}
					} else {
						croak(__PACKAGE__, "::validate_strict: Parameter '$key' has meaningless max value $rule_value");
					}
				} elsif($rule_name eq 'matches') {
					unless ($value =~ $rule_value) {
						croak "validate_strict: Parameter '$key' must match '$rule_value'";
					}
				} elsif ($rule_name eq 'callback') {
					unless (defined &$rule_value) {
						croak(__PACKAGE__, "::validate_strict: callback for '$key' must be a code reference");
					}
					my $res = $rule_value->($value);
					unless ($res) {
						croak "validate_strict: Parameter '$key' failed callback validation";
					}
				} elsif($rule_name eq 'optional') {
					# Already handled at the beginning of the loop
				} else {
					croak "validate_strict: Unknown rule '$rule_name'";
				}
			}
		}

		$validated_args{$key} = $value;
	}

	return \%validated_args;
}

# Helper routine to parse the arguments given to a function.
# Processes arguments passed to methods and ensures they are in a usable format,
#	allowing the caller to call the function in anyway that they want
#	e.g. foo('bar'), foo(arg => 'bar'), foo({ arg => 'bar' }) all mean the same
#	when called _get_params('arg', @_);
sub _get_params
{
	my $default = shift;

	# Directly return hash reference if the first parameter is a hash reference
	return $_[0] if(ref($_[0]) eq 'HASH');

	my %rc;
	my $num_args = scalar(@_);

	# Populate %rc based on the number and type of arguments
	if(($num_args == 1) && defined($default)) {
		# %rc = ($default => shift);
		return { $default => shift };
	} elsif($num_args == 1) {
		Carp::croak('Usage: ', __PACKAGE__, '->', (caller(1))[3], '()');
	} elsif(($num_args == 0) && defined($default)) {
		Carp::croak('Usage: ', __PACKAGE__, '->', (caller(1))[3], "($default => \$val)");
	} elsif(($num_args % 2) == 0) {
		%rc = @_;
	} elsif($num_args == 0) {
		return;
	} else {
		Carp::croak('Usage: ', __PACKAGE__, '->', (caller(1))[3], '()');
	}

	return \%rc;
}
=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

=head1 SEE ALSO

=over 4

=item * L<Params::Validate>

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
