package Pistachio::Html;
# ABSTRACT: provides snippet(), which turns source code text into stylish HTML

use strict;
use warnings;
our $VERSION = '0.10'; # VERSION

use Pistachio::Tokenizer;
use Pistachio::Language;
use HTML::Entities;
use Module::Load;
use Carp 'croak';

# @param string $type Object type.
# @param mixed $lang String: language, e.g., 'Perl5'.
#                    Object: A Pistachio::Language.
# @param string $style Style, e.g., 'Github'.
# @return Pistachio::Html
sub new {
    my $type = shift;
    my ($lang, $style) = (shift || '', shift || '');

    # A Pistachio::Css's methods return the Language-independent 
    # CSS definitions that correspond to the given style.
    my $Css = "Pistachio::Css::${style}";
    eval { load $Css };
    croak "No CSS support for `$style`" if $@;
    my $css = $Css->new;

    # If $lang is a Pistachio::Language, then there is no
    # more work to do. If $lang is a string, attempt to 
    # construct a corresponding Pistachio::Language.
    # (Right now, baked-in language support is limited
    # to Perl5, which is tokenized via PPI::Tokenizer.)
    ref $lang eq 'Pistachio::Language' or do { 
        eval { load "${Css}::${lang}", 'type_to_style' };
        croak "No type_to_style() for `$lang, $style`" if $@;

        eval { load "Pistachio::Token::Constructor::${lang}",
                    'text_to_tokens' };
        croak "No text_to_tokens() for `$lang`" if $@;

        eval { load "Pistachio::Token::Transformer::${lang}", 
                    'transform_rules' };
        croak "No transform_rules() for `$lang`" if $@;

        $lang = Pistachio::Language->new(
            $lang,
            tokens          => sub { text_to_tokens($_[0]) },
            type_to_style   => sub { type_to_style($_[0]) },
            transform_rules => sub { transform_rules() },
        );
    };

    bless [$lang, $css], $type;
}

# @param Pistachio::Html $this
# @return A Pistachio::Language
sub lang { shift->[0] }

# @param Pistachio::Html $this
# @return Pistachio::Css Provides methods to access language-independent 
#                        css definitions, for the given style.
sub css { shift->[1] }

# @param Pistachio::Html $this
# @param scalarref $text    source code text
# @return string    line numbers div + source code div html
sub snippet {
    my ($this, $text) = @_;

    NUMBER_STRIP: my $num_strip = do {
        my @nums = 1 .. @{[split /\n/, $$text]};
        my $spec = '<div style="%s">%d</div>';
        my @divs = map sprintf($spec, $this->css->number_cell, $_), @nums;

        $spec = qq{<div style="%s">\n%s\n</div>\n};
        sprintf $spec, $this->css->number_strip, "@divs";
    };

    CODE_DIV: my $code_div = do {
        my $code = '';
        my $it = Pistachio::Tokenizer->new($this->lang)->iterator($text);

        while ($_ = $it->()) { 
            my $style = $this->lang->type_to_style($_->type);
            my $val = encode_entities $_->value;
            $code .= $style ? qq|<span style="$style">$val</span>|
                            : qq|<span>$val</span>|;
        }

        sprintf qq{<div style="%s">%s</div>}, $this->css->code_div, $code;
    };

    join "\n", '<div>', $num_strip, $code_div, '</div>',
               '<div style="clear:both"></div>';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pistachio::Html - provides snippet(), which turns source code text into stylish HTML

=head1 VERSION

version 0.10

=head1 SYNOPSIS

 use Pistachio::Html;
 my $html = Pistachio::Html->new('Perl5', 'Github');

 my $scalar_ref = \"use strict; ...;";
 my $snip = $html->snippet($scalar_ref);

=head2 ALSO SEE

L<Pistachio> - See the ROLL YOUR OWN LANGUAGE SUPPORT section.

=head1 AUTHOR

Joel Dalley <joeldalley@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Joel Dalley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
