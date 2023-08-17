#!perl
# most of these tests assume that the following is available
#   gemini://gemini.thebackupbox.net/test/torture/
#
# however, various environment variables must be set for the network
# tests to actually happen, and most are commented out as I didn't want
# to hammer epoch's system too much while working through the list.
# probably they would only need a review if Net::Gemini or the
# specification (and thus tests) change, and hopefully enough of these
# tests are covered in other test files
use strict;
use warnings;
use Data::Dumper;
use Net::Gemini 'gemini_request';
use Parse::MIME 'parse_mime_type';
use Test2::V0;
use URI ();

my $base = 'gemini://gemini.thebackupbox.net/test/torture/';

# these are from the body of '0019' (and also '0020' without trailing text),
# confirm that URI does not do anything silly with time
for my $eg (
    'gopher://gopher.thebackupbox.net/', 'http://www.thebackupbox.net/',
    'about:blank',                       'example:test'
) {
    my $u = URI->new_abs( $eg, 'gemini://whatever.example.org/' );
    is $u->canonical, $eg;
}

# URI maybe throws out the illegal characters because <mailto:...>
# is a common URL quoting form? at least test this here in the event
# URI changes it
my $u = URI->new_abs( '<0032>', $base . '0031' );
is $u->canonical, $base . '0032';

if ( $ENV{AUTHOR_TEST_JMATES} and $ENV{GEMINI_NET_TESTS} ) {

    $Data::Dumper::Terse = 1;

    sub request {
        my ( $uri, %param ) = @_;
        my ( $gem, $code )  = gemini_request($uri);
        diag("URI $uri");
        my $ok = is( $gem->{_status}, 20 );
        if ( !$ok ) {
            diag( "  FAIL code $code status " . $gem->{_status} );
        } else {
            if ( $param{mime} ) {
                my ( $type, $sub, $pr ) = parse_mime_type( $gem->meta );
                is( $type,          'text' );
                is( $sub,           'gemini' );
                is( $pr->{charset}, $param{charset} )        if exists $param{charset};
                is( $pr->{CHARSET}, $param{shouty_charset} ) if exists $param{shouty_charset};
                is( $pr->{format},  $param{mime_format} )    if exists $param{mime_format};
                is( $pr->{foo},     $param{mime_foo} )       if exists $param{mime_foo};
                diag "MIME $type/$sub " . Dumper($pr);
            }
        }
        # the content has instructions
        my $body = $gem->{_content};
        $body = '(no-content)' unless length $body;
        diag "\n" . $body;
        return $gem;
    }

    my ( $g, $url );

    # testing that the URI module is correct (none of these failed
    # for me, besides the "illegal character" test up at the top of
    # this file)

    #request( $base . '0001' );
    #$g = request( $base . '0002' );
    # URI->new_abs() is how bin/gmitool is doing relative requests
    #$g = request( URI->new_abs( '//gemini.thebackupbox.net/test/torture/0003', $g->{_uri} ));
    # which should be the same as the following
    #request( URI->new_abs( '//gemini.thebackupbox.net/test/torture/0003', $base . '0002' ));
    #request( URI->new_abs( '//gemini.thebackupbox.net/test/torture/0004', $base . '0003' ));
    #request( URI->new_abs( '/test/torture/0005', $base . '0004' ));
    # this one lacks any after-link text, which we aren't really testing
    # here, and I'm pretty sure the relevant code in gmitool handles that
    #request( URI->new_abs( '/test/torture/0006', $base . '0005' ));
    #request( URI->new_abs( '0007', $base . '0006' ));
    #request( URI->new_abs( '0008', $base . '0007' ));
    #request( URI->new_abs( '/test/../test/torture/0009', $base . '0008' ));
    #request( URI->new_abs( '/test/torture/../../test/./torture/0010', $base . '0009' ));
    #request( URI->new_abs( '../../../../test/./././torture/./0011', $base . '0010' ));

    # MIME -- that Parse::MIME is correct

    #request( URI->new_abs( '0012', $base . '0011' ), mime => 1, charset => 'utf-8' );
    #request( URI->new_abs( '0013', $base . '0012' ), mime => 1, charset => 'iso-8859-1' );
    #request( URI->new_abs( '0014', $base . '0013' ), mime => 1, charset => 'us-ascii' );
    #request( URI->new_abs( '0015', $base . '0014' ), mime => 1, mime_format => 'flowed' );
    #request( URI->new_abs( '0016', $base . '0015' ), mime => 1, mime_foo => 'bar' );
    #request( URI->new_abs( '0017', $base . '0016' ), mime => 1, mime_format => 'flowed', mime_foo => 'bar' );
    #request( URI->new_abs( '0018', $base . '0017' ), mime => 1, charset => 'utf-8' );

    # NOTE client code may need to look for CHARSET vs. charset, see
    # bin/gmitool for an example
    #request( URI->new_abs( '0019', $base . '0018' ), mime => 1, shouty_charset => 'UTF-8' );
    #request( URI->new_abs( '0020', $base . '0019' ) );
    #request( URI->new_abs( '0021', $base . '0020' ) );

    # from '0021', with, uh, love?
    #for my $eg ( 'data:text/gemini;charset=utf-8,This%20is%20a%20test%20of%20a%20Gemini%20index%20page.%20%20For%20this%20page%2C%20this%20server%20will%0D%0Aconduct%20a%20test%20of%20URL%20processing.%20%20This%20is%20only%20a%20test.%20%20If%20this%20had%20been%20an%0D%0Aactual%20page%2C%20you%20would%20have%20connected%20to%20the%20server%20and%20retrieved%20an%20actual%0D%0Apage.%20%20This%20has%20been%20a%20test%20of%20a%20Gemini%20index%20page.%0D%0A%3D%3E%20gemini%3A%2F%2Fgemini.thebackupbox.net%2Ftest%2Ftorture%2F0022%0D%0A', 'data:text/gemini;charset=utf-8;base64,VGhpcyBpcyBhIHRlc3Qgb2YgYSBHZW1pbmkgaW5kZXggcGFnZS4gIEZvciB0aGlzIHBhZ2UsIHRoaXMgc2VydmVyIHdpbGwNCmNvbmR1Y3QgYSB0ZXN0IG9mIFVSTCBwcm9jZXNzaW5nLiAgVGhpcyBpcyBvbmx5IGEgdGVzdC4gIElmIHRoaXMgaGFkIGJlZW4gYW4NCmFjdHVhbCBwYWdlLCB5b3Ugd291bGQgaGF2ZSBjb25uZWN0ZWQgdG8gdGhlIHNlcnZlciBhbmQgcmV0cmlldmVkIGFuIGFjdHVhbA0KcGFnZS4gIFRoaXMgaGFzIGJlZW4gYSB0ZXN0IG9mIGEgR2VtaW5pIGluZGV4IHBhZ2UuDQo9PiBnZW1pbmk6Ly9nZW1pbmkuY29ubWFuLm9yZy90ZXN0L3RvcnR1cmUvMDAyMg0K' ) {
    #    my $u = URI->new_abs( $eg, 'gemini://gemini.thebackupbox.net/test/torture/' );
    #    diag "DATA>>>" . $u->data . "<<<";
    #}

    # REDIRECTONS - these return 51 as epoch had not gotten the source for
    # them at the time (some may still not be implemented?)

    #request( URI->new_abs( '0022', $base . '0021' ) );
    #request( URI->new_abs( '/test/redirhell/', $base . '0022' ) );
    #request( URI->new_abs( '0023', $base . '0022' ) );
    #request( URI->new_abs( '/test/redirhell2/', $base . '0023' ) );
    #request( URI->new_abs( '0024', $base . '0023' ) );
    #request( URI->new_abs( '/test/redirhell3/', $base . '0024' ) );
    #request( URI->new_abs( '0025', $base . '0024' ) );
    #request( URI->new_abs( '/test/redirhell4/', $base . '0025' ) );
    #request( URI->new_abs( '0026', $base . '0025' ) );
    #request( URI->new_abs( '/test/redirhell5/', $base . '0026' ) );
    # and a surprise gopher redirection
    #request( URI->new_abs( '0027', $base . '0026' ) );
    #request( URI->new_abs( '/test/redirhell6/', $base . '0027' ) );

    # URI gives a link of "gemini://gemini.thebackupbox.net/test/torture/This" from
    # "=> This is out of order gemini://gemini.thebackupbox.net/test/torture/'0029'"
    # which seems pretty reasonable?
    #request( URI->new_abs( '0028', $base . '0027' ) );
    #request( URI->new_abs( '0029', $base . '0028' ) );
    #request( URI->new_abs( '0030', $base . '0029' ) );

    #request( URI->new_abs( '0031', $base . '0030' ) );

    # empty link is skipped by gmitool
    #   perl ./bin/gmitool get -l gemini://gemini.thebackupbox.net/test/torture/'0032'
    #request( URI->new_abs( '0032', $base . '0031' ) );

    #   perl ./bin/gmitool get -l gemini://gemini.thebackupbox.net/test/torture/'0033'
    #request( URI->new_abs( '0033', $base . '0032' ) );

    # t/30-gemini.t should cover this
    #request( URI->new_abs( '0034', $base . '0033' ) );
    #{
    #    my ( $gem, $code ) = gemini_request('gemini://gemini.thebackupbox.net/test/torture/0034a');
    #    is $code, 0;
    #    like $gem->{_error}, qr/invalid response/;
    #}

    # TODO not sure how '29' is undefined, specification as I read it says a
    # 2x can put any digit in for x?
    #request( URI->new_abs( '0035', $base . '0034' ) );
    #{
    #    my ( $gem, $code ) = gemini_request('gemini://gemini.thebackupbox.net/test/torture/0035a');
    #    is $code, 2;
    #    is $gem->{_status}, 29;
    #}

    # "This page will return a status of '39'" -> "invalid response 20.d.a"
    #request( URI->new_abs( '0036', $base . '0035' ) );
    #{
    #    my ( $gem, $code ) = gemini_request('gemini://gemini.thebackupbox.net/test/torture/0036a');
    #    diag $code;
    #    diag $gem->{_error};
    #}

    #request( URI->new_abs( '0037', $base . '0036' ) );
    #{
    #    my ( $gem, $code ) = gemini_request('gemini://gemini.thebackupbox.net/test/torture/0037a');
    #    is $code, 4;
    #    is $gem->{_status}, 49;
    #}

    #request( URI->new_abs( '0038', $base . '0037' ) );
    #{
    #    my ( $gem, $code ) = gemini_request('gemini://gemini.thebackupbox.net/test/torture/0038a');
    #    is $code, 5;
    #    is $gem->{_status}, 58;
    #}

    #request( URI->new_abs( '0039', $base . '0038' ) );
    #{
    #    my ( $gem, $code ) = gemini_request('gemini://gemini.thebackupbox.net/test/torture/0039a');
    #    is $code, 0;
    #    like $gem->{_error}, qr/invalid response/;
    #}

    #request( URI->new_abs( '0040', $base . '0039' ) );
    #{
    #    my ( $gem, $code ) = gemini_request('gemini://gemini.thebackupbox.net/test/torture/0040a');
    #    is $code, 0;
    #    like $gem->{_error}, qr/invalid response/;
    #}

    # has a really long line it it... probably no issue for this code (I'm
    # punting the issue of how a client should display or wrap the text to
    # something else, e.g. Text::Wrap or Text::Autoformat or via some pager
    # like less or vi)
    #request( URI->new_abs( '0041', $base . '0040' ) );

    # specifications suggests to break on "-" for long lines like this one has
    #request( URI->new_abs( '0042', $base . '0041' ) );

    # long text, nothing obvious to break on
    #request( URI->new_abs( '0043', $base . '0042' ) );

    # long text with UTF-8...
    #request( URI->new_abs( '0044', $base . '0043' ) );
    #request( URI->new_abs( '0045', $base . '0044' ) );
    #request( URI->new_abs( '0046', $base . '0045' ) );
    #request( URI->new_abs( '0047', $base . '0046' ) );
    #request( URI->new_abs( '0048', $base . '0047' ) );
    #request( URI->new_abs( '0049', $base . '0048' ) );
    #request( URI->new_abs( '0050', $base . '0049' ) );
    #request( URI->new_abs( '0051', $base . '0050' ) );

} else {
    diag 'many torture tests are author only';
}
done_testing
