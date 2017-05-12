use strict;
use warnings;

use Test::More tests => 37;
use Test::MockModule;

use FindBin qw/$Bin/;
use File::Slurp;
my $html_content = read_file("$Bin/sample/05.issue_search.html");
my $xml_content = read_file("$Bin/sample/05.issue_search.xml");

my $mock = Test::MockModule->new('Net::Google::Code::Issue::Search');
$mock->mock(
    'fetch',
    sub {
        my $self = shift;
        my $url  = shift;
        if ( $url =~ /feeds/ ) {
            return $xml_content;
        }
        else {
            return $html_content;
        }

    }
);
my $mock_mech = Test::MockModule->new('WWW::Mechanize');
$mock_mech->mock( 'title',       sub { 'issues' } );
$mock_mech->mock( 'submit_form', sub { } );
$mock_mech->mock( 'is_success',  sub { 1 } );
$mock_mech->mock( 'response',    sub { HTTP::Response->new } );
my $mock_response = Test::MockModule->new('HTTP::Response');
$mock_response->mock( 'is_success', sub { 1 } );
$mock_response->mock( 'content',    sub { $html_content } );

use Net::Google::Code::Issue::Search;
my $search = Net::Google::Code::Issue::Search->new( project => 'test' );
isa_ok( $search, 'Net::Google::Code::Issue::Search', '$search' );

# search tests
can_ok( $search, 'search' );
$search->search(load_after_search => 0);

is( scalar @{ $search->results }, 8, 'results number in total' );
my %first_result = (
    'owner'       => 'sunnavy',
    'attachments' => [],
    'summary'     => 'labels',
    'status'      => 'Accepted',
    'project'     => 'test',
    'id'          => '2',
    'labels'      => [],
    'comments'    => []
);

for my $key ( keys %first_result ) {
    is_deeply( $search->results->[0]->$key,
        $first_result{$key}, "first result $key" );
}

is_deeply( $search->results->[-1]->labels,
    [qw/0.05 blabla/], 'last result labels' );

# updated_after tests
can_ok( $search, 'updated_after' );
my $mock_issue = Test::MockModule->new('Net::Google::Code::Issue');
$mock_issue->mock(
    'load',
    sub {
        my $id   = shift->id;
        ok( 1, "load( $id ) is called" );
    }
);

my $dt = DateTime->new( year => 2009, month => 6, day => 1 );
my $issues = $search->updated_after( $dt );
my @ids = map { $_->id } @$issues;
is_deeply( \@ids, [ 22, 13, 14, 10 ], 'updated_after 2009-06-01 got 4 issues' );
$dt = DateTime->new( year => 2010, month => 1, day => 1 );
$issues = $search->updated_after( $dt );
is_deeply( $issues, [ ], 'updated_after 2010-01-01 got 0 issues' );


# let updated_after call ->search
$dt = DateTime->new( year => 2008, month => 1, day => 1 );
my $updated = DateTime->new( year => 2010, month => 1, day => 1 );
$mock_issue->mock( 'updated', sub { $updated } );
$issues = $search->updated_after( $dt );

is( scalar @{ $search->results }, 8, 'downgraded to ->search to find issues' );

$updated = DateTime->new( year => 2005, month => 1, day => 1 );
$mock_issue->mock( 'updated', sub { $updated } );
$issues = $search->updated_after( $dt );
is( scalar @{ $search->results },
    0, 'downgraded updated_after version also filters by the updated date' );
