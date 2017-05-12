use strict;
use warnings;

use Test::More tests => 20;

use Test::Mock::LWP;
$LWP::UserAgent::VERSION = '6';
$HTTP::Request::VERSION  = '6';

use DateTime;
use_ok('Net::Google::Code::Issue::Comment');
can_ok( 'Net::Google::Code::Issue::Comment', 'new' );

my $comment = Net::Google::Code::Issue::Comment->new(
    project  => 'net-google-code',
    issue_id => 9,
);

isa_ok( $comment, 'Net::Google::Code::Issue::Comment' );
isa_ok( $comment, 'Net::Google::Code::Issue::Base' );

my @attrs = qw/date sequence issue_id author content updates /;

for my $attr (@attrs) {
    can_ok( $comment, $attr );
}

for my $method (qw/list/) {
    can_ok( $comment, $method );
}
$Mock_ua->mock( get            => sub { $Mock_response } );
$Mock_ua->mock( default_header => sub { } );                  # to erase warning
$Mock_response->mock(
    content => sub {
        local $/;
        open my $fh, '<', 't/google_api/data/comments.xml' or die $!;
        <$fh>;
    }
);

my @list = $comment->list;
is( scalar @list,       9, 'list number' );
is( $list[0]->sequence, 1, '1st comment id' );
is( $list[1]->sequence, 2, '2nd comment id' );
my %hash = (
    'author'   => 'sunnavy',
    'updates'  => { 'labels' => ['-Priority-Medium'] },
    'sequence' => '1',
    'date'     => '2009-05-12T09:29:18',
);
for my $k ( keys %hash ) {
    is_deeply( scalar $list[0]->$k, $hash{$k}, "$k is loaded" );
}

is_deeply(
    scalar $list[7]->{updates},
    { 'labels' => [ 'Type-Defect', 'test-ok', '0.05' ] },
    "updates is loaded"
);

is_deeply(
    scalar $list[8]->{updates},
    { 'cc' => 'sunnavy' },
    "updates is loaded"
);

