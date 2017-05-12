package Net::Google::DocumentsList::Role::EnsureListed;
use Any::Moose '::Role';

our $SLEEP = 1;
our $RETRY = 10;

sub ensure_listed {
    my ($self, $item, $args) = @_;
    for (1 .. $RETRY) {
        my @items = $self->item(
            {
                resource_id => $item->resource_id,
                title => $item->title,
                'title-exact' => 'true',
                category => $item->kind,
            }
        );
        grep {$_ && $_->id eq $item->id} @items and last;
        sleep $SLEEP;
    }
    my $found_item;
    for (1 .. $RETRY) {
        $found_item = $self->_find_entry($item);
        if ($found_item->title ne $item->title) {
            undef $found_item;
            sleep $SLEEP;
            next;
        }
        if ($args->{etag_should_change}) {
            $found_item->etag eq $item->etag and next;
            # retry, but keep $found_item (it would the the true item)
        }
        last;
    }
    $found_item or confess "updated entry couldn't be retrieved"; 
    $item->container->sync if $item->container;
    return $found_item;
}

sub ensure_not_listed {
    my ($self, $folder) = @_;

    my $found;
    for (1 .. $RETRY) {
        undef $found;
        my @list = $folder->item(
            {
                resource_id => $self->resource_id,
                title => $self->title,
                'title-exact' => 'true',
                category => $self->kind,
            }
        );
        ($found) = grep {$_ && $_->id eq $self->id} @list or last;
        sleep $SLEEP;
    }
    $found and confess "item couldn't be moved"; 
}

sub ensure_trashed {
    my ($self, $item) = @_;
    my $found_item;
    for (1 .. $RETRY) {
        my @items = $self->item(
            {
                resource_id => $item->resource_id,
                title => $item->title,
                'title-exact' => 'true',
                category => [$item->kind, 'trashed'],
            }
        );
        my ($found) = grep {$_ && $_->id eq $item->id && $_->deleted} @items and last;
        sleep $SLEEP;
    }
    for (1 .. $RETRY) {
        $found_item = $self->_find_entry($item);
        $found_item->title eq $item->title && $found_item->deleted and last;
        undef $found_item;
        sleep $SLEEP;
    }
    $found_item or confess "couldn't trash the item";
}

sub ensure_deleted {
    my ($self, $item) = @_;
    my $found_item;
    for (1 .. $RETRY) {
        my @items = $self->service->item(
            {
                resource_id => $item->resource_id,
                title => $item->title,
                'title-exact' => 'true',
                category => $item->kind,
            }
        );
        push @items, $self->service->item(
            {
                resource_id => $item->resource_id,
                title => $item->title,
                'title-exact' => 'true',
                category => [$item->kind, 'trashed'],
            }
        );
        grep {$_ && $_->id eq $item->id} @items or last;
        sleep $SLEEP; 
    }
    my $found;
    for (1 .. $RETRY) {
        undef $found;
        $found = eval {$self->_find_entry($item)} or last;
        sleep $SLEEP;
    }
    $found and confess "couldn't delete the item";
}

sub _find_entry {
    my ($self, $item) = @_;
    my $found = $self->service->get_entry($item->selfurl) or return;
    return (ref $item)->new(
        $item->container ? (container => $item->container) 
        : ( service => $self->service),
        atom => $found,
    );
}

1;
