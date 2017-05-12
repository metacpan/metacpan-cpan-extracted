package MooseX::Storage::Base::SerializedClass;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Deserialize according to the serialized __CLASS__
$MooseX::Storage::Base::SerializedClass::VERSION = '0.2.0';

use parent 'Exporter';

use Moose::Role;

with 'MooseX::Storage::Basic';

use Moose::Util qw/ with_traits /;
use Class::Load 'load_class';
use List::MoreUtils qw/ apply /;

our @EXPORT_OK = qw/ moosex_unpack /;

use namespace::autoclean;

around unpack => sub {
    my( $orig, $class, $data, %args ) = @_;

    $class = _unpack_class( $data );

    $orig->($class,$data,%args);
};

sub _unpack_class {
    my $data = shift;

    my $class = Class::Load::load_class( $data->{'__CLASS__'} );

    if( my $roles = delete $data->{'__ROLES__'} ) {
        my @roles = apply { 
            if( my( $c, $params ) = eval { %$_} ) {
                $_ = $c->meta->generate_role( parameters => $params );
            }
        } @$roles;

        $class = with_traits( $class, @roles );
    }

    return $data->{'__CLASS__'} = $class;
}

sub moosex_unpack {
    my $data = shift;
    _unpack_class($data)->unpack($data);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Storage::Base::SerializedClass - Deserialize according to the serialized __CLASS__

=head1 VERSION

version 0.2.0

=head1 SYNOPSIS

  package ThirdDimension;
  use Moose::Role;

  has 'z' => (is => 'rw', isa => 'Int');

  package Point;
  use Moose;
  use MooseX::Storage;

  with Storage( base => 'SerializedClass', traits => [ 'WithRoles' ] );

  has 'x' => (is => 'rw', isa => 'Int');
  has 'y' => (is => 'rw', isa => 'Int');

  1;

  use Moose::Util qw/ with_traits /;

  my $p = with_traits( 'Point', 'ThirdDimension' )->new(x => 10, y => 10, z => 10);

  my $packed = $p->pack(); 
  # { __CLASS__ => 'Point', '__ROLES__' => [ 'ThirdDimension' ], x => 10, y => 10, z => 10 }

  # unpack the hash into a class
  my $p2 = Point->unpack($packed);

  print $p2->z;

=head1 DESCRIPTION

Behaves like L<MooseX::Storage::Basic>, with the exception that 
the unpacking will reinflate the object into the class and roles
as provided in the serialized data. It is means to be used in
conjuncture with L<MooseX::Storage::Traits::WithRoles>.

=head1 EXPORTED FUNCTIONS

The function C<moosex_unpack> can be exported. The function unpacks
a serialized object based on its C<__CLASS__> and C<__ROLES__> attributes.

    use MooseX::Storage::Base::SerializedClass qw/ moosex_unpack /;

    my $object = moosex_unpack( $struct );

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
