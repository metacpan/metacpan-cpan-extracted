package Pistachio::Token::Transformer::Perl5;
# ABSTRACT: provides transform_rules(), which returns an array of Pistachio::Token::Transformer::Rules

use strict;
use warnings;
our $VERSION = '0.10'; # VERSION

use Pistachio::Token::Transformer::Rule;
use Exporter 'import';
our @EXPORT_OK = 'transform_rules';

# @return arrayref    Pistachio::Token::Transformer::Rules
sub transform_rules {
    my @rules;

    push @rules, Pistachio::Token::Transformer::Rule->new(
        type => 'Word',
        prec => [['Word::Reserved', 'package']],
        succ => [['Structure', ';']],
        into => 'Word::Package',
    );

    push @rules, Pistachio::Token::Transformer::Rule->new(
        type => 'Word',
        prec => [['Word::Reserved', 'use']],
        succ => [['Structure', ';']],
        into => 'Word::Use',
    );

    push @rules, Pistachio::Token::Transformer::Rule->new(
        type => 'Word',
        prec => [['Word::Reserved', 'require']],
        succ => [['Structure', ';']],
        into => 'Word::Require',
    );

    push @rules, Pistachio::Token::Transformer::Rule->new(
        type => 'Word::Reserved',
        val  => sub {
            my $keyword = '^(use|require|sub|my|our|new|last|'
                        . 'next|redo|if|else|elsif|do|unless)$';
            shift =~ /$keyword/o
        },
        into => 'Word::Reserved::Keyword',
    );

    push @rules, Pistachio::Token::Transformer::Rule->new(
        type => 'Word::Reserved',
        val  => sub {
            my $speclit = '^__(FILE|LINE|PACKAGE|SUB|DATA|END)__$';
            shift =~ /$speclit/o
        },
        into => 'Word::Special::Literal',
    );

    push @rules, Pistachio::Token::Transformer::Rule->new(
        type => 'Word',
        prec => [['Word::Reserved', 'sub']],
        into => 'Word::Sub::Define',
    );

    push @rules, Pistachio::Token::Transformer::Rule->new(
        type => 'Word::Defined',
        succ => [['Structure', '(']],
        into => 'Word::Sub::Invoke',
    );

    push @rules, Pistachio::Token::Transformer::Rule->new(
        type => 'Word',
        prec => [['Operator::Dereference', '->']],
        succ => [['Structure', '(']],
        into => 'Word::Coderef::Invoke',
    );

    push @rules, Pistachio::Token::Transformer::Rule->new(
        type => 'Word::Defined',
        succ => [['Operator', '=>']],
        into => 'Word::Hashkey',
    );

    push @rules, Pistachio::Token::Transformer::Rule->new(
        type => 'Word::Defined',
        prec => [['Word::Reserved::Keyword', 'use'], 
                 ['Word::Defined', 'constant']],
        succ => [['Operator', '=>']],
        into => 'Word::Constant',
    );

    push @rules, Pistachio::Token::Transformer::Rule->new(
        type => 'Word::Defined',
        val  => sub {shift eq 'lib'},
        into => 'Word::Reserved',
    );

    push @rules, Pistachio::Token::Transformer::Rule->new(
        type => 'Magic',
        val  => sub {shift eq '@_'},
        into => 'Magic::These',
    );

    push @rules, Pistachio::Token::Transformer::Rule->new(
        type => 'Magic',
        val  => sub {shift eq '$_'},
        into => 'Magic::This',
    );

    push @rules, Pistachio::Token::Transformer::Rule->new(
        type => 'Operator',
        val  => sub {shift eq '->'},
        into => 'Operator::Dereference',
    );

    push @rules, Pistachio::Token::Transformer::Rule->new(
        type => 'Operator',
        val  => sub {shift =~ /^[\w\-]+$/},
        into => 'Operator::Wordish',
    );

    push @rules, Pistachio::Token::Transformer::Rule->new(
        type => 'Cast',
        val  => sub {shift eq '\\'},
        into => 'Cast::Reference',
    );

    push @rules, Pistachio::Token::Transformer::Rule->new(
        type => 'Symbol',
        val  => sub {shift =~ /^&/},
        into => 'Symbol::Sub'
    );

    \@rules;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pistachio::Token::Transformer::Perl5 - provides transform_rules(), which returns an array of Pistachio::Token::Transformer::Rules

=head1 VERSION

version 0.10

=head1 AUTHOR

Joel Dalley <joeldalley@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Joel Dalley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
