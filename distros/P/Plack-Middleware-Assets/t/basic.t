use strict;
use warnings;
use Test::More 0.88;
use Plack::Builder;
use HTTP::Request::Common;
use Plack::Test;

our $time;

BEGIN {
    require Time::Local;    # core
    $time = Time::Local::timegm( 37, 50, 14, 29, 11 - 1, 2011 );
    *CORE::GLOBAL::time = sub () {$time};
    require Plack::Middleware::Assets;
    if ( $ENV{DEVEL_COVER_72819} && $INC{'Devel/Cover.pm'} ) {
        no warnings 'redefine';
        eval
            "*Plack::Middleware::Assets::$_ = sub { \$_[0]->{$_} = \$_[1] if \@_ > 1; \$_[0]->{$_} };"
            for qw(separator filter mtime minify type);
    }
}

package Plack::Middleware::Assets::Type::less;
use base 'Plack::Middleware::Assets::Type::css';
use CSS::Minifier::XS qw(minify);
sub content_type {'text/less'}

package main;

my $app = builder {

    # be careful about reusing files: be sure the content is different
    enable "Assets", files => [<t/static/*.js>];
    enable "Assets",
        files  => [<t/static/*.css>],
        minify => 0;
    enable "Assets", files => [<t/static/*.js>], minify => 0, type => 'css';
    enable "Assets", files => [<t/static/*.css>], minify => 1, expires => 300;

    my $d = 't/static';
    enable "Assets", files => ["$d/l1.less"];
    enable "Assets",
        files             => ["$d/l2.less"],
        separator => 0,
        minify            => 1;
    enable "Assets",
        files  => ["$d/l3.less"],
        type   => 'less';
    enable "Assets",
        files  => [ glob "$d/l*.less" ],
        type   => 'js',
        minify => 1;
    enable "Assets",
        files             => ["$d/l1.less"],
        type              => 'plain',
        separator => 0,
        minify            => 0,
        filter            => sub { uc shift };
    enable "Assets",
        files             => ["$d/l2.less"],
        separator => 0,
        minify            => 0,
        filter            => sub { tr/lo2/pi9/; $_ };
    enable "Assets",
        files             => ["$d/l3.less"],
        type              => 'less',
        separator => "!{%s}\n",
        minify            => sub { s/\s+/\t/g; $_ },
        filter => sub {uc},
        extension => 'less';
    return sub {
        my $env = shift;
        [   200,
            [ 'Content-type', 'text/plain' ],
            [ map { $_ . $/ } @{ $env->{'psgix.assets'} } ]
        ];
        }
};

my $assets;
my $total = 11;

my %test = (
    client => sub {
        my $cb = shift;
        {
            my $res = $cb->( GET 'http://localhost/' );
            is( $res->code, 200 );
            $assets = [ split( $/, $res->content ) ];
            is( @$assets, $total );
        }

        {
            like( $assets->[0], qr/\.js$/, '.js file extension' );
            my $res = $cb->( GET 'http://localhost' . $assets->[0] );
            is( $res->code,         200 );
            is( $res->content_type, 'application/javascript' );
            is( $res->content,      'function(){foo};js2()' );
        }

        {
            like( $assets->[1], qr/\.css$/, '.css file extension' );
            my $res = $cb->( GET 'http://localhost' . $assets->[1] );
            is( $res->code,         200 );
            is( $res->content_type, 'text/css' );
            is( $res->content, qq{/* t/static/css1.css */
css1
/* t/static/css2.css */
css2}
            );
        }

        {
            my $res = $cb->( GET 'http://localhost' . $assets->[2] );
            is( $res->code, 200 );
            is( $res->content_type, 'text/css', 'type set explicitly' );
            is( $res->header('Expires'),
                'Thu, 29 Dec 2011 14:50:37 GMT',
                'default expiration'
            );
            is( $res->content, qq</* t/static/js1.js */
function() {
    foo
};
/* t/static/js2.js */
js2()>,
            );
        }

        {
            my $res = $cb->( GET 'http://localhost' . $assets->[3] );
            is( $res->code,         200 );
            is( $res->content_type, 'text/css' );
            is( $res->header('Expires'),
                'Tue, 29 Nov 2011 14:55:37 GMT',
                'expiration set low'
            );
            is( $res->content, qq{css1
css2},
                'minify set explicitly'
            );
        }

        {
            my $res = $cb->( GET 'http://localhost' . $assets->[4] );
            is( $res->code, 200 );
            is( $res->content_type, 'text/plain', 'arbitrary content type' );
            is( $res->content, <<LESS,
.l1 {
  top: 1;
}
LESS
                'no default minification for unknown type'
            );
        }

        {
            my $res = $cb->( GET 'http://localhost' . $assets->[5] );
            is( $res->code, 200 );
            is( $res->content_type, 'text/plain', 'arbitrary content type' );
            is( $res->content, <<LESS,
.l2 {
  top: 2;
}
LESS
                'do not know how to minify unknown type; no filename comment'
            );
        }

        {
            my $res = $cb->( GET 'http://localhost' . $assets->[6] );
            is( $res->code, 200 );
            is( $res->content_type, 'text/less', 'arbitrary content type' );
            is( $res->content, qq<.l3{top:3}>,
                'minify arbitrary type using specified minifier' );
        }

        {
            my $res = $cb->( GET 'http://localhost' . $assets->[7] );
            is( $res->code,         200 );
            is( $res->content_type, 'application/javascript' );
            is( $res->content,
                qq<.l1{top:1;}\n.l2{top:2;}\n.l3{top:3;}>,
                'minify using alternate minifier'
            );
        }

        {
            my $res = $cb->( GET 'http://localhost' . $assets->[8] );
            is( $res->code, 200 );
            is( $res->content_type, 'text/plain', 'arbitrary content type' );
            is( $res->content,
                qq<.L1 {\n  TOP: 1;\n}\n>,
                'custom filter using @_, no filename comment'
            );
        }

        {
            like( $assets->[9], qr/\.txt$/, '.txt file extension' );
            my $res = $cb->( GET 'http://localhost' . $assets->[9] );
            is( $res->code, 200 );
            is( $res->content_type, 'text/plain', 'arbitrary content type' );
            is( $res->content,
                qq<.p9 {\n  tip: 9;\n}\n>,
                'custom filter using $_, no filename comment'
            );
        }

        {
            like( $assets->[10], qr/\.less$/, '.less file extension' );
            my $res = $cb->( GET 'http://localhost' . $assets->[10] );
            is( $res->code, 200 );
            is( $res->content_type, 'text/less', 'arbitrary content type' );
            is( $res->content,
                qq<!{T/STATIC/L3.LESS}\t.L3\t{\tTOP:\t3;\t}\t>,
                'custom filter, custom minifier'
            );
        }

    },
    app => $app,
);

test_psgi %test;

done_testing;
