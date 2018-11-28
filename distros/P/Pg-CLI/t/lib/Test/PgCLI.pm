package Test::PgCLI;

use strict;
use warnings;

use Exporter 'import';

## no critic (Modules::ProhibitAutomaticExportation)
our @EXPORT = 'test_command';

sub test_command {
    my $class   = shift;
    my $run     = shift;
    my $tests   = shift;
    my $version = shift || '8.4.5';

    $class = 'Pg::CLI::' . $class;

    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    no warnings 'redefine';
    no strict 'refs';

    local *{ $class . '::_call_run3' }     = $tests;
    local *{ $class . '::_build_version' } = sub {$version};

    $run->();
}

1;
