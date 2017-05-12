use 5.006;    # our, pragmas
use strict;
use warnings;

package MooseX::AttributeIndexes::Meta::Role::Composite;

our $VERSION = '2.000001';

# ABSTRACT: Give a either a class or role indexable attributes.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose::Role qw( around );

around apply_params => sub {
  my $orig = shift;
  my $self = shift;

  $self->$orig(@_);

  $self = Moose::Util::MetaRole::apply_metaroles(
    for            => $self,
    role_metaroles => {
      application_to_class => ['MooseX::AttributeIndexes::Meta::Role::ApplicationToClass'],
      application_to_role  => ['MooseX::AttributeIndexes::Meta::Role::ApplicationToRole'],
    },
  );

  return $self;
};

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::AttributeIndexes::Meta::Role::Composite - Give a either a class or role indexable attributes.

=head1 VERSION

version 2.000001

=head1 AUTHORS

=over 4

=item *

Kent Fredric <kentnl@cpan.org>

=item *

Jesse Luehrs <doy@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
