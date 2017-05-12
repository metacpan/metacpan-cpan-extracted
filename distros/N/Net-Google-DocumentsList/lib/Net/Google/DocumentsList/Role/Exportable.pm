package Net::Google::DocumentsList::Role::Exportable;
use Any::Moose '::Role';
use File::Slurp;

requires 'item_feedurl', 'kind';

sub export {
    my ($self, $args) = @_;

    $self->kind eq 'folder' 
        and confess "You can't export folder";
    my $format = delete $args->{format};
    my $file = delete $args->{file};
    my $res = $self->service->request(
        {
            uri => $self->item_feedurl,
            query => {
                %{$args || {}},
                exportFormat => $format,
            },
            $self->kind eq 'spreadsheet' ? 
                (sign_host => 'spreadsheets.google.com') 
                : (),
        }
    );
    if ($res->is_redirect) {
        my $next = $res->header('Location');
        $res = $self->service->request({uri => $next});
    }
    if ($res->is_success) {
        if ( $file ) {
            my $content = $res->content_ref;
            return write_file( $file, {binmode => ':raw'}, $content );
        }
        return $res->decoded_content;
    }
}

1;
__END__

=head1 NAME

Net::Google::DocumentsList::Role::Exportable - implementation of download items

=head1 SYNOPSIS

  use Net::Google::DocumentsList;

  my $client = Net::Google::DocumentsList->new(
    username => 'myname@gmail.com',
    password => 'p4$$w0rd'
  );

  # pickup one document
  my $d = $client->item;

  # download and set to variable
  my $content = $d->export(
    {
        format => 'txt',
    }
  );

  # download to a file
  $d->export(
    {
        format => 'txt',
        file => '/path/to/download.txt',
    }
  );

=head1 DESCRIPTION

This module implements download functionality.

=head1 METHODS

=head2 export

downloads the item. available formats are seen in L<http://code.google.com/intl/en/apis/documents/docs/3.0/developers_guide_protocol.html#DownloadingDocs>.

=head1 AUTHOR

Noubo Danjou E<lt>danjou@soffritto.orgE<gt>

=head1 SEE ALSO

L<Net::Google::DocumentsList>

L<Net::Google::DocumentsList::Item>

L<Net::Google::DocumentsList::Revision>

L<http://code.google.com/intl/en/apis/documents/docs/3.0/developers_guide_protocol.html#DownloadingDocs>.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
