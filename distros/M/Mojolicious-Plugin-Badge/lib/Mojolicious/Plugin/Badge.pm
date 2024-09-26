package Mojolicious::Plugin::Badge;
use Mojo::Base 'Mojolicious::Plugin';

use Carp ();
use Image::Magick;
use Mojo::ByteStream;
use Mojo::File qw(path);
use Mojo::URL;
use Mojo::UserAgent;
use Mojo::Util qw(b64_encode);
use Mojolicious::Types;

our $VERSION = '1.11';

use constant DEBUG => $ENV{BADGE_PLUGIN_DEBUG} || 0;

# Shields colors
my %SHIELDS_COLORS = (
    brightgreen => '#4c1',
    green       => '#97ca00',
    yellow      => '#dfb317',
    yellowgreen => '#a4a61d',
    orange      => '#fe7d37',
    red         => '#e05d44',
    blue        => '#007ec6',
    grey        => '#555',
    lightgrey   => '#9f9f9f',

    # Alias
    gray          => '#555',
    lightgray     => '#9f9f9f',
    critical      => '#e05d44',
    important     => '#fe7d37',
    success       => '#4c1',
    informational => '#007ec6',
    inactive      => '#9f9f9f',
);

my %NAMED_COLORS = (
    aliceblue            => '#f0f8ff',
    antiquewhite         => '#faebd7',
    aqua                 => '#00ffff',
    aquamarine           => '#7fffd4',
    azure                => '#f0ffff',
    beige                => '#f5f5dc',
    bisque               => '#ffe4c4',
    black                => '#000000',
    blanchedalmond       => '#ffebcd',
    blue                 => '#0000ff',
    blueviolet           => '#8a2be2',
    brown                => '#a52a2a',
    burlywood            => '#deb887',
    cadetblue            => '#5f9ea0',
    chartreuse           => '#7fff00',
    chocolate            => '#d2691e',
    coral                => '#ff7f50',
    cornflowerblue       => '#6495ed',
    cornsilk             => '#fff8dc',
    crimson              => '#dc143c',
    cyan                 => '#00ffff',
    darkblue             => '#00008b',
    darkcyan             => '#008b8b',
    darkgoldenrod        => '#b886b',
    darkgray             => '#a9a9a9',
    darkgreen            => '#006400',
    darkgrey             => '#a9a9a9',
    darkkhaki            => '#bdb76b',
    darkmagenta          => '#8b008b',
    darkolivegreen       => '#556b2f',
    darkorange           => '#ff8c00',
    darkorchid           => '#9932cc',
    darkred              => '#8b0000',
    darksalmon           => '#e9967a',
    darkseagreen         => '#8fbc8f',
    darkslateblue        => '#483d8b',
    darkslategray        => '#2f4f4f',
    darkslategrey        => '#2f4f4f',
    darkturquoise        => '#00ced1',
    darkviolet           => '#9400d3',
    deeppink             => '#ff1493',
    deepskyblue          => '#00bfff',
    dimgray              => '#696969',
    dimgrey              => '#696969',
    dodgerblue           => '#1e90ff',
    firebrick            => '#b22222',
    floralwhite          => '#fffaf0',
    forestgreen          => '#228b22',
    fuchsia              => '#ff00ff',
    gainsboro            => '#dcdcdc',
    ghostwhite           => '#f8f8ff',
    gold                 => '#ffd700',
    goldenrod            => '#daa520',
    gray                 => '#808080',
    green                => '#008000',
    greenyellow          => '#adff2f',
    grey                 => '#808080',
    honeydew             => '#f0fff0',
    hotpink              => '#ff69b4',
    indianred            => '#cd5c5c',
    indigo               => '#4b0082',
    ivory                => '#fffff0',
    khaki                => '#f0e68c',
    lavender             => '#e6e6fa',
    lavenderblush        => '#fff0f5',
    lawngreen            => '#7cfc00',
    lemonchiffon         => '#fffacd',
    lightblue            => '#add8e6',
    lightcoral           => '#f08080',
    lightcyan            => '#e0ffff',
    lightgoldenrodyellow => '#fafad2',
    lightgray            => '#d3d3d3',
    lightgreen           => '#90ee90',
    lightgrey            => '#d3d3d3',
    lightpink            => '#ffb6c1',
    lightsalmon          => '#ffa07a',
    lightseagreen        => '#20b2aa',
    lightskyblue         => '#87cefa',
    lightslategray       => '#778899',
    lightslategrey       => '#778899',
    lightsteelblue       => '#b0c4de',
    lightyellow          => '#ffffe0',
    lime                 => '#00ff00',
    limegreen            => '#32cd32',
    linen                => '#faf0e6',
    magenta              => '#ff00ff',
    maroon               => '#800000',
    mediumaquamarine     => '#66cdaa',
    mediumblue           => '#0000cd',
    mediumorchid         => '#ba55d3',
    mediumpurple         => '#9370db',
    mediumseagreen       => '#3cb371',
    mediumslateblue      => '#7b68ee',
    mediumspringgreen    => '#00fa9a',
    mediumturquoise      => '#48d1cc',
    mediumvioletred      => '#c71585',
    midnightblue         => '#191970',
    mintcream            => '#f5fffa',
    mistyrose            => '#ffe4e1',
    moccasin             => '#ffe4b5',
    navajowhite          => '#ffdead',
    navy                 => '#000080',
    oldlace              => '#fdf5e6',
    olive                => '#808000',
    olivedrab            => '#6b8e23',
    orange               => '#ffa500',
    orangered            => '#ff4500',
    orchid               => '#da70d6',
    palegoldenrod        => '#eee8aa',
    palegreen            => '#98fb98',
    paleturquoise        => '#afeeee',
    palevioletred        => '#db7093',
    papayawhip           => '#ffefd5',
    peachpuff            => '#ffdab9',
    peru                 => '#cd853f',
    pink                 => '#ffc0cb',
    plum                 => '#dda0dd',
    powderblue           => '#b0e0e6',
    purple               => '#800080',
    rebeccapurple        => '#663399',
    red                  => '#ff0000',
    rosybrown            => '#bc8f8f',
    royalblue            => '#4169e1',
    saddlebrown          => '#8b4513',
    salmon               => '#fa8072',
    sandybrown           => '#f4a460',
    seagreen             => '#2e8b57',
    seashell             => '#fff5ee',
    sienna               => '#a0522d',
    silver               => '#c0c0c0',
    skyblue              => '#87ceeb',
    slateblue            => '#6a5acd',
    slategray            => '#708090',
    slategrey            => '#708090',
    snow                 => '#fffafa',
    springgreen          => '#00ff7f',
    steelblue            => '#4682b4',
    tan                  => '#d2b48c',
    teal                 => '#008080',
    thistle              => '#d8bfd8',
    tomato               => '#ff6347',
    turquoise            => '#40e0d0',
    violet               => '#ee82ee',
    wheat                => '#f5deb3',
    white                => '#ffffff',
    whitesmoke           => '#f5f5f5',
    yellow               => '#ffff00',
    yellowgreen          => '#9acd32',
);

sub register {

    my ($self, $app, $config) = @_;

    # Config
    my $prefix = $config->{route} // $app->routes->any('/badge');
    $prefix->to(return_to => $config->{return_to} // '/');

    # Templates
    my $resources = path(__FILE__)->sibling('Badge', 'resources');
    push @{$app->renderer->paths}, $resources->child('templates')->to_string;

    # Routes
    if (!$config->{disable_api}) {
        $prefix->get('/#content' => \&_badge_api)->to('content' => undef)->name('badge');
    }

    # Helpers
    $app->helper('badge', sub { Mojo::ByteStream->new(_badge(@_)) });

}

sub _badge {

    my ($c, %options) = @_;

    my %badge_options = _build_options(%options);

    DEBUG and $c->log->debug('[Badge] User Config',  $c->app->dumper(\%options));
    DEBUG and $c->log->debug('[Badge] Badge Config', $c->app->dumper(\%badge_options));

    my $svg = $c->render_to_string('badge', format => 'svg', %badge_options);

    if ($badge_options{badge_format} eq 'png') {

        my $image = Image::Magick->new(magick => 'svg');
        $image->BlobToImage($svg);

        return $image->ImageToBlob(magick => 'png');

    }

    # Minify SVG
    $svg =~ s/^(\s+)//mg;
    $svg =~ s/\n//mg;

    return $svg;

}

sub _build_options {

    my (%options) = @_;

    my $embed_logo = $options{embed_logo};

    my $id_suffix = $options{id_suffix};

    my $logo         = $options{logo};
    my $color        = _decode_color($options{color} || 'informational');
    my $link         = $options{link};
    my $title        = $options{title};
    my $style        = $options{style}        || 'flat';
    my $badge_format = $options{badge_format} || 'svg';

    if ($style !~ /^(flat|flat-square|plastic|for-the-badge)$/) {
        Carp::croak 'Unknown badge style';
    }

    if ($badge_format !~ /^(png|svg)$/) {
        Carp::croak 'Unknown badge format';
    }

    my $label            = $options{label} || Carp::croak 'Missing label';
    my $label_color      = _decode_color($options{label_color} || 'gray');
    my $label_link       = $options{label_link};
    my $label_text_color = _decode_color($options{label_text_color} || 'white');
    my $label_title      = $options{label_title};

    my $message            = $options{message};
    my $message_link       = $options{message_link};
    my $message_text_color = _decode_color($options{message_text_color} || 'white');
    my $message_title      = $options{message_title};

    if (($label_link || $message_link) && $link) {
        Carp::croak '"link" may not bet set with "label_link" or "message_link"';
    }

    if ($style eq 'for-the-badge') {
        $label   = uc($label);
        $message = uc($message) if ($message);
    }

    my $label_text_width   = _get_text_width($label);
    my $message_text_width = 0;

    if ($message) {
        if ($style eq 'for-the-badge') {
            $message_text_width = _get_text_width($message, font => 'DejaVu-Sans-Bold');
        }
        else {
            $message_text_width = _get_text_width($message);
        }
    }

    # Embed image if is a file
    $options{embed_logo} = 1 if ($logo && -e $logo);

    # Embed image if badge format is "png"
    $options{embed_logo} = 1 if ($logo && $badge_format eq 'png');

    $logo = _embed_image($logo) if ($options{logo} && $options{embed_logo});

    # FIX label color
    $label_text_color = '#333' if ($label_color =~ /white/i || $label_color =~ /#FFFFFF/i);

    my $aria_label = $title;
    $aria_label = "$label_title: $message_title" if ($label_title && $message_title);
    $aria_label = "$label: $message"             if ($label       && $message);

    return (
        aria_label         => $aria_label,
        badge_format       => $badge_format,
        color              => $color,
        embed_logo         => $embed_logo,
        id_suffix          => $id_suffix,
        label              => $label,
        label_color        => $label_color,
        label_link         => $label_link,
        label_text_color   => $label_text_color,
        label_text_width   => $label_text_width,
        label_title        => $label_title,
        link               => $link,
        logo               => $logo,
        message            => $message,
        message_link       => $message_link,
        message_text_color => $message_text_color,
        message_text_width => $message_text_width,
        message_title      => $message_title,
        style              => $style,
        title              => $title,
    );

}

sub _decode_color {

    my $color = shift;

    return unless $color;

    return $SHIELDS_COLORS{$color}    if (defined $SHIELDS_COLORS{$color});
    return $NAMED_COLORS{$color}      if (defined $NAMED_COLORS{$color});
    return sprintf('#%s', lc($color)) if ($color =~ /^(?:[0-9a-fA-F]{3}){1,2}$/);

}

sub _badge_api {

    my $c = shift;

    # Shields.io compatibility
    my $badge_content = $c->param('content') || $c->param('badgeContent');
    my $link          = $c->param('link');
    my $label         = $c->param('label');
    my $label_color   = $c->param('labelColor');
    my $color         = $c->param('color');
    my $logo          = $c->param('logo');
    my $style         = $c->param('style') || 'flat';

    my $log     = $c->app->log->context('[Badge API]');
    my %options = ();

    DEBUG and $log->debug("Content: $badge_content");

    if ($badge_content) {

        $badge_content =~ s/\-{2}/\0/g;
        $badge_content =~ s/\_{2}/\t/g;
        $badge_content =~ s/_/ /g;
        $badge_content =~ s/\t/_/g;

        my ($_label, $_message, $_color) = split '-', $badge_content;

        $_label   =~ s/\0/-/g;
        $_message =~ s/\0/-/g;

        DEBUG and $log->debug("Label => $_label - Message => $_message - Color => $_color");

        if ($_color =~ /\.(png|svg)$/) {
            $options{badge_format} = $1;
            $_color =~ s/(\.(png|svg))$//;
        }

        $options{label}   = $_label;
        $options{message} = $_message;
        $options{color}   = $_color;

        $options{title} = "$_label: $_message";

        if (!$_color) {

            if ($options{message} =~ /\.(png|svg)$/) {
                $options{badge_format} = $1;
                $options{message} =~ s/(\.(png|svg))$//;
            }

            $options{label_color} = $options{message};
            $options{title}       = $options{label};

            delete $options{message};
            delete $options{color};

        }

    }


    $options{badge_format} //= 'svg';

    $options{link}        = $link        if ($link);
    $options{label}       = $label       if ($label);
    $options{label_color} = $label_color if ($label_color);
    $options{color}       = $color       if ($color);
    $options{style}       = $style       if ($style);

    my $status = 200;

    if (!$options{label}) {
        $options{label}   = 404;
        $options{message} = 'badge not found';
        $options{color}   = 'red';
        $status           = 404;
    }

    my $badge = _badge($c, %options);

    if ($options{badge_format} eq 'png') {
        return $c->render(data => $badge, format => 'png', status => $status);
    }

    return $c->render(text => $badge, format => 'svg', status => $status);

}

sub _embed_image {

    my $image = shift;
    my $ua    = Mojo::UserAgent->new;
    my $log   = Mojo::Log->new->context('[Badge]');

    my $content      = undef;
    my $content_type = undef;

    if ($image =~ /^http/) {

        my $url = (ref($image) ne 'Mojo::URL') ? Mojo::URL->new($image) : $image;

        $log->info("Embedding image from URL: $url");

        my $tx = $ua->get($url);

        if (my $err = $tx->error) {
            $log->error('Embed image error:', $err->{message});
            return;
        }

        my $res = $tx->result;

        $content_type = $res->headers->content_type;

        if ($content_type !~ /^image/) {
            $log->error(sprintf(q{URL doesn't contain an image (%s)}, $content_type));
            return;
        }

        $content = $res->body;

    }

    if (-e $image) {

        my $file  = (ref($image) ne 'Mojo::File') ? Mojo::File->new($image) : $image;
        my $types = Mojolicious::Types->new;

        $content_type = $types->file_type($file);

        if ($content_type !~ /^image/) {
            $log->error(sprintf('File is not an image (%s)', $content_type));
            return;
        }

        $content = $file->slurp;

    }

    return sprintf('data:%s;base64,%s', $content_type, b64_encode($content));

}

sub _get_text_width {

    my ($text, %properties) = @_;

    my $image = Image::Magick->new;

    $properties{pointsize} ||= 110;
    $properties{text}      ||= $text;
    $properties{gravity}   ||= 'northwest';
    $properties{font}      ||= 'DejaVu-Sans';

    $image->Set(size => '1x1');
    $image->ReadImage('xc:none');

    my ($x_ppem, $y_ppem, $ascender, $descender, $width, $height, $max_advance)
        = $image->QueryMultilineFontMetrics(%properties);

    return sprintf('%.0f', ($width / 10.0));

}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Badge - Badge Plugin for Mojolicious

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Badge');

  # Mojolicious::Lite
  plugin 'Badge';

  get '/my-cool-badge' => sub ($c) {

    my $badge = $c->app->badge(
      label        => 'Hello',
      message      => 'Mojo!',
      color        => 'orange'
      logo         => 'https://docs.mojolicious.org/mojo/logo.png'
      badge_format => 'png',
    );

    $c->render(data => $badge, format => 'png');

  };


=head1 DESCRIPTION

L<Mojolicious::Plugin::Badge> is a L<Mojolicious> plugin that generate "Shields.io"
like badge from L</badge> helper or via API URL (e.g. C</badge/Hello-Mojo!-orange>).

=begin html

<p>
  <img alt="Hello Mojo!" src="https://raw.github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/main/examples/hello-mojo.png?raw=true">
</p>

=end html


=head1 OPTIONS

L<Mojolicious::Plugin::Badge> supports the following options.

=head2 disable_api

  # Mojolicious::Lite
  plugin 'Badge' => {disable_api => 1};

Disable the L</API URL>.

=head2 route

  # Mojolicious::Lite
  plugin 'Badge' => {route => app->routes->any('/stuff')};

L<Mojolicious::Routes::Route> object to attach the badge API URL, defaults to
generating a new one with the prefix C</badge>.


=head1 METHODS

L<Mojolicious::Plugin::Badge> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 badge

  $plugin->badge( %options );

Build and render a badge in SVG (or PNG) format.

=head3 %options

=over

=item * C<badge_format>, Badge image format, C<svg> (default) or C<png>.

=item * C<color>, Message color (see L</COLORS>)

=item * C<embed_logo>, Includes logo in badge

=item * C<id_suffix>, The suffix of the id attributes used in the SVG's elements.
Use to prevent duplicate ids if several badges are embedded on the same page.

=item * C<label>, The text that should appear on the left-hand-side of the badge

=item * C<label_color>, Label color (see L</COLORS>)

=item * C<label_link>, The URL that should be redirected to when the right-hand
text is selected.

=item * C<label_text_color>, Label text color (see L</COLORS>)

=item * C<label_title>, The title attribute to associate with the left part of the
badge.

=item * C<link>, Link for the whole badge (works only for SVG badge)

=item * C<logo>, A file, URL or data (e.g. "data:image/svg+xml;utf8,<svg...")
representing a logo that will be displayed inside the badge.

=item * C<message> The text that should appear on the right-hand-side of the badge

=item * C<message_link>, The URL that should be redirected to when the right-hand
text is selected.

=item * C<message_text_color>, Message text color (see L</COLORS>)

=item * C<message_title>, The title attribute to associate with the right part of the
badge.

=item * C<style>, Badge style (see L</STYLES>)

=item * C<title>, The title attribute to associate with the entire badge.
See L<https://developer.mozilla.org/en-US/docs/Web/SVG/Element/title>.

=back

C<(label|message)_title>, C<(label|message)_link>, C<title> and C<link> options
works only for SVG badge.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 API URL

The default base URL is C</badge>. You can change the base URL via C<route> option (see L</OPTIONS>).

A badge require a single path parameter with C<label>, C<message> and C<color> separated by dash (C<->).

Example:

  /badge/label-message-color

=head2 Escape

=over

=item * Underscore C<_> or C<%20> are converted to space C< >

=item * Double underscore C<__> is converted to underscore C<_>

=item * Double dash C<--> is converted to dash C<->

=back

Examples:

  /badge/Hello-Mojo!-green

  /badge/Mojolicious--Plugin--Badge-1.0.0-green


=head2 Query parametrers

=over

=item * C<style>, If not specified, the default style for this badge is C<flat> (see L</STYLES>)

=item * C<label>, Override the default left-hand-side text

=item * C<labelColor>, Background color of the left part

=item * C<color>, Background color of the right part

=item * C<link>, Specify what clicking on the left/right of a badge should do.
Note that this only works when integrating your badge in an C<E<lt>objectE<gt>> HTML
tag, but not an C<E<lt>imgE<gt>> tag or a markup language.

=back

=head2 Image format

Badge API supports C<svg> (default) and C<png> image formats.

Examples:

  /badge/Hello-Mojo!-green
  /badge/Hello-Mojo!-green.svg

  /badge/Hello-Mojo!-green.png


=head1 COLORS

The L<badge> method support named and HEX colors:

  # Named color
  $plugin->badge( color => 'orange', label => 'Status', message => 'Warning' );

  # HEX color
  $plugin->badge( color => 'fe7d37', label => 'Status', message => 'Warning' );


Shields colors:

=over

=item * C<brightgreen>

=item * C<green>

=item * C<yellow>

=item * C<yellowgreen>

=item * C<orange>

=item * C<red>

=item * C<blue>

=item * C<grey>

=item * C<lightgrey>

=item * C<gray> (alias for C<grey>)

=item * C<lightgray> (alias for C<lightgrey>)

=item * C<critical> (alias for C<red>)

=item * C<important> (alias for C<orange>)

=item * C<success> (alias for C<brightgreen>)

=item * C<informational> (alias for C<blue>)

=item * C<inactive> (alias for C<lightgrey>)

=back

=begin html

<p>
  <img alt="blue" src="https://raw.github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/main/examples/color-blue.png?raw=true">
  <img alt="brightgreen" src="https://raw.github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/main/examples/color-brightgreen.png?raw=true">
  <img alt="green" src="https://raw.github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/main/examples/color-green.png?raw=true">
  <img alt="grey" src="https://raw.github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/main/examples/color-grey.png?raw=true">
  <img alt="lightgrey" src="https://raw.github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/main/examples/color-lightgrey.png?raw=true">
  <img alt="orange" src="https://raw.github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/main/examples/color-orange.png?raw=true">
  <img alt="red" src="https://raw.github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/main/examples/color-red.png?raw=true">
  <img alt="yellow" src="https://raw.github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/main/examples/color-yellow.png?raw=true">
  <img alt="yellowgreen" src="https://raw.github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/main/examples/color-yellowgreen.png?raw=true">
</p>

=end html


=head1 STYLES

Allowed styles:

=over

=item * C<flat> (default)

=item * C<flat-square>

=item * C<plastic>

=item * C<for-the-badge>

=back

=begin html

<p>
  <img alt="flat" src="https://raw.github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/main/examples/style-flat.png?raw=true">
  <img alt="flat-square" src="https://raw.github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/main/examples/style-flat-square.png?raw=true">
  <img alt="plastic" src="https://raw.github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/main/examples/style-plastic.png?raw=true">
  <img alt="for-the-badge" src="https://raw.github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/main/examples/style-for-the-badge.png?raw=true">
</p>

=end html


=head1 DEBUGGING

You can set the C<BADGE_PLUGIN_DEBUG> environment variable to get some advanced diagnostics information printed to
C<STDERR>.

  BADGE_PLUGIN_DEBUG=1


=head1 SEE ALSO

L<Mojolicious::Command::badge>, L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Mojolicious-Plugin-Badge>

    git clone https://github.com/giterlizzi/perl-Mojolicious-Plugin-Badge.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
