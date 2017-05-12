use warnings;
use strict;
use Test::Most tests => 12;
use File::Spec;

BEGIN { use_ok( 'Siebel::Srvrmgr::Util::IniDaemon', 'create_daemon' ) }

my $package = 'Siebel::Srvrmgr::Util::IniDaemon';

can_ok( $package, 'create_daemon' );
dies_ok { create_daemon('foobar.INI') }
'create_daemon requires a existing INI file to read';
like(
    $@,
    qr/does\snot\sexist\sor\sis\snot\sreadable/,
    'got expected error message'
);
dies_ok {
    create_daemon( File::Spec->catfile( 't', 'config', 'invalid_daemon.ini' ) )
}
'dies with a invalid daemon';
like(
    $@,
    qr/Invalid\svalue\s"\w+"\sfor\sdaemon\stype/,
    'got expected error message'
);
dies_ok {
    create_daemon( File::Spec->catfile( 't', 'config', 'missing_param.ini' ) )
}
'dies due missing gateway parameter';
like( $@, qr/gateway/, 'got expected error message' );
ok(
    my $daemon =
      create_daemon( File::Spec->catfile( 't', 'config', 'correct.ini' ) ),
    'a correct ini file is ok'
);
isa_ok( $daemon, 'Siebel::Srvrmgr::Daemon::Heavy' );
ok(
    $daemon =
      create_daemon( File::Spec->catfile( 't', 'config', 'light.ini' ) ),
    'a light type in the ini file is ok'
);
isa_ok( $daemon, 'Siebel::Srvrmgr::Daemon::Light' );

