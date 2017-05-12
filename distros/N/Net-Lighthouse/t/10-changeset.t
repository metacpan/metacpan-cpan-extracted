use strict;
use warnings;

use Test::More tests => 33;
use Test::Mock::LWP;
use DateTime;

use_ok('Net::Lighthouse::Project');
use_ok('Net::Lighthouse::Project::Changeset');
can_ok( 'Net::Lighthouse::Project::Changeset', 'new' );

my $changeset = Net::Lighthouse::Project::Changeset->new;
isa_ok( $changeset, 'Net::Lighthouse::Project::Changeset' );
isa_ok( $changeset, 'Net::Lighthouse::Base' );

my @attrs = (
    'body',    'revision', 'project_id', 'changed_at',
    'changes', 'user_id',  'title',      'body_html',
);

for my $attr (@attrs) {
    can_ok( $changeset, $attr );
}

for my $method (qw/create delete load load_from_xml list initial_state/)
{
    can_ok( $changeset, $method );
}

$Mock_ua->mock( get            => sub { $Mock_response } );
$Mock_ua->mock( default_header => sub { } );                  # to erase warning
$Mock_response->mock(
    content => sub {
        local $/;
        open my $fh, '<', 't/data/changeset_983.xml' or die $!;
        <$fh>;
    }
);

my $n1 = Net::Lighthouse::Project::Changeset->new(
    account    => 'sunnavy',
    project_id => 2,
);
my $load = $n1->load(1);
is( $load, $n1, 'load returns $self' );
my %hash = (
                 'account' => 'sunnavy',
                 'body' => '#{unprocessed body}',
                 'revision' => 983,
                 'changes' => [
                     [ 'M', '/trunk/test/unit/changeset_test.rb' ],
                     [ 'M', '/trunk/app/models/changeset.rb' ],
                     [ 'M', '/trunk/db/schema.rb' ]
                 ],
                 'user_id' => 1,
                 'title' => 'rick committed changeset [983]',
                 'body_html' => '#{processed HTML body}',
                 'changed_at' => DateTime->new(
                     year => 2007,
                     month => 3,
                     day => 21,
                     hour => 21,
                     minute => 45, 
                     second => 23,
                 ),
                 'project_id' => 2,
);

for my $k ( keys %hash ) {
    is_deeply( scalar $n1->$k, $hash{$k}, "$k is loaded" );
}

$Mock_response->mock(
    content => sub {
        local $/;
        open my $fh, '<', 't/data/changesets.xml' or die $!;
        <$fh>;
    }
);

$changeset = Net::Lighthouse::Project::Changeset->new(
    account    => 'sunnavy',
    project_id => 2,
);
my @list = $changeset->list;
is( scalar @list, 1, 'list number' );
is( $list[0]->revision, 983, '1st changeset number' );
is_deeply( scalar $changeset->list, \@list, 'list returns array ref in scalar context' );

# test initial_state
$Mock_response->mock(
    content => sub {
        local $/;
        open my $fh, '<', 't/data/changeset_new.xml' or die $!;
        <$fh>;
    }
);
$changeset = Net::Lighthouse::Project::Changeset->new(
    account    => 'sunnavy',
    project_id => 2,
);
my $expect_initial_state = {
    'body'     => '',
    'revision' => '',
    'changes'  => [],
    'user_id'    => undef,
    'title'      => '',
    'body_html'  => '',
    'changed_at' => undef,
    'project_id' => 2
};

is_deeply( $changeset->initial_state, $expect_initial_state, 'initial state' );
