package TRTest;
use warnings;
use strict;
use utf8;
use Test::More;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = (qw/trfile/, @Test::More::EXPORT, @Table::Readable::EXPORT_OK);
use Carp;

my $builder = Test::More->builder;
binmode $builder->output, ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output, ":encoding(utf8)";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";

use Table::Readable ':all';

sub import
{
    my ($class) = @_;

    strict->import ();
    utf8->import ();
    warnings->import ();

# We already had to do this to use this module.
#    FindBin->import ('$Bin');
    Test::More->import ();
    Table::Readable->import (':all');

    TRTest->export_to_level (1);
}

sub trfile
{
    my ($file) = @_;
    my @input = read_table ($file);
}

1;
