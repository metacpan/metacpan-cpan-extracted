package Persistence::Relationship;

use strict;
use warnings;

use vars qw($VERSION);
use vars qw(@EXPORT_OK %EXPORT_TAGS $VERSION);

use Abstract::Meta::Class ':all';
use Persistence::Fetchable ':all';
use base qw(Exporter Persistence::Fetchable);
use Carp 'confess';

use constant NONE      => 0;
use constant ALL       => 1;
use constant ON_INSERT => 2;
use constant ON_UPDATE => 3;
use constant ON_DELETE => 4;


$VERSION = 0.03;

@EXPORT_OK = qw(LAZY EAGER NONE ALL ON_INSERT ON_UPDATE ON_DELETE);
%EXPORT_TAGS = (all => \@EXPORT_OK);

=head1 NAME

Persistence::Relationship - Object relationship mapping

=head1 CLASS HIERARCHY

 Persistence::Fetchable
    |
    +----Persistence::Relationship

=head1 SYNOPSIS

use Persistence::Relationship ':all';

=head1 DESCRIPTION

Represents a base class for object relationship.

=head1 EXPORT

LAZY EAGER NONE ALL ON_INSERT ON_UPDATE ON_DELETE method by ':all' tag.

=head2 ATTRIBUTES

=over

=item name

Relationship name

=cut

has '$.name' => (required => 1);


=item attribute

=cut

has '$.attribute' => (required => 1);


=item attribute_name

Attribute name

=cut

has '$.attribute_name';


=item fetch_method

LAZY, EAGER

=cut

has '$.fetch_method' => (default => LAZY);


=item cascade

NONE, ALL ON_UPDATE, ON_DELETE, ON_INSERT

=cut

has '$.cascade' => (default => NONE);


=item orm

=cut

has '$.orm' => (associated_class => 'Persistence::ORM', the_other_end => 'lobs');


=back

=head2 METHODS

=over

=cut

=item add_relationship

Adds relationship to meta data cache,
Takes package name of persisitence mapping, name of relationsship, reelationship constructor parameters.

=cut


sub add_relationship {
    my ($class, $package, $name, %args) = (@_);
    my $orm  = Persistence::ORM::mapping_meta($package);
    my $attribute_class = $orm->mop_attribute_adapter;
    my $attribute = $args{attribute};
    $attribute = $args{attribute} =  $attribute_class->new(attribute => $attribute, column_name => $name)
        unless $attribute->isa('Persistence::Attribute');
    my $relation = $class->new(%args, name => $name);
    $relation->set_attribute_name($attribute->name);
    $attribute->associated_class
        or confess "associated class must be defined for attribute: " . $attribute->name;
    $orm->add_relationships($relation);
    $relation->install_fetch_interceptor($attribute)
        if ($relation->fetch_method eq LAZY);
    $relation;
}


=item relationships

=cut

sub relationships {
    my ($class, $package) = @_;
    my $orm  = Persistence::ORM::mapping_meta($package);
    my $relationships = $orm->relationships;
    $relationships;
}


=item insertable_to_many_relations

Returns all to many relation where insert applies.

=cut

sub insertable_to_many_relations {
    my ($class, $obj_class) = @_;
    my $relations = $class->relationships($obj_class) or return;
    my @result;
    foreach my $attribute_name (keys %$relations) {
        my $relation = $relations->{$attribute_name};
        next if ref($relation) eq 'Persistence::Relationship::ToOne';
        my $cascade = $relation->cascade;
        next if($cascade ne ALL && $cascade ne ON_INSERT);
        push @result, $relation;
    }
    @result;
}


=item insertable_to_one_relations

Returns all to one relation where insert applies.

=cut

sub insertable_to_one_relations {
    my ($class, $obj_class) = @_;
    my $relations = $class->relationships($obj_class) or return;
    my @result;
    foreach my $attribute_name (keys %$relations) {
        my $relation = $relations->{$attribute_name};
        next unless ref($relation) eq 'Persistence::Relationship::ToOne';
        my $cascade = $relation->cascade;
        next if($cascade ne ALL && $cascade ne ON_INSERT);
        push @result, $relation;
    }
    @result;
}


=item updatable_to_many_relations

Returns all relation where insert applies.

=cut

sub updatable_to_many_relations {
    my ($class, $obj_class) = @_;
    my $relations = $class->relationships($obj_class) or return;
    my @result;
    foreach my $attribute_name (keys %$relations) {
        my $relation = $relations->{$attribute_name};
        next if ref($relation) eq 'Persistence::Relationship::ToOne';
        my $cascade = $relation->cascade;
        next if($cascade ne ALL && $cascade ne ON_UPDATE);
        push @result, $relation;
    }
    @result;
}


=item updatable_to_one_relations

Returns all relation where insert applies.

=cut

sub updatable_to_one_relations {
    my ($class, $obj_class) = @_;
    my $relations = $class->relationships($obj_class) or return;
    my @result;
    foreach my $attribute_name (keys %$relations) {
        my $relation = $relations->{$attribute_name};
        next if ref($relation) ne 'Persistence::Relationship::ToOne';
        my $cascade = $relation->cascade;
        next if($cascade ne ALL && $cascade ne ON_UPDATE);
        push @result, $relation;
    }
    @result;
}


=item deleteable_to_many_relations

Returns all to many relation where insert applies.

=cut

sub deleteable_to_many_relations {
    my ($class, $obj_class) = @_;
    my $relations = $class->relationships($obj_class) or return;
    my @result;
    foreach my $attribute_name (keys %$relations) {
        my $relation = $relations->{$attribute_name};
        next if ref($relation) eq 'Persistence::Relationship::ToOne';
        my $cascade = $relation->cascade;
        next if($cascade ne ALL && $cascade ne ON_DELETE);
        push @result, $relation;
    }
    @result;
}


=item deleteable_to_one_relations

Returns all to one relation where insert applies.

=cut

sub deleteable_to_one_relations {
    my ($class, $obj_class) = @_;
    my $relations = $class->relationships($obj_class) or return;
    my @result;
    foreach my $attribute_name (keys %$relations) {
        my $relation = $relations->{$attribute_name};
        next if ref($relation) ne 'Persistence::Relationship::ToOne';
        my $cascade = $relation->cascade;
        next if($cascade ne ALL && $cascade ne ON_DELETE);
        push @result, $relation;
    }
    @result;
}


=item eager_fetch_relations

=cut

sub eager_fetch_relations {
    my ($class, $obj_class) = @_;
    my $relations = $class->relationships($obj_class) or return;
    $class->eager_fetch_filter($relations);
}


=item lazy_fetch_relations

=cut

sub lazy_fetch_relations {
    my ($class, $obj_class) = @_;
    my $relations = $class->relationships($obj_class) or return;
    $class->lazy_fetch_filter($relations);
}


=item install_fetch_interceptor

=cut

sub install_fetch_interceptor {
    my ($self) = @_;
    my $attribute = $self->attribute;
    $attribute->install_fetch_interceptor($self->lazy_fetch_handler($self->attribute));
}



=item values

Returns relations values as array ref, takes object as parameter

=cut

sub values {
    my ($self, $object) = @_;
    my $values = $self->value($object);
    ref($values) eq 'HASH' ? [values %$values] : $values;
}


=item value

Returns relations value

=cut

sub value {
    my ($self, $object) = @_;
    my $attribute = $self->attribute;
    my $accessor = $attribute->accessor;
    $object->$accessor;
}



1;

__END__

=back

=head1 SEE ALSO

L<Persistence::Entity>
L<Persistence::Relationship::OneToMany>
L<Persistence::Relationship::ManyToMany>

=head1 COPYRIGHT AND LICENSE

The Persistence::Relationship module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut

1;
