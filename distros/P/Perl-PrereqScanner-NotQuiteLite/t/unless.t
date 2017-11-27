use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Test::More;
use t::Util;

test('unless', <<'END', {unless => 0}, {}, {'POE::Kernel' => 0});
use unless ( $^O =~ /^(?:linux|MSWin32|darwin)$/ ), 'POE::Kernel', { loop => 'POE::XS::Loop::Poll' };
END

done_testing;
