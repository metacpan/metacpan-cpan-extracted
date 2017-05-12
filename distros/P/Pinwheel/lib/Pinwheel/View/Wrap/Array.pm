package Pinwheel::View::Wrap::Array;

use strict;
use warnings;

use Carp qw(croak);

our $AUTOLOAD;
our @WRAP_METHODS = qw(first last reverse sort min max length size empty);


sub first
{
    return $_[1]->[0];
}

sub last
{
    return $_[1]->[-1];
}

sub reverse
{
    return [reverse @{$_[1]}];
}

sub sort
{
    return [sort @{$_[1]}];
}

sub min
{
    return [sort { $a <=> $b } @{$_[1]}]->[0];
}

sub max
{
    return [sort { $a <=> $b } @{$_[1]}]->[-1];
}

sub length
{
    return scalar(@{$_[1]});
}

*size = *length;

sub empty
{
    return scalar(@{$_[1]}) == 0;
}

sub AUTOLOAD
{
    my ($name);

    $name = $AUTOLOAD;
    $name =~ s/.*:://;
    croak "Bad array method '$name'" unless $name =~ /[A-Z]/;
}


1;
