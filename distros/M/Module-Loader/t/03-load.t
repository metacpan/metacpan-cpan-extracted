#! perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use File::Spec::Functions qw/ catfile /;
BEGIN {
    # OS-portable version of "use lib 't/lib';"
    # Otherwise this test will fail on Win32
    push(@INC, catfile('t', 'lib'));
}
use Module::Loader;

my $loader = Module::Loader->new()
             || BAIL_OUT("Can't instantiate Module::Loader");

eval {
    $loader->load('LoadMe::Failing');
};
ok($@, "Trying to load 'LoadMe::Failing' should croak");

eval {
    $loader->load('LoadMe::HollowVoice');
};
ok(!$@, "Trying to load 'LoadMe::HollowVoice' should NOT croak");

my $result;
eval {
    $result = LoadMe::HollowVoice::hollow_voice();
};
ok(!$@ && $result eq 'plugh',
   "On loading 'LoadMe::HollowVoice' we should be able to call its function");

done_testing;

