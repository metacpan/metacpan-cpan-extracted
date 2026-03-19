#!perl
use v5.36;
use Test::More;

{
  # Require
  require_ok('PlackX::Framework::Response');

  # Create
  {
    my $response = PlackX::Framework::Response->new;
    ok($response, 'Create response object');
    isa_ok($response, 'PlackX::Framework::Response');

    # Response properties
    ok(!$response->isa('Plack::Request' ));
    ok( $response->isa('Plack::Response'));

    # Stop and continue
    ok(ref $response->stop,  'Stop');
    ok(not($response->next), 'Next');
  }

  # Charset then Content type
  {
    my $response = PlackX::Framework::Response->new;
    is_deeply(
      [$response->content_type] => [''],
      'Empty content_type upon new()'
    );

    $response->charset('abc');
    is(
      $response->charset => 'abc',
      'Charset set successfully (before content_type)'
    );

    $response->content_type('text/test');
    is_deeply(
      [$response->headers->content_type] => ['text/test', 'charset=abc'],
      'Set charset then content-type'
    );

    # Set charset with content_type overrides earlier charset() call
    $response->content_type('text/test2; charset=def');
    is_deeply(
      [$response->headers->content_type] => ['text/test2', 'charset=def'],
      'Content_type is correct after setting content-type then charset'
    );
  }

  # Content-type then charset
  {
    my $response = PlackX::Framework::Response->new;
    $response->content_type('text/test3; charset=hij');
    $response->charset('klm');
    is(
      $response->charset => 'klm',
      'Charset set successfully (after content-type)'
    );
    is_deeply(
      [$response->headers->content_type] => ['text/test3', 'charset=klm'],
      'Content_type is correct after setting content-type then charset'
    );
  }

  # Print
  {
    my $response = PlackX::Framework::Response->new;
    $response->print('Line 1');
    $response->print('Line 2');
    my $body = join '', $response->body->@*;
    ok($body eq 'Line 1Line 2');
  }

  # Flash
  {
    # We have to subclass to override flash_cookie_name()
    eval q{
      package PXF_Test_Response {
        use parent 'PlackX::Framework::Response';
        sub app_namespace     { die }
        sub flash_cookie_name { 'flash-123456789-test' }
      }
      1;
    } or die 'Could not create sublcass of PXFR: ' .$@;

    my $response = PXF_Test_Response->new(200);
    $response->flash("A plain string!");
    is(
      $response->finalize->[1][0] => 'Set-Cookie',
      'Flash cookie is set'
    );

    my ($cookie_value) = split /; /, $response->finalize->[1][1];
    is(
      $cookie_value => 'flash-123456789-test=A%20plain%20string%21',
      'Flash cookie value is correct (plain string)'
    );

    # This should get converted to JSON-url-base64
    my $hashref = { title => "Hello\r\n", message => 'World!!!?', array => [0..9] };
    $response->flash($hashref);
    ($cookie_value) = split /; /, $response->finalize->[1][1];
    ok(
      $cookie_value =~
      m/^flash-123456789-test=flash-123456789-test-ju64-([a-zA-Z0-9_-]+)$/,
      'Flash cookie hashref is converted to JSON ub64'
    );

    my $coded = $1;
    is_deeply(
      PXF::Util::decode_ju64($coded) => $hashref,
      'JSON cookie decoded back to hashref correctly'
    );
  }

}
done_testing();
