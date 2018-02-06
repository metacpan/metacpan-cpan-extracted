use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Stepford.pm',
    'lib/Stepford/Error.pm',
    'lib/Stepford/FinalStep.pm',
    'lib/Stepford/Graph.pm',
    'lib/Stepford/GraphBuilder.pm',
    'lib/Stepford/LoggerWithMoniker.pm',
    'lib/Stepford/Role/Step.pm',
    'lib/Stepford/Role/Step/FileGenerator.pm',
    'lib/Stepford/Role/Step/FileGenerator/Atomic.pm',
    'lib/Stepford/Role/Step/Unserializable.pm',
    'lib/Stepford/Runner.pm',
    'lib/Stepford/Trait/StepDependency.pm',
    'lib/Stepford/Trait/StepProduction.pm',
    'lib/Stepford/Types.pm',
    'lib/Stepford/Types/Internal.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/Runner-child-death.t',
    't/Runner-diamond-graph.t',
    't/Runner-dry-run.t',
    't/Runner-inner-steps.t',
    't/Runner-integration.t',
    't/Runner-no-unnecessary-rebuild.t',
    't/Runner-parallel-unserializable.t',
    't/Runner-parallel.t',
    't/Runner-rebuild-on-missing-files.t',
    't/Runner-rebuild.t',
    't/Runner-step-modifies-topic.t',
    't/Runner.t',
    't/Step-FileGenerator-Atomic-fork-bug.t',
    't/Step-FileGenerator-Atomic.t',
    't/Step.t',
    't/lib/Test1/Step/CombineFiles.pm',
    't/lib/Test1/Step/CreateA1.pm',
    't/lib/Test1/Step/CreateA2.pm',
    't/lib/Test1/Step/UpdateFiles.pm',
    't/lib/Test1/StepGroup/CreateAndBackup.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
