use 5.010;
use warnings;

use Test::More;
plan 'no_plan';

my %AcceptableVersions = (
    '0.95' => 1,
    '0.98' => 1,
    '1.01' => 1,
);

my %UnacceptableVersions = (
    '0.99' => 1,
    '1.00' => 1,
);

my $version_checker = do{
    use Regexp::Grammars;
    qr{
        <Valid_Language_Version>

        <rule: Valid_Language_Version>
              vers = <%AcceptableVersions>
            |
              vers = <badversion=%UnacceptableVersions>
              <fatal: (?{ "Cannot parse language version $MATCH{badversion}" })>
            |
              vers = <fatal:>
    }xms;
};

ok 'vers = 0.95' =~ $version_checker => 'Matched version 0.95';
ok @! == 0                           => 'with no error messages';

ok 'vers = 0.99' !~ $version_checker           => 'Correctly failed to match version 0.99';
ok @! == 1                                     => 'with correct number of error messages';
is $![0], 'Cannot parse language version 0.99' => 'with correct error message';

ok 'vers = 0.96' !~ $version_checker           => 'Correctly failed to match version 0.96';
ok @! == 1                                     => 'with correct number of error messages';
is $![0], q{Expected valid language version, but found '0.96' instead}
                                               => 'with correct error message';
