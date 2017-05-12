#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Prancer::Core qw(config);

sub main {
    # figure out where exist to make finding config files possible
    my (undef, $root, undef) = File::Basename::fileparse($0);

    # load config.yml and <environment>.yml out of the config path
    my $app = Prancer::Core->new("${root}/../conf");

    print "hello, world.\n";
    print "what is foo? foo is " . config->get('foo') . "\n";

    return;
}

main(@ARGV) unless caller;

1;
