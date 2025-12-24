package OIDC::Client::Trait::HashStore;
use utf8;
use Moose::Role;
use namespace::autoclean;
use OIDC::Client::Utils qw(reach_data affect_data delete_data);

=encoding utf8

=head1 NAME

OIDC::Client::Trait::HashStore - Moose Trait for hashref stores

=head1 DESCRIPTION

This Moose Trait automatically adds methods to the instances of the class
based on the name of the attribute using it.

Used by the C<OIDC::Client::Plugin::session> attribute, it adds read_session(), write_session()
and delete_session() methods to the instances of the L<OIDC::Client::Plugin> class.

Used by the C<OIDC::Client::Plugin::stash> attribute, it adds read_stash(), write_stash()
and delete_stash() methods to the instances of the L<OIDC::Client::Plugin> class.

C<read_${name}> method calls the L<OIDC::Client::Utils/"reach_data( $data_tree, \@path, $optional )">
function.

C<write_${name}> method calls the L<OIDC::Client::Utils/"affect_data( $data_tree, \@path, $value )">
function.

C<delete_${name}> method calls the L<OIDC::Client::Utils/"delete_data( $data_tree, \@path )">
function.

=cut

after 'install_accessors' => sub {
  my $self = shift;
  my $realclass = $self->associated_class();
  my $name = $self->name;
  $realclass->add_method("read_${name}"   => sub { return scalar reach_data( $_[0]->$name, $_[1]) });
  $realclass->add_method("write_${name}"  => sub { return scalar affect_data($_[0]->$name, $_[1], $_[2]) });
  $realclass->add_method("delete_${name}" => sub { return scalar delete_data ($_[0]->$name, $_[1]) });
};

1;
