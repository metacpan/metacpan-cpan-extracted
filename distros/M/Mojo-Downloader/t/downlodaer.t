use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Test::More;

use_ok('Mojo::Downloader');
my $d = Mojo::Downloader->new( interval => 3 );
is( $d->interval,3,'test interval set');
is( $d->max_currency,10,'test default max_currency');
$d->set_max_currency(5);
is( $d->max_currency,5,'test set max_currency');
done_testing;


