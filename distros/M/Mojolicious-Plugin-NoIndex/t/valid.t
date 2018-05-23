use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

get '/'                  => \&render_index => 'index';
get '/test'              => \&render_index => 'test';
get '/third'             => \&render_index => 'third';
get '/file/:file'        => \&render_index => 'static';
get '/world/:file/:date' => \&render_index => 'fourth';

my @tests = (
    {
        name     => "index - default",
        param    => { routes => { index => 1 } },
        requests => [
            {
                value => 'noindex',
                route => '/',
                set   => 1,
            },
            {
                route => '/test',
                set   => 0,
            },
        ],
    },
    {
        name     => "static - file param",
        param    => { routes => { 'static###file=privacy' => 1 } },
        requests => [
            {
                value => 'noindex',
                route => '/file/privacy',
                set   => 1,
            },
            {
                route => '/file/imprint',
                set   => 0,
            },
        ],
    },
    {
        name     => "fourth - file and date param",
        param    => { routes => { 'fourth###file=privacy&date=now' => 1 } },
        requests => [
            {
                value => 'noindex',
                route => '/world/privacy/now',
                set   => 1,
            },
            {
                route => '/world/privacy/tomorrow',
                set   => 0,
            },
            {
                route => '/world/imprint/now',
                set   => 0,
            },
        ],
    },
    {
        name     => "static - file param and follow value",
        param    => { routes => { 'static###file=privacy' => 'follow' } },
        requests => [
            {
                value => 'follow',
                route => '/file/privacy',
                set   => 1,
            },
            {
                route => '/file/imprint',
                set   => 0,
            },
        ],
    },
    {
        name     => "static - file param (two values) and follow value",
        param    => { routes => { 'static###file=privacy|imprint' => 'follow' } },
        requests => [
            {
                value => 'follow',
                route => '/file/privacy',
                set   => 1,
            },
            {
                value => 'follow',
                route => '/file/imprint',
                set   => 1,
            },
        ],
    },
    {
        name     => "index and third",
        param    => { routes => { index => 1, third => 1 } },
        requests => [
            {
                value => 'noindex',
                route => '/',
                set   => 1,
            },
            {
                route => '/test',
                set   => 0,
            },
            {
                value => 'noindex',
                route => '/third',
                set   => 1,
            },
        ],
    },
    {
        name     => "index is follow and third is default",
        param    => { routes => { index => 'follow', third => 1, } },
        requests => [
            {
                value => 'follow',
                route => '/',
                set   => 1,
            },
            {
                route => '/test',
                set   => 0,
            },
            {
                value => 'noindex',
                route => '/third',
                set   => 1,
            },
        ],
    },
    {
        name     => "index and default value",
        param    => { default => 'follow', routes => { index => 1 } },
        requests => [
            {
                value => 'follow',
                route => '/',
                set   => 1,
            },
            {
                route => '/test',
                set   => 0,
            },
        ],
    },
    {
        name     => "index and third and default value",
        param    => { default => 'follow', routes => { index => 1, third => 1 } },
        requests => [
            {
                value => 'follow',
                route => '/',
                set   => 1,
            },
            {
                route => '/test',
                set   => 0,
            },
            {
                value => 'follow',
                route => '/third',
                set   => 1,
            },
        ],
    },
    {
        name     => "index is follow, third is default (follow)",
        param    => { default => 'follow', routes => { index => 'follow', third => 1, } },
        requests => [
            {
                value => 'follow',
                route => '/',
                set   => 1,
            },
            {
                route => '/test?debug=1',
                set   => 0,
            },
            {
                value => 'follow',
                route => '/third',
                set   => 1,
            },
        ],
    },
    {
        name     => "by_value: index is noindex",
        param    => { by_value => { noindex => [ 'index' ] } },
        requests => [
            {
                value => 'noindex',
                route => '/',
                set   => 1,
            },
            {
                route => '/test',
                set   => 0,
            },
        ],
    },
    {
        name     => "by_value: static with file is privacy check",
        param    => { by_value => { noindex => [ 'static###file=privacy' ] } },
        requests => [
            {
                value => 'noindex',
                route => '/file/privacy',
                set   => 1,
            },
            {
                route => '/file/imprint?debug=1',
                set   => 0,
            },
        ],
    },
    {
        name     => "by_value: static with file is privacy or imprint check",
        param    => { by_value => { noindex => [ 'static###file=privacy|imprint' ] } },
        requests => [
            {
                value => 'noindex',
                route => '/file/privacy',
                set   => 1,
            },
            {
                value => 'noindex',
                route => '/file/imprint',
                set   => 1,
            },
            {
                route => '/file/world',
                set   => 0,
            },
        ],
    },
    {
        name     => "by_value: index and third is noindex",
        param    => { by_value => { noindex => [ 'index', 'third' ] } },
        requests => [
            {
                value => 'noindex',
                route => '/',
                set   => 1,
            },
            {
                route => '/test',
                set   => 0,
            },
            {
                value => 'noindex',
                route => '/third',
                set   => 1,
            },
        ],
    },
    {
        name     => "by_value: noindex -> third, follow -> index",
        param    => { by_value => { noindex => [ 'third' ], follow => ['index'] } },
        requests => [
            {
                value => 'follow',
                route => '/',
                set   => 1,
            },
            {
                route => '/test',
                set   => 0,
            },
            {
                value => 'noindex',
                route => '/third',
                set   => 1,
            },
        ],
    },
    {
        name     => "all_routes",
        param    => { all_routes => 1 },
        requests => [
            {
                value => 'noindex',
                route => '/',
                set   => 1,
            },
            {
                value => 'noindex',
                route => '/test',
                set   => 1,
            },
            {
                value => 'noindex',
                route => '/third',
                set   => 1,
            },
        ],
    },
    {
        name     => "all_routes and new default value",
        param    => { all_routes => 1, default => 'follow' },
        requests => [
            {
                value => 'follow',
                route => '/',
                set   => 1,
            },
            {
                value => 'follow',
                route => '/test',
                set   => 1,
            },
            {
                value => 'follow',
                route => '/third',
                set   => 1,
            },
        ],
    },
);

my $test_cnt = 1;
for my $test ( @tests ) {
    plugin 'NoIndex' => $test->{param};
    
    my $t = Test::Mojo->new;
    for my $request ( @{ $test->{requests} || [] } ) {
        my $value = $request->{value};

        if ( $request->{set} ) {
            $t->get_ok( $request->{route} )
              ->status_is(200)
              ->content_like( qr{<meta name="robots" content="$value">}, $test->{name} . ': ' . $request->{route} );
        }
        else {
            $t->get_ok( $request->{route} )
              ->status_is(200)
              ->content_unlike( qr{<meta name="robots"}, $test->{name} . ': ' . $request->{route} );
        }
    }

    $test_cnt++;
}

done_testing();

sub render_index {
    shift->render('index');
}

__DATA__
@@ index.html.ep
% layout 'default';

@@ layouts/default.html.ep
<html>
  <head>
  </head>
</html>
