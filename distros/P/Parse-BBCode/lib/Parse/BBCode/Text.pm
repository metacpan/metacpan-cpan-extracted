package Parse::BBCode::Text;
$Parse::BBCode::Text::VERSION = '0.15';
use strict;
use warnings;
use Carp qw(croak carp);

use base qw/ Parse::BBCode /;

my %default_tags = (
    'b'     => '%s',
    'i'     => '%s',
    'u'     => '%s',
    'img'   => '%s',
    'url'   => '%s',
    'email' => 'mailto:%{email}A',
    'size'  => '%s',
    'color' => '%s',
    'list'  => 'block:%{parse}s',
    '*'     => {
        parse => 1,
        output => '* %s',
        close => 0,
        class => 'block',
        code => sub {
            my ($parser, $attr, $content, $attribute_fallback) = @_;
            $$content =~ s/\n+\Z//;
            $$content =~ s/^\s+//;
            return "* $$content\n";
        },
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
=pod

=head1 NAME

Parse::BBCode::Text - Provides plaintext defaults for Parse::BBCode

=head1 SYNOPSIS

    use Parse::BBCode::Text;
    my $p = Parse::BBCode::Markdown->new();
    my $code = 'some [b]b code[/b]';
    my $plaintext = $p->render($code);

=head1 DESCRIPTION

This module can be used to turn bbcode into minimal plaintext.

=head1 METHODS

=over 4

=item defaults

Returns a hash with default tags.

    b, i, u, img, url, email, size, color, list, *

=item default_escapes

Returns a hash with escaping functions.

    html, uri, link, email, htmlcolor, num

=item optional

Returns a hash of optional tags.

    html

=back

=cut

