use Test::Base tests => 1;
use lib -e 't' ? 't' : 'test';

eval "require 'strict-warnings.test'";
like "$@",
   qr{\QGlobal symbol "\E.\Qglobal_variable" requires explicit package name\E};
