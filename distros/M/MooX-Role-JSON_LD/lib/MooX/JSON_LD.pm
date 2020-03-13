=head1 NAME

MooX::JSON_LD - Extend Moo to provide JSON-LD mark-up for your objects.

=head1 SYNOPSIS

    # Your Moo (or Moose) Class
    package My::Moo::Class;

    use Moo;

    use MooX::JSON_LD 'Person';

    has first_name => (
      is => 'ro',
      # various other properties...
      json_ld => 1,
    );

    has last_name  => (
      is => 'ro',
      # various other properties...
      json_ld => 1,
    );

    has birth_date => (
      is => 'ro',
      # various other properties...
      json_ld => 'birthDate',
      json_ld_serializer => sub { shift->birth_date },
    );

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

This is a companion module for L<MooX::Role::JSON_LD>. It extends the
C<has> method to support options to add attributes to the
C<json_ld_fields> and create the C<json_ld_type> .

To declare the type, add it as the option when importing the module,
e.g.

  use MooX::JSON_LD 'Thing';

Moo attributes are extended with the following options:

=over

=item C<json_ld>

  has headline => (
    is      => 'ro',
    json_ld => 1,
  );

This adds the "headline" attribute to the C<json_ld_fields>.

  has alt_headline => (
    is      => 'ro',
    json_ld => 'alternateHeadline',
  );

This adds the "alt_headline" attribute to the C<json_ld_fields>, with
the label "alternateHeadline".

=item C<json_ld_serializer>

  has birth_date => (
    is      => 'ro',
    isa     => InstanceOf['DateTime'],
    json_ld => 'birthDate',
    json_ld_serializer => sub { shift->birth_date->ymd },
  );

This allows you to specify a method for converting the data into an
object that L<JSON> can serialize.

=back

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 SEE ALSO

L<MooX::Role::JSON_LD>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018, Robert Rothenberg.  All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

package MooX::JSON_LD;

use strict;
use warnings;

use Moo       ();
use Moo::Role ();

use MRO::Compat;
use List::Util qw/ all /;
use Sub::Quote qw/ quote_sub /;

our $VERSION = '0.0.17';

my %Attributes;

sub import {
    my ( $class, $type ) = @_;

    my $target = caller;

    no strict 'refs';
    no warnings 'redefine';

    my $installer =
      $target->isa("Moo::Object")
      ? \&Moo::_install_tracked
      : \&Moo::Role::_install_tracked;

    if ( my $has = $target->can('has') ) {
        my $new_has = sub {
            $has->( _process_has(@_) );
        };
        $installer->( $target, "has", $new_has );
    }

    if ( defined $type ) {
        quote_sub "${target}::json_ld_type", "'${type}'";
    }

    my $name   = "json_ld_fields";

    quote_sub "${target}::${name}", '$code->(@_)',
        {
            '$code' => \sub {
                my ($self) = @_;
                my $fields = $self->maybe::next::method || [];
                return [
                    @{$fields},
                    @{$Attributes{$target} || []}
                ];
            },
        }, {
            no_defer => 1,
            package  => $target,
        };


    unless ( all { $target->can($_) }
        qw/ json_ld_encoder json_ld_data json_ld / )
    {

        Moo::Role->apply_single_role_to_package( $target,
            'MooX::Role::JSON_LD' );

    }

}

sub _process_has {
    my ( $name, %opts ) = @_;

    if ( $opts{json_ld} || $opts{json_ld_serializer} ) {

        my $class = caller(1);
        $Attributes{$class} ||= [];

        my $label  = delete $opts{json_ld};
        my $method = delete $opts{json_ld_serializer};

        push @{ $Attributes{$class} }, {
            $label eq "1" ? $name : $label => $method || $name
        };
    }

    return ( $name, %opts );
}

1;
