# ABSTRACT: document builder - relationship
package PONAPI::Document::Builder::Relationship;

use Moose;

use PONAPI::Document::Builder::Resource::Identifier;

with 'PONAPI::Document::Builder',
     'PONAPI::Document::Builder::Role::HasLinksBuilder',
     'PONAPI::Document::Builder::Role::HasMeta';

has name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has _resource_id_builders => (
    init_arg  => undef,
    traits    => [ 'Array' ],
    is        => 'ro',
    isa       => 'ArrayRef[ PONAPI::Document::Builder::Resource::Identifier ]',
    lazy      => 1,
    default   => sub { +[] },
    predicate => '_has_resource_id_builders',
    handles   => {
        '_num_resource_id_builders' => 'count',
        # private ...
        '_add_resource_id_builder'  => 'push',
        '_get_resource_id_builder'  => 'get',
    }
);

has collection => (
    is  => 'ro',
    isa => 'Bool',
);

sub has_resource {
    my $self = $_[0];
    $self->_has_resource_id_builders && $self->_num_resource_id_builders > 0;
}

sub has_resources {
    my $self = $_[0];
    $self->_has_resource_id_builders && $self->_num_resource_id_builders > 1;
}

sub add_resource {
    my ( $self, $resource ) = @_;
    my $b = PONAPI::Document::Builder::Resource::Identifier->new( parent => $self, %$resource );
    $b->add_meta( %{ $resource->{meta} } ) if $resource->{meta};
    $self->_add_resource_id_builder( $b );
}

sub add_self_link    { $_[0]->_add_relationship_link('self')    }
sub add_related_link { $_[0]->_add_relationship_link('related') }

sub _add_relationship_link {
    my ( $self, $key ) = @_;
    my $rec = $self->parent->build;

    $self->links_builder->add_link(
        $key => $self->find_root->req_base
              . $rec->{type}
              . '/' . $rec->{id}
              . ( $key eq 'self' ? '/relationships' : '' )
              . '/' . $self->name
    );

    return $self;
}

sub build {
    my $self   = $_[0];
    my $result = {};

    if ( $self->collection || $self->has_resources ) {
        # if it is a collection, then
        # call build on each one ...
        $result->{data} = [ map { $_->build } @{ $self->_resource_id_builders } ];
    }
    else {
        # if it is a single resource,
        # just use that one
        $result->{data} = $self->_get_resource_id_builder(0)->build;
    }

    $result->{links} = $self->links_builder->build if $self->has_links_builder;
    $result->{meta}  = $self->_meta                if $self->has_meta;

    return $result;
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::Document::Builder::Relationship - document builder - relationship

=head1 VERSION

version 0.001002

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
