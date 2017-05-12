use Test::Chunks;
use lib 't';

plan tests => 1;

eval "require 'strict-warnings.test'";
like("$@", qr{\QGlobal symbol "\E.\Qglobal_variable" requires explicit package name\E});
