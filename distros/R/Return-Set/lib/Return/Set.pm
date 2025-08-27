package Return::Set;

use strict;
use warnings;
use 5.010;

use parent 'Exporter';

use Carp qw(croak);
use Params::Get 0.13;
use Params::Validate::Strict 0.10 qw(validate_strict);

our @EXPORT_OK = qw(set_return);

=head1 NAME

Return::Set - Return a value optionally validated against a strict schema

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use Return::Set qw(set_return);

    my $value = set_return($value);  # Just returns $value

    my $value = set_return($value, { type => 'integer' });  # Validates $value is an integer

=head1 DESCRIPTION

Exports a single function, C<set_return>, which returns a given value.
If a validation schema is provided, the value is validated using
L<Params::Validate::Strict>.
If validation fails, it croaks.

When used hand-in-hand with L<Params::Get> you should be able to formally specify the input and output sets for a method.

=head1	METHODS

=head2 set_return($value, $schema)

Returns C<$value>.
If C<$schema> is provided, it validates the value against it.
Croaks if validation fails.

=cut

sub set_return {
	my $value;
	my $schema;

	if((scalar(@_) == 1) && !ref($_[0])) {
		return $_[0];
	}

	if(scalar(@_) == 2) {
		$value = $_[0];
		$schema = $_[1];
	} else {
		my $params = Params::Get::get_params('output', \@_);
		$value = $params->{'value'} // $params->{'output'};
		$schema = $params->{'schema'};
	}

	if(defined($schema)) {
		eval {
			validate_strict(args => { 'value' => $value }, schema => { 'value' => $schema });
			1;
		} or croak "Validation failed: $@";
	}

	return $value;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 SEE ALSO

=over 4

=item * L<Params::Validate::Strict>

=item * L<Params::Get>

=back

=head1 SUPPORT

This module is provided as-is without any warranty.

=head1 LICENCE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;
