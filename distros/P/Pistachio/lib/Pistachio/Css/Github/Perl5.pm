package Pistachio::Css::Github::Perl5;
# ABSTRACT: provides type_to_style(), which turns Pistachio::Token types into CSS definitions

use strict;
use warnings;
our $VERSION = '0.10'; # VERSION

use Exporter 'import';
our @EXPORT_OK = 'type_to_style';

# map Pistachio::Token type => css style
my %type_to_style = (
    'ArrayIndex'              => 'color:#008080',
    'Cast'                    => 'color:#008080',
    'Cast::Reference'         => 'color:#333;font-weight:bold',
    'Comment'                 => 'color:#999988;font-style:italic',
    'Label'                   => 'color:#333',
    'Magic'                   => 'color:#008080',
    'Magic::These'            => 'color:#008080',
    'Magic::This'             => 'color:#008080',
    'Number'                  => 'color:#008080',
    'Number::Float'           => 'color:#008080',
    'Operator'                => 'color:#333',
    'Operator::Dereference'   => 'color:#333;font-weight:bold',
    'Operator::Wordish'       => 'color:#333;font-weight:bold',
    'Prototype'               => 'color:#333',
    'Quote::Double'           => 'color:#D14',
    'Quote::Interpolate'      => 'color:#D14',
    'Quote::Single'           => 'color:#D14',
    'QuoteLike::Words'        => 'color:#D14',
    'Regexp'                  => 'color:#009926',
    'Regexp::Match'           => 'color:#009926',
    'Regexp::Substitute'      => 'color:#009926',
    'Structure'               => 'color:#333',
    'Symbol'                  => 'color:#008080',
    'Symbol::Sub'             => 'color:#333',
    'Word::Coderef::Invoke'   => 'color:#333',
    'Word::Constant'          => 'color:#D14',
    'Word::Defined'           => 'color:#333',
    'Word::Hashkey'           => 'color:#333',
    'Word::Package'           => 'color:#333',
    'Word::Require'           => 'color:#333',
    'Word::Reserved'          => 'color:#0086B3',
    'Word::Reserved::Keyword' => 'color:#333;font-weight:bold',
    'Word::Special::Literal'  => 'color:#333',
    'Word::Sub::Define'       => 'color:#990000;font-weight:bold',
    'Word::Sub::Invoke'       => 'color:#333',
    'Word::Use'               => 'color:#333',
    );

# @param string $type    a Pistachio::Token type
# @return string    the type's css, or an empty string
sub type_to_style { $type_to_style{$_[0] || ''} || '' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pistachio::Css::Github::Perl5 - provides type_to_style(), which turns Pistachio::Token types into CSS definitions

=head1 VERSION

version 0.10

=head1 AUTHOR

Joel Dalley <joeldalley@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Joel Dalley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
