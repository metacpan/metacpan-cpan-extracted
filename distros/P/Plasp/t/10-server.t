#!perl
use 5.006;
use strict;
use warnings;
use Test::More tests => 17;
use Test::Exception;
use utf8;

use FindBin;
use lib "$FindBin::Bin/lib";
use Mock::Plasp;
use Path::Tiny;

BEGIN { use_ok 'Plasp'; }
BEGIN { use_ok 'Plasp::Server'; }

my ( $root, $Response, $Server );

$Server   = mock_asp->Server;
$Response = mock_asp->Response;

is( $Server->Config( 'GlobalPackage' ),
    'TestApp::ASP',
    '$Server->Config got correct server configuration'
);
is( $Server->CreateObject,
    undef,
    'Unimplemented method $Server->CreateObject'
);
is( [ $Server->Execute( 'templates/some_template.inc' ) ]->[0],
    "I've been included!",
    '$Server->Execute returned correct value'
);
$root = path( $FindBin::Bin, '../t/lib/TestApp/root' )->realpath;
is( $Server->File,
    path( $root, 'welcome.asp' ),
    '$Server->File returned correct calculated value of file'
);
is( $Server->GetLastError,
    undef,
    'Unimplemented method $Server->GetLastError'
);
is( $Server->HTMLEncode( '<&>' ),
    '&lt;&amp;&gt;',
    '$Server->HTMLEncode got expected encoded HTML entities'
);
is( $Server->MapInclude( 'templates/some_template.inc' ),
    path( $root, 'templates/some_template.inc' ),
    '$Server->MapInclude returned correct calculated value of include'
);

# $c->path_to hardcodes to the file path of /welcome.asp
is( $Server->MapPath( 'http://domainname/welcome.asp' ),
    path( $root, 'welcome.asp' ),
    '$Server->MapPath returned correct calculated file path of URL'
);
require Net::SMTP;
if ( Net::SMTP->new( mock_asp->MailHost ) ) {
    ok(
        $Server->Mail( {
                To      => sprintf( '%s@localhost', $ENV{USER} || 'root' ),
                From    => sprintf( '%s@localhost', $ENV{USER} || 'root' ),
                Subject => 'foobar',
                Body    => 'foobar'
        } ),
        sprintf( '$Server->Mail mailed to %s@localhost', $ENV{USER} || 'root' )
    );
} else {
TODO: {
        local $TODO = sprintf( '$Server->Mail untested, startup a mail server at %s', mock_asp->MailHost );
        fail( '$Server->Mail mailed to /dev/null' );
    }
}
is( $Server->RegisterCleanup,
    undef,
    'Unimplemented method $Server->RegisterCleanup'
);
throws_ok( sub { $Server->Transfer( 'templates/some_other_template.inc' ) },
    'Plasp::Exception::End',
    '$Server->Transfer threw an End exception'
);
like( $Response->Output,
    qr{<p>I've been included!</p>},
    '$Server->Transfer returned correct value'
);
is( $Server->URLEncode( '社群首页' ),
    '%E7%A4%BE%E7%BE%A4%E9%A6%96%E9%A1%B5',
    '$Server->URLEncode properly encoded text'
);
is( $Server->URL( '/foobar', { foo => 'bar' } ),
    '/foobar?foo=bar',
    '$Server->URL properly converted params into query string'
);
is( $Server->XSLT,
    undef,
    'Unimplemented method $Server->XSLT'
);
