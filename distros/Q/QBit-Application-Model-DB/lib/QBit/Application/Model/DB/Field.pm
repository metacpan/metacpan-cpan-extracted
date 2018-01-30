
=head1 Name
 
QBit::Application::Model::DB::Field
 
=head1 Description
 
Base class for DB fields.

=cut

package QBit::Application::Model::DB::Field;
$QBit::Application::Model::DB::Field::VERSION = '0.027';
use qbit;

use base qw(QBit::Application::Model::DB::Class);

=head1 RO accessors
 
=over
 
=item *
 
B<name>

=item *
 
B<type>

=item *
 
B<table>

=back
 
=cut

__PACKAGE__->mk_ro_accessors(
    qw(
      name
      type
      table
      )
);

=head1 Package methods

=head2 init
 
=cut

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    weaken($self->{'table'});

    $self->init_check();
}

=head2 init_check
 
=cut

sub init_check {
    my ($self) = @_;

    my @mis_params = grep {!exists($self->{$_})} qw(name type);

    throw gettext('Need required parameter(s): %s (Table "%s")', join(', ', @mis_params), $self->table->name)
      if @mis_params;
}

=head1 Abstract methods
 
=over
 
=item *
 
B<create_sql>

=back
 
=cut

sub create_sql {throw 'Abstract method'}

TRUE;

=pod

For more information see code and test.

=cut
