package Persistence::ValueGenerator::TableGenerator;

use strict;
use warnings;
use vars qw(@EXPORT_OK %EXPORT_TAGS $VERSION);
use base qw (Exporter Persistence::ValueGenerator);

use Abstract::Meta::Class ':all';
use Persistence::Entity;

$VERSION = 0.02;

@EXPORT_OK = qw(table_generator);
%EXPORT_TAGS = (all => \@EXPORT_OK);


=head1 NAME

Persistence::ValueGenerator::TableGenerator - Unique value generator based on database table

=cut

=head1 CLASS HIERARCHY

 Persistence::ValueGenerator
    |
    +----Persistence::ValueGenerator::TableGenerator

=head1 SYNOPSIS

   use Persistence::ValueGenerator::TableGenerator;

   my $generator = Persistence::ValueGenerator::TableGenerator->new(
        name                     => 'pk_generator',
        entity_manager_name      => $entity_manager_name,
        table                    => 'primary_key_generator',
        schema                   => '',
        primary_key_column_name  => 'pk_column',
        primary_key_column_value => 'empno',
        value_column             => 'value_column',
        allocation_size          =>  20,
    );

   my $seq = $generator->nextval;

   or 

   use Persistence::ValueGenerator::TableGenerator ':all';

   my $generator = table_generator 'pk_generator' => (
        entity_manager_name      => $entity_manager_name,
        table                    => 'primary_key_generator',
        schema                   => '',
        primary_key_column_name  => 'pk_column',
        primary_key_column_value => 'empno',
        value_column             => 'value_column',
        allocation_size          =>  20,
   );

=head1 DESCRIPTION

Represents sequence generator that uses table name
The primary_key_column_name holds a value that is used to match the primary key you are generating for.
The value_column holds the value of the counter.

    use Persistence::ValueGenerator::TableGenerator;
    use Persistence::Entity::Manager;

    my $entity_manager = Persistence::Entity::Manager->new(connection_name => 'my_connection');
    my $generator = Persistence::ValueGenerator::TableGenerator->new(
        entity_manager           => $entity_manager,
        name                     => 'pk_generator',
        table                    => 'seq_generator',
        schema                   => '',
        primary_key_column_name  => 'pk_column',
        primary_key_column_value => 'empno',
        value_column             => 'value_column',
        allocation_size          =>  20,
    );

   # for that instance you need the following table
   # CREATE TABLE seq_generator(pk_column VARCHAR2(30), value_column double)
   # CREATE emp(empno number, ename varchar2(100), deptno number);

=head1 EXPORT

table_generator by ':all' tag.

=head2 ATTRIBUTES

=over

=item table

Table name of the generator table.

=cut

has '$.table' => (required => 1, default => 'custom_pk_generator');


=item schema

Schema name of the generator table.

=cut

has '$.schema';


=item primary_key_column_name

Name of the column that identifies the specific table primary key you are generating for. 

=cut

has '$.primary_key_column_name' => (required => 1, default => 'pk_column');


=item primary_key_column_value

Used to match up with the primary key you are generating for.

=cut


has '$.primary_key_column_value' => (required => 1);


=item value_column

Specifies the name of the column that will hold the counter for the generated primary key.

=cut

has '$.value_column' => (required => 1);

    
=back

=head2 METHODS

=over

=item initialise

=cut

   
=item initialise

=cut

sub initialise {
    my ($self) = @_;
    $self->initailise_entity;
    $self->SUPER::initialise();
}
    

=item initailise_entity

=cut

sub initailise_entity {
    my ($self) = @_;
    my $entity_manager = $self->entity_manager;
    return if ($entity_manager->entity($self->id));
    $self->entity_manager->add_entities(
        Persistence::Entity->new(
            id          => $self->id,
            name        => $self->table,
            schema      => $self->schema,
            primary_key => [$self->primary_key_column_name],
            columns     => [
                Persistence::Entity::sql_column(name => $self->value_column),
                Persistence::Entity::sql_column(name => $self->primary_key_column_name),
            ],
            alias       => 't',
        )
    );
}
    

=item id

returns schma.table as id

=cut

sub id {
    my $self = shift;
    my $schema = $self->schema;
    ($schema ? $schema . "." : "") . $self->table;
}




=item retrieve_next_value

Checks current seq number in database, increments counter by $self->allocation_size + 1

=cut

sub retrieve_next_value {
    my ($self) = @_;
    my $entity = $self->entity_manager->entity($self->id);
    my ($record) = $entity->lock(undef, $self->primary_key_column_name => $self->primary_key_column_value);
    my $seq = $record ? $record->{$self->value_column} : undef;
    if ($seq) {
        $entity->update({
                $self->value_column => ($seq + ($self->allocation_size || 1)),
            }, {
                $self->primary_key_column_name => $self->primary_key_column_value
            }
        );
        return $seq;
        
    } else {
        $entity->insert(
            $self->value_column => (($self->allocation_size || 1) + 1),
            $self->primary_key_column_name => $self->primary_key_column_value
        );
        return 1;
    }
}


=item table_generator

Creates a new instance of Persistence::ValueGenerator::TableGenerator

=cut

sub table_generator {
    my $name = shift;
    __PACKAGE__->new(@_, name => $name);
}

1;    

__END__

=back

=head1 SEE ALSO

L<Persistence::Entity>
L<Persistence::Entity::GeneratedValue>

=head1 COPYRIGHT AND LICENSE

The Persistence::ValueGenerator::TableGenerator module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut

1;
