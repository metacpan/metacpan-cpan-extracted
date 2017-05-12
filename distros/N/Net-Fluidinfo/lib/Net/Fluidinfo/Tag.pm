package Net::Fluidinfo::Tag;
use Moose;
extends 'Net::Fluidinfo::Base';

use Net::Fluidinfo::Namespace;

has description => (is => 'rw', isa => 'Str');
has indexed     => (is => 'ro', isa => 'Bool', required => 1);
has namespace   => (is => 'ro', isa => 'Net::Fluidinfo::Namespace', lazy_build => 1);

with 'Net::Fluidinfo::HasObject', 'Net::Fluidinfo::HasPath';

our %FULL_GET_FLAGS = (
    description => 1
);

sub _build_namespace {
    # TODO: add croaks for dependencies
    my $self = shift;
    Net::Fluidinfo::Namespace->get(
        $self->fin,
        $self->path_of_parent,
        %Net::Fluidinfo::Namespace::FULL_GET_FLAGS
    );
}

sub parent {
    shift->namespace;
}

sub create {
    my $self = shift;
    
    my $payload = $self->json->encode({
        description => $self->description,
        indexed     => $self->as_json_boolean($self->indexed),
        name        => $self->name
    });
    
    $self->fin->post(
        path       => $self->abs_path('tags', $self->path_of_parent),
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
    $fin->get(
        path       => $class->abs_path('tags', $path),
        query      => \%opts,
        headers    => $fin->accept_header_for_json,
        on_success => sub {
            my $response = shift;
            my $h = $class->json->decode($response->content);
            my $t = $class->new(fin => $fin, path => $path, %$h);
            $t->_set_object_id($h->{id});
            $t;            
        }
    );
}

sub update {
    my $self = shift;

    my $payload = $self->json->encode({description => $self->description});
    $self->fin->put(
        path    => $self->abs_path('tags', $self->path),
        headers => $self->fin->headers_for_json,
        payload => $payload
    );
}

sub delete {
    my $self = shift;

    $self->fin->delete(path => $self->abs_path('tags', $self->path));
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::Fluidinfo::Tag - Fluidinfo tags

=head1 SYNOPSIS

 use Net::Fluidinfo::Tag;

 # create
 $tag = Net::Fluidinfo::Tag->new(
    fin         => $fin,
    description => $description,
    indexed     => 1,
    path        => $path
 );
 $tag->create;

 # get, optionally fetching descrition
 $tag = Net::Fluidinfo::Tag->get($fin, $path, description => 1);
 $tag->namespace;

 # update
 $tag->description($new_description);
 $tag->update;

 # delete
 $tag->delete;
 
=head1 DESCRIPTION

C<Net::Fluidinfo::Tag> models Fluidinfo tags.

=head1 USAGE

=head2 Inheritance

C<Net::Fluidinfo::Tag> is a subclass of L<Net::Fluidinfo::Base>.

=head2 Roles

C<Net::Fluidinfo::Tag> consumes the roles L<Net::Fluidinfo::HasObject>, and L<Net::Fluidinfo::HasPath>.

=head2 Class methods

=over

=item Net::Fluidinfo::Tag->new(%attrs)

Constructs a new tag. The constructor accepts these parameters:

=over

=item fin (required)

An instance of Net::Fluidinfo.

=item description (optional)

A description of this tag.

=item indexed (required)

A flag that tells Fluidinfo whether this tag should be indexed. This attribute
mirrors the Fluidinfo API, but please note that Fluidinfo currently ignores
its value, nowadays all tags are indexed.

=item namespace (optional, but dependent)

The namespace you want to put this tag into. An instance of L<Net::Fluidinfo::Namespace>
representing an existing namespace in Fluidinfo.

=item name (optional, but dependent)

The name of the tag, which is the rightmost segment of its path.
The name of "fxn/rating" is "rating".

=item path (optional, but dependent)

The path of the tag, for example "fxn/rating".

=back

The C<description> attribute is not required because Fluidinfo allows fetching tags
without their description. It must be defined when creating or updating tags though.

The attributes C<namespace>, C<path>, and C<name> are mutually dependent. Ultimately
tag creation has to be able to send the path of the namespace and the name of the tag
to Fluidinfo. So you can set C<namespace> and C<name>, or just C<path>.

This constructor is only useful for creating new tags in Fluidinfo. Existing tags are
fetched with C<get>.

=item Net::Fluidinfo::Tag->get($fin, $path, %opts)

Retrieves the tag with path C<$path> from Fluidinfo. Options are:

=over

=item description (optional, default false)

Tells C<get> whether you want to fetch the description.

=back

C<Net::Fluidinfo> provides a convenience shortcut for this method.

=item Net::Fluidinfo::Tag->equal_paths($path1, $path2)

Determines whether C<$path1> and C<$path2> are the same in Fluidinfo. The basic
rule is that the username fragment is case-insensitive, and the rest is not.

=back

=head2 Instance Methods

=over

=item $tag->create

Creates the tag in Fluidinfo. Please note that tags are created on the
fly by Fluidinfo if they do not exist.

Creating a tag by hand may be useful for example if you want to change
the inherited permissions right away. That may be interesting if you
are going to store sensitive data that would be by default readable.
Other than that, it is recommended that you let Fluidinfo create tags
as needed.

=item $tag->update

Updates the tag in Fluidinfo. Only the description can be modified.

=item $tag->delete

Deletes the tag in Fluidinfo.

=item $tag->description

=item $tag->description($description)

Gets/sets the description of the tag.

Note that you need to set the C<description> flag when you fetch a
tag for this attribute to be initialized.

=item $tag->indexed

A flag, indicates whether this tag is indexed in Fluidinfo.

This predicate mirrors the Fluidinfo API. Nowadays all tags are indexed,
so this predicate returns always true.

=item $tag->namespace

The namespace the tag belongs to, as an instance of L<Net::Fluidinfo::Namespace>.
This attribute is lazy loaded.

=item $tag->name

The name of the tag.

=item $tag->path

The path of the tag.

=back

=head1 FLUIDINFO DOCUMENTATION

=over

=item Fluidinfo high-level description

L<http://doc.fluidinfo.com/fluidDB/tags.html>

=item Fluidinfo API documentation

L<http://doc.fluidinfo.com/fluidDB/api/namespaces-and-tags.html>

=item Fluidinfo API specification

L<http://api.fluidinfo.com/fluidDB/api/*/tags/*>

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
