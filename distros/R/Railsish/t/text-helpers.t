#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 9;

use Railsish::TextHelpers;

is( pluralize("photo"), "photos");
is( pluralize("photos"), "photos");
is( singularize("photo"), "photo");
is( singularize("photos"), "photo");

is( camelcase("photo_shop"), "PhotoShop" );
is( camelize("photo_shop"), "PhotoShop" );
is( dasherize("photo_shop"), "photo-shop" );

is( forien_key("photo"), "photo_id" );
is( underscore("PhotoShop"), "photo_shop");

