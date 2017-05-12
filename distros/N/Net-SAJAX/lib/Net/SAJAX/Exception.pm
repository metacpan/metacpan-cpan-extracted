package Net::SAJAX::Exception;

use 5.008003;
use strict;
use warnings 'all';

###############################################################################
# METADATA
our $AUTHORITY = 'cpan:DOUGDUDE';
our $VERSION   = '0.107';

###############################################################################
# MOOSE
use Moose 0.77;
use MooseX::StrictConstructor 0.08;

###############################################################################
# MODULE IMPORTS
use Carp qw(croak);
use Class::Load qw(load_class);

###############################################################################
# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean 0.04 -except => [qw(meta)];

###############################################################################
# OVERLOADED FUNCTIONS
__PACKAGE__->meta->add_package_symbol(q{&()}  => sub {                  });
__PACKAGE__->meta->add_package_symbol(q{&(""} => sub { shift->stringify });

###############################################################################
# ATTRIBUTES
has message => (
	is            => 'ro',
	isa           => 'Str',
	documentation => q{The error message},
	required      => 1,
);

###############################################################################
# METHODS
sub stringify {
	my ($self) = @_;

	# The default stringify method just returns the contents of the message
	# attribute.
	return $self->message;
}
sub throw {
	my ($class, %args) = @_;

	if (blessed $class) {
		# Since $class is blessed, this was probably called as a method, so
		# make $class the class name.
		$class = blessed $class;
	}

	my $exception_class = delete $args{class};

	if (!defined $exception_class) {
		croak $class->new(%args);
	}

	# Prefix this class to the beginning of the exception class
	$exception_class = sprintf '%s::%s', $class, $exception_class;

	# Load the exception class
	load_class($exception_class);

	croak $exception_class->new(%args);
}

###############################################################################
# MAKE MOOSE OBJECT IMMUTABLE
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::SAJAX::Exception - Basic exception object for Net::SAJAX

=head1 VERSION

This documentation refers to version 0.107

=head1 SYNOPSIS

  use Net::SAJAX::Exception;

  Net::SAJAX::Exception->throw(
    message => 'This is some error message',
  );

=head1 DESCRIPTION

This is a basic exception class for the L<Net::SAJAX library|Net::SAJAX>.

=head1 ATTRIBUTES

=head2 message

B<Required>. This is a string that contains the error message for the
exception.

=head1 METHODS

=head2 stringify

This method is used to return a string that will be given when this object is
used in a string context. Classes inheriting from this class are welcome to
override this method. By default (as in, in this class) this method simply
returns the contents of the message attribute.

  my $error = Net::SAJAX::Exception->new(message => 'Error message');

  print $error; # Prints "Error message"

=head2 throw

This method will take a HASH as the argument and will pass this HASH to the
constructor of the class, and then throw the newly constructed object. An extra
option that will be stripped is C<class>. This option will actually construct a
different class, where this class is in the package space below the specified
class.

  eval {
    Net::SAJAX::Exception->throw(
      class   => 'ClassName',
      message => 'An error occurred',
    );
  };

  print ref $@; # Prints Net::SAJAX::Exception::ClassName

=head1 DEPENDENCIES

=over

=item * L<Carp|Carp>

=item * L<Class::Load|Class::Load>

=item * L<Moose|Moose> 0.77

=item * L<MooseX::StrictConstructor|MooseX::StrictConstructor> 0.08

=item * L<namespace::clean|namespace::clean> 0.04

=back

=head1 AUTHOR

Douglas Christopher Wilson, C<< <doug at somethingdoug.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-net-sajax at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-SAJAX>.
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
