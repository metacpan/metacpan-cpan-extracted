use strict;
use warnings;

use Test::More tests => 2;

use Log::Log4perl qw(:easy);

my $class = 'MyCPAN::App::BackPAN::Indexer';
use_ok( $class );
can_ok( $class, 'activate' );
