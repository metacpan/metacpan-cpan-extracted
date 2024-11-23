package TestType;
use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw( Int NonEmptyStr );

{
    package TestType::Object;

    sub new {
        my ($class, $check ) = @_;
        bless { check => $check }, $class;
    }

    sub check {
        my ($self, $value) = @_;
        $self->{check}->($value);
    }
}

sub is_int { defined $_[0] && $_[0] =~ /^-?\d+$/ }
sub is_non_empty_str { defined $_[0] && !ref $_[0] && length $_[0] > 1 }

sub Int() { TestType::Object->new(\&is_int) }
sub NonEmptyStr() { TestType::Object->new(\&is_non_empty_str) }

1;
