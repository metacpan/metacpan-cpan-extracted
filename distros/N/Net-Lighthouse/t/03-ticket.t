use strict;
use warnings;

use Test::More tests => 75;
use Test::Mock::LWP;
use DateTime;
use_ok('Net::Lighthouse::Project');
use_ok('Net::Lighthouse::Project::Ticket');
can_ok( 'Net::Lighthouse::Project::Ticket', 'new' );

my $ticket = Net::Lighthouse::Project::Ticket->new;
isa_ok( $ticket, 'Net::Lighthouse::Project::Ticket' );
isa_ok( $ticket, 'Net::Lighthouse::Base' );

my @attrs = (
    'priority',           'raw_data',
    'number',             'milestone_due_on',
    'created_at',         'user_name',
    'state',              'permalink',
    'versions',           'url',
    'updated_at',         'tag',
    'closed',             'attachments',
    'latest_body',        'user_id',
    'milestone_id',       'project_id',
    'attachments_count',  'assigned_user_id',
    'assigned_user_name', 'creator_id',
    'title',              'creator_name',
    'milestone_title',
);

for my $attr (@attrs) {
    can_ok( $ticket, $attr );
}

for my $method (qw/create update delete load load_from_xml list initial_state/)
{
    can_ok( $ticket, $method );
}

$Mock_ua->mock( get            => sub { $Mock_response } );
$Mock_ua->mock( default_header => sub { } );                  # to erase warning
$Mock_response->mock(
    content => sub {
        local $/;
        open my $fh, '<', 't/data/ticket_1.xml' or die $!;
        <$fh>;
    }
);

my $n1 = Net::Lighthouse::Project::Ticket->new(
    account    => 'sunnavy',
    project_id => 35918,
);
my $load = $n1->load(1);
is( $load, $n1, 'load returns $self' );

my %hash = (
    'priority'          => 1,
    'number'            => 1,
    'state'             => 'new',
    'permalink'         => 'first-ticket',
    'milestone_id'      => undef,
    'created_at' => DateTime->new(
        year   => 2009,
        month  => 8,
        day    => 21,
        hour   => 11,
        minute => 15,
        second => 50,
    ),
    'assigned_user_id'  => 67166,
    'attachments_count' => 2,
    'url'        => 'http://sunnavy.lighthouseapp.com/projects/35918/tickets/1',
    'tag'        => 'first',
    'creator_id' => 67166,
    'project_id' => 35918,
    'creator_name'       => 'sunnavy (at gmail)',
    'closed'             => 0,
    'latest_body'        => 'this\'s 1st description',
    'account'            => 'sunnavy',
    'raw_data'           => undef,
    'milestone_due_on'   => undef,
    'user_name'          => 'sunnavy (at gmail)',
    'updated_at'         => DateTime->new( 
        year   => 2009,
        month  => 8,
        day    => 21,
        hour   => 11,
        minute => 15,
        second => 53,
    ),
    'user_id'            => 67166,
    'assigned_user_name' => 'sunnavy (at gmail)',
    'title'              => 'first ticket'
);

for my $k ( keys %hash ) {
    is_deeply( $n1->$k, $hash{$k}, "$k is loaded" );
}

is( @{$n1->versions}, 1, 'version number' );
is_deeply( scalar $n1->versions, [ $n1->versions ], 'versions returns arrayref in scalar context' );
isa_ok( $n1->versions->[0], 'Net::Lighthouse::Project::Ticket::Version' );
is( $n1->versions->[0]->creator_id, 67166, 'version creator_id' );

is( @{$n1->attachments}, 2, 'attachment number' );
is_deeply( scalar $n1->attachments, [ $n1->attachments ], 'attachments returns arrayref in scalar context' );
isa_ok( $n1->attachments->[0], 'Net::Lighthouse::Project::Ticket::Attachment' );
is( $n1->attachments->[0]->filename, 'first', 'attachment filename' );
is( $n1->attachments->[1]->content_type,
    'image/jpeg', 'attachment content type' );

$Mock_response->mock(
    content => sub {
        local $/;
        open my $fh, '<', 't/data/tickets.xml' or die $!;
        <$fh>;
    }
);

$ticket = Net::Lighthouse::Project::Ticket->new(
    account    => 'sunnavy',
    project_id => 35918,
);
my @list = $ticket->list;
is( scalar @list, 2, 'list number' );
is( $list[0]->number, 2, '1st ticket number' );
is( $list[1]->number, 1, '1st ticket number' );
is_deeply( scalar $ticket->list, \@list, 'list returns array ref in scalar context' );

# test initial_state
$Mock_response->mock(
    content => sub {
        local $/;
        open my $fh, '<', 't/data/ticket_new.xml' or die $!;
        <$fh>;
    }
);
$ticket = Net::Lighthouse::Project::Ticket->new(
    account    => 'sunnavy',
    project_id => 35918,
);
my $expect_initial_state = {
    'priority'          => 0,
    'number'            => undef,
    'milestone_id'      => undef,
    'permalink'         => undef,
    'state'             => undef,
    'assigned_user_id'  => undef,
    'attachments_count' => 0,
    'created_at'        => undef,
    'url'         => 'http://sunnavy.lighthouseapp.com/projects/35918/tickets/',
    'tag'         => undef,
    'creator_id'  => undef,
    'project_id'  => 35918,
    'closed'      => 0,
    'latest_body' => undef,
    'raw_data'    => undef,
    'milestone_due_on' => undef,
    'updated_at'       => undef,
    'title'            => undef,
    'user_id'          => undef
};
is_deeply( $ticket->initial_state, $expect_initial_state, 'initial state' );
