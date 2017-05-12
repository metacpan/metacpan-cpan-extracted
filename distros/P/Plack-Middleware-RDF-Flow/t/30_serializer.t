use strict;
use warnings;

use Test::More;
use Plack::Test;

{
    package RDF::Trine::Serializer::MyTest;
    use parent 'RDF::Trine::Serializer';

    our $mime_type = "text/plain";

    $RDF::Trine::Serializer::serializer_names{'mytest'}
        = 'RDF::Trine::Serializer::MyTest';

    sub new {
        my ($class, %args) = @_;
        bless \%args, $class;
    }

    sub serialize_model_to_string {
        return "xxx";
    }

    sub media_types {
        return (shift->{mime} || "text/plain");
    }

    1;
}

use RDF::Flow::Dummy;
use Plack::Middleware::RDF::Flow;
use HTTP::Request::Common;

my $ser = RDF::Trine::Serializer->new('mytest');
is( ($ser->media_types), ('text/plain'), 'my serializer' );

my $app = Plack::Middleware::RDF::Flow->new(
    source  => RDF::Flow::Dummy->new,
    formats => {
        ttl => 'turtle',
        xxx => RDF::Trine::Serializer->new( 'mytest', mime => 'text/xxx' ),
    }
);

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->( GET '/foo?format=ttl' );
    is( $res->code, 200, 'turtle format' );
    like( $res->content, qr{foo> a <http://www.w3.org/2000/01/rdf-schema#Resource>}, 'ttl' );

    $res = $cb->( GET '/foo?format=xxx' );
    is( $res->code, 200, 'xxx format' );
    is( $res->header('Content-Type'), 'text/xxx', 'content type' );
    is( $res->content, 'xxx', 'serialized' );
};

done_testing;
