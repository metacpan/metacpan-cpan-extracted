use 5.006;

use Test::More;

for my $madness
(
    qw
    (
        Module::FromPerlVer::Extract
        Module::FromPerlVer::Dir
        Module::FromPerlVer::Git
        Module::FromPerlVer
    )
)
{
    SKIP:
    {
        require_ok $madness
        or skip "$madness is not usable.", 2;

        # verify that the package is spelled properly,
        # that a version is installed.

        SKIP:
        {
            ok $madness->can( 'VERSION' ), "$madness can 'VERSION'"
            or skip "$madness cannot 'VERSION'", 1;

            ok $madness->VERSION, "$madness has a VERSION";
        }
    }
}

done_testing;
__END__
