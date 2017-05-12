use strict;
use Test::More;
use Test::Exception;

local $ENV{PANDOC_VERSION} = '1.2.3';
require Pandoc::Elements;
is Pandoc::Elements::pandoc_version(), '1.2.3', 'pandoc_version from ENV';

Pandoc::Elements->import('pandoc_version');

$Pandoc::Elements::PANDOC_VERSION = 1.3;
is pandoc_version(), '1.3', 'set pandoc_version via variable';

{
    local $Pandoc::Elements::PANDOC_VERSION = undef;
    is pandoc_version(), '1.19', 'maximum supported version';
}
is pandoc_version(), '1.3', 'localize PANDOC_VERSION';

done_testing;
