package Repository::Simple::Type::Value;

use strict;
use warnings;

use Readonly;
use Repository::Simple::Util;

our @CARP_NOT = qw( Repository::Simple::Util );

require Exporter;

our @ISA = qw( Exporter );

our $VERSION = '0.06';

our @EXPORT_OK = qw(
    $SCALAR_TYPE
    $HANDLE_TYPE
);

our %EXPORT_TAGS = ( type_constants => \@EXPORT_OK );

# Type constants
Readonly our $SCALAR_TYPE  => 'STRING';
Readonly our $HANDLE_TYPE  => 'HANDLE';

=head1 NAME

Repository::Simple::Type::Value - Abstract base class for value types

=head1 SYNOPSIS

  package Repository::Simple::Type::Value::MyValueType;

  use Repository::Simple::Type::Value qw( $STRING_TYPE );
  use base qw( Repository::Simple::Type::Value );

  sub name { 
      return 'my:value-type'; 
  }

  # Only strings starting with "Foo" are accepted
  sub check {
      my ($self, $value) = @_;
      $value =~ /^Foo/
          or die qq(Value "$value" does not start with "Foo".);
  }

  # Since they all start with foo, deflate() strips it and inflate() adds it
  # back in
  sub inflate {
      my ($self, $value) = @_;
      $value =~ s/^/Foo/;
      return $value;
  }

  sub deflate {
      my ($self, $value) = @_;
      $value =~ s/^Foo// or die qq(Bad value "$value" stored!);
      return $value;
  }

=head1 DESCRIPTION

If you are just a casual user of L<Repository::Simple>, then the nature of this class isn't a concern. However, if you want to extend the functionality of L<Repository::Simple>, then you may be interested in this class.

To create a value type, subclass this class and implement methods as appropriate. Below are listed the expected inputs/outputs for each method and the nature of the default implementation, if one is provided.

=head2 REQUIRED METHODS

=over

=item $value_type = Repository::Simple::Type::Value-E<gt>new(@args)

Your type should provide a well-documented constructor.

=item $name = $value_type-E<gt>name

This method MUST be implemented by the subclass. It should return a short string naming the class. This name should be in "ns:name" form as namespaces are an intended feature for implementation in the future.

=cut

sub name { die "Subclasses must implement this method." }

=back

=head2 OPTIONAL METHODS

The following methods are optional. These methods allow storage engine independant features to be added to the store. However, you may need to be careful about employing them. If any of the following methods are defined for a value, the entire value will be read in from storage and passed to each. This may be undesireable if a value may storage large amounts of data.

=over

=item $value_type-E<gt>check($value)

Given a scalar value, this method should throw an exception if the value is not acceptable for some reason. If the value is acceptable, the method must not throw an exception.

If not defined, all input is considered acceptable.

=item $inflated_value = $value_type-E<gt>inflate($deflated_value)

Given a flat scalar value, this method may transform the value into the representation to be accessed by the end-user, and return that as a scalar (possibly a reference to a complex type). 

For example, if this type represents a L<DateTime> object, then the method will translate some string formatted date and parse it into a L<DateTime> object.

This method will be called whenever loading the value from storage.

=item $deflated_value = $value_type-E<gt>deflate($inflated_value)

Given the end-user representation of this type (possibly a reference to a complex type), this method may transform the value into a scalar value for storage and return it.

For example, if this type represents a L<DateTime> object, then the method should return a string representation of the L<DateTime> object.

This method will be called whenever saving the value back to storage.

=back

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2006 Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>.  All 
Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

=cut

1
