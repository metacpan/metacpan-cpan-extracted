use strict;
use warnings;
use v5.10;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use Plack::App::unAPI;

my $app = Plack::App::unAPI->new;

test_psgi $app, sub {
    my $res = (shift)->(GET '/');
    is $res->code, 300, "Multiple Choices";
    like $res->content, qr{<formats>\s*</formats>}, 'empty list of formats';
};

{
    package unAPIServerTest1;
    use parent 'Plack::App::unAPI';

    sub format_json {
        return $_[1] eq 'bar' ? '{"x":1}' : undef; 
    }
}

{
    package unAPIServerTest2;

    our @ISA = qw(unAPIServerTest1);

    sub prepare_app {
        my $self = shift;
        $self->formats( {
            txt  => [ 'text/plain', docs => 'http://example.com' ],
            json => [ 'application/json' ], 
        } );
        $self->SUPER::prepare_app();
    }

    sub format_txt {
        my ($self, $id, $env) = @_;
        return $id eq 'foo' ? "FOO".ref($env) : undef;
    }
}

#eval {
#    $app = unAPIServerTest1->new;
#    $app->prepare_app;
#};
#ok $@, 'formats must be implemented';

$app = unAPIServerTest2->new->to_app;

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET '/');
    is $res->code, 300, "Multiple Choices";

    is_deeply
        [sort grep { /^<format / } split "\n", $res->content],
        ['<format name="json" type="application/json" />', 
         '<format name="txt" type="text/plain" docs="http://example.com" />'],
        'list formats';

    $res = $cb->(GET '/?id=foo&format=txt');
    is $res->code, 200, "Ok";
    is $res->content, "FOOHASH", "FOOHASH";
 
    $res = $cb->(GET '/?id=foo&format=json');
    is $res->code, 404, "Not Found";

    $res = $cb->(GET '/?id=bar&format=json');
    is $res->code, 200, "Ok";
    is $res->content, '{"x":1}', "format=json";
};

done_testing;
