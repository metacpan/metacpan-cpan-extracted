
package Term::ANSIColorx::ColorNicknames;

use Term::ANSIColor qw(colorstrip uncolor);
use common::sense;
use base 'Exporter';

our $VERSION = '2.7191';

our @FIXED       = qw(color colorvalid colored);
our @EXPORT_OK   = qw(fix_color color colorvalid colored colorstrip uncolor);
our %EXPORT_TAGS = ( all => \@EXPORT_OK, fixed=>\@FIXED );

our %NICKNAMES = (
    normal    => "clear",
    unbold    => "clear",

    blood     => "red",
    umber     => "bold red",
    sky       => "bold blue",
    ocean     => "cyan",
    lightblue => "cyan",
    cyan      => "bold cyan",
    lime      => "bold green",
    orange    => "yellow",
    brown     => "yellow",
    yellow    => "bold yellow",
    purple    => "magenta",
    violet    => "bold magenta",
    pink      => "bold magenta",
    pitch     => "bold black",
    coal      => "bold black",
    grey      => "white",
    gray      => "white",
    white     => "bold white",

    dire      => "bold yellow on_red",
    alert     => "bold yellow on_red",
    todo      => "black on_yellow",

    nc_dir  => "bold white on_blue",
    nc_file => "bold white on_blue",
    nc_exe  => "bold green on_blue",
    nc_exec => "bold green on_blue",
    nc_curs => "black on_cyan",
    nc_pwd  => "black on_white",
    nc_cwd  => "black on_white",

    mc_dir  => "bold white on_blue",
    mc_file => "bold white on_blue",
    mc_exe  => "bold green on_blue",
    mc_exec => "bold green on_blue",
    mc_curs => "black on_cyan",
    mc_pwd  => "black on_white",
    mc_cwd  => "black on_white",
);

sub fix_color(_) {
    my $color = shift;
    my $no_nick = $color =~ s/\a//g;

    $color =~ s/[^\w]/ /g;
    $color =~ s/on (\w+)/on_$1/g;
    $color =~ s/un bold/unbold/g;
    $color =~ s/([mn]c) (dir|file|exec?|curs|[pc]wd)/$1_$2/g;

    my @cl = map {
        (!$no_nick && exists $NICKNAMES{$_})
        ? split(" ", $NICKNAMES{$_}) : $_
    } split(" ", $color);

    FIXCL: {
        my %m = (faint=>1, dark=>1, bold=>1, bright=>1, clear=>1);
        for my $i (0 .. $#cl) {
            if( $m{$cl[$i]} ) {
                my $l = 1;

                $l ++ while $m{$cl[ $i+$l ]};

                if( $l > 1 ) {
                    splice @cl, $i, $l, $cl[$i];
                    redo FIXCL;
                }
            }
        }
    }

    $color = join " ", @cl>1 ? grep {$_ ne "clear"} @cl : @cl;

    return $color;
}

sub color(_) {
    @_ = (fix_color $_[0]);
    goto &Term::ANSIColor::color;
}

sub colorvalid(_) {
    @_ = (fix_color $_[0]);
    goto &Term::ANSIColor::colorvalid;
}

sub colored {
    my ($string, @codes);

    if (ref $_[0]) {
        @codes = @{+shift};
        $string = join ('', @_);

    } else {
        $string = shift;
        @codes = @_;
    }

    @_ = ($string, map {fix_color} @codes);
    goto &Term::ANSIColor::colored;
}

"true";

__END__

=encoding UTF-8

=head1 NAME

Term::ANSIColorx::ColorNicknames - nicknames for the ANSI colors

=head1 SYNOPSIS

    # use Term::ANSIColor qw(color colorvalid);
    use Term::ANSIColorx::ColorNicknames qw(color colorvalid);

=head1 DESCRIPTION

I have a hard time remembering the ANSI colors in terms of bolds and regulars,
and also find them irritating to type. If I want the color yellow, why should I
have to type C<"bright_yellow"> to get it?  C<yellow> is really orange
colored, yellow should always be bold.

=head1 HOW THIS WORKS

In the past, this module used to replace the exports of the Term::ANSIColor
package. I was under the impression I am the only user of this package, so I
felt comfortable breaking backwards compatability with versions prior to
C<2.7187>. Lemme know if I jacked up your codes, but please adapt to the new
setup. The old stuff was pretty janky. Kinda cool scope hacking, but janky.

This module exports the following functions, which “override” the functions
from L<Term::ANSIColor>. They use the word “fix” instead of translate because
it’s short, not because it’s a political statement about the ANSI definitions
or L<Term::ANSIColor>.

=over

=item C<fix_color>

Re-writes the (correct) ANSI color to the new nickname color. Additionally, it
re-writes various easy to type natural language (or css feeling) punctuations.

    "bold blue" eq fix_color("sky")

    "bold white on_blue" eq fix_color("bold-white on blue")

Note that C<white> is really C<"bold white"> under this package.
C<fix_color> automatically fixes C<"bold bold white"> should it come up by
accident.  Actually, it tries to do something predictable when you use
bold/faint/dark/bright in any combination.  It just uses the first one.

    "bold blue" eq fix_color("bold dark bold faint dark bold blue");
    "dark blue" eq fix_color("dark bold bold faint dark bold blue");

C<clear> (aka C<normal> aka C<unbold>) is an exception to this rule.  If
C<clear> (aka C<normal> etc) is the only “color” in the color, then it stands,
otherwise, it is removed — presuming that a reset is usually used after some
color sequence anyway..

    "bold black" eq fix_color("coal");
    "black"      eq fix_color("normal coal");
    "clear"      eq fix_color("normal");

Which means, you get the following.  Notice that we get C<\e[30m>, not
C<\e[0;30m> like you might expect.

    say "result: "
    Data::Dump::dump([
        map { colored( " $_ ", $_ ) }

        "coal",
        "normal coal",
        "normal"

    ]);

    result: [
      "\e[1;30m coal \e[0m",
      "\e[30m normal coal \e[0m",
      "\e[0m clear \e[0m",
    ]

Additionally, C<fix_color> uses the prototype C<_>, so one can do this:

    @xlated = map{fix_color} qw(sky ocean blood umber);

which gives:

    ("bold blue", "cyan", "red", "bold red")

and of course, this:

    "bold blue" eq fix_color "sky";

Lastly, there's a secret code to disable the re-writing. If you decide you
hate one of the nicknames, or just want to disable it for a single color,
intoduce a bell character anywhere in the string.

    "bold black" eq fix_color "coal";
    "black" eq fix_color "\ablack";

(This makes more sense if you export L</C<color>> below.

=item C<color>

This is just an export of L<Term::ANSIColor/color>. It runs
L</C<fix_color()>> on the given string and then invokes C<Term::ANSIColor::color()>.
Additionally, C<color()> is defined with the C<_> prototype, which means it can be invoked this way:

    say color "violet", "test test test test", color "reset"

Or like this:

    while(<$colorstream>) {
        chomp;
        print color if colorvalid;
        say "TEST: o rly? (color=$_)";
    }

    print color("reset");

=item C<colorvalid>

Like above, this is just a C<_> prototyped and C<fix_color()> translated export of L<Term::ANSIColor/colorvalid>.

=item C<colored>

Translated (but not C<_> prototyped) export of L<Term::ANSIColor/colored>.

=item C<colorstrip>

Boring re-import of L<Term::ANSIColor/colorstrip>. This is not translated or prototyped.

=item C<uncolor>

Boring re-import of L<Term::ANSIColor/uncolor>. This is not translated or prototyped.

=back

=head1 THE NICKNAMES

=over

=item C<blood>

Alias for the color red.

=item C<umber>

Alias for bold red.

=item C<sky>

Alias for bold blue.

=item C<ocean>

Replaces the color cyan, which should be very bright.

=item C<lightblue>

Alias for ocean.

=item C<cyan>

Cyan is the bold of the ocean. It's a bright cyan color.

=item C<lime>

Bolded green. It's really a lime color.

=item C<orange> C<brown>

Orange. Most correctly, what ANSI calls "yellow", but is really more of a
brown-orange.

=item C<yellow>

Yellow. Technically bolded yellow.

=item C<purple>

Alias for magenta. I can never remember which is right, probably thanks to CSS.

=item C<violet>

Bolded purple.

=item C<pink>

Bolded purple.

=item C<pitch> C<coal>

Bolded black.

=item C<grey> C<gray>

Unbolded white.

=item C<white>

Bolded white.

=item C<dire>

Scary yellow on red warning color.

=item C<alert>

Scary white on red color.

=item C<todo>

Iconic black on orange todo coloring.

=item C<mc_dir> C<nc_dir>

The white on blue directory coloring from Midnight Commander.

=item C<mc_file> C<nc_file>

The grey on blue file coloring.

=item C<mc_exe> C<nc_exe> C<mc_exec> C<nc_exec>

The lime on blue executable coloring.

=item C<mc_curs> C<nc_curs>

The cursor bar black on cyan coloring.

=item C<mc_pwd> C<nc_pwd> C<mc_cwd> C<nc_cwd>

The black on white coloring of the current directory on the current panel.

=item C<normal> C<unbold> C<un-bold>

I can never remember that C<clear> is C<un-bold> or C<normal>.  C<dark> and
C<bright> work ratehr like C<bold> and C<clear>, except that they don't work
from real text consoles (they're really half-bold and extra-bold).

=back

=head1 FAQ

    Q: This is dumb.
    A: Yeah. OK, you have a point. Sorry?

=head1 REPORTING BUGS

You can report bugs either via rt.cpan.org or via the issue tracking system on
github. I'm likely to notice either fairly quickly.

=head1 AUTHOR

Paul Miller C<< <jettero@cpan.org> >>

=head1 COPYRIGHT

Copyright 2014 Paul Miller -- released under the GPL

=head1 SEE ALSO

perl(1), L<Term::ANSIColor>
