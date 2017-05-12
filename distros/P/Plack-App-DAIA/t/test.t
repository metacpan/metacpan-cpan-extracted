use strict;
use warnings;

use Test::Builder::Tester tests => 1;
use Test::More;
use Plack::App::DAIA::Test;
use DAIA;

# no valid DAIA response
test_out("not ok 1 - retrieve method returned a DAIA::Response");
test_fail(+1);
test_daia sub { 1; }, 'my:id' => sub { };

test_out("ok 2 - simple DAIA response");
test_daia 
    sub { DAIA::Response->new; }, 
    'my:id' 
        => { },
    'simple DAIA response';

my $app = sub {
    my $id = shift;
    return DAIA::Response->new if $id ne 'foo:bar';
    my $daia = DAIA::Response->new;
    $daia->addDocument( id => $id );
    return $daia;
};

test_out('ok 3 - $_ set');
test_out('ok 4 - \'response passed\' isa \'DAIA::Response\'');
test_out('ok 5 - response has document');
test_daia $app,
    'foo:bar' => sub { 
        my $res = shift;
        is( $_, $res, '$_ set' ); 
        isa_ok( $res, 'DAIA::Response', 'response passed' ); 
        is( scalar $res->document, 1, 'response has document' );
    };


test_out('ok 6 - response has no document');
test_daia $app,
    'foo:doz' => sub {
        ok( ! $_->document, 'response has no document' );
    };

test_test("Plack::App::DAIA::Test works (at least a bit)");
