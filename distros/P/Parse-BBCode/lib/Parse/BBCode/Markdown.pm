package Parse::BBCode::Markdown;
$Parse::BBCode::Markdown::VERSION = '0.15';
use strict;
use warnings;
use Carp qw(croak carp);
use URI::Escape;
use base qw/ Parse::BBCode /;

my %default_tags = (
    'b'     => '*%s*',
    'i'     => '__%s__',
    'u'     => '_%s_',
    # ![alt text](/path/to/img.jpg "Title")
    'img'   => '![%s](%A)',
    'url'   => 'url:[%s](%{link}A)',
    'email' => 'url:[%s](mailto:%{email}A)',
    'size'  => '%s',
    'color' => '%s',
    'list'  => 'block:%{parse}s',
    '*'     => {
        parse => 1,
        output => '* %s',
        close => 0,
        class => 'block',
    },
    quote => {
        parse => 1,
        class => 'block',
        code => sub {
            my ($parser, $attr, $content, $attribute_fallback) = @_;
            $$content =~ s/^/> /gm;
            $$content =~ s/^> >/>>/gm;
            "$attribute_fallback:\n$$content\n";
        },
    },
    'code'  => {
        code => sub {
            my ($parser, $attr, $content, $attribute_fallback) = @_;
            $$content =~ s/^/| /gm;
            return "Code $attribute_fallback:\n" . ('-' x 20) . "\n$$content\n" . ('-' x 20);
        },
        class => 'block',
    },
    '' => sub {
        my $text = $_[2];
        $text;
    },
);

my %optional_tags = (
#    Parse::BBCode::HTML->optional(),
);

my %default_escapes = (
    Parse::BBCode::HTML->default_escapes
);


sub defaults {
    my ($class, @keys) = @_;
    return @keys
        ? (map { $_ => $default_tags{$_} } grep { defined $default_tags{$_} } @keys)
        : %default_tags;
}

sub default_escapes {
    my ($class, @keys) = @_;
    return @keys
        ? (map { $_ => $default_escapes{$_} } grep  { defined $default_escapes{$_} } @keys)
        : %default_escapes;
}

sub optional {
    my ($class, @keys) = @_;
    return @keys ? (grep defined, @optional_tags{@keys}) : %optional_tags;
}



1;

__END__

=pod

=head1 NAME

Parse::BBCode::Markdown - Provides Markdown defaults for Parse::BBCode

=head1 SYNOPSIS

    use Parse::BBCode::Markdown;
    my $p = Parse::BBCode::Markdown->new();
    my $code = 'some [b]b code[/b]';
    my $parsed = $p->render($code);

=head1 DESCRIPTION

This module is experimental and subject to change.

=head1 METHODS

=over 4

=item defaults

Returns a hash with default tags.

    b, i, u, img, url, email, size, color, list, *, quote, code

=item default_escapes

Returns a hash with escaping functions.

    html, uri, link, email, htmlcolor, num

=item optional

Returns a hash of optional tags.

    html

=back

=cut

