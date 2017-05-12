package Parse::BBCode::HTML;
$Parse::BBCode::HTML::VERSION = '0.15';
use strict;
use warnings;
use Carp qw(croak carp);
use URI::Escape;
use base 'Exporter';
our @EXPORT_OK = qw/ &defaults &default_escapes &optional /;

my $email_valid = 0;
eval {
    require
        Email::Valid;
};
$email_valid = 1 unless $@;

my %colors = (
    aqua    => 1,
    black   => 1,
    blue    => 1,
    fuchsia => 1,
    gray    => 1,
    grey    => 1,
    green   => 1,
    lime    => 1,
    maroon  => 1,
    navy    => 1,
    olive   => 1,
    purple  => 1,
    red     => 1,
    silver  => 1,
    teal    => 1,
    white   => 1,
    yellow  => 1,
);

my %default_tags = (
    'b'     => '<b>%s</b>',
    'i'     => '<i>%s</i>',
    'u'     => '<u>%s</u>',
    'img'   => '<img src="%{link}A" alt="[%{html}s]" title="%{html}s">',
    'url'   => 'url:<a href="%{link}A" rel="nofollow">%s</a>',
    'email' => 'url:<a href="mailto:%{email}A">%s</a>',
    'size'  => '<span style="font-size: %{num}a">%s</span>',
    'color' => '<span style="color: %{htmlcolor}a">%s</span>',
    'list'  => {
        parse => 1,
        class => 'block',
        code => sub {
            my ($parser, $attr, $content, $attribute_fallback, $tag) = @_;
            $$content =~ s/^\n+//;
            $$content =~ s/\n+\z//;
            my $type = "ul";
            my $style = '';
            if ($attr) {
                if ($attr eq '1') {
                    $type = "ol";
                }
                elsif ($attr eq 'a') {
                    $type = "ol";
                    $style = ' style="list-style-type: lower-alpha"';
                }
            }
            return "<$type$style>$$content</$type>";
        },
    },
    '*' => {
        parse => 1,
        code => sub {
            my ($parser, $attr, $content, $attribute_fallback, $tag, $info) = @_;
            $$content =~ s/\n+\z//;
            if ($info->{stack}->[-2] eq 'list') {
                return "<li>$$content</li>",
            }
            return Parse::BBCode::escape_html($tag->raw_text);
        },
        close => 0,
        class => 'block',
    },
    'quote' => {
        code => sub {
            my ($parser, $attr, $content) = @_;
            my $title = 'Quote';
            if ($attr) {
                $title = Parse::BBCode::escape_html($attr);
            }
            return <<"EOM";
<div class="bbcode_quote_header">$title:
<div class="bbcode_quote_body">$$content</div></div>
EOM
        },
        parse => 1,
        class => 'block',
    },
    'code'  => {
        code => sub {
            my ($parser, $attr, $content) = @_;
            my $title = 'Code';
            if ($attr) {
                $title = Parse::BBCode::escape_html($attr);
            }
            $content = Parse::BBCode::escape_html($$content);
            return <<"EOM";
<div class="bbcode_code_header">$title:
<div class="bbcode_code_body">$content</div></div>
EOM
        },
        parse => 0,
        class => 'block',
    },
    'noparse' => '%{html}s',
);
my %optional_tags = (
    'html' => '%{noescape}s',
);

my %default_escapes = (
    html => sub {
        Parse::BBCode::escape_html($_[2]),
    },
    uri => sub {
        uri_escape($_[2]),
    },
    link => sub {
        my ($p, $tag, $var) = @_;
        if ($var =~ m{^ (?: [a-z]+:// | / ) \S+ \z}ix) {
            # allow proto:// and absolute links /
        }
        else {
            # invalid
            return;
        }
        $var = Parse::BBCode::escape_html($var);
        return $var;
    },
    email => $email_valid ? sub {
        my ($p, $tag, $var) = @_;
        # extracts the address part of the email or undef
        my $valid = Email::Valid->address($var);
        return $valid ? Parse::BBCode::escape_html($valid) : '';
    } : sub {
        my ($p, $tag, $var) = @_;
        $var = Parse::BBCode::escape_html($var);
    },
    htmlcolor => sub {
        my $color = $_[2];
        ($color =~ m/^(?:#[0-9a-fA-F]{6})\z/ || exists $colors{lc $color})
        ? $color : 'inherit'
    },
    num => sub {
        $_[2] =~ m/^[0-9]+\z/ ? $_[2] : 0;
    },
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
    return @keys
        ? (map { $_ => $optional_tags{$_} } grep  { defined $optional_tags{$_} } @keys)
        : %optional_tags;
}



1;

__END__

=pod

=head1 NAME

Parse::BBCode::HTML - Provides HTML defaults for Parse::BBCode

=head1 SYNOPSIS

    use Parse::BBCode;
    # my $p = Parse::BBCode->new();
    my $p = Parse::BBCode->new({
        tags => {
            Parse::BBCode::HTML->defaults,
            # add your own tags here if needed
        },
        escapes => {
            Parse::BBCode::HTML->default_escapes,
            # add your own escapes here if needed
        },
    });
    my $code = 'some [b]b code[/b]';
    my $parsed = $p->render($code);

=head1 METHODS

=over 4

=item defaults

Returns a hash with default tags.

    b, i, u, img, url, email, size, color, list, *, quote, code

=item default_escapes

Returns a hash with escaping functions. These are:

    html, uri, link, email, htmlcolor, num

=item optional

Returns a hash of optional tags. These are:

    html

=back

=cut

