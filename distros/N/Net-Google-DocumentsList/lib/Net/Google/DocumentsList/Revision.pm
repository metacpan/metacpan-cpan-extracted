package Net::Google::DocumentsList::Revision;
use Any::Moose;
use Net::Google::DocumentsList::Types;
use Net::Google::DataAPI;
use XML::Atom::Util qw(first);
use String::CamelCase qw(camelize);
with 'Net::Google::DocumentsList::Role::EntryWithoutEtag';

entry_has 'updated' => ( 
    is => 'ro',
    isa => 'Net::Google::DocumentsList::Types::DateTime',
    tagname => 'updated',
    coerce => 1,
);

feedurl item => (
    is => 'ro',
    as_content_src => 1,
    entry_class => 'Net::Google::DocumentsList::Item',
);

has 'kind' => (is => 'ro', isa => 'Str', default => 'revision');

for my $attr (qw(publish publish_auto publish_outside_domain)) {
    my $tag = lcfirst camelize($attr);
    entry_has $attr => (
        is => 'rw',
        isa => 'Bool',
        default => sub {0},
        from_atom => sub {
            my ($self, $atom) = @_;
            my $elem = first($atom->elem, $self->ns('docs')->{uri}, $tag) or return 0;
            return $elem->getAttribute('value') eq "true" ? 1 : 0;
        },
        to_atom => sub {
            my ($self, $atom) = @_;
            $atom->set($self->ns('docs'),$tag, '', {value => $self->$attr ? "true" : "false"});
        }
    );
}

entry_has publish_url => (
    is => 'ro',
    from_atom => sub {
        my ($self, $atom) = @_;
        warn $atom->as_xml;
        warn $_->href for $atom->link;
        my ($url) = grep {
            $_->rel eq 'http://schemas.google.com/docs/2007#publish'
        } $atom->link or return;
        return $url->href;
    }
);

with 'Net::Google::DocumentsList::Role::Exportable';

__PACKAGE__->meta->make_immutable;

no Any::Moose;

1;
__END__

=head1 NAME

Net::Google::DocumentsList::Revision - revision object for Google Documents List Data API

=head1 SYNOPSIS

  use Net::Google::DocumentsList;
  
  my $client = Net::Google::DocumentsList->new(
      username => 'myname@gmail.com',
      password => 'p4$$w0rd'
  );
  
  # taking one document
  my $doc = $client->item;
  
  # getting revisions
  my @revisions = $doc->revisions;
  
  for my $rev (@revisions) {
      # checking revision updated time
      if ( $rev->updated < DateTime->now->subtract(days => 1) ) {
      # download a revision
      $rev->export(
          {
              file => 'backup.txt',
              format => 'txt',
          }
      );
      last;
  }

=head1 DESCRIPTION

This module represents revision object for Google Documents List Data API

=head1 METHODS

=head2 export ( implemented in L<Net::Google::DocumentsList::Role::Exportable> )

downloads the revision.

=head1 ATTRIBUTES

=head2 publish

sets and gets whether if this revision is published or not.

=head2 publish_auto

sets and gets whether if new revision will be published automatically or not.

=head2 publish_outside_domain

sets and gets whether if this revision will be published to outside of the Google Apps domain.

=head2 publish_url

the published URL for this document. THIS DOES NOT WORK FOR NOW (2010 NOV 28)

=head2 updated

=head1 AUTHOR

Noubo Danjou E<lt>danjou@soffritto.orgE<gt>

=head1 SEE ALSO

L<XML::Atom>

L<Net::Google::DataAPI>

L<Net::Google::DocumentsList::Role::Exportable>

L<http://code.google.com/apis/documents/docs/3.0/developers_guide_protocol.html>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
