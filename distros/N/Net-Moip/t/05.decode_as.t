use strict;
use warnings;
use Test::More;
use Net::Moip;

my $moip = Net::Moip->new( token => 1, key => 1 );

is $moip->decode_as, undef, 'decode_as is undef by default';

$moip = Net::Moip->new( token => 2, key => 2, decode_as => 'utf-8' );

is $moip->decode_as, 'utf-8', 'decode_as can be overwritten during new()';

$moip->decode_as('iso-8859-1');

is $moip->decode_as, 'iso-8859-1', 'decode_as is writeable';

$moip->decode_as(undef);

is $moip->decode_as, undef, 'decode_as can be set back to undef';

done_testing;
