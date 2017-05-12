use strict;
use warnings;

use Test::More tests => 20;
use DateTime;
use Test::Mock::LWP;

use_ok('Net::Lighthouse::Token');
can_ok( 'Net::Lighthouse::Token', 'new' );

my $token = Net::Lighthouse::Token->new( account => 'sunnavy' );
isa_ok( $token, 'Net::Lighthouse::Token' );

for my $attr (
    'project_id', 'account',   'user_id', 'created_at',
    'token',      'read_only', 'note'
  )
{
    can_ok( $token, $attr );
}

for my $method ( qw/load load_from_xml/ ) {
    can_ok( $token, $method );
}

$Mock_ua->mock( get            => sub { $Mock_response } );
$Mock_ua->mock( default_header => sub { } );                  # to erase warning
$Mock_response->mock(
    content => sub {
        local $/;
        open my $fh, '<', 't/data/token.xml' or die $!;
        <$fh>;
    }
);

my $m = $token->load('a'x40);

is( $m, $token, 'load returns $self' );
my %hash = (
    'created_at' => DateTime->new(
        year   => 2007,
        month  => 4,
        day    => 21,
        hour   => 18,
        minute => 17,
        second => 32,
    ),
    'account'    => 'http://activereload.lighthouseapp.com',
    'read_only'  => 0,
    'user_id'    => 1,
    'token'      => '01234567890123456789012345678900123456789',
    'project_id' => undef,
    'note'       => 'test 1'
);

for my $k ( keys %hash ) {
    is_deeply( $m->$k, $hash{$k}, "$k is loaded" );
}
