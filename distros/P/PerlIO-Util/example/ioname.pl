#!perl -w

use strict;
use PerlIO::Util;

my $io = PerlIO::Util->open('<', $INC{'strict.pm'});
scalar <$io>;

warn 'warnings with an informative filehandle name';


