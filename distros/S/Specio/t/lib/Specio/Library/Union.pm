package Specio::Library::Union;

use strict;
use warnings;

use parent 'Specio::Exporter';

use Specio::Declare;
use Specio::Library::Builtins;

my $locale_object = declare(
    'LocaleObject',
    parent => t('Object'),
    inline => sub {

        # Using $_[1] directly in the string causes some weirdness with 5.8
        my $var = $_[1];
        return <<"EOF";
(
    $var->isa('DateTime::Locale::FromData')
    || $var->isa('DateTime::Locale::Base')
)
EOF
    },
);

union(
    'Union',
    of => [ t('Str'), $locale_object ],
);

1;
