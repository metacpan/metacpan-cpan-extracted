package Net::Amazon::DynamoDB::HighlyAvailable;
use Net::Amazon::DynamoDB::Table;
use Carp qw/cluck confess carp croak/;
use Moo;
use Try::Tiny;
use DateTime;

our $VERSION="0.03";

has table       => (is => 'rw', required => 1);
has hash_key    => (is => 'rw', required => 1);
has range_key   => (is => 'rw', required => 0);
has dynamodbs   => (is => 'lazy');
has regions     => (is => 'rw', required => 1);
has access_key  => (is => 'rw', lazy => 1, builder => 1);
has secret_key  => (is => 'rw', lazy => 1, builder => 1);
has timeout     => (is => 'rw', default => 5);

sub _build_access_key { $ENV{AWS_ACCESS_KEY} }
sub _build_secret_key { $ENV{AWS_SECRET_KEY} }
sub _build_regions    { [qw/ us-east-1 us-west-1 /] }

sub _build_dynamodbs {
    my $self    = shift;
    my $regions = $self->regions;
    my @dynamodbs;

    for my $region (@$regions) {
        push @dynamodbs, Net::Amazon::DynamoDB::Table->new(
            region     => $region,
            table      => $self->table,
            hash_key   => $self->hash_key,
            range_key  => $self->range_key,
            access_key => $self->access_key,
            secret_key => $self->secret_key,
            timeout    => $self->timeout,
        );
    }

    return \@dynamodbs;
}

sub put {
    my ($self, %args) = @_;

    # timestamp this transaction
    $args{Item}->{last_updated} = DateTime->now . ""; # stringify datetime
    $args{Item}->{deleted}    ||= 0;

    my $dynamodbs = $self->dynamodbs;
    my $success   = 0;

    for my $dynamodb (@$dynamodbs) {
        try { 
            $dynamodb->put(%args);
            $success++;
        }
        catch {
            warn "caught error: " . p $_;
        };
    }

    # make sure at least one put() was successful
    confess "unable to save to any dynamodb" unless $success;
}

sub delete {
    my ($self, %args) = @_;

    my $item = $self->get(%args);

    return unless keys %$item;

    $self->put(Item => { %$item, deleted => 1 });
}

sub permanent_delete {
    my ($self, %args) = @_;

    my $dynamodbs = $self->dynamodbs;
    my $success   = 0;

    for my $dynamodb (@$dynamodbs) {
        try { 
            $dynamodb->delete(%args);
            $success++;
        }
        catch {
            warn "caught error: " . p $_;
        };
    }

    confess "unable to permanently delete item from any dynamodb" unless $success;
}

sub get {
    my ($self, %args) = @_;

    my $dynamodbs = $self->dynamodbs;
    my $success   = 0;
    my @items;

    for my $dynamodb (@$dynamodbs) {
        try { 
            push @items, $dynamodb->get(%args);
            $success++;
        }
        catch {
            warn "caught error: " . p $_;
        };
    }

    confess "unable to connect and get item from any dynamodb" unless $success;

    my $most_recent;
    for my $item (@items) {
        next unless $item;

        $most_recent = $item 
            if !$most_recent ||
                $most_recent->{last_updated} le $item->{last_updated};
    }

    return if $most_recent->{deleted};
    return $most_recent;
}

sub scan {
    my ($self, @args) = @_;

    my $dynamodbs = $self->dynamodbs;
    my $success   = 0;
    my @items;

    for my $dynamodb (@$dynamodbs) {
        my $res;

        try { 
            $res = $dynamodb->scan(@args);
        }
        catch {
            warn "caught error: " . p $_;
        };

        return $res if $res;
    }

    confess "unable to connect and scan from any dynamodb";
}

sub scan_as_hashref {
    my ($self, @args) = @_;

    my $dynamodbs = $self->dynamodbs;
    my $success   = 0;
    my @items;

    for my $dynamodb (@$dynamodbs) {
        my $res;

        try { 
            $res = $dynamodb->scan_as_hashref(@args);
        }
        catch {
            warn "caught error: " . p $_;
        };

        return $res if $res;
    }

    confess "unable to connect and scan from any dynamodb";
}

sub sync_regions {
    my ($self, @args) = @_;

    my $dynamodb0 = $self->dynamodbs->[0];
    my $dynamodb1 = $self->dynamodbs->[1];

    my $scan0 = $dynamodb0->scan(@args);
    my $scan1 = $dynamodb1->scan(@args);

    my $items0 = $self->_process_items($scan0);
    my $items1 = $self->_process_items($scan1);

    # sync from $dynamodb0 -> $dynamodb1
    $self->_sync_items($dynamodb0 => $dynamodb1, $items0 => $items1);

    # sync from $dynamodb1 -> $dynamodb0
    $self->_sync_items($dynamodb1 => $dynamodb0, $items1 => $items0);
}

sub _process_items {
    my ($self, $items_arrayref) = @_;

    my $hash_key_name = $self->hash_key;
    my $items_hashref;

    for my $item (@$items_arrayref) {
        my $hash_key_value = $item->{$hash_key_name};
        $items_hashref->{$hash_key_value} = $item;
    }

    return $items_hashref;
}

sub _sync_items {
    my ($self, $from_ddb, $to_ddb, $from_items, $to_items) = @_;

    my $hash_key_name = $self->hash_key;

    for my $from_key (keys %$from_items) {
        my $from_val = $from_items->{$from_key};
        my $to_val   = $to_items->{$from_key};

        if (!$to_val) {
            $to_val = {last_updated => '1900-01-01T00:00:00'};
            $to_items->{$from_key} = $to_val;
        }

        my $updated0 = $from_val->{last_updated};
        my $updated1 = $to_val->{last_updated};

        # don't need to sync if the items are the same age and not deleted
        next if $updated0 eq $updated1 && !$to_val->{deleted};

        # find the newest item
        my ($newest, $ddb) = $updated0 gt $updated1
            ? ($from_val, $to_ddb)
            : ($to_val,   $from_ddb);

        # sync newest item to the other region
        if ($newest->{deleted}) {
            my $hash_key_value = $newest->{$hash_key_name};
            $self->permanent_delete($hash_key_name => $hash_key_value);
        }
        else {
            $ddb->put(Item => $newest);
        }

        # Lets say we are syncing from $dynamodb0 -> $dynamodb1. This prevents
        # us from re syncing this item when we sync in the other direction from
        # $dynamodb1 -> $dynamodb0
        $to_val->{last_updated} = $from_val->{last_updated};
    }
}

1;
__END__

=head1 NAME

Net::Amazon::DynamoDB::HighlyAvailable - Sync data across multiple regions

=head1 SYNOPSIS

    use Net::Amazon::DynamoDB::HighlyAvailable;

    # the regions param must have a length of 2
    my $table = Amazon::DynamoDB::HighlyAvailable->new(
        table             => $table,       # required
        hash_key          => $hash_key,    # required
        range_key         => $range_key,
        regions           => [qw/us-east-1 us-west-1/],
        access_key_id     => ...,          # default: $ENV{AWS_ACCESS_KEY}
        secret_access_key => ...,          # default: $ENV{AWS_SECRET_KEY}
        timeout           => 1,            # default: 5
    );

    # create or update an item
    $table->put(Item => { planet => 'Mars', ... });

    # get the item with the specified primary key; returns a hashref
    my $item = $table->get(planet => 'Mars');

    # delete the item with the specified primary key
    $table->delete(planet => 'Mars');

    # scan the table for items; returns an arrayref of items
    my $items_arrayref = $table->scan();

    # scan the table for items; returns items as a hash of key value pairs
    my $items_hashref = $table->scan_as_hashref();

    # sync data between AWS regions using the 'last_updated' field to select
    # the newest data.  This method will permanently delete any items marked as
    # 'deleted'.
    $table->sync_regions();

=head1 DESCRIPTION

Amazon says  "All data items ... are automatically replicated across multiple
Availability Zones in a Region to provide built-in high availability and data
durability."

If thats not highly available enough for you, you can use this module to sync
data between multiple regions.

This module is a wrapper around Net::Amazon::DynamoDB::Table.

=head1 ACKNOWLEDGEMENTS

Thanks to L<DuckDuckGo|http://duckduckgo.com> for making this module possible by donating developer time.

=head1 LICENSE

Copyright (C) Eric Johnson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Eric Johnson E<lt>eric.git@iijo.orgE<gt>

=cut

