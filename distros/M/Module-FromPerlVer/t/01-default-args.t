use 5.006;
use version;

use Test::More;

my $madness = 'Module::FromPerlVer';

my @methodz
= qw
(
    perl_version
    source_prefix
    module_source
    source_files
    cleanup
    get_files
);

require_ok $madness
or BAIL_OUT "$madness is not usable.";

ok ! $madness->can( $_ ), "No pre-existing '$_'"
for @methodz;

eval
{
    $madness->import( no_copy => 1 );

    pass "Survived import.";

    ok $madness->can( $_ ), "Import installs: '$_'"
    for @methodz;

    1
}
or
fail "Failed import: $@";

for
(
    [ perl_version  => version->parse( $^V )->numify    ],
    [ source_prefix => 't/version'                      ],
    [ module_source => 't/version/5.005003'             ],
)
{
    my ( $method, $expect ) = @$_;

    my $found   = $madness->$method;

    ok $found == $expect, "$method: '$found' ($expect)";
}

done_testing;
__END__
