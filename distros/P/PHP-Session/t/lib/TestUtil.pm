package TestUtil;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(write_file read_file);

use strict;
use FileHandle;

sub write_file {
    my($file, $cont) = @_;
    my $out = FileHandle->new("> $file") or die "$file: $!";
    $out->print($cont);
}

sub read_file {
    my $file = shift;
    my $in = FileHandle->new($file) or die "$file: $!";
    local $/;
    my $cont = <$in>;
    return $cont;
}

1;
