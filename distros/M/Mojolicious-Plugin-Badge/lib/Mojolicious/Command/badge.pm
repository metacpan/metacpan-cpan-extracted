package Mojolicious::Command::badge;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util qw(getopt);

has description => 'Create a badge';
has usage       => sub { shift->extract_usage };

sub run {
    my ($self, @args) = @_;

    getopt \@args,
        'color=s'              => \my $color,
        'embed-logo'           => \my $embed_logo,
        'file=s'               => \my $file,
        'format=s'             => \my $badge_format,
        'label-color=s'        => \my $label_color,
        'label-link=s'         => \my $label_link,
        'label-text-color=s'   => \my $label_text_color,
        'label-title=s'        => \my $label_title,
        'label=s'              => \my $label,
        'link=s'               => \my $link,
        'logo=s'               => \my $logo,
        'message-link=s'       => \my $message_link,
        'message-text-color=s' => \my $message_text_color,
        'message-title=s'      => \my $message_title,
        'message=s'            => \my $message,
        'style=s'              => \my $style,
        'title=s'              => \my $title;

    if (!$label) {
        say $self->usage;
        exit 1;
    }

    my %options = ();

    $options{label}   = $label;
    $options{message} = $message;
    $options{color}   = $color;

    $options{badge_format} = $badge_format if ($badge_format);
    $options{style}        = $style        if ($style);
    $options{link}         = $link         if ($link);
    $options{title}        = $title        if ($title);
    $options{logo}         = $logo         if ($logo);
    $options{embed_logo}   = 1             if ($embed_logo);

    $options{label_color}      = $label_color      if ($label_color);
    $options{label_link}       = $label_link       if ($label_link);
    $options{label_text_color} = $label_text_color if ($label_text_color);
    $options{label_title}      = $label_title      if ($label_title);

    $options{message_link}       = $message_link       if ($message_link);
    $options{message_text_color} = $message_text_color if ($message_text_color);
    $options{message_title}      = $message_title      if ($message_title);

    my $badge = eval { $self->app->badge(%options) };

    if ($@) {
        say "[ERROR] $@";
        exit 255;
    }

    unless ($file) {
        say $badge;
        return 0;
    }

    Mojo::File->new($file)->spurt($badge);
    return 0;

}

1;

=encoding utf8

=head1 NAME

Mojolicious::Command::badge - Badge command

=head1 SYNOPSIS

  Usage: APPLICATION badge [OPTIONS]

    ./myapp.pl badge --label "Hello" --message "Mojo!" --color "orange" \
        --format png --file my-cool-badge.png

  Options:
    --label <string>                The text that should appear on the left-hand-side
                                    of the badge
    --message <string>              The text that should appear on the right-hand-side
                                    of the badge
    --color <string>                Message color
    --style <string>                Badge style ("flat" [default], "flat-square",
                                    "plastic" or "for-the-badge")
    --format <string>               Badge format ("svg" [default] or "png")
    --title <string>                The title attribute to associate with the
                                    entire badge
    --label-color <string>          Label color
    --label-title <string>          The title attribute to associate with the left
                                    part of the badge
    --label-link <string>           The URL that should be redirected to when the
                                    left-hand text is selected
    --label-text-color <string>     Label text color
    --message-title <string>        The title attribute to associate with the right
                                    part of the badge
    --message-link <string>         The URL that should be redirected to when the
                                    right-hand text is selected
    --message-text-color <string>   Message text color
    --link <string>                 Link for the whole badge (works only for SVG badge)
    --logo <string>                 A file, URL or data (e.g. "data:image/svg+xml;utf8,<svg...")
                                    representing a logo that will be displayed
                                    inside the badge.
    --embed-logo                    Includes logo in badge
    --file <path>                   Write the badge in file

=head1 DESCRIPTION

L<Mojolicious::Command::badge> is a utility for create badges.

=head1 ATTRIBUTES

L<Mojolicious::Command::badge> inherits all attributes from L<Mojolicious::Command>
and implements the following new ones.

=head2 description

  my $description = $job->description;
  $job            = $job->description('Foo');

Short description of this command, used for the command list.

=head2 usage

  my $usage = $job->usage;
  $job      = $job->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Mojolicious::Command::badge> inherits all methods from L<Mojolicious::Command>
and implements the following new ones.

=head2 run

  $job->run(@ARGV);

Run this command.

=head1 SEE ALSO

L<Mojolicious::Plugin::Badge>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut
