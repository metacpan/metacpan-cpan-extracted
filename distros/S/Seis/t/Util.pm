package t::Util;
use strict;
use warnings;
use utf8;
use 5.010_001;
use parent qw(Exporter);
use Seis::Compiler;
use Test::More;

our @EXPORT = qw(compile);

{
    # utf8 hack.
    binmode Test::More->builder->$_, ":utf8" for qw/output failure_output todo_output/;
    no warnings 'redefine';
    my $code = \&Test::Builder::child;
    *Test::Builder::child = sub {
        my $builder = $code->(@_);
        binmode $builder->output,         ":utf8";
        binmode $builder->failure_output, ":utf8";
        binmode $builder->todo_output,    ":utf8";
        return $builder;
    };
}

sub compile {
    my $code = shift;

    my $compiler = Seis::Compiler->new();
    my $compiled = $compiler->compile($code);
    note 'code: ' . $code;
    note 'compiled: ' .  $compiled;
    note 'sexp: ' . eval { Perl6::PVIP->new->parse_string($code)->as_sexp } || 'err';

    my $result = eval $compiled;
    ok !$@ or diag $@;
    return $result;
}

1;
