use strict;
use warnings;

use Test::More tests => 12;

use_ok( 'Net::Lighthouse::User::Membership' );
can_ok( 'Net::Lighthouse::User::Membership', 'new' );

my $ms = Net::Lighthouse::User::Membership->new;
isa_ok( $ms, 'Net::Lighthouse::User::Membership' );

for my $attr( qw/id user_id account project/ ) {
    can_ok( $ms, $attr );
}

can_ok( $ms, 'load_from_xml' );

my $xml = do {
    local $/;
    open my $fh, '<', 't/data/user_67166_membership_69274.xml' or die $!;
    <$fh>;
};
my $m = $ms->load_from_xml($xml);
is( $m, $ms, 'load returns $self' );
my %hash = (
        id => 69274,
        user_id => 67166,
        account => 'http://sunnavy.lighthouseapp.com',
);

for my $k ( keys %hash ) {
    is( $m->$k, $hash{$k}, "$k is loaded" );
}
