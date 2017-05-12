use strict;
use warnings;

use Test::More tests => 86;
use Test::Mock::LWP;
use DateTime;
use_ok('Net::Lighthouse::Project');
can_ok( 'Net::Lighthouse::Project', 'new' );

my $project = Net::Lighthouse::Project->new( account => 'sunnavy', id => 1 );
isa_ok( $project, 'Net::Lighthouse::Project' );
isa_ok( $project, 'Net::Lighthouse::Base' );
for my $attr (
    qw/archived created_at default_assigned_user_id
    default_milestone_id description description_html hidden
    id license name open_tickets_count permalink public
    send_changesets_to_events updated_at open_states_list
    closed_states_list open_states closed_states/
  )
{
    can_ok( $project, $attr );
}

for my $method (
    qw/create update delete load load_from_xml list
    initial_state tickets ticket_bins messages milestones changesets
    ticket ticket_bin message milestone changeset
    /
  )
{
    can_ok( $project, $method );
}

for my $method (qw/ticket ticket_bin message milestone changeset/) {
    can_ok( $project, $method );
    if ( $method eq 'ticket_bin' ) {
        isa_ok( $project->$method, 'Net::Lighthouse::Project::TicketBin' );
    }
    else {
        isa_ok( $project->$method,
            'Net::Lighthouse::Project::' . ucfirst $method );
    }
}

$Mock_ua->mock( get            => sub { $Mock_response } );
$Mock_ua->mock( default_header => sub { } );                  # to erase warning
$Mock_response->mock(
    content => sub {
        local $/;
        open my $fh, '<', 't/data/find_project_35918.xml' or die $!;
        <$fh>;
    }
);

my $sd = Net::Lighthouse::Project->new( account => 'sunnavy' );
my $load = $sd->load(35918);
is( $sd, $load, 'load returns $self' );

my %hash = (
    'description_html' => '<div><p>test for sd</p></div>',
    'open_states_list' => [ 'new', 'open' ],
    'open_states'      => [
        {
            name    => 'new',
            color   => 'f17',
            comment => 'You can add comments here'
        },
        { name => 'open', color => 'aaa', comment => 'if you want to.' }
    ],
    'default_assigned_user_id' => undef,
    'permalink'                => 'sd',
    'created_at'               => DateTime->new(
        year   => 2009,
        month  => 8,
        day    => 21,
        hour   => 10,
        minute => 2,
        second => 21,
    ),
    'default_milestone_id'      => undef,
    'send_changesets_to_events' => 1,
    'public'                    => 0,
    'id'                        => 35918,
    'closed_states'             => [
        {
            name    => 'resolved',
            color   => '6A0',
            comment => 'You can customize colors'
        },
        {
            name    => 'hold',
            color   => 'EB0',
            comment => 'with 3 or 6 character hex codes'
        },
        {
            name    => 'invalid',
            color   => 'A30',
            comment => "'A30' expands to 'AA3300'"
        },
    ],
    'name'               => 'sd',
    'license'            => undef,
    'description'        => 'test for sd',
    'archived'           => 0,
    'closed_states_list' => [ 'resolved', 'hold', 'invalid' ],
    'updated_at'         => DateTime->new(
        year   => 2009,
        month  => 8,
        day    => 24,
        hour   => 5,
        minute => 46,
        second => 52
    ),
    'hidden' => 0,
);

for my $k ( keys %hash ) {
    is_deeply( scalar $sd->$k, $hash{$k}, "$k is loaded" );
}

$Mock_response->mock(
    content => sub {
        local $/;
        open my $fh, '<', 't/data/projects.xml' or die $!;
        <$fh>;
    }
);

my $p = Net::Lighthouse::Project->new( account => 'sunnavy', id => 35918 );
my @projects = $p->list;
is( scalar @projects, 2,     'number of projects' );
is( $projects[0]->id, 35918, 'id of 2nd project' );
is( $projects[1]->id, 36513, 'id of 2nd project' );
is_deeply( $projects[0], $sd,
    'load and list returns the same info for one project' );

is_deeply( scalar $p->list, \@projects, 'list returns array ref in scalar context' );

# test for initial_state
$Mock_response->mock(
    content => sub {
        local $/;
        open my $fh, '<', 't/data/project_new.xml' or die $!;
        <$fh>;
    }
);

my $initial_state          = $p->initial_state;
my $expected_initial_state = {
    'description_html' => undef,
    'open_states_list' => [ 'new', 'open' ],
    'open_states'      => [
        {
            name    => 'new',
            color   => 'f17',
            comment => 'You can add comments here'
        },
        { name => 'open', color => 'aaa', comment => 'if you want to.' }
    ],
    'permalink'                 => undef,
    'default_assigned_user_id'  => undef,
    'default_milestone_id'      => undef,
    'created_at'                => undef,
    'send_changesets_to_events' => 1,
    'public'                    => 0,
    'open_tickets_count'        => 0,
    'closed_states'             => [
        {
            name    => 'resolved',
            color   => '6A0',
            comment => 'You can customize colors'
        },
        {
            name    => 'hold',
            color   => 'EB0',
            comment => 'with 3 or 6 character hex codes'
        },
        {
            name    => 'invalid',
            color   => 'A30',
            comment => "'A30' expands to 'AA3300'"
        },
    ],
    'name'               => undef,
    'license'            => undef,
    'description'        => undef,
    'archived'           => 0,
    'updated_at'         => undef,
    'closed_states_list' => [ 'resolved', 'hold', 'invalid' ],
    'hidden'             => 0,
};

is_deeply( $initial_state, $expected_initial_state, 'initial state' );

# test tickets
$Mock_response->mock(
    content => sub {
        local $/;
        open my $fh, '<', 't/data/bins.xml' or die $!;
        <$fh>;
    }
);

my @bins = $p->ticket_bins;
is( scalar @bins, 3, 'found tickets' );
isa_ok( $bins[0], 'Net::Lighthouse::Project::TicketBin' );
is( $bins[0]->id, 48889, 'bin id' );

for my $method (qw/milestones messages changesets tickets/) {
    $Mock_response->mock(
        content => sub {
            local $/;
            open my $fh, '<', "t/data/$method.xml" or die $!;
            <$fh>;
        }
    );
    my @list = $p->$method;
    ok( scalar @list, 'found list' );

    my $class = ucfirst $method;
    $class =~ s/s$//;
    isa_ok( $list[0], "Net::Lighthouse::Project::$class" );
}
