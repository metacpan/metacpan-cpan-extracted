use warnings;
use autodie;

use Statistics::RserveClient::REXP::Language;

use Test::More tests => 3;

my $lang = new Statistics::RserveClient::REXP::Language;

isa_ok( $lang, 'Statistics::RserveClient::REXP::Language', 'new returns an object that' );
ok( !$lang->isExpression(), 'Language is not an expression' );
ok( $lang->isLanguage(),    'Language is a language' );

done_testing();
