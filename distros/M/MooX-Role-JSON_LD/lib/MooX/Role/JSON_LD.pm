=head1 NAME

MooX::Role::JSON_LD - Easily provide JSON-LD mark-up for your objects.

=head1 SYNOPSIS

    # Your Moo (or Moose) Class
    package::My::Moo::Class

    use Moo;
    with 'MooX::Role::JSON_LD';

    # define your attributes
    has first_name => ( ... );
    has last_name  => ( ... );
    has birth date => ( ... );

    # Add two required methods
    sub json_ld_type { 'Person' };

    sub json_ld_fields { [ qw[ first_name last_name birth_date ] ] };

    # Then, in a program somewhere...
    use My::Moo::Class;

    my $obj = My::Moo::Class->new({
      first_name => 'David',
      last_name  => 'Bowie',
      birth_date => '1947-01-08',
    });

    # print a text representation of the JSON-LD
    print $obj->json_ld;

    # print the raw data structure for the JSON-LD
    use Data::Dumper;
    print Dumper $obj->json_ld_data;

=head1 DESCRIPTION

This role allows you to easily add a method you your class that produces
JSON-LD representing an instance of your class.

To do this, you need to do three things:

=over 4

=item 1. Add the role to your class

    with 'MooX::Role::JSON_LD';

=item 2. Add a method telling the role which JSON-LD type to use in the output

    sub json_ld_type { 'Person' }

=item 3. Add a method defining the fields you want to appear in the JSON-LD

    sub json_ld_fields { [ qw[ first_name last_name birth_date ] ] };

=back

=head2 Using the role

C<MooX::Role::JSON_LD> can be loaded into your class using the C<with>
keyword, just like any other role. The role has been written so that it
works in both L<Moo> and L<Moose> classes.

=head2 Defining your type

JSON-LD can be used to model many different types of object. The current list
can be found at L<https://schema.org/>. Once you have chosen one of the types
you want to use in your JSON-LD, simply add a method called C<json_ld_type>
which returns the name of your type as a string. This string will be used
in the C<@type> field of the JSON-LD.

=head3 Defining your fields

You also need to define the fields that are to be included in your JSON-LD.
To do this, you need to add a method called C<json_ld_fields> which returns
an array reference containing details of the fields you want.

The simplest approach is for each element of the array to be the name of
a method on your object. In our example above, we call the three methods,
C<first_name>, C<last_name> and C<birth_date>. The names of the methods are
used as keys in the JSON-LD and the values returned will be the matching values.
So in our example, we would get the following as part of our output:

    "birth_date" : "1947-01-08",
    "first_name" : "David",
    "last_name" : "Bowie",

Unfortunately, these aren't valid keys in the "Person" type, so we need to
use a slightly more complicated version of the C<json_ld_fields> method, one
that enables us to rename fields.

    sub json_ld_fields {
        [
          qw[ first_name last_name],
          { birthDate => 'birth_date' },
        ]
    }

In this version, the last element of the array is a hash reference. The key
in the hash will be used as the key in the JSON-LD and the value is the name
of a method to call. If we make this change, our JSON will look like this:

    "birthDate" : "1947-01-08",
    "first_name" : "David",
    "last_name" : "Bowie",

The C<birthDate> key is now a valid key in the JSON-LD representation of a
person.

But our C<first_name> and C<last_name> keys are still wrong. We could take
the same approach as we did with C<birthDate> and translate them to
C<givenName> and C<familyName>, but what if we want to combine them into the
single C<name> key. We can do that by using another version of
C<json_ld_fields> where the value of the definition hash is a subroutine
reference. That subroutine is called, passing it the object, so it can build
anything you want. We can use that to get the full name of our person.

    sub json_ld_fields {
        [
          { birthDate => 'birthDate'},
          { name => sub{ $_[0]-> first_name . ' ' . $_[0]->last_name} },
        ]
      }

That configuration will give us the following output:

    "birthDate" : "1974-01-08",
    "name" : "David Bowie",

=cut

package MooX::Role::JSON_LD;

use 5.6.0;

use Moo::Role;
use JSON;
use Carp;
use Types::Standard 'InstanceOf';

our $VERSION = '0.0.5';

requires qw[json_ld_type json_ld_fields];

has json_ld_encoder => (
  isa => InstanceOf['JSON'],
  is  => 'ro',
  lazy => 1,
  builder => '_build_json_ld_encoder',
);

sub _build_json_ld_encoder {
  return JSON->new->canonical->utf8->space_after->indent->pretty;
}

sub json_ld_data {
  my $self = shift;

  my $data = {
    '@context' => 'http://schema.org',
    '@type'    => $self->json_ld_type,
  };

  foreach (@{$self->json_ld_fields}) {
    if (my $reftype = ref $_) {
      if ($reftype eq 'HASH') {
        while (my ($key, $val) = each %{$_}) {
          if (ref $val eq 'CODE') {
            $data->{$key} = $val->($self);
          } else {
            $data->{$key} = $self->$val;
          }
        }
      } else {
        carp "Weird JSON-LD reference: $reftype";
        next;
      }
    } else {
      $data->{$_} = $self->$_;
    }
  }

  return $data;
}

sub json_ld {
  my $self = shift;

  return $self->json_ld_encoder->encode($self->json_ld_data);
}

1;

=head1 AUTHOR

Dave Cross <dave@perlhacks.com>

=head1 SEE ALSO

perl(1), Moo, Moose, L<https://json-ld.org/>, L<https://schema.org/>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018, Magnum Solutions Ltd.  All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
