package Slack::BlockKit::Role::HasStyle 0.005;
# ABSTRACT: a parameterized role for objects with styles

use MooseX::Role::Parameterized;

#pod =head1 OVERVIEW 
#pod
#pod This role exists to help write classes for Block Kit objects that have text
#pod styles applied.  Because not all objects with styles permit all the same
#pod styles, this is a I<parameterized> role, and must be included by providing a
#pod C<styles> parameter, which is an arrayref of style names that may be enabled or
#pod disabled on an object.
#pod
#pod When a Block Kit object class that composes this role is converted into a data
#pod structure with C<as_struct>, the styled defined in that instance's C<style>
#pod hash will be added as JSON boolean objects.
#pod
#pod You probably don't need to think about this role, though.
#pod
#pod =cut

use v5.36.0;

use MooseX::Types::Moose qw(ArrayRef Bool);
use MooseX::Types::Structured qw(Dict Optional);

my sub _boolset ($hashref) {
  return {
    map {; $_ => Slack::BlockKit::boolify($hashref->{$_}) } keys %$hashref,
  };
}

parameter styles => (
  is  => 'bare',
  isa => 'ArrayRef[Str]',
  required  => 1,
  traits    => [ 'Array' ],
  handles   => { styles => 'elements' },
);

role {
  my ($param) = @_;

  has style => (
    is  => 'ro',
    isa => Dict[ map {; $_ => Optional([Bool]) } $param->styles ],
    predicate => 'has_style',
  );

  around as_struct => sub {
    my ($orig, $self, @rest) = @_;

    my $struct = $self->$orig(@rest);

    if ($self->has_style) {
      $struct->{style} = _boolset($self->style);
    }

    return $struct;
  };
};

no MooseX::Types::Moose;
no MooseX::Types::Structured;

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Slack::BlockKit::Role::HasStyle - a parameterized role for objects with styles

=head1 VERSION

version 0.005

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 OVERVIEW 

This role exists to help write classes for Block Kit objects that have text
styles applied.  Because not all objects with styles permit all the same
styles, this is a I<parameterized> role, and must be included by providing a
C<styles> parameter, which is an arrayref of style names that may be enabled or
disabled on an object.

When a Block Kit object class that composes this role is converted into a data
structure with C<as_struct>, the styled defined in that instance's C<style>
hash will be added as JSON boolean objects.

You probably don't need to think about this role, though.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
