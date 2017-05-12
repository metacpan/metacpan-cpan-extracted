package Net::Fluidinfo::Object;
use Moose;
extends 'Net::Fluidinfo::Base';

use Carp;
use Scalar::Util qw(blessed);
use Net::Fluidinfo::Tag;
use Net::Fluidinfo::Value;
use Net::Fluidinfo::Value::Native;
use Net::Fluidinfo::Value::NonNative;
use Net::Fluidinfo::Value::Null;
use Net::Fluidinfo::Value::Boolean;
use Net::Fluidinfo::Value::Integer;
use Net::Fluidinfo::Value::Float;
use Net::Fluidinfo::Value::String;
use Net::Fluidinfo::Value::ListOfStrings;

has id        => (is => 'ro', isa => 'Str', writer => '_set_id', predicate => 'has_id');
has about     => (is => 'rw', isa => 'Str', predicate => 'has_about');
has tag_paths => (is => 'ro', isa => 'ArrayRef[Str]', writer => '_set_tag_paths', default => sub { [] });

sub create {
    my $self = shift;

    my $payload = $self->has_about ? $self->json->encode({about => $self->about}) : undef;
    $self->fin->post(
        path       => $self->abs_path('objects'),
        headers    => $self->fin->headers_for_json,
        payload    => $payload,
        on_success => sub {
            my $response = shift;
            my $h = $self->json->decode($response->content);
            $self->_set_id($h->{id});
            # Unset tag paths to force fetching the about tag.
            $self->_set_tag_paths(['fluiddb/about']) if $self->has_about;
            1;
        }
    );
}

sub get {
    print STDERR "get has been deprecated and will be removed, please use get_by_id instead\n";
    &get_by_id;
}

sub get_by_id {
    my ($class, $fin, $id, %opts) = @_;

    $opts{showAbout} = $class->true if delete $opts{about};
    $fin->get(
        path       => $class->abs_path('objects', $id),
        query      => \%opts,
        headers    => $fin->accept_header_for_json,
        on_success => sub {
            my $response = shift;
            my $h = $class->json->decode($response->content);
            my $o = $class->new(fin => $fin, %$h);
            $o->_set_id($id);
            $o->_set_tag_paths($h->{tagPaths});
            $o;
        }
    );
}

sub get_by_about {
    my ($class, $fin, $about) = @_;
    $fin->get(
        path       => $class->abs_path('/about', $about),
        headers    => $fin->accept_header_for_json,
        on_success => sub {
            my $response = shift;
            my $h = $class->json->decode($response->content);
            my $o = $class->new(fin => $fin);
            $o->_set_id($h->{id});
            $o->_set_tag_paths($h->{tagPaths});
            $o->about($about);
            $o;
        }
    );
}

sub search {
    my ($class, $fin, $query) = @_;

    my %params = (query => $query);
    $fin->get(
        path       => '/objects',
        query      => \%params,
        headers    => $fin->accept_header_for_json,
        on_success => sub {
            my $response = shift;
            @{$class->json->decode($response->content)->{ids}};
        }
    );
}

sub tag {
    my ($self, $tag_or_tag_path, @rest) = @_;

    my $tag_path = $self->get_path_from_string_or_has_path($tag_or_tag_path);
    if (@rest < 2) {
        $self->tag_fin_value_or_scalar($tag_path, @rest);
    } elsif (@rest == 2) {
        $self->tag_fin_value_or_scalar_with_options($tag_path, @rest);
    } else {
        croak "invalid call to Object->tag()";
    }
}

sub has_tag {
    my ($class, $fin, $object_id, $tag_or_tag_path) = @_;

    my $tag_path = $class->get_path_from_string_or_has_path($tag_or_tag_path);
    $fin->head(
        path       => $class->abs_path('/objects', $object_id, $tag_path),
        on_success => sub { 1 },
        on_failure => sub {
            my $response = shift;

            if ($response->code == 404) {
                0;
            } else {
                # Can be a 401 if permissions disallow this test. Do this as we
                # do elsewhere until we get proper support for failures.
                print STDERR $response->as_string;
                0;
            }
        }
    );
}

sub tag_fin_value_or_scalar {
    my ($self, $tag_path, $value) = @_;

    if (defined $value) {
        if (ref $value) {
            if (ref $value eq 'ARRAY') {
                $value = Net::Fluidinfo::Value::ListOfStrings->new(value => $value);
            } elsif (blessed $value && $value->isa('Net::Fluidinfo::Value')) {
                # fine, do nothing
            } else {
                croak "$value is not undef nor a valid reference for tagging\n";
            }
        } else {
            croak "$value is not undef nor a valid reference for tagging\n";
        }
    } else {
        $value = Net::Fluidinfo::Value::Null->new;
    }
    $self->tag_fin_value($tag_path, $value);
}

sub tag_fin_value_or_scalar_with_options {
    my ($self, $tag_path, $type, $value) = @_;

    my $native_type = Net::Fluidinfo::Value::Native->type_from_alias($type);
    $value = $native_type ?
             $native_type->new(value => $value) :
             Net::Fluidinfo::Value::NonNative->new(value => $value, mime_type => $type);
    $self->tag_fin_value($tag_path, $value);
}

sub tag_fin_value {
    my ($self, $tag_path, $value) = @_;

    my $status = $self->fin->put(
        path    => $self->abs_path('objects', $self->id, $tag_path),
        headers => {'Content-Type' => $value->mime_type},
        payload => $value->payload
    );

    if ($status && !$self->is_tag_path_present($tag_path)) {
        push @{$self->tag_paths}, $tag_path;
    }

    $status;
}

sub value {
    my ($self, $tag_or_tag_path, @rest) = @_;
    my $list_context = wantarray;

    my $tag_path = $self->get_path_from_string_or_has_path($tag_or_tag_path);
    $self->fin->get(
        path       => $self->abs_path('objects', $self->id, $tag_path),
        on_success => sub {
            my $response = shift;

            my $mime_type    = $response->headers->header('Content-Type');
            my $fin_type     = $response->headers->header('X-Fluiddb-Type');
            my $content      = $response->content;
            my $value_object = Net::Fluidinfo::Value->new_from_types_and_content($mime_type, $fin_type, $content);

            $list_context ? ($value_object->type, $value_object->value) : $value_object->value;
        }
    );
}

sub is_tag_path_present {
    my ($self, $tag_path) = @_;

    foreach my $known_tag_path (@{$self->tag_paths}) {
        return 1 if Net::Fluidinfo::HasPath->equal_paths($tag_path, $known_tag_path);
    }
    return 0;
}

sub untag {
    my ($self, $tag_or_tag_path) = @_;

    my $tag_path = $self->get_path_from_string_or_has_path($tag_or_tag_path);
    $self->fin->delete(
        path       => $self->abs_path('objects', $self->id, $tag_path),
        on_success => sub {
            my @rest = grep { !Net::Fluidinfo::HasPath->equal_paths($tag_path, $_) } @{$self->tag_paths};
            $self->_set_tag_paths(\@rest);
            1;
        }
    );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::Fluidinfo::Object - Fluidinfo objects

=head1 SYNOPSIS

 use Net::Fluidinfo::Object;

 # create, with optional about
 $object = Net::Fluidinfo::Object->new(
     fin   => $fin,
     about => $unique_about
 );
 $object->create;
 $object->id; # returns the object's ID in Fluidinfo

 # get by ID, optionally fetching about
 $object = Net::Fluidinfo::Object->get_by_id($fin, $id, about => 1);

 # get by about
 $object = Net::Fluidinfo::Object->get_by_about($fin, $about);

 # tag
 $object->tag("fxn/likes");
 $object->tag("fxn/rating", integer => 10);
 $object->tag("fxn/avatar", 'image/png' => $image);

 # retrieve a tag value
 $value = $object->value("fxn/rating");

 # retrieve a tag value and its type
 ($type, $value) = $object->value("fxn/rating");

 # remove a tag
 $object->untag("fxn/rating");

 # search
 @ids = Net::Fluidinfo::Object->search($fin, "has fxn/rating");

=head1 DESCRIPTION

C<Net::Fluidinfo::Object> models Fluidinfo objects.

=head1 USAGE

=head2 Inheritance

C<Net::Fluidinfo::Object> is a subclass of L<Net::Fluidinfo::Base>.

=head2 Class methods

=over

=item Net::Fluidinfo::Object->new(%attrs)

Constructs a new object. The constructor accepts these parameters:

=over

=item fin (required)

An instance of Net::Fluidinfo.

=item about (optional)

A string, if any.

=back

This constructor is only useful for creating new objects in Fluidinfo.
Already existing objects are fetched with C<get_by_id> or C<get_by_about>:

=item Net::Fluidinfo::Object->get_by_id($fin, $id, %opts)

Retrieves the object with ID C<$id> from Fluidinfo. Options are:

=over

=item about (optional, default false)

Tells C<get> whether you want to get the about attribute of the object.

If about is not fetched C<has_about> will be false even if the object
has an about attribute in Fluidinfo.

=back

C<Net::Fluidinfo> provides a convenience shortcut for this method.

=item Net::Fluidinfo::Object->get_by_about($fin, $about)

Retrieves the object with about C<$about> from Fluidinfo.

C<Net::Fluidinfo> provides a convenience shortcut for this method.

=item Net::Fluidinfo::Object->search($fin, $query)

Performs the query C<$query> and returns a (possibly empty) array of strings with
the IDs of the macthing objects.

C<Net::Fluidinfo> provides a convenience shortcut for this method.

=item Net::Fluidinfo::Object->has_tag($fin, $object_id, $tag_or_tag_path)

When you retrieve an object from Fluidinfo the instance has the paths
of its tags as an attribute. But if you only have an object ID and
are interested in checking whether the corresponding object has been
tagged with a certain tag, this predicate is cheaper than fetching
the object.

You can pass either a L<Net::Fluidinfo::Tag> instance or a tag path
in the rightmost argument.

=back

=head2 Instance Methods

=over

=item $object->create

Creates the object in Fluidinfo.

=item $object->id

Returns the UUID of the object, or C<undef> if it is new.

=item $object->has_id

Predicate to test whether the object has an ID.

=item $object->about

=item $object->about($about)

Gets/sets the about attribute. About can't be modified in existing
objects, the setter is only useful for new objects.

Note that you need to set the C<about> flag when you fetch an object
for this attribute to be initialized.

=item $object->has_about

Says whether the object has an about attribute.

Note that you need to set the C<about> flag when you fetch an object
for this attribute to be initialized.

=item $object->tag_paths

Returns the paths of the existing tags on the object as a (possibly
empty) arrayref of strings.

=item $object->tag($tag_or_tag_path)

=item $object->tag($tag_or_tag_path, $value)

=item $object->tag($tag_or_tag_path, $type => $value)

Tags an object.

You can pass either a L<Net::Fluidinfo::Tag> instance or a tag path
in the first argument.

=over

=item Native values

You need to specify the Fluidinfo type of native values using one of
"null", "boolean", "integer", "float", "string", or "list_of_strings":

    $object->tag("fxn/rating", integer => 7);

If C<$value> is C<undef> or an arrayref this is not required:

    $object->tag("fxn/tags");                    # type null (inferred)
    $object->tag("fxn/tags", undef);             # type null (inferred)
    $object->tag("fxn/tags", ["perl", "moose"]); # type list_of_strings (inferred)

The elements of arrayrefs are stringfied if needed to ensure we send
a list of strings.

=item Non-native values

To tag with a non-native value use a suitable MIME type for it:

    $object->tag("fxn/foaf", "application/rdf+xml" => $foaf);

=back

=item $object->value($tag_or_tag_path)

Gets the value of a tag on an object.

You can refer to the tag either with a L<Net::Fluidinfo::Tag> instance or a tag path.

This method returns the very value in scalar context:

    $value = $object->value("fxn/rating");

and also the type in list context:

    ($type, $value) = $object->value("fxn/rating");

For native values the type is one of "null", "boolean", "integer", "float",
"string", or "list_of_strings". For non-native values the type is their MIME type.

=back

=item $object->untag($tag_or_tag_path)

Untags an object.

=back

=head1 FLUIDINFO DOCUMENTATION

=over

=item Fluidinfo high-level description

L<http://doc.fluidinfo.com/fluidDB/objects.html>

=item Fluidinfo API documentation

L<http://doc.fluidinfo.com/fluidDB/api/objects.html>

=item Fluidinfo API specification

L<http://api.fluidinfo.com/fluidDB/api/*/objects/*>

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
