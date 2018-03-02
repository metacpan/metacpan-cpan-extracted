package Steemit::WsClient;

=head1 NAME

Steemit::WsClient - perl library for interacting with the steemit websocket services!

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.10';


=head1 SYNOPSIS


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


=head1 DEPENDENCIES

you will need some packages.
openssl support for https
libgmp-dev for large integer aritmetic needd for the eliptical curve calculations

   libssl-dev zlib1g-dev libgmp-dev


=head1 SUBROUTINES/METHODS

=cut

use Modern::Perl;
use Mojo::Base -base;
use Mojo::UserAgent;
use Mojo::JSON qw(decode_json encode_json);
use Data::Dumper;

has url                => 'https://api.steemit.com/';
has ua                 => sub { Mojo::UserAgent->new };
has posting_key        => undef;
has plain_posting_key  => \&_transform_private_key;


=head2 all database api methods of the steemit api

L<https://github.com/steemit/steem/blob/master/libraries/app/database_api.cpp>

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


=head2 get_discussions_by_xxxxxx

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


=head2 vote

this requires you to initialize the module with your private posting key like this:


   my $steem = Steemit::WsClient->new(
      posting_key => 'copy this one from the steemit site',

   );

   $steem->vote($discossion,$weight)

weight is optional default is 10000 wich equals to 100%


=cut

sub _request {
   my( $self, $api, $method, @params ) = @_;
   my $response = $self->ua->post( $self->url, json => {
      jsonrpc => '2.0',
      method  => 'call',
      params  => [$api,$method,[@params]],
      id      => int rand 100,
   })->result;

   die "error while requesting steemd ". $response->to_string unless $response->is_success;

   my $result   = decode_json $response->body;

   return $result->{result} if $result->{result};
   if( my $error = $result->{error} ){
      die $error->{message};
   }
   #ok no error no result
   require Data::Dumper;
   die "unexpected api result: ".Data::Dumper::Dumper( $result );
}

_install_methods();

sub _install_methods {
   my %definition = _get_api_definition();
   for my $api ( keys %definition ){
      for my $method ( @{ $definition{$api} } ){
         no strict 'subs';
         no strict 'refs';
         my $package_sub = join '::', __PACKAGE__, $method;
         *$package_sub = sub {
            shift->_request($api,$method,@_);
         }
      }
   }
}


sub _get_api_definition {

   my @database_api = qw(
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
   );

   return (
      database_api          => [@database_api],
      account_by_key_api    => [ qw( get_key_references )],
   )
}

sub vote {
   my( $self, $discussion, $weight ) = @_;

   my $permlink = $discussion->{permlink};
   my $author   = $discussion->{author};
   $weight   = $weight // 10000;
   my $voter = $self->get_key_references([$self->public_posting_key])->[0][0];

   my $properties = $self->get_dynamic_global_properties();

   my $block_number  = $properties->{last_irreversible_block_num};
   my $block_details = $self->get_block( $block_number );

   my $ref_block_id  = $block_details->{previous},

   my $time          = $properties->{time};
   #my $expiration = "2018-02-24T17:00:51";#TODO dynamic date
   my ($year,$month,$day, $hour,$min,$sec) = split /\D/, $time;
   require Date::Calc;
   my $epoch = Date::Calc::Date_to_Time($year,$month,$day, $hour,$min,$sec);
   ($year,$month,$day, $hour,$min,$sec) = Date::Calc::Time_to_Date($epoch + 600 );
   my $expiration = "$year-$month-$day".'T'."$hour:$min:$sec";

   my $transaction = {
      ref_block_num => ( $block_number - 1 )& 0xffff,
      ref_block_prefix => unpack( "xxxxV", pack('H*',$ref_block_id)),
      expiration       => $expiration,
      operations       => [[
         vote => {
            voter => $voter,
            author => $author,
            permlink => $permlink,
            weight   => $weight,
         }
      ]],
      extensions => [],
      signatures => [],
   };
   my $serialized_transaction = $self->_serialize_transaction_message( $transaction );

   my $bin_private_key = $self->plain_posting_key;
   require Steemit::ECDSA;
   my ( $r, $s, $i ) = Steemit::ECDSA::ecdsa_sign( $serialized_transaction, Math::BigInt->from_bytes( $bin_private_key ) );
   $i += 4;
   $i += 27;

   $transaction->{signatures} = [ join('', map { unpack 'H*', $_->as_bytes} ($i,$r,$s ) ) ];

   $self->_request('network_broadcast_api','broadcast_transaction_synchronous',$transaction);
}

sub public_posting_key {
   my( $self ) = @_;
   unless( $self->{public_posting_key} ){
      require Steemit::ECDSA;
      my $bin_pubkey = Steemit::ECDSA::get_compressed_public_key( Math::BigInt->from_bytes( $self->plain_posting_key ) );
      #TODO use the STM from dynamic lookup in get_config or somewhere
      require Crypt::RIPEMD160;
      my $rip = Crypt::RIPEMD160->new;
      $rip->reset;
      $rip->add($bin_pubkey);
      my $checksum = $rip->digest;
      $rip->reset;
      $rip->add('');
      $self->{public_posting_key} = "STM".Steemit::Base58::encode_base58($bin_pubkey.substr($checksum,0,4));
   }

   return $self->{public_posting_key}
}


sub _transform_private_key {
   my( $self ) = @_;
   die "posting_key missing" unless( $self->posting_key );

   my $base58 = $self->posting_key;

   require Steemit::Base58;
   my $binary = Steemit::Base58::decode_base58( $base58 );


   my $version            = substr( $binary, 0, 1 );
   my $binary_private_key = substr( $binary, 1, -4);
   my $checksum           = substr( $binary, -4);
   die "invalid version in wif ( 0x80 needed ) " unless $version eq  pack "H*", '80';

   require Digest::SHA;
   my $generated_checksum = substr( Digest::SHA::sha256( Digest::SHA::sha256( $version.$binary_private_key )), 0, 4 );

   die "invalid checksum " unless $generated_checksum eq $checksum;

   return $binary_private_key;
}

sub _serialize_transaction_message  {
   my ($self,$transaction) = @_;

   my $serialized_transaction;

   $serialized_transaction .= pack 'v', $transaction->{ref_block_num};

   $serialized_transaction .= pack 'V', $transaction->{ref_block_prefix};

   require Date::Calc;
   #2016-08-08T12:24:17
   my @dates = split /\D/, $transaction->{expiration} ;
   my $epoch = Date::Calc::Date_to_Time( @dates);

   $serialized_transaction .= pack 'L', $epoch;

   $serialized_transaction .= pack "C", scalar( @{ $transaction->{operations} });

   my $operation_count = 0;
   for my $operation ( @{ $transaction->{operations} } ) {

      my ($operation_name,$operations_parameters) = @$operation;

      ##operation id
      $serialized_transaction .= pack "C", 0;

      $serialized_transaction .= pack "C", length $operations_parameters->{voter};
      $serialized_transaction .= pack "A*", $operations_parameters->{voter};

      $serialized_transaction .= pack "C", length $operations_parameters->{author};
      $serialized_transaction .= pack "A*", $operations_parameters->{author};

      $serialized_transaction .= pack "C", length $operations_parameters->{permlink};
      $serialized_transaction .= pack "A*", $operations_parameters->{permlink};

      $serialized_transaction .= pack "s", $operations_parameters->{weight};
   }
   #extentions in case we realy need them at some point we will have to implement this is a less nive way ;)
   die "extentions not supported" if $transaction->{extensions} and $transaction->{extensions}[0];
   $serialized_transaction .= pack 'H*', '00';

   return pack( 'H*', ( '0' x 64 )).$serialized_transaction;
}



=head1 REPOSITORY

L<https://github.com/snkoehn/perlSteemit>


=head1 AUTHOR

snkoehn, C<< <snkoehn at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-steemit at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Steemit::WsClient>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Steemit::WsClient


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Steemit::WsClient>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Steemit::WsClient>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Steemit::WsClient>

=item * Search CPAN

L<http://search.cpan.org/dist/Steemit::WsClient/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 snkoehn.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

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


=cut

1; # End of Steemit::WsClient
