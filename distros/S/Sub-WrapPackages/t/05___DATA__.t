use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 15;

use Sub::WrapPackages (
    packages => [qw(
        Module::With::Data::Segment
        Module::With::Both::Segments
        Module::With::END::Segment
    )],
    pre      => sub {
        ok(1, "$_[0] pre-wrapper")
    },
    post     => sub {
        ok(1, "$_[0] post-wrapper")
    }
);

use Module::With::Data::Segment;
use Module::With::Both::Segments;
use Module::With::END::Segment;

ok(Module::With::Data::Segment::foo(), "wrapped sub in a module with a __DATA__ segment works");
ok(Module::With::Data::Segment::data() =~ 'wibble', "and the __DATA__ is read OK");
ok(Module::With::Both::Segments::foo(), "wrapped sub in a module with __DATA__ and __END__ works");
ok(Module::With::Both::Segments::data() =~ 'wibble', "and the __DATA__ is read OK");
ok(Module::With::END::Segment::foo(), "wrapped sub in a module with __END__ works");

