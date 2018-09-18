package t::Util;
use strict;
use warnings;
use utf8;

use base 'Exporter';
use Carp;

our @EXPORT = qw(
    generate_st
    first_line_st
    first_line_lineno
    child_line_st
    child_line_lineno
    eval_line_st
);

my $some_func_confess_line;
my $another_func_caller_line;

{
    package Some::Module;
    sub new {
        bless {}, shift;
    }
    sub some_func {
        my ($class, $str, $href) = @_;
        $some_func_confess_line = __LINE__ + 1;
        Carp::confess "some_func use confess";
    }
}

{
    package Another::Module;
    sub another_func {
        my $sf = Some::Module->new;
        $another_func_caller_line = __LINE__ + 1;
        $sf->some_func('Test Arg', { aaa => 5.7 });
    }
}

sub generate_st {
    eval {
        Another::Module::another_func();
    };
    return $@;
}

sub first_line_st {
    my $st = generate_st();
    my ($first_line) = split "\n", $st;
    return $first_line;
}

sub first_line_lineno {
    return $some_func_confess_line;
}

sub child_line_st {
    my $st = generate_st();
    my (undef, $second_line) = split "\n", $st;
    return $second_line;
}

sub child_line_lineno {
    return $another_func_caller_line;
}

sub eval_line_st {
    my $st = generate_st();
    my ($eval_line) = grep { /^\s+eval/ } split "\n", $st;
    return $eval_line;
}

1;
