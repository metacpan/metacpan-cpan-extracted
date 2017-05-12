package MooseX::Role::Restricted;

our $VERSION = '1.03';

use Moose::Role;
use Moose::Exporter;
use Attribute::Handlers;

Moose::Exporter->setup_import_methods(
  also  => 'Moose::Role',
  as_is => [qw(_ATTR_CODE_Public _ATTR_CODE_Private)],
);

sub Public : ATTR(CODE) {
  my ($package, $symbol, $referent, $attr, $data) = @_;
  (my $name = "" . *$symbol) =~ s/.*:://;
  $package->meta->public_private_map->{$name} = 0;
}

sub Private : ATTR(CODE) {
  my ($package, $symbol, $referent, $attr, $data) = @_;
  (my $name = "" . *$symbol) =~ s/.*:://;
  $package->meta->public_private_map->{$name} = 1;
}

# fudge due to delayed resolve in A::H, needed to defined _ATTR_CODE_Private
sub PPP : ATTR(CODE) { }

sub init_meta {
  my ($class, %opt) = @_;
  my $meta = Moose::Role->init_meta(    ##
    %opt,                               ##
    metaclass => 'MooseX::Role::Restricted::Meta'
  );

  $meta;
}

package  # hide from PAUSE
  MooseX::Role::Restricted::Meta;
use Moose;
extends 'Moose::Meta::Role';

has 'public_private_map' => (
  is      => 'rw',
  isa     => 'HashRef',
  default => sub { +{} }
);


sub apply {
  my ($self, $other, %args) = @_;
  my $pp_map = $self->public_private_map;
  my @exclude = grep { exists $pp_map->{$_} ? $pp_map->{$_} : /^_/; } $self->get_method_list;

  if (exists $args{excludes} && !exists $args{'-excludes'}) {
    $args{'-excludes'} = delete $args{excludes};
  }

  if (exists $args{'-excludes'}) {
    push @exclude, (ref $args{'-excludes'} eq 'ARRAY')
      ? @{$args{'-excludes'}}
      : $args{'-excludes'};
  }

  $args{'-excludes'} = \@exclude;
  $self->SUPER::apply($other, %args);
}

1;

__END__

=head1 NAME

  MooseX::Role::Restricted - (DEPRECATED) Restrict which sub are exported by a role

=head1 SYNOPSIS

  package MyApp::MyRole;

  use MooseX::Role::Restricted;

  sub method1 { ... }
  sub _private1 { ... }

  sub _method2 :Public { ... }
  sub private2 :Private { ... }

=head1 DEPRECATED

This module is no longer supported. I suggest looking at L<namespace::autoclean> as an alternative.
In its default form L<MooseX::Role::Restricted> simple excludes ann sub with names starting with C<_>
to be excluded. This can be accomplished using

  use namespace::autoclean -also => qr/^_/;

If you are using C<lazy_build> or other L<Moose> features that require the use of C<_> prefixed methods
make sure to change the pattern to not match those. Or use some other prefix, for example a double 
C<_>, for your private subs that you do not want included in the role.

=head1 DESCRIPTION

By default L<Moose::Role> will export any sub you define in a role package. However
it does not export any sub which was imported from another package

L<MooseX::Role::Restricted> give a little more control over which subs are exported
and which are not.

By default an sub with a name starting with C<_> is considered private and will not
be exported. However L<MooseX::Role::Restricted> provides two subroutine attributes
C<:Public> and C<:Private> which can control is any sub is exported or kept private

=head1 SEE ALSO

L<Moose::Role>

=head1 AUTHOR

Graham Barr <gbarr@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2009 Graham Barr

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

