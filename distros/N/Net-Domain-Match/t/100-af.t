use Test::More ;

use lib 'lib';
use Net::Domain::Match;

my $c = Net::Domain::Match->new;

my $basename = 'the-domain';
my $extended = 'ftp.the-domain';

my $VERBOSE = $ENV{VERBOSE} || 0;

###

for my $sld ( qw/gov.af com.af org.af net.af edu.af/ ){
	my @res = $c->match_map( $basename . '.' . $sld );

	ok( $res[0]{tld} eq $sld => "$basename.$sld - TLD" );
	ok( $res[0]{domain} eq $basename => "$basename.$sld - Domain" );
	ok( $res[0]{hostname} eq '' => "$basename.$sld - Hostname" );
}

done_testing();

