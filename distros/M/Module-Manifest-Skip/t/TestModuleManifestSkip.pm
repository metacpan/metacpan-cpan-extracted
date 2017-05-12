use strict; use warnings;
package TestModuleManifestSkip;

use base 'Exporter';

use Module::Manifest::Skip;
use Cwd qw[cwd abs_path];

our $HOME = cwd;
our $LIB = abs_path 'lib';
our $TEMPLATE = Module::Manifest::Skip->read_file('share/MANIFEST.SKIP');
our @EXPORT = qw[read_file copy_file cwd abs_path $HOME $LIB $TEMPLATE];

sub import {
    strict->import;
    warnings->import;
    goto &Exporter::import;
}

sub read_file {
    return Module::Manifest::Skip->read_file(@_);
}

sub copy_file {
    my ($src, $dest) = @_;
    open my $in, $src or die "Can't open $src for input";
    open my $out, '>', $dest or die "Can't open $dest for output";
    my $text = do { local $/; <$in> };
    print $out $text;
    close $out;
    close $in;
    return 1;
}

1;
