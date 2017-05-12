package Sendmail::Queue::Base;
use Carp qw(croak);

sub make_accessors
{
	my ($class, @instance_vars) = @_;

	no strict 'refs';
	foreach my $name ( @instance_vars ) {
		# Create setter
		if( ! defined &{"${class}::set_$name"} ) {
			*{"${class}::set_$name"} = sub {
				$_[0]->{$name} = $_[1];
			};
		}

		# Create getter
		if( ! defined &{"${class}::get_$name"} ) {
			*{"${class}::get_$name"} = sub {
				if( @_ > 1 ) {
					croak "Cannot call get_$name with an argument";
				}
				return $_[0]->{$name};
			};
		}
	}
	use strict 'refs';
}

1;
__END__

=head1 NAME

Sendmail::Queue::Base - Base class for Sendmail::Queue's objects

=head1 SYNOPSIS

  use base qw( Sendmail::Queue::Base );

  # Generate get_foo, get_bar, set_foo and set_bar accessors
  __PACKAGE__->make_accessors(qw( foo bar ));

=head1 DESCRIPTION

This provides constructor generation for Sendmail::Queue's internal objects.

Why not Moose?  Or Class::Accessor?  Or one of the many others? This module has
to work within several different frameworks, some where Moose is not
appropriate, and others where additional dependencies aren't possible, so
requiring one of the existing modules isn't possible.

=head1 METHODS

=head2 Class Methods

=over 4

=item make_accessors ( @variable_list )

Generates get_ and set_ prefixed getters and setters for every variable in
@variable_list.  Assumes a hash-based object.

=back

=head1 AUTHOR

Dave O'Neill, C<< <support at roaringpenguin.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009 Roaring Penguin Software, Inc.  All rights reserved.

=cut

