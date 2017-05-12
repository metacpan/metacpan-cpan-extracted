use strict;
use Test::More;
use Test::Exception;

local $ENV{PANDOC_VERSION} = 'x';
lives_ok { 
    require Pandoc::Elements; 
    ok Pandoc::Elements::pandoc_version() > '1.12.1';
} 'ignore invalid PANDOC_VERSION from ENV';

done_testing;
