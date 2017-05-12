package Persistence::Relationship::OneToMany;

use strict;
use warnings;

use vars qw(@EXPORT_OK %EXPORT_TAGS $VERSION);

use Abstract::Meta::Class ':all';
use base qw (Exporter Persistence::Relationship);
use Carp 'confess';

$VERSION = 0.01;

@EXPORT_OK = qw(one_to_many);
%EXPORT_TAGS = (all => \@EXPORT_OK);

=head1 NAME

Persistence::Relationship::OneToMany - One to many relationship.

=head1 CLASS HIERARCHY

 Persistence::Relationship
    |
    +----Persistence::Relationship::OneToMany

=head1 SYNOPSIS

    #.... entities definition
    my $membership_entity = Persistence::Entity->new(
        name    => 'wsus_user_service',
        alias   => 'us',
        primary_key => ['user_id', 'service_id'],
        columns => [
            sql_column(name => 'user_id'),
            sql_column(name => 'service_id'),
            sql_column(name => 'agreement_flag')
        ],
    );

    my $user_entity = Persistence::Entity->new(
        name    => 'wsus_user',
        alias   => 'ur',
        primary_key => ['id'],
        columns => [
            sql_column(name => 'id'),
            sql_column(name => 'username', unique => 1),
            sql_column(name => 'password'),
            sql_column(name => 'email'),
        ],
        to_many_relationships => [sql_relationship(target_entity => $membership_entity, join_columns => ['user_id'], order_by => 'service_id, user_id')]
    );
    $entity_manager->add_entities($membership_entity, $user_entity);

    # object mapping
    package User;

    use Abstract::Meta::Class ':all';
    use Persistence::Entity ':all';
    use Persistence::ORM ':all';

    entity 'wsus_user';
    column id => has('$.id');
    column username => has('$.name');
    column password => has('$.password');
    column email => has('$.email');

    one_to_many 'wsus_user_service' => (
        attribute    => has('@.membership' => (associated_class => 'Membership')),
        fetch_method => EAGER,
        cascade      => ALL,
    );

=head1 DESCRIPTION

Represents one to many relationship. Allows cascading operation (inert/update/delete).
Supports eager, lazy fetch, cascading operation (inert/update/delete).

=head1 EXPORT

one_to_many method by ':all' tag.

=head2 METHODS

=over

=cut

=item one_to_many

Create a new instance of one to many relation.
Takes associated entity's id as parameters
and list of named parameters for Persistence::Relationship::OneToMany constructor.

    one_to_many 'wsus_user_service' => (
        attribute    => has('@.membership' => (associated_class => 'Membership')),
        fetch_method => EAGER,
        cascade      => ALL,
    );


=cut

sub one_to_many {
    my $package = caller();
    __PACKAGE__->add_relationship($package, @_);
}


=item deserialise_attribute

Deserialises relation attribute

=cut

sub deserialise_attribute {
    my ($self, $object, $entity_manager, $orm) = @_;
    my $entity = $entity_manager->entity($orm->entity_name);
    my $attribute = $self->attribute;
    my @rows = $entity->relationship_query(
        $self->name,
        ref($object) => $attribute->associated_class,
        $orm->column_values($object, $entity->primary_key)
    );

    if (@rows) {
        my $mutator = $attribute->mutator;
        $object->$mutator(\@rows);
    }
}


=item insert

Inserts relationship data.

=cut

sub insert {
    my ($self, $orm, $entity, $unique_values, $object) = @_;
    my $values = $self->values($object);
    $entity->relationship_insert($self->name, $unique_values, @$values);
}


=item merge

Merges relationship data.

=cut

sub merge {
    my ($self, $orm, $entity, $unique_values, $object) = @_;
    my $values = $self->values($object);
    $entity->relationship_merge($self->name, $unique_values, @$values);
}



=item delete

Merges relationship data.

=cut

sub delete {
    my ($self, $orm, $entity, $unique_values, $object) = @_;
    my $values = $self->values($object);
    $entity->relationship_delete($self->name, $unique_values, @$values);
}

1;

__END__

=back

=head1 SEE ALSO

L<Persistence::Relationship>
L<Persistence::Entity>
L<Persistence::Entity::Manager>
L<Persistence::ORM>

=head1 COPYRIGHT AND LICENSE

The Persistence::Relationship::OneToMany module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut

1;

