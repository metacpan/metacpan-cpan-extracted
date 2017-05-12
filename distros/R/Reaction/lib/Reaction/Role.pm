package Reaction::Role;

use Moose::Role ();
use Reaction::ClassExporter;
use Reaction::Class;
use Moose::Meta::Class;

#TODO: review for Reaction::Object switch / Reaction::Meta::Class

use namespace::clean -except => [ qw(meta) ];

override exports_for_package => sub {
  my ($self, $package) = @_;
  my %exports = $self->SUPER::exports_for_package($package);
  delete $exports{class};
  $exports{role} = sub { $self->do_role_sub($package, @_); };
  return %exports;
};

override next_import_package => sub { 'Moose::Role' };

override default_base => sub { () };

override add_method_to_target => sub {
  my ($self, $target, $method) = @_;
  $target->meta->add_method(@$method);
};
override next_import => sub {
  my ($self) = @_;
  my $import = super;
  # ugh
  return sub {
      push @_, '-metaclass' => 'Reaction::Meta::Role';
      goto $import;
  };
};
sub do_role_sub {
  my ($self, $package, $role, $which, $setup) = @_;
  confess "Invalid role declaration, should be: role Role which { ... }"
    unless ($which eq 'which' && ref($setup) eq 'CODE');
  $self->setup_and_cleanup($role, $setup);
};

__PACKAGE__->meta->make_immutable;


1;

=head1 NAME

Reaction::Role

=head1 DESCRIPTION

=head1 SEE ALSO

L<Moose::Role>

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
