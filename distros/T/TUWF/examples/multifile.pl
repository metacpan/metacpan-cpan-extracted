#!/usr/bin/perl

# This example loads all code from MyWebsite/, which in contains either
# functions that are exported to the main object or TUWF::register() or
# TUWF::set() calls.

use strict;
use warnings;


# See examples/singlefile.pl for an explanation on what this does
use Cwd 'abs_path';
our $ROOT;
BEGIN { ($ROOT = abs_path $0) =~ s{/examples/multifile.pl$}{}; }
use lib $ROOT.'/lib';
use lib $ROOT.'/examples';


# load TUWF
use TUWF;

# load all modules under MyWebsite/
TUWF::load_recursive('MyWebsite');

# Let's enable debug mode
TUWF::set(debug => 1);

# And let's enable logging
# (Note that in practice you don't want to log to /tmp, I'll do it anyway to
# make this example easier to setup, since /tmp is supposed to be always
# writable from any process)
TUWF::set(logfile => '/tmp/tuwf-multifile-example.log');

# run TUWF
TUWF::run();

