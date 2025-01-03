package MooseX::NonMoose::Meta::Role::Constructor;

use Moose::Role 2.0000;

# ABSTRACT: constructor method trait for L<MooseX::NonMoose>
our $VERSION = '0.27'; # VERSION


around can_be_inlined => sub {
    my $orig = shift;
    my $self = shift;

    my $meta = $self->associated_metaclass;
    my $super_new = $meta->find_method_by_name($self->name);
    my $super_meta = $super_new->associated_metaclass;
    if (Moose::Util::find_meta($super_meta)->can('does_role')
     && Moose::Util::find_meta($super_meta)->does_role('MooseX::NonMoose::Meta::Role::Class')) {
        return 1;
    }

    return $self->$orig(@_);
};

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::NonMoose::Meta::Role::Constructor - constructor method trait for L<MooseX::NonMoose>

=head1 VERSION

version 0.27

=head1 SYNOPSIS

  package My::Moose;
  use Moose ();
  use Moose::Exporter;

  Moose::Exporter->setup_import_methods;
  sub init_meta {
      shift;
      my %options = @_;
      Moose->init_meta(%options);
      Moose::Util::MetaRole::apply_metaclass_roles(
          for_class               => $options{for_class},
          metaclass_roles         => ['MooseX::NonMoose::Meta::Role::Class'],
          constructor_class_roles =>
              ['MooseX::NonMoose::Meta::Role::Constructor'],
      );
      return Moose::Util::find_meta($options{for_class});
  }

=head1 DESCRIPTION

This trait implements inlining of the constructor for classes using the
L<MooseX::NonMoose::Meta::Role::Class> metaclass trait; it has no effect unless
that trait is also used. See those docs and the docs for L<MooseX::NonMoose>
for more information.

=head1 AUTHOR

Original author: Jesse Luehrs E<lt>doy@tozt.netE<gt>

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009-2025 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
