package Net::Fluidinfo::Namespace;
use Moose;
extends 'Net::Fluidinfo::Base';

has description     => (is => 'rw', isa => 'Str');
has parent          => (is => 'ro', isa => 'Maybe[Net::Fluidinfo::Namespace]', lazy_build => 1);
has namespace_names => (is => 'ro', isa => 'ArrayRef[Str]', writer => '_set_namespace_names');
has tag_names       => (is => 'ro', isa => 'ArrayRef[Str]', writer => '_set_tag_names');

with 'Net::Fluidinfo::HasObject', 'Net::Fluidinfo::HasPath';

our %FULL_GET_FLAGS = (
    description     => 1,
    namespace_names => 1,
    tag_names       => 1
);

sub _build_parent {
    # TODO: add croaks for dependencies
    my $self = shift;
    if ($self->path_of_parent ne "") {
        __PACKAGE__->get($self->fin, $self->path_of_parent, %FULL_GET_FLAGS);
    } else {
        undef;
    }
}

# Normal usage is to set description and path of self.
sub create {
    my $self = shift;

    my $payload = $self->json->encode({description => $self->description, name => $self->name});
    $self->fin->post(
        path       => $self->abs_path('namespaces', $self->path_of_parent),
        headers    => $self->fin->headers_for_json,
        payload    => $payload,
        on_success => sub {
            my $response = shift;
            my $h = $self->json->decode($response->content);
            $self->_set_object_id($h->{id});
        }
    );
}

sub get {
    my ($class, $fin, $path, %opts) = @_;

    $opts{returnDescription} = $class->true if delete $opts{description};
    $opts{returnNamespaces}  = $class->true if delete $opts{namespace_names};
    $opts{returnTags}        = $class->true if delete $opts{tag_names};
    
    $fin->get(
        path       => $class->abs_path('namespaces', $path),
        query      => \%opts,
        headers    => $fin->accept_header_for_json,
        on_success => sub {
            my $response = shift;
            my $h = $class->json->decode($response->content);
            my $ns = $class->new(fin => $fin, path => $path);
            $ns->_set_object_id($h->{id});
            $ns->description($h->{description})             if $opts{returnDescription};
            $ns->_set_namespace_names($h->{namespaceNames}) if $opts{returnNamespaces};
            $ns->_set_tag_names($h->{tagNames})             if $opts{returnTags};
            $ns;            
        }
    );
}

# Normal usage is to set description and path of self.
sub update {
    my $self = shift;

    my $payload = $self->json->encode({description => $self->description});
    $self->fin->put(
        path    => $self->abs_path('namespaces', $self->path),
        headers => $self->fin->headers_for_json,
        payload => $payload
    );
}

sub delete {
    my $self = shift;

    $self->fin->delete(path => $self->abs_path('namespaces', $self->path));
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::Fluidinfo::Namespace - Fluidinfo namespaces

=head1 SYNOPSIS

 use Net::Fluidinfo::Namespace;

 # create
 $ns = Net::Fluidinfo::Namespace->new(
    fin         => $fin,
    description => $description,
    path        => $path
 );
 $ns->create;

 # get, optionally fetching descrition
 $ns = Net::Fluidinfo::Namespace->get($fin, $path, description => 1);
 $ns->parent;
 
 # update
 $ns->description($new_description);
 $ns->update;

 # delete
 $ns->delete;
 
=head1 DESCRIPTION

C<Net::Fluidinfo::Namespace> models Fluidinfo namespaces.

=head1 USAGE

=head2 Inheritance

C<Net::Fluidinfo::Namespace> is a subclass of L<Net::Fluidinfo::Base>.

=head2 Roles

C<Net::Fluidinfo::Namespace> consumes the roles L<Net::Fluidinfo::HasObject>, and L<Net::Fluidinfo::HasPath>.

=head2 Class methods

=over

=item Net::Fluidinfo::Namespace->new(%attrs)

Constructs a new namespace. The constructor accepts these parameters:

=over

=item fin (required)

An instance of Net::Fluidinfo.

=item description (optional)

A description of this namespace.

=item parent (optional, but dependent)

The namespace you want to put this namespace into. An instance of L<Net::Fluidinfo::Namespace>
representing an existing namespace in Fluidinfo.

=item name (optional, but dependent)

The name of the namespace, which is the rightmost segment of its path.
The name of "fxn/perl" is "perl".

=item path (optional, but dependent)

The path of the namespace, for example "fxn/perl".

=back

The C<description> attribute is not required because Fluidinfo allows fetching namespaces
without their description. It must be defined when creating or updating namespaces though.

The attributes C<parent>, C<path>, and C<name> are mutually dependent. Ultimately
namespace creation has to be able to send the path of the parent and the name of the
namespace to Fluidinfo. So you can set C<parent> and C<name>, or just C<path>.

This constructor is only useful for creating new namespaces in Fluidinfo. Existing
namespaces are fetched with C<get>.

=item Net::Fluidinfo::Namespace->get($fin, $path, %opts)

Retrieves the namespace with path C<$path> from Fluidinfo. Options are:

=over

=item description (optional, default false)

Tells C<get> whether you want to fetch the description.

=item namespace_names (optional, default false)

Tells C<get> whether you want to fetch the names of child namespaces.

=item tag_names (optional, default false)

Tells C<get> whether you want to fetch the names of child tags.

=back

C<Net::Fluidinfo> provides a convenience shortcut for this method.

=back

=head2 Instance Methods

=over

=item $ns->create

Creates the namespace in Fluidinfo. Please note that namespaces are
created on the fly by Fluidinfo if they do not exist.

Creating a namespace by hand may be useful for example if you want
to change the inherited permissions right away. Other than that, it
is recommended that you let Fluidinfo create namespaces as needed.

=item $ns->update

Updates the namespace in Fluidinfo. Only the description can be modified.

=item $ns->delete

Deletes the namespace in Fluidinfo.

=item $ns->description

=item $ns->description($description)

Gets/sets the description of the namespace.

Note that you need to set the C<description> flag when you fetch a
namespace for this attribute to be initialized.

=item $ns->namespace_names

Returns the names of the child namespaces as a (possibly empty) arrayref of
strings.

Note that you need to set the C<namespace_names> flag when you fetch a
namespace for this attribute to be initialized.

=item $ns->tag_names

Returns the names of the child tags as a (possibly empty) arrayref of strings.

Note that you need to set the C<tag_names> flag when you fetch a namespace for this
attribute to initialized.

=item $ns->parent

The parent of the namespace, as an instance of L<Net::Fluidinfo::Namespace>.
This attribute is lazy loaded.

=item $ns->name

The name of the namespace.

=item $ns->path

The path of the namespace.

=back

=head1 FLUIDINFO DOCUMENTATION

=over

=item Fluidinfo high-level description

L<http://doc.fluidinfo.com/fluidDB/namespaces.html>

=item Fluidinfo API documentation

L<http://doc.fluidinfo.com/fluidDB/api/namespaces-and-tags.html>

=item Fluidinfo API specification

L<http://api.fluidinfo.com/fluidDB/api/*/namespaces/*>

=back

=head1 AUTHOR

Xavier Noria (FXN), E<lt>fxn@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2012 Xavier Noria

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
