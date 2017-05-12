use Test::More tests => 9;
use strict;
use Regexp::Log::BlueCoat;

my $log = Regexp::Log::BlueCoat->new();

# Object type
is( ref($log), 'Regexp::Log::BlueCoat', "Object type" );

# check the defaults
is( $log->format, '', "Default format" );
is( $log->ufs,    '', "Default ufs" );
is( $log->login,  '', "Default login" );
is_deeply( [ $log->capture ], [], "Default capture" );

# check the non-standard accessors
is( $log->ufs('smartfilter'), 'smartfilter', "ufs return the new value" );
is( $log->ufs,                'smartfilter', "ufs()" );
is( $log->login('ldap'),      'ldap',        "login return the new value" );
is( $log->login,              'ldap',        "login()" );

