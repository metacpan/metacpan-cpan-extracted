#!perl -Tw

use Test::More;
use Solaris::SMF;

my $author_tests = $ENV{RELEASE_TESTING} ? 1 : 0;

if ( $author_tests && ( $< == 0 ) ) {
    plan tests => 7;
}
else {
    plan skip_all => 'Skipping release tests';
}

# Disable a service - the system-log, for testing. Later this might be a special
# service we create, using a 'new' function.

my ($system_log) = get_services( wildcard => 'system-log' );
ok( $system_log->disable == 0, 'disable system-log' );
ok( $system_log->mark == 0,    'mark system-log' );
ok( $system_log->clear == 0,   'clear system-log' );
ok( $system_log->start == 0,   'start system-log' );
ok( $system_log->stop == 0,    'stop system-log' );
ok( $system_log->enable == 0,  'enable system-log' );
ok( $system_log->refresh == 0, 'refresh system-log' );

done_testing();
