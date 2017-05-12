use strict;
use warnings;

use Test::Most;

# For the benefit of Data::Localize
BEGIN { $ENV{ANY_MOOSE} = 'Moose' }

use Silki::I18N;

Silki::I18N->SetLanguage('fr');

is( Silki::I18N->Language(), 'fr', 'Language is fr' );

done_testing();
