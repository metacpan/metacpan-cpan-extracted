package Queue::Gearman::Util;
use strict;
use warnings;
use utf8;

use parent qw/Exporter/;
our @EXPORT_OK = qw/dumper/;

sub dumper {
    require Data::Dumper;

    no warnings qw/once/;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Sortkeys = 1;
    use warnings qw/once/;

    return Data::Dumper::Dumper(@_);
}

1;
__END__
