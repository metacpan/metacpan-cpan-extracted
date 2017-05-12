package MooseX::Storage::Traits::WithRoles;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: A custom trait to include roles in serialization
$MooseX::Storage::Traits::WithRoles::VERSION = '0.2.0';
use Moose::Role;
use namespace::autoclean;

requires 'pack';
requires 'unpack';

around 'pack' => sub {
    my ($orig, $self, %args) = @_;

    $args{engine_traits} ||= [];

    push @{$args{engine_traits}}, 'WithRoles';

    $self->$orig(%args);
};

around 'unpack' => sub {
    my ($orig, $self, $data, %args) = @_;

    $args{engine_traits} ||= [];

    push @{$args{engine_traits}}, 'WithRoles';

    $self->$orig($data, %args);
};

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Storage::Traits::WithRoles - A custom trait to include roles in serialization

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

This trait is meant to be used when a base class will be consuming roles at runtime
via (for example) C<with_traits>.
Without this trait, the '__CLASS__' attribute of the serialized object would be the name
of the resulting anonymous class, which is useless to reconstruct the class after the fact.

When this trait is used, the serialized C<__CLASS__> value will be the base 
class, and C<__ROLES__> will contain the list of roles that it consumes. If used
in conjecture with L<MooseX::Storage::Base::SerializedClass>, C<unpack()> will reinflate the data
in the right class augmented by the given roles.

Oh yeah, and the trait also works with L<MooseX::Role::Parameterized> roles. You're
welcome, Sartak. ;-)

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
