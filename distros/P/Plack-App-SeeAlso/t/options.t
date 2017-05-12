use strict;
use warnings;
use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

use Plack::App::SeeAlso;

{
    package Foo;
    use parent 'Plack::App::SeeAlso';

    our $ShortName = 'The ShortName is truncated';
    our $Contact   = 'admin@example.com';
}

my $app = Foo->new(
    Developer => 'admin@example.org',
);

sub read_file { do { local( @ARGV, $/ ) = $_[0] ; <> } }

test_psgi $app, sub {
    my $cb  = shift;

    my $res = $cb->(GET "/?format=opensearchdescription");
    is( $res->content, read_file('t/osd1.xml'), 'OSD XML'  );

    $res = $cb->(GET "/");
    like( $res->content, qr{<\?xml-stylesheet}, 'has stylesheet' );
};

$app = Foo->new(
    Stylesheet  => undef,
    Query       => sub {
        my $id = shift;
        return if $id eq 'nope';
        die 'Oh, my!' if $id eq 'boom';
        push_seealso [$id], 'foo', 'bar', 'doz';
    }
);

# catch errors
{
    package MyErrorHandler;
    sub new { bless $_[1], $_[0]; }
    sub print { ${$_[0]} = $_[1] };
}
my $error;
$app = builder {
    enable sub {
        my $app = shift;
        sub {
            my $env = shift;
            $error = '';
            $env->{'psgi.errors'} = MyErrorHandler->new( \$error );
            $app->($env);
        }
    };
    $app;
};

test_psgi $app, sub {
    my $cb  = shift;

    my $res = $cb->(GET "/");
    ok( $res->content !~ qr{<\?xml-stylesheet}, 'stylesheet disabled' );

    $res = $cb->(GET "/?id=xyz&format=seealso");
    is( $res->content, '["xyz",["foo"],["bar"],["doz"]]', 'content ok' );

    $res = $cb->(GET "/?id=boom&format=seealso");
    is( $res->content, '["boom",[],[],[]]', 'query crashed' );
    like( $error, qr{^Oh, my!}, 'error catched' );

    $res = $cb->(GET "/?id=nope&format=seealso");
    is( $res->content, '["nope",[],[],[]]', 'query crashed' );
    ok( !$error, 'no error on undef return' );
};


done_testing;
