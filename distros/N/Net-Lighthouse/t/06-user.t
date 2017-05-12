use strict;
use warnings;

use Test::More tests => 26;
use Test::Mock::LWP;

use_ok( 'Net::Lighthouse::User' );
can_ok( 'Net::Lighthouse::User', 'new' );

my $user = Net::Lighthouse::User->new( account => 'sunnavy' );
isa_ok( $user, 'Net::Lighthouse::User' );
isa_ok( $user, 'Net::Lighthouse::Base' );

for my $attr( qw/id name job name website avatar_url/ ) {
    can_ok( $user, $attr );
}

for my $method ( qw/load load_from_xml update memberships/ ) {
    can_ok( $user, $method );
}

$Mock_ua->mock( get => sub { $Mock_response } );
$Mock_ua->mock( default_header => sub { } ); # to erase warning
$Mock_response->mock(
    content => sub {
        local $/;
        open my $fh, '<', 't/data/user_67166.xml' or die $!;
        <$fh>
    }
);

my $sunnavy = $user->load( 67166 );
is( $sunnavy, $user, 'load returns $self' );
for ( qw/name id job website avatar_url/ ) {

}

my %hash = (
    'website'    => undef,
    'avatar_url' => '/images/avatar.gif',
    'name'       => 'sunnavy (at gmail)',
    'id'         => 67166,
    'job'        => ''
);

for my $attr ( keys %hash ) {
    is( $user->$attr, $hash{$attr}, "$attr is loaded" );
}


# test memberships
$Mock_response->mock(
    content => sub {
        local $/;
        open my $fh, '<', 't/data/user_67166_memberships.xml' or die $!;
        <$fh>
    }
);
my $memberships = $user->memberships;
is( scalar @$memberships, 1, 'we got 1 membership' );
isa_ok( $memberships->[0], 'Net::Lighthouse::User::Membership' );
%hash = (
    'account' => 'http://sunnavy.lighthouseapp.com',
    'user_id' => '67166',
    'id'      => '69274',
    project   => undef,
);

for my $attr ( keys %hash ) {
    is( $memberships->[0]->$attr, $hash{$attr}, "$attr is loaded" );
}
