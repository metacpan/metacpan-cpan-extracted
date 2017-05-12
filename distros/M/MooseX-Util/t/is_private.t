use strict;
use warnings;

use Test::More;
use MooseX::Util;

ok  is_private '_private' => '_private: is private';
ok !is_private 'public'   => 'public: is public';

done_testing;
