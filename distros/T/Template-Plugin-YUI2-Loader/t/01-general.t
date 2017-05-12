#!/usr/bin/perl -w
use lib qw( ./lib ../blib );
use strict;
use warnings;
use Template::Test;

$Template::Test::DEBUG = 1;
$Template::Test::PRESERVE = 1;

test_expect(\*DATA);

__END__
# 1 - plugin loading
-- test --
[% USE YUI2Loader=YUI2.Loader %]
-- expect --

# 2 - first USE in localized nested template
-- test --
[% BLOCK scoped;
   	USE YUI2Loader=YUI2.Loader;
	CALL YUI2Loader.components( 'blub', 'bla' ).on_success( 'some_function()' );
   END;
   INCLUDE scoped;

   USE YUI2Loader=YUI2.Loader;
   CALL YUI2Loader.components( 'blub', 'bar' ).on_success( 'some_other_function()' );
   YUI2Loader.components; "\n"; 
   YUI2Loader.on_success;
%]
-- expect --
[ 'bar', 'bla', 'blub' ]
(function() { some_function() })();
(function() { some_other_function() })();
