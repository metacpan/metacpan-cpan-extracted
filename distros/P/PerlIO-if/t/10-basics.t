# perl -T

use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use PerlIO::Layers qw/query_handle/;

my $fh;
lives_ok { open $fh, '<:if(buffered,pop)', $0; } 'Can open :if(buffered, pop)';
ok !query_handle($fh, 'buffered'), 'Handle is no longer buffered';

ok binmode($fh, ':if(!buffered,crlf)'), 'binmode succedded';

ok query_handle($fh, 'buffered'), 'Handle is buffered again';
ok query_handle($fh, 'crlf'), 'Handle is crlf too';

my $fh2;
lives_ok { open $fh2, '<:if(!buffered, perlio):encoding(utf-8)', $0 or die $!; } 'Can open :if(!buffered,perlio):encoding(utf-8)';

my $fh3;
lives_ok { open $fh3, '<:if(!buffered, encoding(utf-8))', $0 or die $!; } 'Can open ::if(!buffered, encoding(utf-8))';

throws_ok { open my $fh4, '<:if', $0 or die $! } qr/^Invalid argument at /, 'if without argument throws exception';

done_testing;
