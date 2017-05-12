use strict;
use Test::More;
use Test::Exception;

use Path::Class;
use SWF::Generator;

my $swfgen = SWF::Generator->new();

throws_ok { $swfgen->process('t/err.xml'); } 'Template::Exception', 'no template error';

throws_ok { $swfgen->process('t/error.xml'); } qr/parser error : Start tag expected/, 'invalid template error';

done_testing;
