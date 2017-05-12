# perl -T

use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use PerlIO::Layers qw/query_handle/;

my $fh;
lives_ok { open $fh, '<:buffersize(256)', $0; } 'Can open :buffersize(256)';

done_testing;
