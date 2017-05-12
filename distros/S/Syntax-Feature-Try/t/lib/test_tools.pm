package test_tools;

use strict;
use warnings;
use Test::Spec;

use base 'Exporter';
our @EXPORT_OK = qw/
    dump_code
    test_syntax_error
    compile_ok
/;

sub dump_code {
    my ($code) = @_;
    my ($dump, $linenr) = ("Tested code:\n", 0);
    foreach (split "\n", $code) {
        ++$linenr;
        $dump .= "   $linenr: $_\n";
    }
    diag "$dump\n";
}

sub test_syntax_error {
    my ($code, $err_pattern, $test_name) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    eval $code;
    like($@, $err_pattern, $test_name) or dump_code($code);
}

sub compile_ok {
    my ($code, $err_patterni, $test_name) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my @result = eval $code;
    is($@, '', $test_name) or dump_code($code);

    return @result;
}

1;
