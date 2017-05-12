use strict;
use warnings;

use Test::More;
eval "use JSON::Any";
plan skip_all => "JSON::Any couldn't be loaded" if $@;
plan tests => 1;
use_ok 'POE::Component::IRC::Plugin::Eval';
