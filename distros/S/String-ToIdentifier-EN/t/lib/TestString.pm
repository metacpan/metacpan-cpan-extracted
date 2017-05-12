package TestString;
use strict;
use warnings;
use Test::More;
use namespace::clean;
use Exporter 'import';
use String::ToIdentifier::EN ();
use String::ToIdentifier::EN::Unicode ();

our @EXPORT_OK = qw/is_both to_ascii to_unicode/;

sub to_ascii {
    return String::ToIdentifier::EN::to_identifier(@_)
}

sub to_unicode {
    return String::ToIdentifier::EN::Unicode::to_identifier(@_)
}

sub is_both {
    my @args = @{ +shift };
    my ($expected, $test_name) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    is to_ascii(@args),   $expected, $test_name;
    is to_unicode(@args), $expected, $test_name;
}

1;
