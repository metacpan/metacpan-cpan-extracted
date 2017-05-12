package Dummy;

# dummy operations used for testing

use strict;
use warnings;
use ExtUtils::Command ();

sub touch {
    local @ARGV = @_;

    ExtUtils::Command::touch;
}

sub cp {
    local @ARGV = @_;

    ExtUtils::Command::cp;
}

sub mv {
    local @ARGV = @_;

    ExtUtils::Command::mv;
}

sub mkpath {
    local @ARGV = @_;

    ExtUtils::Command::mkpath;
}

sub ls {
    my @patters = @_;
    my @results;

    foreach my $pat ( @patters ) {
        push @results, sort map { -d $_ ? "$_/" : $_ } glob $pat;
    }

    return @results;
}

1;
