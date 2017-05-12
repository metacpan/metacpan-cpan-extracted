use strict;
use warnings;

use Test::More tests => 2;
use Test::MockModule;
# test the decode stuff in fetch

use FindBin qw/$Bin/;
use File::Slurp;

use Encode;
my $content = read_file("$Bin/sample/06.fetch.html");

my $mock_mech = Test::MockModule->new('WWW::Mechanize');
$mock_mech->mock( 'get',       sub { } );
$mock_mech->mock( 'is_success',  sub { 1 } );
$mock_mech->mock( 'response',    sub { HTTP::Response->new } );
$mock_mech->mock( 'content',    sub { $content } );
my $mock_response = Test::MockModule->new('HTTP::Response');
$mock_response->mock( 'is_success', sub { 1 } );

use Net::Google::Code::Issue;
my $issue = Net::Google::Code::Issue->new( project => 'test' );
isa_ok( $issue, 'Net::Google::Code::Issue', '$issue' );
$issue->load(487);

my $summary = 'Can´t get K9 to work with Exchange Account';

is( $issue->summary, $summary, 'summary is extracted' );

