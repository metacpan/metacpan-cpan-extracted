package POE::Component::Client::CouchDB::Database;
use Moose;
use JSON;

our $VERSION = 0.05;

has couch => (
  is       => 'ro',
  isa      => 'POE::Component::Client::CouchDB',
  required => 1,
);

has name => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

sub call {
  my ($self, $method, $path, @rest) = @_;
  $self->couch->call($method, join('/', $self->name, $path), @rest);
}

sub all_docs {
  my ($self, @opt) = @_;
  $self->call(GET => _all_docs => @opt);
}

sub get {
  my ($self, $id, @opt) = @_;
  $self->call(GET => $id, @opt);
}

sub get_revision {
  my ($self, $id, $revision, @opt) = @_;
  $self->call(GET => $id, query => {rev => $revision}, @opt);
}

sub get_revinfo {
  my ($self, $id, @opt) = @_;
  $self->call(GET => $id, query => {revs => JSON::true}, @opt);
}

sub create {
  my ($self, $doc, @opt) = @_;
  $self->call(POST => q(), content => $doc, @opt);
}

sub create_named {
  my ($self, $id, $doc, @opt) = @_;
  $self->call(PUT => $id, content => $doc, @opt);
}

__PACKAGE__->meta->add_method(update => \&create_named);

sub delete : method {
  my ($self, $id, $revision, @opt) = @_;
  $self->call(DELETE => $id, query => {rev => $revision}, @opt);
}

sub attachment {
  my ($self, $id, $name, @opt) = @_;
  $self->call(GET => "$id/$name", response_cooker => undef, @opt);
}

sub create_design {
  my ($self, $id, $doc, @opt) = @_;
  $self->create_named("_views/$id", content => $doc, @opt);
}

__PACKAGE__->meta->add_method(update_design => \&create_design);

sub delete_design {
  my ($self, $id, $revision, @opt) = @_;
  $self->delete("_views/$id", query => {rev => $revision}, @opt);
}

sub view {
  my ($self, $design, $name, @opt) = @_;
  $self->get("_views/$design/$name", @opt);
}

sub temp_view {
  my ($self, $viewfn, @opt) = @_;
  $self->call(POST => _temp_view => @opt,
    request_cooker => undef,
    headers        => [
      'Content-Type'   => 'text/javascript',
      'Content-Length' => bytes::length($viewfn),
    ],
    content        => $viewfn,
  );
}

1;

__END__

=head1 NAME

POE::Component::Client::CouchDB::Database 

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

This class is for easy interaction with a single CouchDB database.  As with
L<POE::Component::Client::CouchDB>, everything goes through the
L<call|/METHODS> interface, which you can use to do anything fancy not
provided by the other helpers.

=head1 ATTRIBUTES

=over 4

=item couch

The <POE::Component::Client::CouchDB> object that this database lives on.
Required.

=item name

The name of the database to interact with.  Required.

=back

=head1 METHODS

Where a I<doc> is specified in the methods below, it means a simple perl HASH
in the structure described in by the CouchDB docs.

=over 4

=item call I<method, path, ...>

This is L<call|POE::Component::Client::REST::JSON/METHODS> with the url and
database parts filled in - use a path such as "_all_docs" instead.  You 
shouldn't need to use this directly, so don't.

=item all_docs <query_opts>

=item get I<id>

=item get_revision I<id, revision>

=item get_revinfo I<id>

=item create I<doc>

=item create_named I<id, doc>

=item update I<id, doc>

=item delete I<id>

=item attachment I<id, name>

=item create_design I<id, doc>

=item update_design I<id, doc>

=item delete_design I<id>

=item view I<design, name>

=item temp_view I<viewfn>

These all do what you would expect according to the CouchDB documentation.
See L<http://wiki.apache.org/couchdb/HttpDocumentApi>.

=back

=head1 AUTHOR

Paul Driver, C<< <frodwith at cpan.org> >>

=head1 BUGS

Probably.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Paul Driver

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
