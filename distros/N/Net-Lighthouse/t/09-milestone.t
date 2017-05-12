use strict;
use warnings;

use Test::More tests => 44;
use Test::Mock::LWP;
use DateTime;

use_ok('Net::Lighthouse::Project');
use_ok('Net::Lighthouse::Project::Milestone');
can_ok( 'Net::Lighthouse::Project::Milestone', 'new' );

my $milestone = Net::Lighthouse::Project::Milestone->new;
isa_ok( $milestone, 'Net::Lighthouse::Project::Milestone' );
isa_ok( $milestone, 'Net::Lighthouse::Base' );

my @attrs = (
    'open_tickets_count', 'created_at',
    'goals_html',            'user_name',
    'permalink',             'project_id',
    'due_on',                'tickets_count',
    'url',                   'updated_at',
    'id',                    'title',
    'goals'
);

for my $attr (@attrs) {
    can_ok( $milestone, $attr );
}

for my $method (qw/create update delete load load_from_xml list initial_state/)
{
    can_ok( $milestone, $method );
}

$Mock_ua->mock( get            => sub { $Mock_response } );
$Mock_ua->mock( default_header => sub { } );                  # to erase warning
$Mock_response->mock(
    content => sub {
        local $/;
        open my $fh, '<', 't/data/milestone_48761.xml' or die $!;
        <$fh>;
    }
);

my $n1 = Net::Lighthouse::Project::Milestone->new(
    account    => 'sunnavy',
    project_id => 35918,
);
my $load = $n1->load(1);
is( $load, $n1, 'load returns $self' );
my %hash = (
    'account'            => 'sunnavy',
    'due_on' => DateTime->new(
        year  => 2009,
        month => 8,
        day   => 31,
    ),
    'user_name'          => undef,
    'permalink'          => 'first-release',
    'goals_html'         => '<div><p>release 1st version</p></div>',
    'created_at' => DateTime->new(
        year   => 2009,
        month  => 8,
        day    => 27,
        hour   => 2,
        minute => 7,
        second => 15,
    ),
    'updated_at'         => DateTime->new(
        year   => 2009,
        month  => 8,
        day    => 27,
        hour   => 2,
        minute => 7,
        second => 15,
    ),
    'open_tickets_count' => 0,
    'tickets_count'      => 0,
    'url' => 'http://sunnavy.lighthouseapp.com/projects/35918/milestones/48761',
    'id'  => 48761,
    'title'      => 'first release',
    'goals'      => 'release 1st version',
    'project_id' => 35918,

);

for my $k ( keys %hash ) {
    is( $n1->$k, $hash{$k}, "$k is loaded" );
}

$Mock_response->mock(
    content => sub {
        local $/;
        open my $fh, '<', 't/data/milestones.xml' or die $!;
        <$fh>;
    }
);

$milestone = Net::Lighthouse::Project::Milestone->new(
    account    => 'sunnavy',
    project_id => 35918,
);
my @list = $milestone->list;
is( scalar @list, 1, 'list number' );
is( $list[0]->id, 48761, '1st milestone number' );
is_deeply( scalar $milestone->list, \@list, 'list returns array ref in scalar context' );

# test initial_state
$Mock_response->mock(
    content => sub {
        local $/;
        open my $fh, '<', 't/data/milestone_new.xml' or die $!;
        <$fh>;
    }
);
$milestone = Net::Lighthouse::Project::Milestone->new(
    account    => 'sunnavy',
    project_id => 35918,
);
my $expect_initial_state = {
    'due_on'             => undef,
    'permalink'          => '',
    'created_at'         => undef,
    'goals_html'         => '',
    'open_tickets_count' => 0,
    'tickets_count'      => 0,
    'title'              => '',
    'goals'              => '',
    'project_id'         => undef,
};
is_deeply( $milestone->initial_state, $expect_initial_state, 'initial state' );
