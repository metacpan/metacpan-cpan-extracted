package t::Util;
use strict;
use warnings;
use utf8;
use 5.010_001;
use parent qw(Exporter);
use lib 't/lib/';
use Data::Dumper;
use Data::SExpression::Lite;
use File::Temp;
use Test::More;

our @EXPORT = qw(compile_and_compare parse_perl6 parse_sexp);

sub compile_and_compare {
    my ( $perl6, $expected_sexp ) = @_;
    my $got_sexp = parse_perl6($perl6);
    my $got      = parse_sexp($got_sexp);
    my $expected = parse_sexp($expected_sexp);
    is_deeply($got, $expected, 'Test: ' . $perl6) or do {
        $Data::Dumper::Sortkeys=1;
        $Data::Dumper::Indent=1;
        $Data::Dumper::Terse=1;
        diag "GOT:";
        diag Dumper($got);
        diag "EXPECTED:";
        diag Dumper($expected);
        diag "SEXP: $got_sexp";
    };
}

sub parse_perl6 {
    my ($src) = @_;

    my $tmp = File::Temp->new();
    print {$tmp} $src;

    my $sexp = `./pvip $tmp`;
    unless ($sexp =~ /\A\(/) {
        die "Cannot get sexp from '$src': $sexp";
    }
    $sexp;
}

sub parse_sexp {
    my $expected = shift;
    my $sexp = Data::SExpression::Lite->new();
    return $sexp->parse($expected);
}

1;

