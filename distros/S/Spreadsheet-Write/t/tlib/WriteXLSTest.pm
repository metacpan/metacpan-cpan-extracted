package WriteXLSTest;

use strict;
use warnings;

use Test::Unit::Lite;
use base qw(Common Test::Unit::TestCase);

sub test_all {
    my $self=shift;

    $self->check_package('Spreadsheet::WriteExcel') ||
        return;

    $self->spreadsheet_test('xls');

    $self->spreadsheet_test('XLS');
}

1;
