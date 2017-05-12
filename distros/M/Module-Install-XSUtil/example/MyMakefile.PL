#!perl -w

use strict;

use FindBin qw($Bin);
use File::Spec;
use lib File::Spec->join($Bin, '..', 'lib');
use Config;

use inc::Module::Install;

BEGIN{
	@ARGV = qw(-g) unless @ARGV;
}

all_from 'lib/Foo.pm';

requires_xs 'B::Hooks::OP::Annotation'; # for testing only

use_ppport 3.19;
use_xshelper -clean;

cc_warnings;

requires_c99 if $Config{gccversion};

cc_include_paths 'include';
cc_src_paths     'src';

cc_define -DFOO_OK;

install_headers;

WriteAll check_nmake => 0;
