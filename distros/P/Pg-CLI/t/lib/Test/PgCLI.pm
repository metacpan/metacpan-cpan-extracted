package Test::PgCLI;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT = 'test_command';

sub test_command {
    my $class = shift;
    my $run   = shift;
    my $tests = shift;

    $class = 'Pg::CLI::' . $class;

    no warnings 'redefine';
    no strict 'refs';

    local *{ $class . '::_call_run3' }  = $tests;
    local *{ $class . '::_build_version' } = sub { '8.4.5' };

    $run->();
}

1;
