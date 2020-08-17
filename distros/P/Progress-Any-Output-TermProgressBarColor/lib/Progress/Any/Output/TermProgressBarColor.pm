package Progress::Any::Output::TermProgressBarColor;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-15'; # DATE
our $DIST = 'Progress-Any-Output-TermProgressBarColor'; # DIST
our $VERSION = '0.249'; # VERSION

use 5.010001;
use strict;
use warnings;

use Color::ANSI::Util qw(ansifg ansibg);
require Win32::Console::ANSI if $^O =~ /Win/;

$|++;

sub _patch {
    my $out = shift;

    return if $out->{patch_handle1};

    require Monkey::Patch::Action;
    if (defined &{"Log::Any::Adapter::Screen::hook_before_log"}) {
        $out->{patch_handle1} = Monkey::Patch::Action::patch_package(
            'Log::Any::Adapter::Screen', 'hook_before_log', 'replace',
            sub {
                # we install a hook to clean up progress indicator first before
                # we print log message to the screen.
                $out->cleanup(1);
                $Progress::Any::output_data{"$out"}{force_update} = 1;
            }
        );
    } elsif (defined  &{"Log::ger::Output::Screen::hook_before_log"}) {
        $out->{patch_handle1} = Monkey::Patch::Action::patch_package(
            'Log::ger::Output::Screen', 'hook_before_log', 'replace',
            sub {
                # we install a hook to clean up progress indicator first before
                # we print log message to the screen.
                $out->cleanup(1);
                $Progress::Any::output_data{"$out"}{force_update} = 1;
            }
        );
    }

    if (defined &{"Log::Any::Adapter::Screen::hook_after_log"}) {
        $out->{patch_handle2} = Monkey::Patch::Action::patch_package(
            'Log::Any::Adapter::Screen', 'hook_after_log', 'replace',
            sub {
                my ($self, $msg) = @_;

                # make sure we print a newline after logging so progress bar
                # starts at column 1
                print { $self->{_fh} } "\n" unless $msg =~ /\R\z/;

                # reset show_delay because we have displayed something
                $out->keep_delay_showing if $out->{show_delay};

                # redisplay progress bar if were cleaned up
                print { $self->{_fh} } $out->{_bar} if $out->{_bar};
            }
        );
    } elsif (defined &{"Log::ger::Output::Screen::hook_after_log"}) {
        $out->{patch_handle2} = Monkey::Patch::Action::patch_package(
            'Log::ger::Output::Screen', 'hook_after_log', 'replace',
            sub {
                my ($ctx, $msg) = @_;
                # make sure we print a newline after logging so progress bar
                # starts at column 1
                print { $ctx->{_fh} } "\n" unless $msg =~ /\R\z/;

                # reset show_delay because we have displayed something
                $out->keep_delay_showing if $out->{show_delay};

                # redisplay progress bar if were cleaned up
                print { $ctx->{_fh} } $out->{_bar} if $out->{_bar};
            }
        );
    }
}

sub _unpatch {
    my $self = shift;
    undef $self->{patch_handle1};
    undef $self->{patch_handle2};
}

sub _template_length {
    require Progress::Any; # for $template_regex
    no warnings 'once'; # $Progress::Any::template_regex

    my ($self, $template) = @_;

    my $template_length = length($template);

    while ($template =~ /$Progress::Any::template_regex/g) {
        my ($all, $width, $dot, $prec, $conv) =
            ($1, $2, $3, $4, $5);

        if (defined $template_length) {

            if ($conv eq '%') {
                $width //= 1;
            } elsif ($conv eq 'b' || $conv eq 'B') {
                $width //= $self->{_default_b_width};
            } elsif ($conv eq 'p') {
                $width //= 3;
            } elsif ($conv eq 'e') {
                $width //= -8;
            } elsif ($conv eq 'r') {
                $width //= -8;
            } elsif ($conv eq 'R') {
                $width //= -(8 + 1 + 7);
            }

            if (defined $width) {
                $template_length += abs($width) - length($all);
            } else {
                $template_length = undef;
            }

        }
    }

    $template_length;
}

sub new {
    my ($class, %args0) = @_;

    my %args;

    $args{width} = delete($args0{width});
    if (!defined($args{width})) {
        my ($cols, $rows);
        if ($ENV{COLUMNS}) {
            $cols = $ENV{COLUMNS};
        } elsif (eval { require Term::Size; 1 }) {
            ($cols, $rows) = Term::Size::chars(*STDOUT{IO});
        }
        $cols //= 80;
        # on windows if we print at rightmost column, cursor will move to the
        # next line, so we try to avoid that
        $args{width} = $^O =~ /Win/ ? $cols-1 : $cols;
    }

    $args{fh} = delete($args0{fh});
    $args{fh} //= \*STDERR;

    $args{show_delay} = delete($args0{show_delay});

    $args{freq} = delete($args0{freq});

    $args{wide} = delete($args0{wide});

    $args{rownum} = delete($args0{rownum});
    $args{rownum} //= 0;

    $args{template} = delete($args0{template}) //
        '<color ffff00>%p%%</color> <color 808000>[</color>%B<color 808000>]</color><color ffff00>%R</color>';

    keys(%args0) and die "Unknown output parameter(s): ".
        join(", ", keys(%args0));

    $args{_last_hide_time} = time();

    require Text::ANSI::Util;
    if ($args{wide}) {
        require Text::ANSI::WideUtil;
    }

    my $self = bless \%args, $class;

    # determine the default width for %b and %B
    {
        $self->{_default_b_width} = 0;
        (my $template = $args{template}) =~ s!<color \w+>|</color>!!g;
        my $len = $self->_template_length($template) // 16;
        $self->{_default_b_width} = $args{width} - $len;
    }

    # render color in template
    ($self->{_template} = $self->{template}) =~ s!<color (\w+)>|<(/)color>!$1 ? ansifg($1) : "\e[0m"!eg;

    $self;
}

sub _handle_unknown_conversion {
    my %args = @_;

    my $conv = $args{conv};
    return () unless $conv eq 'b' || $conv eq 'B';

    my $p = $args{indicator};
    my $self = $args{self};

    my $tottgt = $p->total_target;
    my $totpos = $p->total_pos;

    my $bar_bar = '';
    my $bwidth = abs($args{width} // $self->{_default_b_width});

    if ($tottgt) {
        my $bfilled = int($totpos / $tottgt * $bwidth);
        $bfilled = $bwidth if $bfilled > $bwidth;
        $bar_bar = ("=" x $bfilled) . (" " x ($bwidth-$bfilled));
    } else {
        # display 15% width of bar just moving right
        my $bfilled = int(0.15 * $bwidth);
        $bfilled = 1 if $bfilled < 1;
        $self->{_x}++;
        if ($self->{_x} > $bwidth-$bfilled) {
            $self->{_x} = 0;
        }
        $bar_bar = (" " x $self->{_x}) . ("=" x $bfilled) .
            (" " x ($bwidth-$self->{_x}-$bfilled));
    }

    my $msg = $args{args}{'message.alt.output.TermProgressBarColor'} //
        $args{args}{message};
    if ($conv eq 'B' && defined $msg) {
        if ($msg =~ m!</elspan!) {
            require String::Elide::Parts;
            $msg = String::Elide::Parts::elide($msg, $bwidth);
        }
        my $mwidth;
        if ($self->{wide}) {
            $msg = Text::ANSI::WideUtil::ta_mbtrunc($msg, $bwidth);
            $mwidth = Text::ANSI::WideUtil::ta_mbswidth($msg);
        } else {
            $msg = Text::ANSI::Util::ta_trunc($msg, $bwidth);
            $mwidth = Text::ANSI::Util::ta_length($msg);
        }
        $bar_bar = $msg . substr($bar_bar, $mwidth);
    }

    return ("%s", $bar_bar);
}

sub update {
    my ($self, %args) = @_;

    return unless $ENV{PROGRESS_TERM_BAR} // $ENV{PROGRESS} // (-t $self->{fh});

    my $now = time();

    # if there is show_delay, don't display until we've surpassed it
    if (defined $self->{show_delay}) {
        return if $now - $self->{show_delay} < $self->{_last_hide_time};
    }

    $self->_patch;

    $self->cleanup;

    my $p = $args{indicator};
    my $is_finished = $p->{state} eq 'finished';
    if ($is_finished) {
        if ($self->{_lastlen}) {
            $self->{_last_hide_time} = $now;
        }
        return;
    }

    my $bar = $p->fill_template(
        {
            template => $self->{_template},
            handle_unknown_conversion => sub {
                _handle_unknown_conversion(
                    self => $self,
                    @_,
                );
            },
        },
        %args,
    );

    my $len = Text::ANSI::Util::ta_length($bar);
    $self->{_bar} = join(
        "",
        "\n" x $self->{rownum},
        $bar,
        ("\b" x $len),
        $self->{rownum} > 0 ? "\e[$self->{rownum}A" : "", # up N lines
    );
    print { $self->{fh} } $self->{_bar};
    $self->{_lastlen} = $len;
}

sub cleanup {
    my ($self, $dont_reset_lastlen) = @_;

    # sometimes (e.g. when a subtask's target is undefined) we don't get
    # state=finished at the end. but we need to cleanup anyway at the end of
    # app, so this method is provided and will be called by e.g.
    # Perinci::CmdLine

    my $ll = $self->{_lastlen};
    return unless $ll;
    my $clean_str = join(
        "",
        "\n" x $self->{rownum},
        " " x $ll,
        "\b" x $ll,
        $self->{rownum} > 0 ? "\e[$self->{rownum}A" : "", # up N lines
    );
    print { $self->{fh} } $clean_str;
    undef $self->{_lastlen} unless $dont_reset_lastlen;
}

sub keep_delay_showing {
    my $self = shift;

    $self->{_last_hide_time} = time();
}

sub DESTROY {
    my $self = shift;
    $self->_unpatch;
}

1;
# ABSTRACT: Output progress to terminal as color bar

__END__

=pod

=encoding UTF-8

=head1 NAME

Progress::Any::Output::TermProgressBarColor - Output progress to terminal as color bar

=head1 VERSION

This document describes version 0.249 of Progress::Any::Output::TermProgressBarColor (from Perl distribution Progress-Any-Output-TermProgressBarColor), released on 2020-08-15.

=head1 SYNOPSIS

 use Progress::Any::Output;

 # use default options
 Progress::Any::Output->set('TermProgressBarColor');

 # set options
 Progress::Any::Output->set('TermProgressBarColor',
                            width=>50, fh=>\*STDERR, show_delay=>5);

=head1 DESCRIPTION

B<THIS IS AN EARLY RELEASE, SOME THINGS ARE NOT YET IMPLEMENTED E.G. STYLES,
COLOR THEMES>.

Sample screenshots:

=for Pod::Coverage ^(update|cleanup)$

=for HTML <img src="http://blogs.perl.org/users/perlancar/progany-tpc-sample.jpg" />

This output displays progress indicators as colored progress bar on terminal. It
produces output similar to that produced by L<Term::ProgressBar>, except that it
uses the L<Progress::Any> framework and has additional features:

=over

=item * colors and color themes

=item * template and styles

=item * displaying message text in addition to bar/percentage number

=item * wide character support

=back

XXX option to cleanup when complete or not (like in Term::ProgressBar) and
should default to 1.

=head1 METHODS

=head2 new(%args) => OBJ

Instantiate. Usually called through C<<
Progress::Any::Output->set("TermProgressBarColor", %args) >>.

Known arguments:

=over

=item * freq => num

Limit the frequency of output updating. 0 means no frequency limiting (update
output after every C<update()>).

A positive number means to update output when there has been that amount of
difference in position since last C<update()>. For example, if C<freq> is 10 and
the last C<update()> was at position 5, then the next output update will be when
position is at least 15.

A negative number means to update output when time has passed that amount of
absolute value (in seconds). For example, if C<freq> is -3 and the last
C<update()> was 1 second ago, then the next output update will not be until the
next two seconds has passed.

By default undef, in which case Progress::Any will use the default -0.5 (at most
once every 0.5 seconds).

=item * wide => bool

If set to 1, enable wide character support (requires L<Text::ANSI::WideUtil>.

=item * width => INT

Width of progress bar. The default is to detect terminal width and use the whole
width.

=item * color_theme => STR

Not yet implemented.

Choose color theme. To see what color themes are available, use
C<list_color_themes()>.

=item * style => STR

Not yet implemented.

Choose style. To see what styles are available, use C<list_styles()>. Styles
determine the characters used for drawing the bar, alignment, etc.

=item * template => str

See B<fill_template> in Progress::Any's documentation. Aside from conversions
supported by Progress::Any, this output recognizes these additional conversions:
C<%b> to display the progress bar (with width using the rest of the available
width), C<%B> to display the progress bar as well as the message inside it. You
can also enclose parts of text with "<color RGB>" ... "</color>" to give color.

The default template is:

 <color ffff00>%p</color> <color 808000>[</color>%B<color 808000>]</color><color ffff00>%e</color>

=item * fh => handle (default: \*STDERR)

Instead of the default STDERR, you can direct the output to another filehandle
e.g. STDOUT.

=item * show_delay => int

If set, will delay showing the progress bar until the specified number of
seconds. This can be used to create, e.g. a CLI application that is relatively
not chatty but will display progress after several seconds of seeming inactivity
to indicate users that the process is still going on.

=item * rownum => uint

Default 0. Can be set to put the progress bar at certain rownum. This can be
used to display several progress bars together.

=back

=head2 keep_delay_showing()

Can be called to reset the timer that counts down to show progress bar when
C<show_delay> is defined. For example, if C<show_delay> is 5 seconds and two
seconds have passed, it should've been 3 seconds before progress bar is shown in
the next C<update()>. However, if you call this method, it will be 5 seconds
again before showing.

=head1 FAQ

=head2 How to update progress bar output more often?

Set C<freq> to e.g. -0.1 or -0.05. The default C<freq>, when unset, is -0.5
which means to update output at most once every 0.5 second.

=head2 How to display a different message for this output?

For example, this output formats message using L<String::Elide::Parts> so inside
the message, substrings can be tagged for eliding priority:

 <elspan prio=2>Downloading </elspan><elspan prio=3 truncate=middle>http://127.0.0.1:7007/2.mp4 </elspan>37.3M/139.5M

while another output like L<Progress::Any::Output::TermMessage> does not use
String::Elide::Parts. It should just display the string as:

 Downloading http://127.0.0.1:7007/2.mp4 37.3M/139.5M

In the indicator, you can provide a specific message for this output:

 $progress->update(
     message => 'Downloading http://127.0.0.1:7007/2.mp4 37.3M/139.5M',
     'message.alt.output.TermProgressBarColor' => '<elspan prio=2>Downloading </elspan><elspan prio=3 truncate=middle>http://127.0.0.1:7007/2.mp4 </elspan>37.3M/139.5M',
     ...
 );

=head1 ENVIRONMENT

=head2 NO_COLOR

Bool. Can be used to disable color. Consulted before L<NO_COLOR>. See
L<Color::ANSI::Util>.

=head2 COLOR

Bool. Can be used to force or disable color. See L<Color::ANSI::Util>.

=head2 COLOR_DEPTH

Integer. Can be used to override color depth detection. See
L<Color::ANSI::Util>.

=head2 COLUMNS

Integer. Can be used to override terminal width detection.

=head2 PROGRESS_TERM_BAR

Bool. Forces disabling or enabling progress output (just for this output).

In the absence of PROGRESS_TERM_MESSAGE and PROGRESS, will default to 1 if
filehandle is detected as interactive (using C<-t>).

=head2 PROGRESS

Bool. Forces disabling or enabling progress output (for all outputs).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Progress-Any-Output-TermProgressBarColor>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Progress-Any-Output-TermProgressBarColor>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Progress-Any-Output-TermProgressBarColor>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Progress::Any>

L<Term::ProgressBar>

Ruby library: ruby-progressbar, L<https://github.com/jfelchner/ruby-progressbar>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018, 2017, 2016, 2015, 2014, 2013 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
