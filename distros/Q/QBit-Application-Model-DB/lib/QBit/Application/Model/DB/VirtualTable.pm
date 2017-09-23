
=head1 Name
 
QBit::Application::Model::DB::VirtualTable
 
=head1 Description
 
Base class for DB virtual tables.

=cut

package QBit::Application::Model::DB::VirtualTable;
$QBit::Application::Model::DB::VirtualTable::VERSION = '0.020';
use qbit;

use base qw(QBit::Application::Model::DB::Class);

use Sys::Hostname;

=head1 RO accessors
 
=over
 
=item *
 
B<query>

=item *
 
B<name>

=back
 
=cut

__PACKAGE__->mk_ro_accessors(qw(query name));

my $COUNTER = 0;

=head1 Package methods

=head2 init
 
=cut

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    throw Exception::BadArguments
      unless $self->query
          && blessed($self->query)
          && $self->query->isa('QBit::Application::Model::DB::Query');

    $self->{'name'} ||= join('_', 'vt', hostname, $$, $COUNTER++);
}

=head2 fields
 
=cut

sub fields {
    my ($self) = @_;

    my @fields;

    foreach my $qtable (@{$self->query->{'__TABLES__'}}) {
        push(@fields, map {{name => $_}} keys(%{$qtable->{'fields'}}));
    }

    return \@fields;
}

=head2 get_sql_with_data
 
=cut

sub get_sql_with_data {
    my ($self, %opts) = @_;

    return $self->query->get_sql_with_data(%opts);
}

sub _fields_hs {
    my ($self) = @_;

    return {map {$_->{'name'} => $_} @{$self->fields}};
}

TRUE;

=pod

For more information see code and test.

=cut
