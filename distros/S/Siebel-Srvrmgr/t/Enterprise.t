use warnings;
use strict;
use Test::More;
use Test::Moose qw(has_attribute_ok);
use Test::TempDir::Tiny 0.016;
use File::Spec;
use lib 't';
use Test::Siebel::Srvrmgr::Fixtures qw(create_ent_log);

use constant TMP_DIR => tempdir();
use constant ENTERPRISE_LOG =>
  File::Spec->catfile( TMP_DIR, 'foobar.foobar666.log' );

# a fake PID, doesn't matter anyway
create_ent_log( 1234, ENTERPRISE_LOG );

BEGIN { use_ok('Siebel::Srvrmgr::Log::Enterprise') }

my $ent_log =
  Siebel::Srvrmgr::Log::Enterprise->new( { path => ENTERPRISE_LOG } );

foreach my $attrib (qw(eol fs fh filename header)) {

    has_attribute_ok( $ent_log, $attrib,
        "attribute $attrib is available on a instance" );

}

my @methods = (
    'get_path',      'get_eol',    '_set_eol',    'get_fs',
    '_set_fs',       'get_fh',     '_set_fh',     'get_filename',
    '_set_filename', 'get_header', '_set_header', '_check_header',
    'DEMOLISH',      '_define_fs', '_define_eol',
);

can_ok( $ent_log, @methods );

my $next = $ent_log->read();
is( ref($next), 'CODE', 'read method returns a code reference' );
like( $next->(), qr/ServerStartup/, 'iterator returns a expected content' );
like( $ent_log->get_header(), qr/\w+/,  'get_header method returns a string' );
like( $ent_log->get_fs(),     qr/\t/,   'get_fs returns a tab' );
like( $ent_log->get_eol(),    qr/\r\n/, 'get_eol returns a CRLF' );
like(
    $ent_log->get_filename(),
    qr/^Siebel_Srvrmgr_Log_Enterprise_/,
    'get_filename returns the correct path'
);

done_testing();
