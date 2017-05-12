package Persistence::ValueGenerator;

use strict;
use warnings;
use vars qw($VERSION);

use Abstract::Meta::Class ':all';

abstract_class;

$VERSION = 0.01;

=head1 NAME

Persistence::ValueGenerator - Unqiue value generator.

=cut  

=head1 SYNOPSIS

   use Persistence::ValueGenerator::TableGenerator;

    my $generator = Persistence::ValueGenerator::TableGenerator->new(
        entity_manager           => $entity_manager_name,
        name                     => 'empno_generator',
        table                    => 'seq_generator',
        primary_key_column_name  => 'pk_column',
        primary_key_column_value => 'empno',
        value_column             => 'value_column',
        allocation_size          =>  5,
    );

    my $entity = Persistence::Entity->new(
        name                  => 'emp',
        unique_expression     => 'empno',
        primary_key           => ['empno'],
        columns               => [
            sql_column(name => 'ename'),
            sql_column(name => 'empno'),
            sql_column(name => 'deptno')
        ],
        value_generators => {empno => 'empno_generator'},
    );
    # or
    # $entity->add_value_generators(empno => 'empno_generator');

    $entity_manager->add_entities($entity);


=head1 DESCRIPTION

Abstract class for value generator's class.

=head1 EXPORT

None

=head2 ATTRIBUTES

=over

=item name

Defines the name of the Persistence::ValueGenerator::TableGenerator instance and is the name referenced in the

=cut

has '$.name' => (required => 1);


=item allocation_size

Defined how much the counter will be incremented when entity queries the table for a new value,
This feature is to cache blocks so that it doesn't have to go to the database every time it needs a new ID.

=cut

has '$.allocation_size' => (default => 20);


=item _cached_seq

Stores counter for current seq and allocation_size

=cut

has '$._cached_seq';


=item entity_manager_name

Entity manager  name

=cut

has '$.entity_manager_name' => (required => 1);


=item _entity_manager

Caches entity manager instance.

=cut

has '$._entity_manager' => (associated_class => 'Persistence::Entity::Manager');

=back

=head2 METHODS

=over

=cut

{
my %generators;

=item initialise

=cut

    sub initialise {
        my ($self) = @_;    
        $generators{$self->name} = $self;        
    }


=item generator

Returns generator instance, takes table generator name.

=cut

    sub generator {
        my ($class, $name) = @_;
        $generators{$name};
    }

}

=item nextval

Returns next value for the instance generator

=cut

sub nextval {
    my ($self) = @_;
    my $result = $self->has_cached_seq ? $self->_cached_seq : $self->retrieve_next_value;
    $self->_cached_seq($result + 1);
    $result;
}


=item retrieve_next_value

Abstract method retrieve_next_value

=cut

abstract 'retrieve_next_value';


=item has_cached_seq

Return true if objects holds cached_seq.

=cut

sub has_cached_seq {
    my ($self) = @_;
    my $cached_seq = $self->_cached_seq or return;
    my $allocation_size = $self->allocation_size or return;
    return if($cached_seq &&  ! (($cached_seq  -1) % ($allocation_size)));
    $self;
}


=item entity_manager

Returns entity manager.

=cut

sub entity_manager {
    my ($self) = @_;
    $self->_entity_manager || $self->_entity_manager(Persistence::Entity::Manager->manager($self->entity_manager_name));
}


1;    

__END__

=back

=head1 SEE ALSO

L<Persistence::ValueGenerator::TableGenerator>
L<Persistence::ValueGenerator::SequenceGenerator>

=head1 COPYRIGHT AND LICENSE

The Persistence::ValueGenerator module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut

1;
