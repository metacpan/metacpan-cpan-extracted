use Test::More tests=>5;

use strict;
$XML::SAX::ParserPackage = $XML::SAX::ParserPackage ||= $ENV{'NOH_ParserPackage'};

use_ok( 'Net::OAI::Harvester' );

my $token = new_ok('Net::OAI::ResumptionToken');

$token->expirationDate( 'May-28-1969' );
is( $token->expirationDate(), 'May-28-1969', 'expirationDate()' );

$token->completeListSize( 2000 );
is( $token->completeListSize(), 2000, 'completeListSize()' );

$token->cursor( 1000 );
is( $token->cursor(), 1000, 'cursor()' );

