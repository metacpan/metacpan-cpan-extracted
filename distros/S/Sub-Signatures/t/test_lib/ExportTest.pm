package ExportTest;

use base 'Exporter';
use Sub::Signatures;

@EXPORT_OK = qw/foo/;

sub foo($bar) {
    $bar;
}

sub foo($bar, $baz) {
    return [$bar, $baz];
}

1;
