package Line::Storage;
use strict;
use warnings;
use parent 'Exporter';

our @EXPORT_OK   = qw( remember_line recall_line );
our %EXPORT_TAGS = (ALL => \@EXPORT_OK);

my %lines;

sub remember_line {
    my ($name) = @_;
    die "$name already taken" if $lines{$name};
    $lines{$name} = (caller)[2];
    return;
}

sub recall_line {
    my ($name) = @_;
    die "$name not found" if not $lines{$name};
    return $lines{$name};
}

1;
