use strict;
use warnings;

use Test::More tests => 45;
use Net::StackExchange;

# checks if class implements required methods
sub check_can_ok {
    my ( $class, $methods ) = @_;
    for my $method ( @{$methods} ) {
        can_ok( $class, $method );
    }
}

check_can_ok( 'Net::StackExchange', [qw( network version route )] );

check_can_ok( 'Net::StackExchange::Owner', [
    qw{user_id user_type display_name reputation email_hash}
] );

check_can_ok( 'Net::StackExchange::Answers', [
    qw{
      answer_id accepted answer_comments_url question_id locked_date owner
      creation_date last_edit_date last_activity_date up_vote_count
      down_vote_count view_count score community_owned title body comments
      }
] );

check_can_ok( 'Net::StackExchange::Answers::Request', [
    qw{
      id body comments fromdate jsonp max min order page pagesize sort todate
      type key jsonp
      }
] );

check_can_ok( 'Net::StackExchange::Answers::Response', [
    qw{ json answers total page pagesize }
] );
