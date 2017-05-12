# ABSTRACT: document builder - resource
package PONAPI::Document::Builder::Resource;

use Moose;

use PONAPI::Document::Builder::Relationship;

with 'PONAPI::Document::Builder',
     'PONAPI::Document::Builder::Role::HasLinksBuilder',
     'PONAPI::Document::Builder::Role::HasMeta';

has id   => ( is => 'ro', isa => 'Str', required => 1 );
has type => ( is => 'ro', isa => 'Str', required => 1 );

has _attributes => (
    init_arg => undef,
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef',
    lazy     => 1,
    default  => sub { +{} },
    handles  => {
        'has_attributes'    => 'count',
        'has_attribute_for' => 'exists',
        # private ...
        '_add_attribute'   => 'set',
        '_get_attribute'   => 'get',
        '_keys_attributes' => 'keys',
    }
);

has _relationships => (
    init_arg => undef,
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef[ PONAPI::Document::Builder::Relationship ]',
    lazy     => 1,
    default  => sub { +{} },
    handles  => {
        'has_relationships'    => 'count',
        'has_relationship_for' => 'exists',
        # private ...
        '_add_relationship'   => 'set',
        '_get_relationship'   => 'get',
        '_keys_relationships' => 'keys',
    }
);

sub add_attribute {
    my ( $self, $key, $value ) = @_;

    $self->raise_error( 400,
        title => 'Attribute key conflict, a relation already exists for key: ' . $key
    ) if $self->has_relationship_for( $key );

    $self->_add_attribute( $key, $value );

    return $self;
}

sub add_attributes {
    my ( $self, %args ) = @_;
    $self->add_attribute( $_, $args{ $_ } ) foreach keys %args;
    return $self;
}

sub add_relationship {
    my ( $self, $key, $resource, $collection ) = @_;

    $self->raise_error( 400,
        title => 'Relationship key conflict, an attribute already exists for key: ' . $key
    ) if $self->has_attribute_for( $key );

    my @resources =
        ( ref $resource eq 'ARRAY' ) ? @$resource :
        ( ref $resource eq 'HASH'  ) ? $resource  :
        die 'Relationship resource information must be a reference (HASH or ARRAY)';

    my $builder = $self->has_relationship_for($key)
        ? $self->_get_relationship($key)
        : PONAPI::Document::Builder::Relationship->new(
            parent     => $self,
            name       => $key,
            collection => $collection,
          );

    $builder->add_resource( $_ ) foreach @resources;

    $self->_add_relationship( $key => $builder );
}

sub add_self_link {
    my $self = shift;
    my $base = $self->find_root->req_base;
    $self->links_builder->add_link( self => $base . $self->{type} . '/' . $self->{id} );
    return $self;
}

sub build {
    my $self   = shift;
    my %args   = @_;
    my $result = {};

    $result->{id}    = $self->id;
    $result->{type}  = $self->type;
    $result->{links} = $self->links_builder->build if $self->has_links_builder;
    $result->{meta}  = $self->_meta                if $self->has_meta;

    # support filtered output for attributes/relationships through args
    my @field_filters;
    @field_filters = @{ $args{fields}{ $self->type } }
        if exists $args{fields} and exists $args{fields}{ $self->type };

    if ( $self->has_attributes ) {
        my @attributes = @field_filters
            ? grep { $self->has_attribute_for($_) } @field_filters
            : $self->_keys_attributes;

        $result->{attributes} = +{ map { $_ => $self->_get_attribute($_) } @attributes };
    }

    $result->{relationships} = +{
        map { my $v = $self->_get_relationship($_); $v ? ( $_ => $v->build ) : () }
        ( @field_filters ? @field_filters : $self->_keys_relationships )
    } if $self->has_relationships;

    return $result;
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::Document::Builder::Resource - document builder - resource

=head1 VERSION

version 0.001002

=head1 SYNOPSIS

    use PONAPI::Document::Builder::Resource;

    PONAPI::Document::Builder::Resource->new(
        id   => $id,
        type => $type,
    );

=head1 DESCRIPTION

C<PONAPI::Document::Builder::Resource> is used internally by
C<PONAPI::Document> to build C<{json:api}> documents.  Generally,
these will be created by C<< PONAPI::Document->add_resources >>, which
will return an object that you can call C<add_relationship>,
C<add_attributes>, and others on.

=head1 METHODS

=over

=item * new( id => $id, type => $type, parent => $parent )

Create a new object. C<id> and C<type> are mandatory.

Parent is assigned by C<< PONAPI::Document->add_resources >>,
so you don't need to specify it.

=item * id

Returns the id of this object.

=item * type

Returns the type of this object.

=item * add_attributes( $attr_name => $value, ... )

Adds the specified attributes to the object.

=item * add_relationship( $relationship_name => $resource, $is_a_collection)

Adds C<$resource> to the C<$relationship_name> relationship for this
object.  Will create the relationship if it doesn't already exist.

Note that trying to add multiple resources when C<$is_a_collection> is false
will result in an error.

=item * add_links( $link_name => $url, ... )

See L<PONAPI::Document/add_links>.

=item * add_self_link

See L<PONAPI::Document/add_self_link>.

=item * add_meta

See L<PONAPI::Document/add_meta>.

=item * parent

See L<PONAPI::Document/parent>.

=item * find_root

See L<PONAPI::Document/find_root>.

=item * is_root

See L<PONAPI::Document/is_root>.

=back

=cut

=head1 AUTHORS

=over 4

=item *

Mickey Nasriachi <mickey@cpan.org>

=item *

Stevan Little <stevan@cpan.org>

=item *

Brian Fraser <hugmeir@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Mickey Nasriachi, Stevan Little, Brian Fraser.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
