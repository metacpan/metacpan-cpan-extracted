package Role::HasPayload::Auto 0.007;
use Moose::Role;
# ABSTRACT: a thing that automatically computes its payload based on attributes

#pod =head1 SYNOPSIS
#pod
#pod   package Example;
#pod   use Moose;
#pod
#pod   with qw(Role::HasPayload::Auto);
#pod
#pod   sub Payload { 'Role::HasPayload::Meta::Attribute::Payload' }
#pod
#pod   has height => (
#pod     is => 'ro',
#pod     traits   => [ Payload ],
#pod   );
#pod
#pod   has width => (
#pod     is => 'ro',
#pod     traits   => [ Payload ],
#pod   );
#pod
#pod   has color => (
#pod     is => 'ro',
#pod   );
#pod
#pod ...then...
#pod
#pod   my $example = Example->new({
#pod     height => 10,
#pod     width  => 20,
#pod     color  => 'blue',
#pod   });
#pod
#pod   $example->payload; # { height => 10, width => 20 }
#pod
#pod =head1 DESCRIPTION
#pod
#pod Role::HasPayload::Auto only provides one method, C<payload>, which returns a
#pod hashref of the name and value of every attribute on the object with the
#pod Role::HasPayload::Meta::Attribute::Payload trait.  (The attribute value is
#pod gotten with the the method returned by the attribute's C<get_read_method>
#pod method.)
#pod
#pod This role is especially useful when combined with L<Role::HasMessage::Errf>.
#pod
#pod =cut

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

=encoding UTF-8

=head1 NAME

Role::HasPayload::Auto - a thing that automatically computes its payload based on attributes

=head1 VERSION

version 0.007

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

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
