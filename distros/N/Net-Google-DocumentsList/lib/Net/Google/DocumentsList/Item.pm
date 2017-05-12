package Net::Google::DocumentsList::Item;
use Any::Moose;
use Net::Google::DataAPI;
with 'Net::Google::DataAPI::Role::Entry',
    'Net::Google::DocumentsList::Role::EnsureListed';
use XML::Atom::Util qw(nodelist first);
use Carp;
use URI::Escape;
use File::stat;

feedurl item => (
    is => 'ro',
    as_content_src => 1,
    entry_class => 'Net::Google::DocumentsList::Item',
);

entry_has 'kind' => (
    is => 'ro',
    from_atom => sub {
        my ($self, $atom) = @_;
        my ($kind) = 
            map {$_->label}
            grep {$_->scheme eq 'http://schemas.google.com/g/2005#kind'}
            $atom->categories;
        return $kind;
    },
    to_atom => sub {
        my ($self, $atom) = @_;
        my $cat = XML::Atom::Category->new;
        $cat->scheme('http://schemas.google.com/g/2005#kind');
        $cat->label($self->kind);
        $cat->term(join("#", "http://schemas.google.com/docs/2007", $self->kind));
        $atom->category($cat);
    }
);

with 'Net::Google::DocumentsList::Role::HasItems',
    'Net::Google::DocumentsList::Role::Exportable';

for my $label (qw(starred viewed hidden mine private trashed)) {
    entry_has $label => (
        is => 'ro',
        isa => 'Bool',
        from_atom => sub {
            my ($self, $atom) = @_;
            grep {
                ($_->scheme eq 'http://schemas.google.com/g/2005/labels')
                && ($_->label eq $label)
            } $atom->categories;
        },
    );
}

feedurl 'acl' => (
    from_atom => sub {
        my ($self, $atom) = @_;
        return $self->_get_feedlink('http://schemas.google.com/acl/2007#accessControlList');
    },
    entry_class => 'Net::Google::DocumentsList::ACL',
);

feedurl 'revision' => (
    from_atom => sub {
        my ($self, $atom) = @_;
        return $self->_get_feedlink('http://schemas.google.com/docs/2007/revisions');
    },
    entry_class => 'Net::Google::DocumentsList::Revision',
    can_add => 0,
);

entry_has 'published' => ( tagname => 'published', is => 'ro' );
entry_has 'updated' => ( tagname => 'updated', is => 'ro' );
entry_has 'edited' => ( tagname => 'edited', ns => 'app', is => 'ro' );
entry_has 'resource_id' => ( tagname => 'resourceId', ns => 'gd', is => 'ro' );
entry_has 'last_viewd' => ( tagname => 'lastViewed', ns => 'gd', is => 'ro' );
entry_has 'deleted' => ( 
    is => 'ro',
    isa => 'Bool',
    from_atom => sub {
        my ($self, $atom) = @_;
        first($atom->elem, $self->ns('gd')->{uri}, 'deleted') ? 1 : 0;
    },
);
entry_has 'parent' => (
    is => 'ro',
    isa => 'Str',
    from_atom => sub {
        my ($self, $atom) = @_;
        $self->container or return;
        my ($parent) = 
            grep {$_ eq $self->container->_url_with_resource_id}
            map {$_->href}
            grep {$_->rel eq 'http://schemas.google.com/docs/2007#parent'}
            $atom->link;
        $parent;
    }
);

entry_has 'alternate' => (
    is => 'ro',
    isa => 'Str',
    from_atom => sub {
        my ($self, $atom) = @_;
        my ($alt) = 
            map {$_->href}
            grep {$_->rel eq 'alternate' && $_->type eq 'text/html'}
            $atom->link;
        return $alt;
    }
);

entry_has 'resumable_edit_media' => (
    is => 'ro',
    isa => 'Str',
    from_atom => sub {
        my ($self, $atom) = @_;
        my ($link) = 
            map {$_->href}
            grep {$_->rel eq 'http://schemas.google.com/g/2005#resumable-edit-media'}
            $atom->link;
        return $link;
    }
);

sub _url_with_resource_id {
    my ($self) = @_;
    join('/', $self->service->item_feedurl, uri_escape $self->resource_id);
}

sub _get_feedlink {
    my ($self, $rel) = @_;
    my ($feedurl) = 
        map {$_->getAttribute('href')}
        grep {$_->getAttribute('rel') eq $rel}
        nodelist($self->elem, $self->ns('gd')->{uri}, 'feedLink');
    return $feedurl;
}

sub update_content {
    my ($self, $file) = @_;

    $self->kind eq 'folder' 
        and confess "You can't update folder content with a file";
    -r $file or confess "File $file does not exist";
    my $stat = stat($file) or confess "can not stat file $file";
    my $size = $stat->size;
    my $ct = MIME::Types->new->mimeTypeOf($file)->type || 'application/octet-stream';
    open my $fh, '<:bytes', $file or confess "file $file could not be opened";

    $self->sync;
    my $res = $self->service->request(
        {
            method => 'PUT',
            uri => $self->resumable_edit_media,
            content_type => $ct,
            header => {
                'Content-Length' => 0,
                'X-Upload-Content-Type' => $ct,
                'X-Upload-Content-Length' => $size,
                'If-Match' => $self->etag,
            },
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
            if ($res->code == 200) {
                $atom = XML::Atom::Entry->new(\($res->content));
                last;
            } else {
                if (my $next = $res->header('Location')) {
                    $uri = $next;
                }
            }
            $self->container->sync if $self->container;
            $offset = $offset + $length;
        }
    }
    my $updated = $self->atom($atom);
    $self->container->sync if $self->container;
    return $updated;
}

sub move_to {
    my ($self, $dest) = @_;

    (
        ref($dest) eq 'Net::Google::DocumentsList::Item'
        && $dest->kind eq 'folder'
    ) or confess 'destination should be a folder';
    
    my $atom = $self->service->request(
        {
            method => 'POST',
            content_type => 'application/atom+xml',            
            uri => $dest->item_feedurl,
            content => $self->atom->as_xml,
            response_object => 'XML::Atom::Entry',
        }
    );
    my $item = (ref $self)->new(
        container => $dest,
        atom => $atom,
    );
    my $updated = $dest->ensure_listed($item);
    $self->container->sync if $self->container;
    $dest->sync;
    $self->atom($updated->atom);
}

sub move_out_of {
    my ($self, $folder) = @_;

    (
        ref($folder) eq 'Net::Google::DocumentsList::Item'
        && $folder->kind eq 'folder'
    ) or confess 'the argument should be a folder';
    
    my $res = $self->service->request(
        {
            method => 'DELETE',
            uri => join('/', $folder->item_feedurl, $self->resource_id),
            header => {'If-Match' => $self->etag},
        }
    );
    if ($res->is_success) {
        $self->ensure_not_listed($folder);
        $self->container->sync if $self->container;
        $folder->sync;
        $self->sync;
    }
}

sub copy {
    my ($self, $new_title) = @_;

    $new_title or confess 'new title not specified';
    grep {$_ eq $self->kind} qw(document spreadsheet presentation)
        or confess 'This kind of item can not be copied';

    my $target = (ref $self)->new(
        {
            service => $self->service,
            title => $new_title,
        }
    )->to_atom;
    $target->id($self->id);
    
    my $atom = $self->service->request(
        {
            method => 'POST',
            content_type => 'application/atom+xml',            
            uri => $self->service->item_feedurl,
            content => $target->as_xml,
            response_object => 'XML::Atom::Entry',
        }
    );
    my $item = (ref $self)->new(
        service => $self->service,
        atom => $atom,
    );
    my $updated = $self->service->ensure_listed($item);
    $self->container->sync if $self->container;
    return $updated;
}

sub update {
    my ($self) = @_;
    $self->etag or return;
    my $parent = $self->container || $self->service;
    my $atom = $self->service->put(
        {
            self => $self,
            entry => $self->to_atom,
        }
    );
    my $item = (ref $self)->new(
        $self->container ? (container => $self->container) 
        : ( service => $self->service),
        atom => $atom
    );
    my $updated = $parent->ensure_listed($item);
    $self->container->sync if $self->container;
    $self->atom($updated->atom);
}

sub delete {
    my ($self, $args) = @_;

    $self->sync;
    my $parent = $self->container || $self->service;

    my $selfurl = $self->container ? $self->_url_with_resource_id : $self->selfurl;

    $args->{delete} = 'true' if $args->{delete};
    my $res = $self->service->request(
        {
            uri => $selfurl,
            method => 'DELETE',
            header => {'If-Match' => $self->etag},
            self => $self,
            query => $args,
        }
    );
    $res->is_success or return;
    if ($args->{delete}) {
        $parent->ensure_deleted($self);
    } else {
        $parent->ensure_trashed($self);
    }
    return 1;
}

around 'add_acl' => sub {
    my ($next, $self, $args) = @_;
    if ((delete($args->{send_notification_emails}) || '') eq 'false') {
        my $feedurl = $self->acl_feedurl . '?send-notification-emails=false';
        my $class = $self->acl_entryclass;
        Any::Moose::load_class($class);
        my $entry = $class->new(
            container => $self,
            %$args
        )->to_atom;
        my $atom = $self->service->post($feedurl, $entry);
        $self->sync if $self->can('sync');
        return $class->new(
            container => $self,
            atom => $atom,
        );
    } else {
        return $next->($self, $args);
    }
};

__PACKAGE__->meta->make_immutable;

no Any::Moose;

1;
__END__

=head1 NAME

Net::Google::DocumentsList::Item - document or folder in Google Documents List Data API

=head1 SYNOPSIS

  use Net::Google::DocumentsList;
  
  my $client = Net::Google::DocumentsList->new(
      username => 'myname@gmail.com',
      password => 'p4$$w0rd'
  );
  
  # taking one document
  my $doc = $client->item;
  

=head1 DESCRIPTION

This module represents document of folder object for Google Documents List Data API.

=head1 METHODS

=head2 add_item, items, item, add_folder, folders, folder

creates or retrieves items. This method works only for the object with 'folder' kind.
This method is implemented in L<Net::Google::DocumentsList::Role::HasItems>.

=head2 add_acl, acls, acl

creates and gets Access Control List object attached to the object.
See L<Net::Google::DocumentsList::ACL> for the details.

=head2 revisions, revision

gets revision objects of the object.
See L<Net::Google::DocumentsList::Revision> for the details.

=head2 update_content

updates the content of the document with specified file.

  my $new_object = $doc->update_content('/path/to/my/new_content.ppt');

=head2 move_to

move the object to specified folder.

  my $client = Net::Google::DocumentsList->new(
    usernaem => 'foo.bar@gmail.com',
    password => 'p4ssw0rd',
  );
  my $doc = $client->item({title => 'my doc', category => 'document'});
  my $folder = $client->folder({title => 'my folder'});
  $doc->move_to($folder);

=head2 move_out_of

move the object out of specified folder.

  my $client = Net::Google::DocumentsList->new(
    usernaem => 'foo.bar@gmail.com',
    password => 'p4ssw0rd',
  );
  my $folder = $client->folder({title => 'my folder'});
  my $doc = $folder->item({title => 'my doc', category => 'document'});
  $doc->move_out_of($folder);

=head2 copy

copies the document to a new document. You can copy documents, spreadsheets, 
and presentations. PDFs or folders is not supported.

  my $client = Net::Google::DocumentsList->new(
    usernaem => 'foo.bar@gmail.com',
    password => 'p4ssw0rd',
  );
  my $doc = $client->add_item({title => 'my doc', kind => 'document'});
  my $copied = $doc->copy('copied doc');

=head2 delete

deletes the object.

  my $client = Net::Google::DocumentsList->new(
    usernaem => 'foo.bar@gmail.com',
    password => 'p4ssw0rd',
  );
  my $doc = $client->item({title => 'my doc', category => 'document'});

  $doc->delete; # goes to trash

If you set delete argument to true, the object will be deleted completely.

  $doc->delete({delete => 1}); # deletes completely

=head2 export 

downloads the document. This method doesn't work for the object whose kind is 'folder'.
This method is implemented in L<Net::Google::DocumentsList::Role::Exportable>.

=head1 ATTRIBUTES

you can get and set (if it is rw) these attributes in a moose way.

=over 2

=item * title (rw)

=item * kind (ro)

=item * alternate (ro)

You can view the item from the web browser with the url associated with this attribute.

=item * published (ro)

=item * updated (ro)

=item * edited (ro)

=item * resource_id (ro)

=item * last_viewed (ro)

=item * deleted (ro)

=item * parent (ro)

=back

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
