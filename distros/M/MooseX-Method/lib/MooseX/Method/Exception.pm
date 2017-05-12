package MooseX::Method::Exception;

use Moose;

use overload '""' => \&stringify;

has error => (is => 'rw',isa => 'Str',required => 1);

our $VERSION = '0.01';

our $AUTHORITY = 'cpan:BERLE';

sub throw {
  my ($class,$error) = @_;

  my $self = $class->new (error => $error);

  die $self;

  return;
}

sub rethrow {
  my ($self) = @_;

  die $self;

  return;
}

sub stringify {
  my ($self) = @_;

  return $self->error;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

MooseX::Method::Exception - Exception class for MooseX::Method

=head1 WARNING

This API is unstable, it may change at any time. This should not
affect ordinary L<MooseX::Method> usage.

=head1 SYNOPSIS

  eval {
    MooseX::Method::Exception->throw ("OH NOES!");
  };

  if ($@) {
    if (blessed $@ && $@->isa ('MooseX::Method::Exception') {
      # Our exception
    } else {
      # Something else
    }
  }

=head1 DESCRIPTION

To get MooseX::Method to treat your exceptions like its own, use
this class to throw exceptions in the validation.

=head1 ATTRIBUTES

=over 4

=item B<error>

The error message.

=back

=head1 METHODS

=over 4

=item B<throw>

Shorthand for...

  my $exception = MooseX::Method::Exception->new (error => $message);

  die $exception;

Takes a single argument, the error message.

=item B<rethrow>

Rethrows an existing exception.

=item B<stringify>

Makes the exception object stringify to the error message in a string
context.

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

