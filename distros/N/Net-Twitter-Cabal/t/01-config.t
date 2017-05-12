#!perl -T

use Test::More tests => 15;

BEGIN {
	use_ok( 'Net::Twitter::Cabal::Config' );
}

diag( "Testing Net::Twitter::Cabal::Config $Net::Twitter::Cabal::Config::VERSION, Perl $], $^X" );

my $file   = 't/samplecfg.yml';

my $config = Net::Twitter::Cabal::Config->new( { file => $file } );
isa_ok( $config, 'Net::Twitter::Cabal::Config' );

is( $config->name, 'Cabal Test', 'name' );
is( $config->description, 'A Lovely Cabal', 'description' );
is( $config->jid, 'cabal-test@jabber.org', 'jid' );
is( $config->password, 'oooooook', 'password' );
is( $config->twitter, 'cabal_test', 'twitter stream' );
is( $config->twitterpw, 'fooooooo', 'twitter password' );

ok( exists $config->accept->{'ajid@jabber.org'}, 'accept exists' );
is( $config->accept->{'ajid@jabber.org'}, 'foo', '..nickname' );
ok( exists $config->accept->{'another@livejournal.com'}, 'accept exists' );
is( $config->accept->{'another@livejournal.com'}, 'bar', '..nickname' );

is( $config->avatar->{'file'}, 'animage.png', 'avatar file' );
is( $config->avatar->{'type'}, 'image/png', 'avatar image type' );
is( $config->url, 'http://example.com/mycabal', 'url' );
