use Test::More;
use Test::Pod::Coverage;

pod_coverage_ok(
    "RPG::Traveller::Person",
    { also_private => [qw/ intToAlpha /] },
    "Pod Coverage RPG::Traveller::Person"
);

pod_coverage_ok(
    "RPG::Traveller::Person::Constants",

    "Pod Coverage RPG::Traveller::Person"
);

done_testing;
