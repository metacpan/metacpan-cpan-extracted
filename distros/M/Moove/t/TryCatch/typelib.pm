package t::TryCatch::typelib;

use Types::Standard -all;
use Type::Utils -all;
use Type::Library -base;

extends 'Types::Standard';

declare IntErr => as Str, where { $_ =~ /^\d+ at/ };
declare StrErr => as Str, where { $_ =~ /^\w+ at/ };

1;
