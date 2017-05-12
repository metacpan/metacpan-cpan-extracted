# ABSTRACT: document builder class
package PONAPI::Document::Builder::Document;

use Moose;

use PONAPI::Document::Builder::Resource;
use PONAPI::Document::Builder::Resource::Null;
use PONAPI::Document::Builder::Errors;

with 'PONAPI::Document::Builder',
     'PONAPI::Document::Builder::Role::HasLinksBuilder',
     'PONAPI::Document::Builder::Role::HasMeta',
     'PONAPI::Document::Builder::Role::HasPagination';

has version => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has status => (
    init_arg  => undef,
    is        => 'ro',
    isa       => 'Num',
    default   => sub { 200 },
    writer    => 'set_status',
    lazy      => 1,
    predicate => 'has_status',
);

has req_base => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { '/' },
);

has req_path => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { '/' },
);

has is_collection => (
    is      => 'ro',
    writer  => '_set_is_collection',
    isa     => 'Bool',
    default => 0
);

has _included => (
    init_arg => undef,
    traits   => [ 'Array' ],
    is       => 'ro',
    isa      => 'ArrayRef[ PONAPI::Document::Builder::Resource ]',
    lazy     => 1,
    default  => sub { +[] },
    handles  => {
        'has_included'  => 'count',
        # private ...
        '_add_included' => 'push',
    }
);

has _resource_builders => (
    init_arg  => undef,
    traits    => [ 'Array' ],
    is        => 'ro',
    isa       => 'ArrayRef[ PONAPI::Document::Builder::Resource | PONAPI::Document::Builder::Resource::Null ]',
    lazy      => 1,
    default   => sub { +[] },
    predicate => 'has_resource_builders',
    handles   => {
        '_num_resource_builders' => 'count',
        # private ...
        '_add_resource_builder'  => 'push',
        '_get_resource_builder'  => 'get',
    }
);

has errors_builder => (
    init_arg  => undef,
    is        => 'ro',
    isa       => 'PONAPI::Document::Builder::Errors',
    lazy      => 1,
    predicate => 'has_errors_builder',
    builder   => '_build_errors_builder',
);

sub _build_errors_builder { PONAPI::Document::Builder::Errors->new( parent => $_[0] ) }

sub convert_to_collection { $_[0]->_set_is_collection(1) }

sub has_errors {
    my $self = shift;
    return $self->errors_builder->has_errors
        if $self->has_errors_builder and $self->errors_builder->has_errors;
    return 0;
}

sub has_resource {
    my $self = shift;
    $self->has_resource_builders && $self->_num_resource_builders > 0;
}

sub has_resources {
    my $self = shift;
    $self->has_resource_builders && $self->_num_resource_builders > 1;
}

sub add_resource {
    my ($self, %args) = @_;

    die 'Cannot add more then one resource unless the Document is in collection mode'
        if $self->has_resource && !$self->is_collection;

    my $builder = PONAPI::Document::Builder::Resource->new( %args, parent => $self );
    $self->_add_resource_builder( $builder );
    return $builder;
}

sub add_null_resource {
    my $self = shift;

    my $builder = PONAPI::Document::Builder::Resource::Null->new( parent => $self );
    $self->_add_resource_builder( $builder );
    return $builder;
}

sub add_included {
    my ($self, %args) = @_;
    my $builder = PONAPI::Document::Builder::Resource->new( parent => $self, %args );
    $self->_add_included( $builder );
    return $builder;
}

sub add_self_link {
    my $self = shift;
    $self->links_builder->add_link( self => $self->req_path );
    return $self;
}

sub build {
    my $self   = shift;
    my %args   = @_;
    my $result = +{ jsonapi => { version => $self->version } };

    if ( ! $self->has_errors_builder ) {
        $result->{meta}  = $self->_meta                if $self->has_meta;
        $result->{links} = $self->links_builder->build if $self->has_links_builder;

        if ( $self->has_resource_builders ) {
            if ( $self->is_collection ) {
                # if it is a collection, then
                # call build on each one ...
                $result->{data} = [ map { $_->build( %args ) } @{ $self->_resource_builders } ];
            }
            else {
                # if it is a single resource,
                # just use that one
                $result->{data} = $self->_get_resource_builder(0)->build( %args )
                    if $self->has_resource;
            }


            # http://jsonapi.org/format/#document-compound-documents
            # "A compound document MUST NOT include more than one resource
            # object for each type and id pair."
            # So in short, we need to check that we don't have any duplicates.
            if ( $self->has_included ) {
                my $included_builders = $self->_included;
                my (@included, %seen);
                foreach my $builder ( @$included_builders ) {
                    next if $seen{$builder->{type}}{$builder->{id}}++;
                    push @included, $builder->build( %args );
                }
                $result->{included} = \@included;
            }
        }
        else {
            if ( $self->is_collection ) {
                $result->{data} = [];
            }
            else {
                die "[PANIC] OH NOES, THIS SHOULD NEVER HAPPEN!!!!!"
                    if ! $self->has_meta;
            }
        }
    }

    if ( $self->has_errors_builder ) {
        my $errors = $self->errors_builder->build;
        if ( $errors ) {
            $_->{status} //= $self->status for @$errors;
        }
        return +{
            jsonapi => +{ version => $self->version },
            errors  => $errors,
        };
    }

    return $result;
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::Document::Builder::Document - document builder class

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
