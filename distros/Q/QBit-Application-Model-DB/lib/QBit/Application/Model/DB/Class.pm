
=head1 Name
 
QBit::Application::Model::DB::Class
 
=head1 Description
 
Base class for DB modules.

=cut

package QBit::Application::Model::DB::Class;
$QBit::Application::Model::DB::Class::VERSION = '0.023';
use qbit;

use base qw(QBit::Class);

=head1 RO accessors
 
=over
 
=item *
 
B<db>

=back
 
=cut

__PACKAGE__->mk_ro_accessors(qw(db));

=head1 Package methods

=head2 init
 
=cut

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    throw gettext('Required opt "db" must be QBit::Application::Model::DB descendant')
      unless $self->db && $self->db->isa('QBit::Application::Model::DB');

    weaken($self->{'db'});
}

=head2 quote
 
=cut

sub quote {
    my ($self, $name) = @_;

    return $self->db->quote($name);
}

=head2 quote_identifier
 
=cut

sub quote_identifier {
    my ($self, $name) = @_;

    return $self->db->quote_identifier($name);
}

=head2 filter
 
=cut

sub filter {shift->db->filter(@_)}

TRUE;

=pod

For more information see code and test.

=cut
