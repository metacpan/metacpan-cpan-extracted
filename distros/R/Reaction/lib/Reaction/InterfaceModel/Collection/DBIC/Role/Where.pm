package Reaction::InterfaceModel::Collection::DBIC::Role::Where;

use Reaction::Role;
use Scalar::Util qw/blessed/;

use namespace::clean -except => [ qw(meta) ];


#requires qw/_source_resultset _im_class/;
sub where {
  my $self = shift;
  my $rs = $self->_source_resultset->search_rs(@_);
  return (blessed $self)->new(
                              _source_resultset => $rs,
                              member_type => $self->member_type
                             );
};
sub add_where {
  my $self = shift;
  my $rs = $self->_source_resultset->search_rs(@_);
  $self->_source_resultset($rs);
  $self->_clear_collection_store if $self->_has_collection_store;
  return $self;
};

#XXX may need a rename, but i needed this for ListView
sub find {
  my $self = shift;
  $self->_source_resultset
    ->search({},{result_class => $self->member_type})
      ->find(@_);
};


1;

=head1 NAME

Reaction::InterfaceModel::Collection::DBIC::Role::Where

=head1 DESCRIPTION

Provides methods to allow a ResultSet collection to be restricted

=head1 METHODS

=head2 where

Will return a clone with a restricted C<_source_resultset>.

=head2 add_where

Will return itself after restricting C<_source_resultset>. This also clears the
C<_collection_store>

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
