#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use File::Basename ();

use Prancer::Core qw(config);
use Prancer::Plugin::Xslate qw(render);

sub main {
    # figure out where exist to make finding config files possible
    my (undef, $root, undef) = File::Basename::fileparse($0);

    # this just returns a prancer object so we can get access to configuration
    # options and other awesome things like plugins.
    my $app = Prancer::Core->new("${root}/foobar.yml");

    # in here we get to initialize things!
    my $plugin = Prancer::Plugin::Xslate->load();
    $plugin->path($root);

    print render("foobar.tx", {
        "foo" => "bar"
    }, {
        'function' => {
            'baz' => sub { return "barfoo"; },
        },
        'module' => [
            'Digest::SHA1' => ['sha1_hex'],
            'Data::Dumper'
        ]
    });

    return;
}

main(@ARGV) unless caller;

1;
