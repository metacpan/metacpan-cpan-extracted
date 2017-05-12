package Net::Google::DocumentsList::Role::HasItems;
use Any::Moose '::Role';
with 'Net::Google::DocumentsList::Role::EnsureListed';
use Net::Google::DataAPI;
use URI;
use MIME::Types;
use File::stat;
use Carp 'confess';

requires 'items', 'item', 'add_item';

around items => sub {
    my ($next, $self, $cond) = @_;

    my @items;
    if (my $resource_id = delete $cond->{resource_id}) {
        my $atom = eval {$self->service->get_entry(
            join('/', $self->service->item_feedurl, $resource_id)
        )} or return;
        my $class = $self->item_entryclass;
        Any::Moose::load_class($class);
        @items = $class->new(
            $self->can('sync') ? (container => $self) : (service => $self),
            atom => $atom,
        );
    } elsif (my $cats = delete $cond->{category}) {
        $cats = [ "$cats" ] unless ref $cats eq 'ARRAY';
        @items = $self->items_with_category('item', $cats, $cond);
    } else {
        @items = $next->($self, $cond);
    }
    if ($self->can('sync')) {
        @items = grep {$_->parent eq $self->_url_with_resource_id} @items;
    }
    @items;
};

sub items_with_category {
    my ($self, $method, $cats, $cond) = @_;
    my $feedurl = $self->can($method.'_feedurl');
    my $entryclass = $self->can($method.'_entryclass');

    my $uri = URI->new_abs(
        join('/','-', @$cats),
        $feedurl->($self). '/',
    );
    my $feed = $self->service->get_feed($uri, $cond);
    my $class = $entryclass->($self);
    Any::Moose::load_class($class);
    return map {
        $class->new(
            $self->can('sync') ? (container => $self) : (service => $self),
            atom => $_,
        );
    } $feed->entries;
}

around add_item => sub {
    my ($next, $self, $args) = @_;
    my $item;
    if (my $file = delete $args->{file}) {
        -r $file or confess "File $file does not exist";
        my $stat = stat($file) or confess "can not stat file $file";
        my $size = $stat->size;

        my $convert = delete $args->{convert} || 'true';
        my $source_lang = delete $args->{source_language};
        my $target_lang = delete $args->{target_language};

        my $ct = MIME::Types->new->mimeTypeOf($file)->type || 'application/octet-stream';
        open my $fh, '<:bytes', $file or confess "file $file could not be opened";

        my $class = $self->item_entryclass;
        Any::Moose::load_class($class);
        my $entry = $class->new(
            $self->can('sync') ? (container => $self) : (service => $self),
            %$args,
        )->to_atom;
        
        my ($link) = map {$_->href} 
                     grep {$_->rel eq 'http://schemas.google.com/g/2005#resumable-create-media'} 
                     $self->service->get_feed($self->item_feedurl)->link;
        my $res = $self->service->request(
            {  
                uri => $link,
                content_type => 'application/atom+xml',
                header => {
                    'X-Upload-Content-Type' => $ct,
                    'X-Upload-Content-Length' => $size,
                },
                query => {
                    $convert eq 'false' ? (convert =>  'false') : (),
                    $source_lang ? (sourceLanguage => $source_lang) : (),
                    $target_lang ? (targetLanguage => $target_lang) : (),
                },
                content => $entry->as_xml,
            }
        );
        my $atom;
        if ($res->is_success) {
            my $uri = $res->header('Location');
            my $offset = 0;
            while (my $length = read $fh, my $part, 512*1024) {
                my $req = HTTP::Request->new(PUT => $uri);
                $req->content_type($ct);
                $req->content_length($length);
                $req->header('Content-Range' => sprintf('bytes %d-%d/%d', $offset, $offset + $length - 1, $size));
                $req->content($part);
                my $res = $self->service->request($req);
                if ($res->code == 201) {
                    $atom = XML::Atom::Entry->new(\($res->content));
                    last;
                } else {
                    if (my $next = $res->header('Location')) {
                        $uri = $next;
                    }
                }
                $offset = $offset + $length;
            }
        }
        $self->sync if $self->can('sync');
        $item = $class->new(
            $self->can('sync') ? (container => $self) : (service => $self),
            atom => $atom,
        );
    } else {
        $item = $next->($self, $args);
    }
    return $self->ensure_listed($item, {etag_should_change => 1});
};

sub add_folder {
    my ($self, $args) = @_;
    return $self->add_item(
        {
            %{$args || {}},
            kind => 'folder',
        }
    );
}

sub folders {
    my ($self, $args) = @_;
    my $cat = delete $args->{category} || [];
    $cat = [ $cat ] unless ref $cat;
    return $self->items(
        {
            %{$args || {}},
            category => [ 'folder', @$cat ],
        }
    );
}

sub folder {
    my ($self, $args) = @_;
    return [ $self->folders($args) ]->[0];
}

1;
__END__

=head1 NAME

Net::Google::DocumentsList::Role::HasItems - item CRUD implementation

=head1 SYNOPSIS

  use Net::Google::DocumentsList;

  my $service = Net::Google::DocumentsList->new(
    username => 'myname@gmail.com',
    password => 'p4$$w0rd'
  );

  # add a document to the root directory of your docs.
  my $doc = $service->add_item(
    {
        title => 'my document',
        kind  => 'document',
    }
  );

  # add a folder to the root directory of your docs.
  my $folder = $service->add_folder(
    {
        title => 'my folder',
    }
  );

  # add a spreadsheet to a directory
  my $spreadsheet = $folder->add_item(
    {
        title => 'my spreadsheet',
        kind  => 'spreadsheet',
    }
  );
  

=head1 DESCRIPTION

This module implements item CRUD for Google Documents List Data API.

=head1 METHODS

=head2 add_item

creates specified file or folder.

  my $file = $client->add_item(
    {
        title => 'my document',
        kind  => 'document',
    }
  );

available values for 'kind' are 'document', 'folder', 'pdf', 'presentation',
'spreadsheet', and 'form'.

You can also upload file:

  my $uploaded = $client->add_item(
    {
        title => 'uploaded file',
        file  => '/path/to/my/presentation.ppt',
    }
  );

To translate the file specify source_language and target_language:

  my $uploaded = $client->add_item(
    {
        title => 'uploaded file',
        file  => '/path/to/my/presentation.ppt',
        source_language => 'ja',
        target_language => 'en',
    }
  );

THIS DOESN NOT WORK FOR NOW (2010 NOV 28)

=head2 items

searches items like this:

  my @items = $client->items(
    {
        'title' => 'my document',
        'title-exact' => 'true',
        'category' => 'document',
    }
  );

  my @not_viewed_and_starred_presentation = $client->items(
    {
        'category' => ['-viewed','starred','presentation'],
    }
  );

You can specify query with hashref and specify categories in 'category' key.
See L<http://code.google.com/intl/en/apis/documents/docs/3.0/developers_guide_protocol.html#SearchingDocs> for details.

You can also specify resource_id for the query. It naturally returns 0 or 1 item which matches the resource_id. This is useful to work with Net::Google::Spreadsheets:

  my $ss_in_docs = $client->item(
      {resource_id => 'spreadsheet:'.$ss->key}
  );

=head2 item

returns the first item found by items method.

=head2 add_folder

shortcut for add_item({kind => 'folder'}).

  my $new_folder = $client->add_folder( { title => 'new_folder' } );

is equivalent to 

  my $new_folder = $client->add_item( 
      { 
          title => 'new_folder',
          kind  => 'folder',
      } 
  );

=head2 folders

shortcut for items({category => 'folder'}).

=head2 folder

returns the first folder found by folders method.

=head1 AUTHOR

Noubo Danjou E<lt>danjou@soffritto.orgE<gt>

=head1 SEE ALSO

L<Net::Google::DocumentsList>

L<Net::Google::DataAPI>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
