use strict;
use warnings;

use Test::More tests => 20;
use Test::MockModule;

use FindBin qw/$Bin/;
use File::Slurp;

my $content = read_file( "$Bin/sample/02.issue.html" );
utf8::downgrade( $content, 1 );

my $mock = Test::MockModule->new('Net::Google::Code::Issue');
$mock->mock(
    'fetch',
    sub { $content }
);

my $mock_att = Test::MockModule->new('Net::Google::Code::Issue::Attachment');
$mock_att->mock( 'fetch', sub { '' } );

use Net::Google::Code::Issue;
my $issue = Net::Google::Code::Issue->new( project => 'test' );
isa_ok( $issue, 'Net::Google::Code::Issue', '$issue' );
$issue->load(8);

my %info = (
    id          => 8,
    summary     => 'issue 8',
    description => 'test the hack of file field',
    cc          => 'sunnavy, t...@example.com',
    owner       => 'sunnavy',
    reporter    => 'sunnavy',
    status => 'Accepted',
    closed => undef,
    merged => undef,
    stars => 1,
);

my @labels = ( 'Test-fine', );

for my $item (
    qw/id summary description owner cc reporter status closed merged
    stars/
  )
{
    if ( defined $info{$item} ) {
        is( $issue->$item, $info{$item}, "$item is extracted" );
    }
    else {
        ok( !defined $issue->$item, "$item is not defined" );
    }
}

is_deeply( $issue->labels, \@labels, 'labels is extracted' );

is( scalar @{$issue->comments}, 5, 'comments are extracted' );
is( $issue->comments->[0]->sequence, 0, 'comment 0 is for the actual create' );
is( scalar @{ $issue->comments->[0]->attachments },
    2, 'comment 0 has 2 attachments' );
is( $issue->comments->[1]->sequence, 1, 'sequence of comment 1 is 1' );
is( $issue->comments->[2]->sequence, 2, 'sequence of comment 2 is 4' ); 

is( scalar @{ $issue->attachments }, 2, 'attachments are extracted' );
is( $issue->attachments->[0]->size, '223 bytes', 'size of the 1st attachment' );

is( $issue->updated, '2009-10-14T12:07:40', 'updated' );

