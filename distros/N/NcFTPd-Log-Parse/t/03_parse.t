use strict;
use warnings;
use lib 't/lib';

use Test::More tests => 10;
use TestHelper qw{$MISC_LOG $SESS_LOG $XFER_LOG};

BEGIN { use_ok('NcFTPd::Log::Parse') }

my $parser = NcFTPd::Log::Parse->new(xfer => $XFER_LOG);
isa_ok($parser, 'NcFTPd::Log::Parse::Xfer');

$parser = NcFTPd::Log::Parse->new($XFER_LOG);
isa_ok($parser, 'NcFTPd::Log::Parse::Xfer');

$parser = NcFTPd::Log::Parse->new(misc => $MISC_LOG);
isa_ok($parser, 'NcFTPd::Log::Parse::Misc');

$parser = NcFTPd::Log::Parse->new($MISC_LOG);
isa_ok($parser, 'NcFTPd::Log::Parse::Misc');

$parser = NcFTPd::Log::Parse->new(session => $SESS_LOG);
isa_ok($parser, 'NcFTPd::Log::Parse::Session');

$parser = NcFTPd::Log::Parse->new($SESS_LOG);
isa_ok($parser, 'NcFTPd::Log::Parse::Session');

$parser = NcFTPd::Log::Parse->new('t/logs/session.log');
isa_ok($parser, 'NcFTPd::Log::Parse::Session');

eval { NcFTPd::Log::Parse->new(bad_format => 'baaaahd') };
ok($@);

eval { NcFTPd::Log::Parse->new('unknown.file.format.log') };
ok($@);
