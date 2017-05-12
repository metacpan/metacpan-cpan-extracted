package MooseX::Meta::Parameter;

use Moose::Role;

requires qw/validate/;

our $VERSION = '0.01';

our $AUTHORITY = 'cpan:BERLE';

sub export {
  my ($self) = @_;

  my $export = {};

  for (keys %$self) {
    $export->{$_} = $self->{$_} if defined $self->{$_};
  }

  return $export;
}

1;

__END__

=pod

=head1 NAME

MooseX::Meta::Parameter - Parameter API role

=head1 METHODS

=over 4

=item B<export>

Exports a data structure representing the parameter.

=back

=head1 WARNING

This API is unstable, it may change at any time. This should not
affect ordinary L<MooseX::Method> usage.

=head1 DESCRIPTION

Ensures that the class importing the role conforms to the
MooseX::Method parameter API.

=head1 BUGS

Most software has bugs. This module probably isn't an exception.
If you find a bug please either email me, or add the bug to cpan-RT.

=head1 AUTHOR

Anders Nor Berle E<lt>debolaz@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Anders Nor Berle.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

