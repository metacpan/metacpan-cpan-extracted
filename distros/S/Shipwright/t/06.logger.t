use strict;
use warnings;

use Test::More tests => 2;

require Shipwright::Logger;
Shipwright::Logger->new( { log_level => undef } );

ok( Log::Log4perl->initialized, 'initialized' );
my $logger = Log::Log4perl->get_logger;
ok( $logger->is_fatal, 'default level is fatal' );

