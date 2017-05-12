use Test::Most;
use if $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}, 'Test::Warnings';

BEGIN {
    eval "use YAML::Syck;";
    plan skip_all => "YAML::Syck is not installed" if $@;
}

use_ok('Object::Signature::Portable');

sub serializer {
    local $YAML::Syck::Headless        = 1;
    local $YAML::Syck::SortKeys        = 1;
    local $YAML::Syck::SingleQuote     = 1;
    local $YAML::Syck::ImplicitTyping  = 0;
    local $YAML::Syck::ImplicitUnicode = 1;
    local $YAML::Syck::ImplicitBinary  = 1;
    return Dump( $_[0] );
}

is signature( digest => 'MD5', format => 'b64udigest', data => '' ),
    'nUVowAnSA6sQ4z6plToCZA', 'MD5 blank string';

is signature(
    digest     => 'MD5',
    format     => 'b64udigest',
    serializer => \&serializer,
    data       => ''
    ),
    'NQadES1QTFNhg7lXPmrdWA', 'MD5 blank string (YAML)';

done_testing;
