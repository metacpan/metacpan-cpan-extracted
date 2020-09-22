#!perl
use 5.006;
use strict;
use warnings;
use Test::More tests => 16;

use FindBin;
use lib "$FindBin::Bin/lib";
use Path::Tiny;
use Mock::Plasp;

BEGIN { use_ok 'Plasp'; }
BEGIN { use_ok 'Plasp::Request'; }

my $Request;

$Request = mock_asp( type => 'upload' )->Request;
ok( !$Request->BinaryRead( 26 ),
    '$Request->BinaryRead should be undef for file uploads'
);
is( $Request->ClientCertificate,
    undef,
    'Unimplemented method $Request->ClientCertificate'
);
is( $Request->Cookies( 'foo' ),
    'bar',
    '$Request->Cookies returned simple cookie'
);
is( $Request->Cookies( 'foofoo', 'baz' ),
    'bar',
    '$Request->Cookies returned correct hash cookie'
);
is( $Request->Cookies( 'foofoo', 'bar' ),
    'baz',
    '$Request->Cookies returned correct hash cookie'
);
is( $Request->FileUpload( 'foofile', 'ContentType' ),
    'text/plain',
    '$Request->FileUpload returned correct Content-Type'
);
is( $Request->FileUpload( 'foofile', 'BrowserFile' ),
    'foo.txt',
    '$Request->FileUpload returned correct uploaded filename'
);
mock_asp( type => 'upload' )->cleanup;

$Request = mock_asp( type => 'post' )->Request;
is( $Request->BinaryRead( 26 ),
    'foo=bar&bar=foo&baz=foobar',
    '$Request->BinaryRead got correct data back'
);
is( $Request->Form( 'foo' ),
    'bar',
    '$Request->Form returned correct form value'
);
my %form = %{ $Request->Form };
is( $form{foo},
    'bar',
    '$Request->Form hash returned correct form value'
);
is( $Request->Params( 'foobar' ),
    'baz',
    '$Request->Params returned correct parameter value'
);
is( $Request->Params( 'bar' ),
    'foo',
    '$Request->Params returned correct parameter value'
);
mock_asp( type => 'post' )->cleanup;

$Request = mock_asp->Request;
is( $Request->QueryString( 'foobar' ),
    'baz',
    '$Request->QueryString returned correct query string value'
);
like( $Request->ServerVariables( 'PATH' ),
    qr|.|,
    '$Request->ServerVariables contains environment variables'
);
mock_asp->cleanup;
