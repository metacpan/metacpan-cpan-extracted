#!perl

use strict;
use warnings;
use Test::More 0.98;

use Perinci::Sub::Util::DepModule qw(get_required_dep_modules);

is_deeply(get_required_dep_modules({v=>1.1}), {});
is_deeply(get_required_dep_modules({v=>1.1, deps=>{}}),
          {"Perinci::Sub::DepChecker"=>0});
is_deeply(get_required_dep_modules({v=>1.1, deps=>{any=>[{foo=>1}, {bar=>1}], env=>"ENV1", prog=>"prog1"}}),
          {"Perinci::Sub::DepChecker"=>0, "Perinci::Sub::Dep::foo"=>0, "Perinci::Sub::Dep::bar"=>0});
done_testing;
