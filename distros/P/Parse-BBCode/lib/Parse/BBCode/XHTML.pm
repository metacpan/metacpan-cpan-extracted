package Parse::BBCode::XHTML;
$Parse::BBCode::XHTML::VERSION = '0.15';
use strict;
use warnings;
use Carp qw(croak carp);
use URI::Escape;
use base qw/ Parse::BBCode /;

my $email_valid = 0;
eval {
    require
        Email::Valid;
};
$email_valid = 1 unless $@;

my %default_tags = (
    Parse::BBCode::HTML->defaults(),
    '' => sub {
        my $text = Parse::BBCode::escape_html($_[2]);
        $text =~ s{\r?\n|\r}{<br />\n}g;
        $text;
    },
    'img'   => '<img src="%{link}A" alt="[%{html}s]" title="%{html}s" />',
);
my %optional_tags = (
    Parse::BBCode::HTML->optional(),
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

Parse::BBCode::XHTML - Provides XHTML defaults for Parse::BBCode

=head1 SYNOPSIS

    use Parse::BBCode::XHTML;
    my $p = Parse::BBCode::XHTML->new();
    my $code = 'some [b]b code[/b]';
    my $parsed = $p->render($code);

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

