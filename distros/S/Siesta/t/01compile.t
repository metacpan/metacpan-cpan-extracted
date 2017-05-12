#!perl -w
#   $Id: 01compile.t,v 1.4 2002/09/12 12:55:32 clampr Exp $
# test compile all .pm files - note, may not find broken dependencies,
# as all things are loaded into the same interpreter
use lib qw(t/lib);
use Siesta::Test;

use strict;
use File::Find::Rule;

# Hack - Siesta::Web won't compile without Apache (unless
# Siesta::Web::FakeApache is compiled first - sorting it backwards
# makes sure that happens

my @files = sort { $b cmp $a } find( name => '*.pm', in => 'blib/lib' );

require Test::More;
Test::More->import( tests => scalar @files );

for my $class (@files) {
    $class =~ s{blib/lib/(.*)\.pm}{$1};
    $class =~ s{/}{::}g;
    require_ok($class);
}

