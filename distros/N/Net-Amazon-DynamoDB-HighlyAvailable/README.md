# NAME

Net::Amazon::DynamoDB::HighlyAvailable - Sync data across multiple regions

# SYNOPSIS

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

# DESCRIPTION

Amazon says  "All data items ... are automatically replicated across multiple
Availability Zones in a Region to provide built-in high availability and data
durability."

If thats not highly available enough for you, you can use this module to sync
data between multiple regions.

This module is a wrapper around Net::Amazon::DynamoDB::Table.

# ACKNOWLEDGEMENTS

Thanks to [DuckDuckGo](http://duckduckgo.com) for making this module possible by donating developer time.

# LICENSE

Copyright (C) Eric Johnson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Eric Johnson <eric.git@iijo.org>
