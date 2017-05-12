#!perl

use warnings;
use strict;

use Test::More tests => 7;

BEGIN{ use_ok('Ruby', ':DEFAULT', 'rb_c') }

oTODO:{
	local $TODO = 'rb_require(Ruby XS) not yet solved';

	ok eval{ rb_require('digest/md5.so') }, q{rb_require 'digest/md5.so'};

	use Digest::MD5;

	is Digest::MD5::md5_hex('foo'), eval{ rb_c(Digest::MD5)->hexdigest('foo') }, "do call so's method";

	is Digest::MD5::md5_hex('foo'), eval{ rb_c(Digest::MD5)->hexdigest('foo') }, "redo call so's method";

	ok eval{ rb_require("dbm.so") }, "rb_require 'dbm.so'";
}

ok !eval{ rb_require("nolibrary.so") }, "failed to require";

ok($rb_errinfo->kind_of("LoadError"));

