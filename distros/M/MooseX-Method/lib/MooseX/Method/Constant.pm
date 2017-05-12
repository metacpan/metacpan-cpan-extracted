package MooseX::Method::Constant;

use Moose;

our $VERSION = '0.01';

our $AUTHORITY = 'cpan:BERLE';

our $count;

sub make {
  my ($class,$value) = @_;

  $count++;

  no strict qw/refs/;

  *{"$class\::constant_$count"} = sub () { $value };

  return "$class\::constant_$count()";
}

1;

__END__

=head1 NAME

MooseX::Method::Constant - Constant generator for MooseX::Method

=head1 WARNING

This API is unstable, it may change at any time. This should not
affect ordinary L<MooseX::Method> usage.

=head1 SYNOPSIS

  use MooseX::Method::Constant;

  my $constant = MooseX::Method::Constant->make;

  print eval "$constant";

=head1 DESCRIPTION

Primarily used within the inlining compiler suite of MooseX::Method,
and there are no guarantees this won't be gone tomorrow.

=head1 METHODS

=over 4

=item make

Makes a constant.

=back

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

