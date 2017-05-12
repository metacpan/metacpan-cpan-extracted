package Net::Google::DocumentsList::Metadata;
use Any::Moose;
use Net::Google::DataAPI;
with 'Net::Google::DataAPI::Role::Entry';
use XML::Atom::Util qw(nodelist first);
use String::CamelCase ();

has 'kind' => (is => 'ro', isa => 'Str', default => 'metadata');
entry_has 'updated' => ( tagname => 'updated', is => 'ro' );
entry_has largest_changestamp => (
    is => 'ro',
    isa => 'Int',
    from_atom => sub {
        my ($self, $atom) = @_;
        my $elem = first($atom->elem, $self->ns('docs')->{uri}, 'largestChangestamp') or return;
        $elem->getAttribute('value');
    }
);
entry_has quota_bytes_total => (is => 'ro', isa => 'Int', tagname => 'quotaBytesTotal', ns => 'gd');
entry_has quota_bytes_used => (is => 'ro', isa => 'Int', tagname => 'quotaBytesUsed', ns => 'gd');
entry_has quota_bytes_used_in_trash => (is => 'ro', isa => 'Int', tagname => 'quotaBytesUsed', ns => 'gd');
entry_has max_upload_size => (is => 'ro', isa => 'HashRef',
    from_atom => sub {
        my ($self, $atom) = @_;
        +{ 
            map { $_->getAttribute('kind') => $_->textContent } 
            nodelist($atom->elem, $self->ns('docs')->{uri}, 'maxUploadSize')
        }
    },
);
for my $tag (qw(importFormat exportFormat)) {
    entry_has String::CamelCase::decamelize($tag) => (is => 'ro', isa => 'HashRef',
        from_atom => sub {
            my ($self, $atom) = @_;
            my $res = {};
            for my $node (nodelist($atom->elem, $self->ns('docs')->{uri}, $tag)) {
                my $source =  $node->getAttribute('source');
                my $target = $node->getAttribute('target');
                $res->{$source} ||= [];
                push @{$res->{$source}}, $target;
            }
            return $res;
        }
    );
}

__PACKAGE__->meta->make_immutable;

no Any::Moose;

1;
__END__

=head1 NAME

Net::Google::DocumentsList::Metadata - metadata object for Google Documents List Data API

=head1 SYNOPSIS

  use Net::Google::DocumentsList;
  
  my $client = Net::Google::DocumentsList->new(
      username => 'myname@gmail.com',
      password => 'p4$$w0rd'
  );

  my $metadata = $client->metadata;


=head1 DESCRIPTION

This module represents metadata object for Google Documents List Data API

=head1 ATTRIBUTES

=head2 updated

returns updated time

=head2 largest_changestamp

returns largest changestamp: you can use this attribute to get latest changes from change feeds

  my $client = Net::Google::DocumentsList->new(...);
  my $largest_changestamp = $client->metadata->largest_changestamp;
  my @changes = $client->changes({'start-index' => $largest_changestamp - 10, 'max-results' => 10});

see also: L<Net::Google::DocumentsList::Change>

=head2 quota_bytes_total

returns total quota bytes you can use

=head2 quota_bytes_used

returns total quota bytes you've already used

=head2 quota_bytes_used_in_trash

returns total quota bytes you've already used with items in trash

=head2 max_upload_size

returns max upload size for each services in hashref format:

  my $metadata = $client->metadata;
  my $max = $metadata->max_upload_size;
  # returns (for example):
  # {
  #   'document' => '2097152',
  #   'drawing' => '2097152',
  #   'file' => '10737418240',
  #   'pdf' => '10737418240',
  #   'presentation' => '52428800',
  #   'spreadsheet' => '20971520'
  # }

  my $file = '/path/to/your.pdf';
  if (-s $file > $max->{pdf}) {
    die 'you can not upload this pdf because it is too large';
  }
  # now you can upload the file safely

  $client->add_item({file => $file});

=head2 import_format

returns map of file formats and types of Google Docs items to be converted:

  my $map = $client->metadata->import_format;
  # returns (for example):
  # {
  #   'application/msword' => ['document'],
  #   'application/pdf' => ['document'],
  #   'application/rtf' => ['document'],
  #   'application/vnd.ms-excel' => ['spreadsheet'],
  #   ....
  # }

=head2 export_format

returns map of types of items and exportable formats:

  my $map = $client->metadata->import_format;
  # returns (for example):
  # {
  #   'document' => ['text/html', 'application/pdf', 'text/rtf' ... ],
  #   'drawing'  => ['application/pdf', 'image/png', 'image/jpeg', 'image/svg+xml' ],
  #   'presentation' => ['application/vnd.ms-powerpoint', 'text/plain', 'application/pdf', ... ],
  #   'spreadsheet' => ['application/vnd.ms-excel', 'application/pdf', ... ],
  # }

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
