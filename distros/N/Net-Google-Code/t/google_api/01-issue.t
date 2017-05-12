use strict;
use warnings;

use Test::More tests => 35;
use Test::Mock::LWP;
use DateTime;

$LWP::UserAgent::VERSION = '6';
$HTTP::Request::VERSION  = '6';

use_ok('Net::Google::Code::Issue');
can_ok( 'Net::Google::Code::Issue', 'new' );

{
    no warnings 'once';
    $Net::Google::Code::Issue::USE_HYBRID = 1;
}

my $issue = Net::Google::Code::Issue->new( project => 'net-google-code' );
isa_ok( $issue, 'Net::Google::Code::Issue' );
isa_ok( $issue, 'Net::Google::Code::Issue::Base' );

my @attrs =
  qw/ reported id reporter status owner summary description
  labels cc comments stars/;

for my $attr (@attrs) {
    can_ok( $issue, $attr );
}

for my $method (qw/create update updated load list load_comments/) {
    can_ok( $issue, $method );
}

$Mock_ua->mock( get            => sub { $Mock_response } );
$Mock_ua->mock( default_header => sub { } );                  # to erase warning
$Mock_response->mock(
    content => sub {
        local $/;
        open my $fh, '<', 't/google_api/data/issue_8.xml' or die $!;
        <$fh>;
    }
);

my $n1 = Net::Google::Code::Issue->new( project => 'net-google-code', );
($n1) = $n1->list(id =>8);
my %hash = (
    'owner'       => 'sunnavy',
    'project'     => 'net-google-code',
    'description' => 'test the hack of file field',
    'reporter'    => 'sunnavy',
    'reported'    => '2009-02-20T08:46:06',
    'labels'      => ['Test-fine'],
    'status'      => 'Accepted',
    'summary'     => 'test attachment 8',
    'id'          => '8',
    'stars'       => 1,
);

for my $k ( keys %hash ) {
    is_deeply( $n1->$k, $hash{$k}, "$k is loaded" );
}

$Mock_response->mock(
    content => sub {
        local $/;
        open my $fh, '<', 't/google_api/data/issues.xml' or die $!;
        <$fh>;
    }
);

$issue = Net::Google::Code::Issue->new( project => 'net-google-code', );
my @list = $issue->list;
is( scalar @list, 21, 'list number' );
is( $list[0]->id, 1,  '1st issue id' );
is( $list[1]->id, 2,  '2nd issue id' );
is_deeply(
    $list[9]->labels,
    [ 'Type-Defect', 'Priority-Medium' ],
    '9th issue labels'
);

