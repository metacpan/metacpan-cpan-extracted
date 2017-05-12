package Persistence::LOB;

use strict;
use warnings;

use vars qw($VERSION);
use vars qw(@EXPORT_OK %EXPORT_TAGS $VERSION);

use Abstract::Meta::Class ':all';
use Persistence::Fetchable ':all';
use base qw(Exporter Persistence::Fetchable);
use Carp 'confess';

$VERSION = 0.02;

@EXPORT_OK = qw(LAZY EAGER);
%EXPORT_TAGS = (all => \@EXPORT_OK);

=head1 NAME

Persistence::LOB - LOBs mapping object.

=head1 CLASS HIERARCHY

 Persistence::Fetchable
    |
    +----Persistence::LOB

=head1 SYNOPSIS

    use Persistence::ORM':all';
    use Persistence::Entity ':all';

    my $photo_entity = Persistence::Entity->new(
        name    => 'photo',
        alias   => 'ph',
        primary_key => ['id'],
        columns => [
            sql_column(name => 'id'),
            sql_column(name => 'name', unique => 1),
        ],
        lobs => [
            sql_lob(name => 'blob_content', size_column => 'doc_size'),
        ]
    );
    $entity_manager->add_entities($photo_entity);

    package Photo;
    use Abstract::Meta::Class ':all';
    use Persistence::ORM ':all';
    entity 'photo';

    column 'id'   => has('$.id');
    column 'name' => has('$.name');
    lob    'blob_content' => (attribute => has('$.image'), fetch_method => LAZY);


    package EagerPhoto;
    use Abstract::Meta::Class ':all';
    use Persistence::ORM ':all';
    entity 'photo';

    column 'id'   => has('$.id');
    column 'name' => has('$.name');
    lob    'blob_content' => (attribute => has('$.image'), fetch_method => EAGER);

    my ($photo) = $entity_manager->find(photo => 'Photo', id => 10);
    $photo->name('Moon');
    $photo->set_image($moon_image);
    $entity_manager->update($photo);


=head1 DESCRIPTION

Represents a base class for object relationship.

=head1 EXPORT

LAZY EAGER NONE ALL ON_INSERT ON_UPDATE ON_DELETE method by ':all' tag.

=head2 ATTRIBUTES

=over

=item attribute

=cut

has '$.attribute' => (required => 1);


=item orm

=cut

has '$.orm' => (associated_class => 'Persistence::ORM', the_other_end => 'lobs');


=item initialise

=cut

sub initialise {
    my ($self) = @_;
    $self->install_fetch_interceptor if ($self->fetch_method eq LAZY);
}


=item install_fetch_interceptor

=cut

sub install_fetch_interceptor {
    my ($self) = @_;
    my $attribute = $self->attribute;
    $attribute->install_fetch_interceptor($self->lazy_fetch_handler($self->attribute));
}


=item deserialise_attribute

Deserializes attribute value.

=cut

sub deserialise_attribute {
    my ($self, $this, $entity_manager, $orm) = @_;
    my $attribute = $self->attribute;
    my $entity = $entity_manager->entity($orm->entity_name);
    my $unique_values = $orm->unique_values($this, $entity);
    my $lob_column = $entity->lob($attribute->column_name);
    my $lob = $entity->fetch_lob($lob_column->name, $unique_values, $lob_column->size_column);
    my $mutator = $attribute->mutator;
    $this->$mutator($lob);
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

The Persistence::LOB module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, E<lt>adrian@webapp.strefa.pl</gt>

=cut

1;
