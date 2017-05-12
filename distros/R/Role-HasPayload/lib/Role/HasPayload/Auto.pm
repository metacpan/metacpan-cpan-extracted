package Role::HasPayload::Auto;
{
  $Role::HasPayload::Auto::VERSION = '0.006';
}
use Moose::Role;
# ABSTRACT: a thing that automatically computes its payload based on attributes


use Role::HasPayload::Meta::Attribute::Payload;

sub payload {
  my ($self) = @_;

  my @attrs = grep { $_->does('Role::HasPayload::Meta::Attribute::Payload') }
              $self->meta->get_all_attributes;

  my %payload = map {;
    my $method = $_->get_read_method;
    ($_->name => $self->$method)
  } @attrs;

  return \%payload;
}


no Moose::Role;
1;

__END__

=pod

=head1 NAME

Role::HasPayload::Auto - a thing that automatically computes its payload based on attributes

=head1 VERSION

version 0.006

=head1 SYNOPSIS

  package Example;
  use Moose;

  with qw(Role::HasPayload::Auto);

  sub Payload { 'Role::HasPayload::Meta::Attribute::Payload' }

  has height => (
    is => 'ro',
    traits   => [ Payload ],
  );

  has width => (
    is => 'ro',
    traits   => [ Payload ],
  );

  has color => (
    is => 'ro',
  );

...then...

  my $example = Example->new({
    height => 10,
    width  => 20,
    color  => 'blue',
  });

  $example->payload; # { height => 10, width => 20 }

=head1 DESCRIPTION

Role::HasPayload::Auto only provides one method, C<payload>, which returns a
hashref of the name and value of every attribute on the object with the
Role::HasPayload::Meta::Attribute::Payload trait.  (The attribute value is
gotten with the the method returned by the attribute's C<get_read_method>
method.)

This role is especially useful when combined with L<Role::HasMessage::Errf>.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
