use strict;
use warnings;

use Test::More tests => 48;
use DateTime;
use_ok('Net::Lighthouse::Project::Ticket::Version');
can_ok( 'Net::Lighthouse::Project::Ticket::Version', 'new' );

my $version = Net::Lighthouse::Project::Ticket::Version->new;
isa_ok( $version, 'Net::Lighthouse::Project::Ticket::Version' );

my @attrs = (
    'assigned_user_name', 'assigned_user_id',
    'attachments_count',  'body',
    'body_html',          'closed',
    'created_at',         'creator_id',
    'milestone_id',       'number',
    'permalink',          'project_id',
    'state',              'tag',
    'title',              'updated_at',
    'user_id',            'user_name',
    'creator_name',       'url',
    'diffable_attributes', 'milestone_title',
);

for my $attr (@attrs) {
    can_ok( $version, $attr );
}

can_ok( $version, 'load_from_xml' );

my $xml = do {
    local $/;
    open my $fh, '<', 't/data/ticket_1_version_1.xml' or die $!;
    <$fh>;
};
my $v1 = $version->load_from_xml($xml);
is( $v1, $version, 'load returns $self' );

my %hash = (
    'number'            => 1,
    'state'             => 'new',
    'permalink'         => 'first-ticket',
    'milestone_id'      => undef,
    'body'              => 'this\'s 1st description',
    'assigned_user_id'  => 67166,
    'attachments_count' => 0,
    'created_at' => DateTime->new(
        year   => 2009,
        month  => 8,
        day    => 21,
        hour   => 11,
        minute => 15,
        second => 50,
    ),
    'url'        => 'http://sunnavy.lighthouseapp.com/projects/35918/tickets/1',
    'tag'        => 'first',
    'project_id' => 35918,
    'creator_id' => 67166,
    'creator_name'        => 'sunnavy (at gmail)',
    'closed'              => 0,
    'user_name'           => 'sunnavy (at gmail)',
    'diffable_attributes' => {},
    'updated_at'         => DateTime->new( 
        year   => 2009,
        month  => 8,
        day    => 21,
        hour   => 11,
        minute => 15,
        second => 53,
    ),
    'body_html'          => '<div><p>this\'s 1st description</p></div>',
    'user_id'            => 67166,
    'assigned_user_name' => 'sunnavy (at gmail)',
    'title'              => 'first ticket'
);

for my $k ( keys %hash ) {
    is_deeply( $v1->$k, $hash{$k}, "$k is loaded" );
}
