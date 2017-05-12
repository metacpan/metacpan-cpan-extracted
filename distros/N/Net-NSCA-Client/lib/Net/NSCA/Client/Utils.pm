package Net::NSCA::Client::Utils;

use 5.008001;
use strict;
use warnings 'all';

###########################################################################
# METADATA
our $AUTHORITY = 'cpan:DOUGDUDE';
our $VERSION   = '0.009002';

###########################################################################
# MODULES
use Sub::Exporter 0.978 -setup => {
	exports => [qw(initialize_moose_attr_early)],
};

###########################################################################
# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean 0.04 -except => [qw(import meta)];

###########################################################################
# FUNCTIONS
sub initialize_moose_attr_early {
	my ($class, $attr_name, $args) = @_;

	# Find the attribute with the given name
	my $attr = $class->meta->find_attribute_by_name($attr_name);

	if (!$attr->has_init_arg || !exists $args->{$attr->init_arg}) {
		# There would be only defaults, which this function doesn't consider
		return;
	}

	# Get the value from the args
	my $raw_value = $args->{$attr->init_arg};

	# Get the coerced value
	my $value = $attr->should_coerce && $attr->type_constraint->has_coercion
		? $attr->type_constraint->coerce($raw_value) : $raw_value;

	# Make sure it is a valid value
	$attr->verify_against_type_constraint($value, instance => $class->meta);

	return $value;
}

1;

__END__

=head1 NAME

Net::NSCA::Client::Utils - Utility functions for Net::NSCA::Client

=head1 VERSION

This documentation refers to version 0.009002

=head1 DESCRIPTION

This module provides utilities for use with
L<Net::NSCA::Client|Net::NSCA::Client> modules and really shouldn't be used
by other packages.

=head1 SYNOPSIS

  use Net::NSCA::Client::Utils ();

  # See each function for a synopsis of it

=head1 FUNCTIONS

=head2 initialize_moose_attr_early

This function takes three ordered arguments: C<$class> which is the string
of the class the Moose class the attribute is being initialized in,
C<$attr_name> which is the name of the attribute to initialize, and
C<$args> which is the hash reference of the arguments to the constructor.

This function will return C<undef> if the attribute was not provided to the
constructor (or if the actual attribute's value is C<undef>, in which case
this function is useless for) or the actual (possibly coerced) value for
that attribute. A typical invalid attribute passed to the constructor error
will occur if the value is invalid.

  # Used in a BUILDARGS modifier
  around BUILDARGS => sub {
      my ($original_method, $class, @args) = @_;

      # Call the original method to get args HASHREF
      my $args = $class->$original_method(@args);

      if (defined(my $obj = _initialize_attr_early($class, obj => $args))) {
          # The obj attribute was coerced and valudated and is defined
          # Do something with $obj
      }

      return $args;
  };

=head1 DEPENDENCIES

=over

=item * L<Sub:Exporter|Sub::Exporter> 0.978

=back

=head1 AUTHOR

Douglas Christopher Wilson, C<< <doug at somethingdoug.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-net-nsca-client at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-NSCA-Client>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

I highly encourage the submission of bugs and enhancements to my modules.

=head1 LICENSE AND COPYRIGHT

Copyright 2009 Douglas Christopher Wilson.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back
