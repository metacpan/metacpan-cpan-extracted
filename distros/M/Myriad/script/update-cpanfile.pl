#!/usr/bin/env perl 
use strict;
use warnings;

use feature qw(say);
use Path::Tiny;
use Module::Load;
require V;

path('cpanfile')->edit_lines_utf8(sub {
    if(/^require/) {
        my ($module, $version) = /^requires\s+['"]([^'"]+)['"](?:\s*,\s*["']>= ([^'"]+)['"])?/;
        $version //= 0;
        my $target = V::get_version($module) // do {
            Module::Load::load($module);
            $module->VERSION
        };
        if($version and $target and $version < $target) {
            say "Update $module => $version ($target)";
            s{['"]>=\s*\K(?:[^'"]+)(?=\s*['"].*;)}{$target};
        }
    }
});
