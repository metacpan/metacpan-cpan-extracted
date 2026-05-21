#!/usr/bin/env perl
# Show how Router::Ragel translates each pattern segment into Ragel grammar.
# Useful when a route matches surprising input or refuses to compile.
#
# Note: this calls the internal _segment_to_ragel helper, which is not part
# of the public API and may change.
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Router::Ragel;

my @patterns = (
    '/users',
    '/users/:id',
    '/users/:id<int>',
    '/blog/:year<int>/:month<int>/:slug',
    '/v/:major<int>.:minor<int>',
    '/file/:name<[a-z0-9\-]+>.:ext<[a-z]+>',
    '/path/to_:type<string>/id_:id<int>/end',
);

for my $pattern (@patterns) {
    print "pattern: $pattern\n";
    my @segments = split '/', $pattern, -1;
    shift @segments; # leading '' from required leading '/'
    my $cap = 0;
    for my $seg (@segments) {
        if ($seg eq '') {
            print "  (empty segment - just '/')\n";
            next;
        }
        my $ragel = Router::Ragel::_segment_to_ragel($pattern, $seg, \$cap);
        print "  '$seg' -> $ragel\n";
    }
    print "\n";
}
