package Repository::Simple::Value;

use strict;
use warnings;

our $VERSION = '0.06';

use Repository::Simple::Permission;
use Repository::Simple::Util;

our @CARP_NOT = qw( Repository::Simple::Util );

=head1 NAME

Repository::Simple::Value - Class for retrieving and setting property values

=head1 DESCRIPTION

This class is used for access a property value. This class is never instantiated directly, but retrieved from a property via the C<value()> method:

  my $value = $property->value;
  my $scalar = $value->get_scalar;
  my $handle = $handle->get_handle('<');

=head2 METHODS

=over

=cut

# $value = Repository::Simple::Value->new($engine, $path)
#
# Create a value object.
#
sub new {
    my ($class, $repository, $path) = @_;

    return bless { 
        repository => $repository,
        engine     => $repository->engine,
        path       => $path,
    }, $class;
}

=item $scalar = $value-E<gt>get_scalar

Retrieve the value of the property as a scalar value.

=cut

sub get_scalar {
    my $self = shift;

    $self->{repository}->check_permission($self->{path}, $READ);

    return $self->{engine}->get_scalar($self->{path});
}

=item $handle = $value-E<gt>get_handle

=item $handle = $value-E<gt>get_handle($mode)

Retrieve the value of the property as an IO handle. The C<$mode> argument is used to specify what kind of handle it is. It should be one of:

=over

=item *

"<"

=item *

">"

=item *

">>"

=item *

"+<"

=item *

"+>"

=item *

"+>>"

=back

If the value cannot be returned with a handle in the given mode, the method will croak. If C<$mode> is not given, then "<" is assumed.

=cut

sub get_handle {
    my ($self, $mode) = @_;

    $mode ||= '<';

    $self->{repository}->check_permission($self->{path}, $READ)
        if $mode =~ /<|\+/;

    $self->{repository}->check_permission($self->{path}, $SET_PROPERTY)
        if $mode =~ />|\+/;

    return $self->{engine}->get_handle($self->{path}, $mode)
}

=item $value-E<gt>set_handle($handle)

Given a ready-to-read IO handle, this method will replace the contents of the value with the contents of the entire file handle. The handle should be passed as a reference to a glob. E.g.,

  $foo = "blah blah";
  $value1->set_handle(\*STDIN);
  $value2->set_handle(IO::Scalar->new(\$foo));

Make sure to call the C<save()> method on the property or a parent node to ensure the change has taken place. The change might take place immediately for some engines, but the change is guaranteed to have happened by the time the C<save()> method returned.

=cut

sub set_handle {
    my ($self, $handle) = @_;

    $self->{repository}->check_permission($self->{path}, $SET_PROPERTY);

    $self->{engine}->set_handle($self->{path}, $handle);
}

=item $value-E<gt>set_value($value)

Replaces the value with the scalar value C<$value>.

Make sure to call the C<save()> method on the property or a parent node to ensure the change has taken place. The change might take place immediately for some engines, but the change is guaranteed to have happened by the time the C<save()> method returned.

=cut

sub set_scalar {
    my ($self, $value) = @_;

    $self->{repository}->check_permission($self->{path}, $SET_PROPERTY);

    $self->{engine}->set_scalar($self->{path}, $value);
}

=back

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2005 Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>.  All 
Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

=cut

1
