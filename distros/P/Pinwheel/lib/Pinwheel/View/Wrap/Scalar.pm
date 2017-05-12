package Pinwheel::View::Wrap::Scalar;

use strict;
use warnings;

use Carp qw(croak);

our $AUTOLOAD;
our @WRAP_METHODS = qw(strip upcase downcase length size);


sub strip
{
    my $s = $_[1];
    $s =~ s/^\s+|\s+$//g;
    return $s;
}

sub upcase
{
    return uc($_[1]);
}

sub downcase
{
    return lc($_[1]);
}

sub length
{
    return CORE::length($_[1]);
}

*size = *length;

sub AUTOLOAD
{
    my ($name);

    $name = $AUTOLOAD;
    $name =~ s/.*:://;
    croak "Bad scalar method '$name'" unless $name =~ /[A-Z]/;
}


1;
