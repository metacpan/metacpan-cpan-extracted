package MooseX::Meta::Method::Signature;

use Moose;

use Carp;
use Moose::Util qw/does_role/;
use MooseX::Method::Exception;

extends qw/Moose::Meta::Method/;

our $VERSION = '0.01';

our $AUTHORITY = 'cpan:BERLE';

sub wrap_with_signature {
  my ($class,$signature,$coderef,$classname,$subname) = @_;

  MooseX::Method::Exception->throw ('No valid signature provided')
    unless does_role ($signature,'MooseX::Meta::Signature');

  MooseX::Method::Exception->throw ('No valid coderef provided')
    unless ref $coderef;

  my $self = $class->wrap (
      $class->_make_validating_coderef ($signature,$coderef),
      package_name => $classname, name => $subname
  );

  $self->{'$!signature'} = $signature;

  return $self;
}

sub _make_validating_coderef {
  my ($class,$signature,$coderef) = @_;

  return sub {
    my $self = shift;

    eval {
      @_ = ($self,$signature->validate (@_));
    };

    Carp::croak ("$@")
      if $@;

    goto $coderef;
  };
}

sub signature {
  my ($self) = @_;

  return $self->{'$!signature'};
}

sub has_signature {
  my ($self) = @_;

  return (defined $self->{'$!signature'} ? 1 : 0);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

MooseX::Meta::Method::Signature - Signature supporting method metaclass

=head1 WARNING

This API is unstable, it may change at any time. This should not
affect ordinary L<MooseX::Method> usage.

=head1 SYNOPSIS

  use MooseX::Meta::Method::Signature;
  use MooseX::Meta::Signature::Named;

  my $method = MooseX::Meta::Method::Signature->wrap_with_signature (
    MooseX::Meta::Signature::Named->new,
    sub { print "Hello world!\n" },
  );

  Someclass->meta->add_method (foo => $method);

=head1 DESCRIPTION

A subclass of L<Moose::Meta::Method> that has some added attributes
and methods to support signatures.

=head1 METHODS

=over 4

=item B<wrap_with_signature>

Similar to the wrap method from L<Moose::Meta::Method> but lets you
specify a signature for your coderef.

=item B<signature>

Returns the signature if any.

=item B<has_signature>

Returns true or false depending on if a signature is present.

=back

=head1 SEE ALSO

=over 4

=item L<Moose::Meta::Method>

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

