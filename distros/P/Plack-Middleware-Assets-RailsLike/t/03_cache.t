use utf8;
use strict;
use warnings;
use t::Util qw(compiled_js compiled_css);
use Test::More;
use Test::Name::FromLine;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Cache::MemoryCache;

{
    package MyCache;

    sub new {
        my $class = shift;
        bless {}, $class;
    }

    sub get {
        my $self = shift;
        my ($key) = @_;
        return $self->{$key};
    }

    sub set {
        my $self = shift;
        my ($key, $content, $expires) = @_;
        $self->{$key} = [$content, $expires];
    }
}

my $cache = MyCache->new;
my $app = builder {
    enable 'Assets::RailsLike',
        cache   => $cache,
        root    => './t',
        expires => 12345,
        minify  => 0;
    sub { [ 200, [ 'Content-Type', 'text/html' ], ['OK'] ] };
};

test_psgi(
    app    => $app,
    client => sub {
        my $cb = shift;

        subtest 'javascript' => sub {
            my $res = $cb->( GET '/assets/application.js' );
            is $res->code,    200;
            is $res->content, compiled_js;
        };

        subtest 'css' => sub {
            my $res = $cb->( GET '/assets/application.css' );
            is $res->code,    200;
            is $res->content, compiled_css;
        };

        subtest 'with versioning' => sub {
            my $res = $cb->( GET '/assets/application-123456789.js' );
            is $res->code,    200;
            is $res->content, compiled_js;
        };
    }
);

sub cache_ok {
    my ( $name, $key, $expected ) = @_;
    subtest $name => sub {
        my $cached = $cache->get($key);
        is $cached->[0], $expected;
        is $cached->[1], 12345;
    };
}

cache_ok( 'js cache',  't/assets/application.js',  compiled_js );
cache_ok( 'css cache', 't/assets/application.css', compiled_css );
cache_ok( 'with versioning cache',
    't/assets/application-123456789.js', compiled_js );

done_testing;
