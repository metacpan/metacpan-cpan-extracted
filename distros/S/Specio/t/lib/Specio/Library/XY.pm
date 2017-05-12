package Specio::Library::XY;

use strict;
use warnings;

use parent 'Specio::Exporter';

use Specio::Declare;
use Specio::Library::Builtins;

declare(
    'X',
    parent => t('Str'),
    where  => sub { $_[0] =~ /x/ },
);

declare(
    'Y',
    parent => t('X'),
    where  => sub { $_[0] =~ /y/ },
);

1;
