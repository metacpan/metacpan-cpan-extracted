package Pinwheel::Helpers::List;

use strict;
use warnings;

use Exporter;

use Pinwheel::Context;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(group enumerate uniq take drop);


sub group
{
    my ($list, $n) = @_;
    my ($size, $i, @result);

    $size = scalar(@$list);
    for ($i = 0; $i < $size; ) {
        push @result, [map { $list->[$i++] } (1 .. $n)];
    }
    return \@result;
}

sub enumerate
{
    my ($list, $i) = @_;
    my @result;

    push @result, [$i++, $_] foreach @$list;
    return \@result;
}

sub uniq
{
    my ($list) = @_;

    my %seen = ();
    my @uniq = grep { ! $seen{$_} ++ } @$list;

    return \@uniq;
}

sub take
{
    my ($list, $n) = @_;

    if ($n < scalar(@$list)) {
        $list = [@$list[0 .. $n - 1]];
    }
    return $list;
}

sub drop
{
    my ($list, $n) = @_;

    return [@$list[$n .. scalar(@$list) - 1]];
}


1;
