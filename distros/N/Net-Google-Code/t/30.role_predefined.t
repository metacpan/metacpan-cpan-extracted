use strict;
use warnings;

use Test::More tests => 3;
use Test::MockModule;

use FindBin qw/$Bin/;
use File::Slurp;

my $content = read_file("$Bin/sample/30.role_predefined.js");

my $mock = Test::MockModule->new('Net::Google::Code::Issue');
$mock->mock( 'fetch',
    sub { q{codesite_token = "faked_token" } } );
$mock->mock( 'signed_in', sub { 1 } );

my $mock_mech = Test::MockModule->new('WWW::Mechanize');
$mock_mech->mock( 'content',     sub { $content } );
$mock_mech->mock( 'update_html', sub { } );
$mock_mech->mock( 'submit_form', sub { } );
$mock_mech->mock( 'success',     sub { 1 } );

use Net::Google::Code::Issue;
my $issue = Net::Google::Code::Issue->new( project => 'test' );
ok( $issue->load_predefined, 'loaded predefined' );

is_deeply(
    $issue->predefined_labels,
    [
        'Type-Defect',           'Type-Enhancement',
        'Type-Task',             'Type-Review',
        'Type-Other',            'Priority-Critical',
        'Priority-High',         'Priority-Medium',
        'Priority-Low',          'OpSys-All',
        'OpSys-Windows',         'OpSys-Linux',
        'OpSys-OSX',             'Milestone-Release1.0',
        'Component-UI',          'Component-Logic',
        'Component-Persistence', 'Component-Scripts',
        'Component-Docs',        'Security',
        'Performance',           'Usability',
        'Maintainability',
    ],
    'predefined labels'
);

is_deeply(
    $issue->predefined_status,
    {
        'closed' =>
          [ 'Fixed', 'Verified', 'Invalid', 'Duplicate', 'WontFix', 'Done', ],
        'open' => [ 'New', 'Accepted', 'Started', ],

    },
    'predefined status'
);
