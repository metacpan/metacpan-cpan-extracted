#!/usr/bin/env perl
use utf8;
use strict;
use warnings;
use Test::More tests => 9;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use URI::Escape::XS qw'uri_escape uri_unescape';
use Encode qw'encode_utf8 decode_utf8';

require_ok('Router::Ragel');

subtest 'Basic router functionality' => sub {
    plan tests => 5;
    
    my $router = Router::Ragel->new;
    isa_ok($router, 'Router::Ragel', 'Constructor returns a Router::Ragel object');
    
    $router->add('/users', 'users_list');
    $router->add('/users/:id', 'user_detail');
    $router->add('/users/:id/edit', 'user_edit');
    
    $router->compile;
    
    my @result1 = $router->match('/users');
    is($result1[0], 'users_list', 'Simple static route matched correctly');
    is(scalar @result1, 1, 'Static route returns no captures');
    
    my @result2 = $router->match('/users/123');
    is($result2[0], 'user_detail', 'Route with placeholder matched correctly');
    is($result2[1], '123', 'Placeholder value captured correctly');
};

subtest 'Multiple independent routers' => sub {
    plan tests => 7;
    
    my $api_router = Router::Ragel->new;
    my $admin_router = Router::Ragel->new;
    
    # API routes
    $api_router->add('/api/users', 'api_users_list');
    $api_router->add('/api/users/:id', 'api_user_detail');
    $api_router->compile;
    
    # Admin routes
    $admin_router->add('/admin/users', 'admin_users_list');
    $admin_router->add('/admin/users/:id', 'admin_user_detail');
    $admin_router->compile;
    
    # Test API router
    my @api_result1 = $api_router->match('/api/users');
    is($api_result1[0], 'api_users_list', 'API static route matched correctly');
    
    my @api_result2 = $api_router->match('/api/users/123');
    is($api_result2[0], 'api_user_detail', 'API route with placeholder matched correctly');
    is($api_result2[1], '123', 'API placeholder value captured correctly');
    
    # Test Admin router
    my @admin_result1 = $admin_router->match('/admin/users');
    is($admin_result1[0], 'admin_users_list', 'Admin static route matched correctly');
    
    my @admin_result2 = $admin_router->match('/admin/users/456');
    is($admin_result2[0], 'admin_user_detail', 'Admin route with placeholder matched correctly');
    is($admin_result2[1], '456', 'Admin placeholder value captured correctly');
    
    # Test that routers don't interfere with each other
    my @not_found = $api_router->match('/admin/users');
    is(scalar @not_found, 0, 'API router does not match admin routes');
};

subtest 'Versioned API routers' => sub {
    plan tests => 6;
    
    my $v1_router = Router::Ragel->new;
    my $v2_router = Router::Ragel->new;
    
    # V1 API routes
    $v1_router->add('/v1/products', 'list_products_v1');
    $v1_router->add('/v1/products/:id', 'get_product_v1');
    $v1_router->compile;
    
    # V2 API routes
    $v2_router->add('/v2/products', 'list_products_v2');
    $v2_router->add('/v2/products/:id', 'get_product_v2');
    $v2_router->add('/v2/products/:id/reviews', 'product_reviews_v2');
    $v2_router->compile;
    
    # Test V1 routes
    my @v1_result = $v1_router->match('/v1/products/123');
    is($v1_result[0], 'get_product_v1', 'V1 route matched correctly');
    is($v1_result[1], '123', 'V1 placeholder captured correctly');
    
    # Test V2 routes
    my @v2_result1 = $v2_router->match('/v2/products/456');
    is($v2_result1[0], 'get_product_v2', 'V2 product route matched correctly');
    is($v2_result1[1], '456', 'V2 placeholder captured correctly');
    
    my @v2_result2 = $v2_router->match('/v2/products/456/reviews');
    is($v2_result2[0], 'product_reviews_v2', 'V2 reviews route matched correctly');
    is($v2_result2[1], '456', 'V2 placeholder in nested route captured correctly');
};

subtest 'Multiple placeholders' => sub {
    plan tests => 7;
    
    my $router = Router::Ragel->new;
    $router->add('/blog/:year/:month/:slug', 'blog_post');
    $router->add('/users/:user_id/posts/:post_id', 'user_post');
    $router->compile;
    
    my @result1 = $router->match('/blog/2023/05/perl-routing');
    is($result1[0], 'blog_post', 'Blog route matched correctly');
    is($result1[1], '2023', 'First placeholder captured correctly');
    is($result1[2], '05', 'Second placeholder captured correctly');
    is($result1[3], 'perl-routing', 'Third placeholder captured correctly');
    
    my @result2 = $router->match('/users/123/posts/456');
    is($result2[0], 'user_post', 'User post route matched correctly');
    is($result2[1], '123', 'User ID placeholder captured correctly');
    is($result2[2], '456', 'Post ID placeholder captured correctly');
};

subtest 'Special character handling' => sub {
    plan tests => 2;
    
    my $router = Router::Ragel->new;
    $router->add('/path/with-hyphen', 'hyphen_data');
    $router->add(q(/path/with'quote), 'quote_data');
    $router->compile;
    
    my @result1 = $router->match('/path/with-hyphen');
    is($result1[0], 'hyphen_data', 'Path with hyphen matched correctly');
    
    my @result2 = $router->match("/path/with'quote");
    is($result2[0], 'quote_data', 'Path with single quote matched correctly');
};

subtest 'Percent encoded path segments' => sub {
    plan tests => 5;
    
    my $router = Router::Ragel->new;
    $router->add('/products/:category/items', 'category_items');
    $router->add('/search/:query', 'search_results');
    $router->add('/files/:filename', 'file_download');
    $router->compile;
    
    # Test with spaces encoded as %20
    my @result1 = $router->match('/products/home%20decor/items');
    is($result1[0], 'category_items', 'Route with space in placeholder matched');
    is($result1[1], 'home%20decor', 'Percent-encoded space preserved in capture');
    is(uri_unescape($result1[1]), 'home decor', 'Percent-encoded space correctly unescaped');
    
    # Test with special characters encoded
    my @result2 = $router->match('/search/perl%2Brouting%26testing');
    is($result2[0], 'search_results', 'Route with special chars matched');
    is(uri_unescape($result2[1]), 'perl+routing&testing', 'Special characters correctly unescaped');
};

subtest 'Percent encoded Unicode characters' => sub {
    plan tests => 7;
    
    my $router = Router::Ragel->new;
    $router->add('/blog/:post', 'blog_post');
    $router->add('/cities/:city/info', 'city_info');
    $router->add(encode_utf8('/🤖'), 'robot');
    $router->compile;

    my @result0 = $router->match(encode_utf8('/🤖'));
    is($result0[0], 'robot', 'static route');
    
    # Test with UTF-8 characters that are percent-encoded
    my $utf8_title = 'こんにちは世界'; # "Hello World" in Japanese
    my $encoded_title = uri_escape(encode_utf8($utf8_title));
    
    my @result1 = $router->match("/blog/$encoded_title");
    is($result1[0], 'blog_post', 'Route with percent-encoded UTF-8 matched');
    is(decode_utf8(uri_unescape($result1[1])), $utf8_title, 'UTF-8 characters correctly decoded');
    
    # Test with a city name containing accents
    my $city = 'São Paulo';
    my $encoded_city = uri_escape(encode_utf8($city));
    
    my @result2 = $router->match("/cities/$encoded_city/info");
    is($result2[0], 'city_info', 'Route with percent-encoded city name matched');
    is(decode_utf8(uri_unescape($result2[1])), $city, 'Accented characters correctly decoded');
    
    # Test with mixed case percent encodings (which should be treated the same)
    my $mixed_encoding = '/blog/%E3%81%93%E3%82%93%E3%81%AB%E3%81%A1%E3%81%AF%e4%b8%96%e7%95%8c';
    my @result3 = $router->match($mixed_encoding);
    is($result3[0], 'blog_post', 'Route with mixed-case percent encoding matched');
    is(decode_utf8(uri_unescape($result1[1])), $utf8_title, 'Mixed-case encoding correctly decoded');
};

subtest 'Edge cases with special characters' => sub {
    plan tests => 8;
    
    my $router = Router::Ragel->new;
    $router->add('/path/:param/with/+/plus', 'plus_path');
    $router->add('/path/:param/with/%/percent', 'percent_path');
    $router->add('/path/:param/with/@/at', 'at_path');
    $router->add('/path/:param/with/&/ampersand', 'ampersand_path');
    $router->compile;
    
    # Test with plus sign in URL (should not be treated as space in path)
    my @result1 = $router->match('/path/value/with/+/plus');
    is($result1[0], 'plus_path', 'Route with plus sign matched');
    is($result1[1], 'value', 'Parameter value correctly captured with plus in path');
    
    # Test with percent sign in URL (tricky because % is used for percent encoding)
    my @result2 = $router->match('/path/value/with/%/percent');
    is($result2[0], 'percent_path', 'Route with percent sign matched');
    is($result2[1], 'value', 'Parameter value correctly captured with percent in path');
    
    # Test with @ symbol in URL (commonly used in REST-like paths)
    my @result3 = $router->match('/path/value/with/@/at');
    is($result3[0], 'at_path', 'Route with @ symbol matched');
    is($result3[1], 'value', 'Parameter value correctly captured with @ in path');
    
    # Test with & symbol in URL (commonly used for query params but can be in path)
    my @result4 = $router->match('/path/value/with/&/ampersand');
    is($result4[0], 'ampersand_path', 'Route with & symbol matched');
    is($result4[1], 'value', 'Parameter value correctly captured with & in path');
};
