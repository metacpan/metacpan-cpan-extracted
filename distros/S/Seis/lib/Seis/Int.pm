package Seis::Int;
use strict;
use warnings;
use utf8;
use 5.010_001;

package # Hide from PAUSE
    Int;

sub perl { $_[0] }

sub clone { 0+$_[0] }

sub say { CORE::say($_[0]) }

sub isa {
    my ($self, $stuff) = @_;
    return $stuff->{name} eq 'Int' if UNIVERSAL::isa($stuff, 'Seis::Class');
    # Yes, it's boolean.
    return 1 if Bool::_isBoolean($self) && $stuff eq 'Seis::Bool';
    return 1 if $stuff eq 'Int';
    return 0;
}

sub Bool { Bool::boolean($_[0]) }

sub WHAT {
    my $self = shift;
    Seis::Class->_new(name => 'Int');
}

sub base {
    my ($num, $base) = @_;
    require Math::BaseCnv;
    Math::BaseCnv::cnv($num, 10, $base);
}

sub defined { 1 }

sub chr: method { CORE::chr($_[0]) }

sub rand:method { CORE::rand($_[0]) }

sub fmt {
    my ($self, $pattern) = @_;
    $pattern //= "%d";
    sprintf($pattern, $self);
}

{
    # Note.
    # I don't think Math::Prime::Util is the best solution to solve the 'is_prime' problem.
    # If you know the best module for this issue, patches welcome.
    # Small memory foot point is great. And if you can write a fast xs code, it's the best.
    sub isーprime {
        require Math::Prime::Util;
        Math::Prime::Util::is_prime($_[0])
    };
}

sub Int { $_[0] }

sub ords {
    my @ret = map { ord($_) } split //, $_[0];
    wantarray ? @ret : \@ret;
}

sub rindex:method { goto &Str::rindex }

sub kv {
    [0, $_[0]]
}

sub sign {
    my $self = shift;
    if ($self < 0) {
        -1;
    } elsif ($self == 0) {
        0;
    } else {
        1;
    }
}

1;

