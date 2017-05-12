# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Linux-Distribution.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
use Sys::SyslogMessages;

my $log=new Sys::SyslogMessages();

ok( defined($log) ,     'new() works 1' );
like( ref $log, qr/^Sys::SyslogMessages.*/,     'check new() works 2' );
ok( $log->tail({'number_lines' => '10'}),   'check tail() works 1' );
ok( $log->tail({'number_hours' => '1'}),    'check tail() works 2' );

