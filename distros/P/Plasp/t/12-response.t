#!perl
use 5.006;
use strict;
use warnings;
use Test::More tests => 43;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/lib";
use Mock::Plasp;
use Path::Tiny;
use Plack::Util;

BEGIN { use_ok 'Plasp'; }
BEGIN { use_ok 'Plasp::Response'; }

my ( $script, $htmlref );
my ( $status, $headers, $body, @cookies, $Response );

my $headers_writer = sub { $status = $_[0]; $headers = [ @{ $_[1] } ] };
my $content_writer = sub { push @$body, $_[0] };

$Response = mock_asp->Response;
tie local *STDOUT, 'Plasp::Response';

# Building a Reponse object in CatalystX::ASP fashion, ie. buffer until end of
# processing. Nothing will get sent the client until everything is complete
$Response->AppendToLog( 'a debug message' );
ok( grep( $_->{message} =~ /a debug message/, @{ mock_logger->entries } ),
    '$Response->AppendToLog added to proper debug log'
);
$Response->AddHeader( 'X-Foo' => 'bar' );
$headers = { @{ $Response->Headers } };
is( $headers->{'X-Foo'},
    'bar',
    '$Response successfully set X-Foo header'
);
$Response->Cookies( 'foo', 'bar' );
@cookies = @{ $Response->CookiesHeaders };
ok( grep( /foo=bar/, @cookies ),
    '$Response->Cookies wrote out simple cookie'
);
$Response->Cookies( 'foofoo', 'baz', 'bar' );
@cookies = @{ $Response->CookiesHeaders };
ok( grep( /foofoo=baz%3Dbar/, @cookies ),
    '$Response->Cookies wrote out correct hash cookie'
);
$Response->Cookies( 'foofoo', 'bar', 'baz' );
@cookies = @{ $Response->CookiesHeaders };
ok( grep( /foofoo=.*bar%3Dbaz/, @cookies ),
    '$Response->Cookies wrote out correct hash cookie'
);
print "THIS GOES TO THE CLIENT\n";
like( $Response->Output,
    qr/THIS GOES TO THE CLIENT/,
    'print STDOUT goes to $Response->Output'
);
printf "THIS ALSO GOES TO THE CLIENT\n";
like( $Response->Output,
    qr/THIS ALSO GOES TO THE CLIENT/,
    'printf STDOUT goes to $Response->Output'
);
$Response->BinaryWrite( "THIS ALSO ALSO GOES TO THE CLIENT\n" );
like( $Response->Output,
    qr/THIS ALSO ALSO GOES TO THE CLIENT/,
    '$Response->BinaryWrite goes to $Response->Output'
);
$Response->WriteRef( \"THIS ALSO ALSO ALSO GOES TO THE CLIENT\n" );
like( $Response->Output,
    qr/THIS ALSO ALSO ALSO GOES TO THE CLIENT/,
    '$Response->WriteRef goes to $Response->Output'
);
$Response->Flush;
like( $Response->Output,
    qr/THIS ALSO ALSO ALSO GOES TO THE CLIENT/,
    '$Response->Output contains expected output after $Response->Flush'
);
$Response->Write( "THIS SHOULD NOT GO TO THE CLIENT\n" );
$Response->Clear;
like( $Response->Output,
    qr/THIS ALSO ALSO ALSO GOES TO THE CLIENT/,
    '$Response->Output contains expected output after $Response->Flush and $Response->Clear'
);
unlike( $Response->Output,
    qr/THIS SHOULD NOT GO TO THE CLIENT/,
    '$Response->Output doesn\'t contain unexpected output after $Response->Clear'
);

# Build a response object yet stream response to client as it comes, ie. when
# Flush is called, actually send to client. Run same tests as above.
$Response = mock_asp( create_new => 1 )->Response;
tie local *STDOUT, 'Plasp::Response';
$Response->_headers_writer( $headers_writer );
$Response->_content_writer( $content_writer );
( $status, $headers, $body ) = ( undef, undef, undef );

$Response->AddHeader( 'X-Foo', 'bar' );
ok( !$headers,
    '$Response has not written X-Foo header out yet'
);
$Response->Cookies( 'foo', 'bar' );
ok( !$headers,
    '$Response has not written Cookies headers out yet'
);
$Response->Cookies( 'foofoo', 'baz', 'bar' );
$Response->Cookies( 'foofoo', 'bar', 'baz' );
$Response->Flush;
is( Plack::Util::header_get( $headers, 'X-Foo' ),
    'bar',
    '$Response successfully set X-Foo header'
);
@cookies = @{ $Response->CookiesHeaders };
ok( grep( /foo=bar/, @cookies ),
    '$Response->Cookies wrote out simple cookie'
);
ok( grep( /foofoo=.*baz%3Dbar/, @cookies ),
    '$Response->Cookies wrote out correct hash cookie'
);
ok( grep( /foofoo=.*bar%3Dbaz/, @cookies ),
    '$Response->Cookies wrote out correct hash cookie'
);
print "THIS GOES TO THE CLIENT\n";
like( $Response->Output,
    qr/THIS GOES TO THE CLIENT/,
    'print STDOUT goes to $Response->Output'
);
printf "THIS ALSO GOES TO THE CLIENT\n";
like( $Response->Output,
    qr/THIS ALSO GOES TO THE CLIENT/,
    'printf STDOUT goes to $Response->Output'
);
$Response->BinaryWrite( "THIS ALSO ALSO GOES TO THE CLIENT\n" );
like( $Response->Output,
    qr/THIS ALSO ALSO GOES TO THE CLIENT/,
    '$Response->BinaryWrite goes to $Response->Output'
);
$Response->WriteRef( \"THIS ALSO ALSO ALSO GOES TO THE CLIENT\n" );
like( $Response->Output,
    qr/THIS ALSO ALSO ALSO GOES TO THE CLIENT/,
    '$Response->WriteRef goes to $Response->Output'
);
$Response->Flush;
ok( !$Response->Output,
    '$Response->Output should be empty after $Response->Flush'
);
ok( grep ( /THIS GOES TO THE CLIENT/, @$body ),
    'Initial output should now be with client after $Response->Flush'
);
ok( grep ( /THIS ALSO ALSO ALSO GOES TO THE CLIENT/, @$body ),
    'Last output should now be with client after $Response->Flush'
);
$Response->Write( "THIS SHOULD NOT GO TO THE CLIENT\n" );
$Response->Clear;
ok( !grep ( /THIS SHOULD NOT GO TO THE CLIENT/, @$body ),
    'Client should not have Output after $Response->Clear'
);
ok( !$Response->Output,
    '$Response->Output should be empty after $Response->Clear'
);

$Response->Debug( { foo => 'bar', bar => 'foo' } );
ok( grep( $_->{message} =~ /foo.*bar/, @{ mock_logger->entries } ),
    '$Response->Debug added to proper debug log'
);
throws_ok( sub { $Response->End },
    'Plasp::Exception::End',
    '$Response->End threw an End exception'
);
is( $Response->ErrorDocument,
    undef,
    'Unimplemented method $Response->ErrorDocument'
);
$Response->Include( 'templates/some_other_template.inc' );
like( $Response->Output,
    qr|<p>I've been included!</p>|,
    '$Response->Include wrote out template into $Response->Output'
);
$script = "<%= q(I've also been included!) %>";
$Response->Include( \$script );
like( $Response->Output,
    qr|I've also been included!|,
    '$Response->Include wrote out script ref into $Response->Output'
);
$script  = "<%= q(I've also also been included!) %>";
$htmlref = $Response->TrapInclude( \$script );
unlike( $Response->Output,
    qr|I've also also been included!|,
    '$Response->TrapInclude didn\'t write to $Response->Output'
);
like( $$htmlref,
    qr|I've also also been included!|,
    '$Response->TrapInclude returned correct captured output in ref'
);
is( $Response->IsClientConnected,
    1,
    '$Response->IsClientConnected will always return 1'
);
throws_ok( sub { $Response->Redirect( '/hello_world.asp' ) },
    'Plasp::Exception::Redirect',
    '$Response->Redirect threw a Redirect exception'
);
$Response->Flush;
isnt( $status,
    302,
    '$Response->Redirect can\'t change status if already flushed once'
);
isnt( Plack::Util::header_get( $headers, 'Location' ),
    '/hello_world.asp',
    '$Response->Redirect can\'t change location if already flushed once'
);

$Response = mock_asp( create_new => 1 )->Response;
tie local *STDOUT, 'Plasp::Response';
$Response->_headers_writer( $headers_writer );
$Response->_content_writer( $content_writer );
( $status, $headers, $body ) = ( undef, undef, undef );

throws_ok( sub { $Response->Redirect( '/hello_world.asp' ) },
    'Plasp::Exception::Redirect',
    '$Response->Redirect threw a Redirect exception'
);
$Response->Flush;
is( $status,
    302,
    '$Response->Redirect set status to 302 in response'
);
is( Plack::Util::header_get( $headers, 'Location' ),
    '/hello_world.asp',
    '$Response->Redirect set location in response'
);
