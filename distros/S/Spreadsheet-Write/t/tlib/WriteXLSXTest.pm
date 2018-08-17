package WriteXLSXTest;

use strict;
use warnings;

use Test::Unit::Lite;
use base qw(Common Test::Unit::TestCase);

sub test_all {
    my $self=shift;

    $self->check_package('Excel::Writer::XLSX') ||
        return;

    $self->spreadsheet_test('xlsx');

    $self->spreadsheet_test('XLSX');
}

1;
