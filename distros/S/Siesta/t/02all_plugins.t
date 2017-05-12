#!perl -w
#  $Id: 02all_plugins.t,v 1.4 2002/09/12 12:55:32 clampr Exp $
# test all plugins maintian the Plugin API, and compile

use strict;
use File::Find::Rule qw(find);
use lib qw(t/lib);
use Siesta::Test;

my @files = find( name => '*.pm', in => 'blib/lib/Siesta/Plugin' );
require Test::More;
Test::More->import( tests => @files * 2 );

for my $class (@files) {
    $class =~ s{blib/lib/(.*).pm}{$1};
    $class =~ s{/}{::}g;
    require_ok($class);
    eval { $class->description };
    ok( !$@, "$class has a description" );
}
