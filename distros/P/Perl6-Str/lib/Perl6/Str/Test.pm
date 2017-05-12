package Perl6::Str::Test;
use strict;
use warnings;
use Exporter qw(import);
use Test qw(ok);
use charnames ();
require Test::More;

our @EXPORT_OK = qw(expand_str escape_str is_eq);

sub expand_str {
    my $str = eval qq{use charnames qw(:full); "$_[0]"};
    die $@ if $@;
    return $str;
}

sub escape_str {
    my $str = shift;
    $str =~ s{([^\0-\177])}{_N_escape($1)}eg;
    return $str;
}

sub _N_escape {
    return '\N{' . charnames::viacode(ord($_[0])) . '}';
}

sub is_eq {
    my ($lhs, $rhs, $descr) = @_;
    $descr = '' if @_ < 3;

    Test::More::ok(($lhs eq $rhs), escape_str($descr))
        or Test::More::diag(sprintf("lhs: '%s'\nrhs: '%s'\n", 
                escape_str($lhs), escape_str($rhs)));
}

1;
