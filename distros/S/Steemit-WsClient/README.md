# NAME

Steemit::WsClient - perl library for interacting with the steemit websocket services!

# VERSION

Version 0.09

# SYNOPSIS

```perl
    use Steemit::WsClient;

    my $foo = Steemit::WsClient->new();
    my $steem = Steemit::WsClient->new( url => 'https://some.steemit.d.node.address');

    say "Initialized Steemit::WsClient client with url ".$steem->url;

    #get the last 99 discussions with the tag utopian-io
    #truncate the body since we dont care here
    my $discussions = $steem->get_discussions_by_created({
          tag => 'utopian-io',
          limit => 99,
          truncate_body => 100,
    });

    #extract the author names out of the result
    my @author_names = map { $_->{author} } @$discussions;
    say "last 99 authors: ".join(", ", @author_names);

    #load the author details
    my $authors = $steem->get_accounts( [@author_names] );
    #say Dumper $authors->[0];

    #calculate the reputation average
    my $reputation_sum = 0;
    for my $author ( @$authors ){
       $reputation_sum += int( $author->{reputation} / 1000_000_000 );
    }

    say "Average reputation of the last 99 utopian authors: ". ( int( $reputation_sum / scalar(@$authors) )  / 100 );
```

# DEPENDENCIES

you will need some packages.
openssl support for https
libgmp-dev for large integer aritmetic needd for the eliptical curve calculations

    libssl-dev zlib1g-dev libgmp-dev

# SUBROUTINES/METHODS

## all database api methods of the steemit api

[https://github.com/steemit/steem/blob/master/libraries/app/database\_api.cpp](https://github.com/steemit/steem/blob/master/libraries/app/database_api.cpp)

      get_miner_queue
      lookup_account_names
      get_discussions
      get_discussions_by_blog
      get_witness_schedule
      get_open_orders
      get_trending_tags
      lookup_witness_accounts
      get_discussions_by_children
      get_accounts
      get_savings_withdraw_to
      get_potential_signatures
      get_required_signatures
      get_order_book
      get_key_references
      get_tags_used_by_author
      get_account_bandwidth
      get_replies_by_last_update
      get_dynamic_global_properties
      get_block
      get_witnesses
      get_transaction_hex
      get_comment_discussions_by_payout
      get_discussions_by_votes
      get_witness_by_account
      verify_authority
      get_config
      get_account_votes
      get_discussions_by_promoted
      get_conversion_requests
      get_account_history
      get_escrow
      get_discussions_by_comments
      get_feed_history
      get_hardfork_version
      set_block_applied_callback
      get_discussions_by_author_before_date
      get_discussions_by_hot
      get_discussions_by_payout
      get_discussions_by_trending
      get_recovery_request
      get_reward_fund
      get_chain_properties
      get_witnesses_by_vote
      get_account_references
      get_post_discussions_by_payout
      get_active_witnesses
      get_ops_in_block
      get_discussions_by_created
      get_discussions_by_active
      get_account_count
      get_owner_history
      get_next_scheduled_hardfork
      get_savings_withdraw_from
      get_active_votes
      get_current_median_history_price
      get_transaction
      get_block_header
      get_expiring_vesting_delegations
      get_witness_count
      get_content
      verify_account_authority
      get_liquidity_queue
      get_discussions_by_feed
      get_discussions_by_cashout
      get_content_replies
      lookup_accounts
      get_state
      get_withdraw_routes

## get\_discussions\_by\_xxxxxx

all those methods will sort the results differently and accept one query parameter with the values:

    {
       tag   => 'tagtosearch',   # optional
       limit => 1,               # max 100
       filter_tags => [],        # tags to filter out
       select_authors => [],     # only those authors
       truncate_body  => 0       # the number of bytes of the post body to return, 0 for all
       start_author   => ''      # used together with the start_permlink gor pagination
       start_permlink => ''      #
       parent_author  => ''      #
       parent_permlink => ''     #
    }

so one example on how to get 200 discussions would be

    my $discussions = $steem->get_discussions_by_created({
          limit => 100,
          truncate_body => 1,
    });

    my $discussion = $discussions[-1];

    push @$discussions, $steem->get_discussions_by_created({
          limit => 100,
          truncate_body => 1,
          start_author   => $discussion->{author},
          start_permlink => $discussion->{permlink},
    });

## vote

this requires you to initialize the module with your private posting key like this:

    my $steem = Steemit::WsClient->new(
       posting_key => 'copy this one from the steemit site',

    );

    $steem->vote($discussion,$weight)

weight is optional default is 10000 wich equals to 100%

## comment

this requires you to initialize the module with your private posting key like this:

    my $steem = Steemit::WsClient->new(
       posting_key => 'copy this one from the steemit site',

    );

    $steem->comment(
          "parent_author"   => $parent_author,
          "parent_permlink" => $parent_permlink,
          "author"          => $author,
          "permlink"        => $permlink,
          "title"           => $title,
          "body"            => $body,
          "json_metadata"   => $json_metadata,
    )

you need at least a permlink and body
fill the parent parameters to comment on an existing post
json metadata can be already a json string or a perl hash

## delete\_comment

    $steem->delete_comment(
       author => $author,
       permlink => $permlink
    )

you need the permlink
author will be filled with the user of your posting key if missing

# REPOSITORY

[https://github.com/snkoehn/perlSteemit](https://github.com/snkoehn/perlSteemit)

# AUTHOR

snkoehn, `<snkoehn at cpan.org>`

# BUGS

Please report any bugs or feature requests to `bug-steemit at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Steemit::WsClient](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Steemit::WsClient).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Steemit::WsClient

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Steemit::WsClient](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Steemit::WsClient)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Steemit::WsClient](http://annocpan.org/dist/Steemit::WsClient)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Steemit::WsClient](http://cpanratings.perl.org/d/Steemit::WsClient)

- Search CPAN

    [http://search.cpan.org/dist/Steemit::WsClient/](http://search.cpan.org/dist/Steemit::WsClient/)

# ACKNOWLEDGEMENTS

# LICENSE AND COPYRIGHT

Copyright 2018 snkoehn.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
