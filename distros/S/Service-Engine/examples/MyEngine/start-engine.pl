#!/usr/bin/perl

use File::Basename qw(dirname);
use Cwd qw(abs_path);
my $engine_path = dirname(abs_path $0);

# we need to know about our custom modules
use lib dirname(dirname abs_path $0);

# for testing, we also need to know where the Service::Engine modules are
# normally these would be installed in @INC
use lib dirname(dirname abs_path $0) . '/../lib';

use Service::Engine;

# initialize the Service Engine
my $engine = Service::Engine->new({'config_file'=>"$engine_path/config.pl"});

$engine->start();

1;
