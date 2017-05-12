use strict;
use warnings;

use Test::More tests => 36;
use Test::Mock::LWP;
use DateTime;

use_ok('Net::Lighthouse::Project');
use_ok('Net::Lighthouse::Project::TicketBin');
can_ok( 'Net::Lighthouse::Project::TicketBin', 'new' );

my $bin = Net::Lighthouse::Project::TicketBin->new;
isa_ok( $bin, 'Net::Lighthouse::Project::TicketBin' );
isa_ok( $bin, 'Net::Lighthouse::Base' );

my @attrs = (
    'query',      'user_id', 'position',   'name',
    'default',    'shared',  'project_id', 'tickets_count',
    'updated_at', 'id'
);

for my $attr (@attrs) {
    can_ok( $bin, $attr );
}

for my $method (qw/create update delete load load_from_xml list/) {
    can_ok( $bin, $method );
}

$Mock_ua->mock( get            => sub { $Mock_response } );
$Mock_ua->mock( default_header => sub { } );                  # to erase warning
$Mock_response->mock(
    content => sub {
        local $/;
        open my $fh, '<', 't/data/bin_48889.xml' or die $!;
        <$fh>;
    }
);

my $b1 = Net::Lighthouse::Project::TicketBin->new(
    account    => 'sunnavy',
    project_id => 35918,
);
my $load = $b1->load(48889);
is( $load, $b1, 'load returns $self' );
my %hash = (
    'query'         => 'state:open',
    'account'       => 'sunnavy',
    'position'      => 1,
    'name'          => 'Open tickets',
    'default'       => undef,
    'shared'        => 1,
    'updated_at'    => DateTime->new(
        year => 2009,
        month => 8,
        day => 21,
        hour => 10,
        minute => 2,
        second => 21,
    ),
    'tickets_count' => 2,
    'user_id'       => 67166,
    'id'            => 48889,
    'project_id'    => 35918,
);

for my $k ( keys %hash ) {
    is_deeply( $b1->$k, $hash{$k}, "$k is loaded" );
}

$Mock_response->mock(
    content => sub {
        local $/;
        open my $fh, '<', 't/data/bins.xml' or die $!;
        <$fh>;
    }
);

$bin = Net::Lighthouse::Project::TicketBin->new(
    account    => 'sunnavy',
    project_id => 35918,
);
my @list = $bin->list;
is( scalar @list, 3, 'list number' );
is( $list[0]->id, 48889, '1st bin number' );
is_deeply( scalar $bin->list, \@list, 'list returns array ref in scalar context' );

