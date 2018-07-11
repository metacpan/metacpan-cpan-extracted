package WriteCSVTest;

use strict;
use warnings;

use Test::Unit::Lite;
use base qw(Common Test::Unit::TestCase);

sub test_text_format {
    my $self=shift;

    $self->check_package('Text::CSV') ||
        return;

    $self->spreadsheet_test('csv',\*DATA);

    $self->spreadsheet_test('CSV',\*DATA);
}

1;

__DATA__
Column1,Column#2,"Column 3","Column  4"
1,"Cell #2/1",C.3/1,"C.4/1/☺"
2,"Cell #2/2",C.3/2,"C.4/2/☺"
