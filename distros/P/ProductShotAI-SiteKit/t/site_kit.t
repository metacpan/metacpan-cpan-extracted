use strict;
use warnings;
use Test::More tests => 10;
use lib "lib";
use ProductShotAI::SiteKit qw(base brand home_url workbench_url pricing_url blog_url contact_url zh_home_url localized_url site_metadata);

is(base(), "https://productshotai.app", "base");
is(brand(), "ProductShot AI", "brand");
is(home_url(), "https://productshotai.app/", "home URL");
is(workbench_url(), "https://productshotai.app/#workbench", "workbench URL");
is(pricing_url(), "https://productshotai.app/#pricing", "pricing URL");
is(blog_url(), "https://productshotai.app/blog/", "blog URL");
is(contact_url(), "https://productshotai.app/contact/", "contact URL");
is(zh_home_url(), "https://productshotai.app/zh/", "zh home URL");
is(localized_url("zh-CN", "blog"), "https://productshotai.app/zh/blog/", "zh blog URL");
is(site_metadata()->{name}, "ProductShot AI", "metadata name");
