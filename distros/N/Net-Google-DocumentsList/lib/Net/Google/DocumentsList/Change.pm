package Net::Google::DocumentsList::Change;
use Any::Moose;
use Net::Google::DataAPI;
with 'Net::Google::DataAPI::Role::Entry';
use XML::Atom::Util qw(first);

entry_has 'resource_id' => ( tagname => 'resourceId', ns => 'gd', is => 'ro' );
entry_has 'updated' => ( 
    is => 'ro',
    isa => 'Net::Google::DocumentsList::Types::DateTime',
    tagname => 'updated',
    coerce => 1,
);
entry_has 'changestamp' => (is => 'ro', isa => 'Int',
    from_atom => sub {
        my ($self, $atom) = @_;
        my $elem = first($atom->elem, $self->ns('docs')->{uri}, 'changestamp') or return;
        $elem->getAttribute('value');
    }
);
entry_has deleted => ( is => 'ro', isa => 'Bool',
    from_atom => sub {
        my ($self, $atom) = @_;
        first($atom->elem, $self->ns('gd')->{uri}, 'deleted') ? 1 : 0;
    },
);
entry_has removed => ( is => 'ro', isa => 'Bool',
    from_atom => sub {
        my ($self, $atom) = @_;
        first($atom->elem, $self->ns('docs')->{uri}, 'removed') ? 1 : 0;
    },
);

sub item {
    my $self = shift;
    return $self->service->item({resource_id => $self->resource_id});
}

__PACKAGE__->meta->make_immutable;

no Any::Moose;

1;
__END__

=head1 NAME

Net::Google::DocumentsList::Change - change object for Google Documents List Data API

=head1 SYNOPSIS

  use Net::Google::DocumentsList;
  
  my $client = Net::Google::DocumentsList->new(
      username => 'myname@gmail.com',
      password => 'p4$$w0rd'
  );

  my @changes = $client->changes;

=head1 DESCRIPTION

This module represents change object for Google Documents List Data API

=head1 ATTRIBUTES

=head2 updated

=head2 largest_changestamp

=head2 quota_bytes_total

=head2 quota_bytes_used

=head2 quota_bytes_used_in_trash

=head2 max_upload_size

=head2 import_format

=head2 export_format

=head1 AUTHOR

Noubo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=head1 SEE ALSO

L<XML::Atom>

L<Net::Google::DataAPI>

L<https://developers.google.com/google-apps/documents-list/>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
