#!perl -T

use strict;
use warnings FATAL => 'all';

use Term::ANSIScreen qw( :cursor :screen );
use Term::ANSIColor;
use Time::HiRes qw( sleep );
use Term::ANSIEncode;
use utf8;

use Test::More tests => 2;

binmode(STDOUT, ":encoding(UTF-8)");

BEGIN {
	use_ok('Term::ANSIEncode') || diag 'Cannot load Term::ANSIEncode!';
}


my $ansi = Term::ANSIEncode->new();
isa_ok($ansi,'Term::ANSIEncode');

exit;

__END__

