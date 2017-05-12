use strict;
use warnings;

use Test::More tests => 13;

use Net::Google::Code::Issue;
my $issue = Net::Google::Code::Issue->new( project => 'net-google-code' );
isa_ok( $issue, 'Net::Google::Code::Issue', '$issue' );
for my $id ( 8 .. 9 ) {
    ok( $issue->load($id) );
    # to make sure $_->content can be called continuously
    ok( $_->content ) for @{ $issue->attachments };
}

$Net::Google::Code::Issue::USE_HYBRID = 1;
for my $id ( 8 .. 9 ) {
    ok( $issue->load($id) );
    ok( $_->content ) for @{ $issue->attachments };
}
