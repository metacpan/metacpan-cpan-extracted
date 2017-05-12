package Term::Detect::Software;

our $DATE = '2015-01-03'; # DATE
our $VERSION = '0.21'; # VERSION

use 5.010001;
use strict;
use warnings;
use experimental 'smartmatch';
#use Log::Any '$log';

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(detect_terminal detect_terminal_cached);

my $dt_cache;
sub detect_terminal_cached {
    if (!$dt_cache) {
        $dt_cache = detect_terminal(@_);
    }
    $dt_cache;
}

sub detect_terminal {
    my @dbg;
    my $info = {_debug_info=>\@dbg};

  DETECT:
    {
        unless (defined $ENV{TERM}) {
            push @dbg, "skip: TERM env undefined";
            $info->{emulator_engine}   = '';
            $info->{emulator_software} = '';
            last DETECT;
        }

        if ($ENV{KONSOLE_DBUS_SERVICE} || $ENV{KONSOLE_DBUS_SESSION}) {
            push @dbg, "detect: konsole via KONSOLE_DBUS_{SERVICE,SESSION} env";
            $info->{emulator_engine} = 'konsole';
            $info->{color_depth}     = 2**24;
            $info->{default_bgcolor} = '000000';
            $info->{unicode}         = 1;
            $info->{box_chars}       = 1;
            last DETECT;
        }

        if ($ENV{XTERM_VERSION}) {
            push @dbg, "detect: xterm via XTERM_VERSION env";
            $info->{emulator_engine} = 'xterm';
            $info->{color_depth}     = 256;
            $info->{default_bgcolor} = 'ffffff';
            $info->{unicode}         = 0;
            $info->{box_chars}       = 1;
            last DETECT;
        }

        # cygwin terminal
        if ($ENV{TERM} eq 'xterm' && ($ENV{OSTYPE} // '') eq 'cygwin') {
            push @dbg, "detect: xterm via TERM env (cygwin)";
            $info->{emulator_engine} = 'cygwin';
            $info->{color_depth}     = 16;
            $info->{default_bgcolor} = '000000';
            $info->{unicode}         = 0; # CONFIRM?
            $info->{box_chars}       = 1;
            last DETECT;
        }

        if ($ENV{TERM} eq 'linux') {
            push @dbg, "detect: linux via TERM env";
            # Linux virtual console
            $info->{emulator_engine} = 'linux';
            $info->{color_depth}     = 16;
            $info->{default_bgcolor} = '000000';
            # actually it can show a few Unicode characters like single borders
            $info->{unicode}         = 0;
            $info->{box_chars}       = 0;
            last DETECT;
        }

        my $gnome_terminal_terms = [qw/gnome-terminal guake xfce4-terminal
                                       mlterm lxterminal/];

        my $set_gnome_terminal_term = sub {
            $info->{emulator_software} = $_[0];
            $info->{emulator_engine}   = 'gnome-terminal';

            # xfce4-terminal only shows 16 color, despite being
            # gnome-terminal-based?
            $info->{color_depth}       = $_[0] =~ /xfce4/ ? 16 : 256;

            $info->{unicode}           = 1;
            if ($_[0] ~~ [qw/mlterm/]) {
                $info->{default_bgcolor} = 'ffffff';
            } else {
                $info->{default_bgcolor} = '000000';
            }
            $info->{box_chars} = 1;
        };

        if (($ENV{COLORTERM} // '') ~~ $gnome_terminal_terms) {
            push @dbg, "detect: gnome-terminal via COLORTERM";
            $set_gnome_terminal_term->($ENV{COLORTERM});
            last DETECT;
        }

        # Windows command prompt
        if ($ENV{TERM} eq 'dumb' && $ENV{windir}) {
            push @dbg, "detect: windows via TERM & windir env";
            $info->{emulator_software} = 'windows';
            $info->{emulator_engine}   = 'windows';
            $info->{color_depth}       = 16;
            $info->{unicode}           = 0;
            $info->{default_bgcolor}   = '000000';
            $info->{box_chars}         = 0;
            last DETECT;
        }

        # run under CGI or something like that
        if ($ENV{TERM} eq 'dumb') {
            push @dbg, "detect: dumb via TERM env";
            $info->{emulator_software} = 'dumb';
            $info->{emulator_engine}   = 'dumb';
            $info->{color_depth}       = 0;
            # XXX how to determine unicode support?
            $info->{default_bgcolor}   = '000000';
            $info->{box_chars}         = 0;
            last DETECT;
        }

        {
            last if $^O =~ /Win/;

            require Proc::Find::Parents;
            my $ppids = Proc::Find::Parents::get_parent_processes();
            unless (defined $ppids) {
                push @dbg, "skip: get_parent_processes returns undef";
                last;
            }

            # [0] is shell
            my $proc = @$ppids >= 1 ? $ppids->[1]{name} : '';
            #say "D:proc=$proc";
            if ($proc ~~ $gnome_terminal_terms) {
                push @dbg, "detect: gnome-terminal via procname ($proc)";
                $set_gnome_terminal_term->($proc);
                last DETECT;
            } elsif ($proc ~~ [qw/rxvt mrxvt/]) {
                push @dbg, "detect: rxvt via procname ($proc)";
                $info->{emulator_software} = $proc;
                $info->{emulator_engine}   = 'rxvt';
                $info->{color_depth}       = 16;
                $info->{unicode}           = 0;
                $info->{default_bgcolor}   = 'd6d2d0';
                $info->{box_chars}         = 1;
                last DETECT;
            } elsif ($proc ~~ [qw/pterm/]) {
                push @dbg, "detect: pterm via procname ($proc)";
                $info->{emulator_software} = $proc;
                $info->{emulator_engine}   = 'putty';
                $info->{color_depth}       = 256;
                $info->{unicode}           = 0;
                $info->{default_bgcolor}   = '000000';
                last DETECT;
            } elsif ($proc ~~ [qw/xvt/]) {
                push @dbg, "detect: xvt via procname ($proc)";
                $info->{emulator_software} = $proc;
                $info->{emulator_engine}   = 'xvt';
                $info->{color_depth}       = 0; # only support bold
                $info->{unicode}           = 0;
                $info->{default_bgcolor}   = 'd6d2d0';
                last DETECT;
            }
        }

        # generic
        {
            unless (exists $info->{color_depth}) {
                if ($ENV{TERM} =~ /256color/) {
                    push @dbg, "detect color_depth: 256 via TERM env";
                    $info->{color_depth} = 256;
                } else {
                    require File::Which;
                    if (File::Which::which("tput")) {
                        my $res = `tput colors` + 0;
                        push @dbg, "detect color_depth: $res via tput";
                        $info->{color_depth} = $res;
                    }
                }
            }

            $info->{emulator_software} //= '(generic)';
            $info->{emulator_engine} //= '(generic)';
            $info->{unicode} //= 0;
            $info->{color_depth} //= 0;
            $info->{box_chars} //= 0;
            $info->{default_bgcolor} //= '000000';
        }

    } # DETECT

    # some additional detections

    # we're running under emacs, it doesn't support box chars
    if ($ENV{INSIDE_EMACS}) {
        $info->{inside_emacs} = 1;
        $info->{box_chars} = 0;
    }

    $info;
}

1;
# ABSTRACT: Detect terminal (emulator) software and its capabilities

__END__

=pod

=encoding UTF-8

=head1 NAME

Term::Detect::Software - Detect terminal (emulator) software and its capabilities

=head1 VERSION

This document describes version 0.21 of Term::Detect::Software (from Perl distribution Term-Detect-Software), released on 2015-01-03.

=head1 SYNOPSIS

 use Term::Detect::Software qw(detect_terminal detect_terminal_cached);
 my $res = detect_terminal();
 die "Not running under terminal!" unless $res->{emulator_engine};
 say "Emulator engine: ", $res->{emulator_engine};
 say "Emulator software: ", $res->{emulator_software};
 say "Unicode support? ", $res->{unicode} ? "yes":"no";
 say "Boxchars support? ", $res->{box_chars} ? "yes":"no";
 say "Color depth: ", $res->{color_depth};
 say "Inside emacs? ", $res->{inside_emacs} ? "yes":"no";

=head1 DESCRIPTION

This module uses several heuristics to find out what terminal (emulator)
software the current process is running in, and its capabilities/settings. This
module complements other modules such as L<Term::Terminfo> and
L<Term::Encoding>.

=head1 FUNCTIONS

=head2 detect_terminal() => HASHREF

Return a hashref containing information about running terminal (emulator)
software and its capabilities/settings.

Detection method is tried from the easiest/cheapest (e.g. checking environment
variables) or by looking at known process names in the process tree. Terminal
capabilities is determined using heuristics.

Currently Konsole and Konsole-based terminals (like Yakuake) can be detected
through existence of environment variables C<KONSOLE_DBUS_SERVICE> or
C<KONSOLE_DBUS_SESSION>. xterm is detected through C<XTERM_VERSION>. XFCE's
Terminal is detected using C<COLORTERM>. The other software are detected via
known process names.

Terminal capabilities and settings are currently determined via heuristics.
Probing terminal configuration files might be performed in the future.

Result:

=over

=item * emulator_engine => STR

Possible values: C<konsole>, C<xterm>, C<gnome-terminal>, C<rxvt>, C<pterm>
(PuTTY), C<xvt>, C<windows> (CMD.EXE), C<cygwin>, or empty string (if not
detected running under terminal).

=item * emulator_software => STR

Either: C<xfce4-terminal>, C<guake>, C<gnome-terminal>, C<mlterm>,
C<lxterminal>, C<rxvt>, C<mrxvt>, C<putty>, C<xvt>, C<windows> (CMD.EXE), or
empty string (if not detected running under terminal).

w=item * color_depth => INT

Either 0 (does not support ANSI color codes), 16, 256, or 16777216 (2**24).

=item * default_bgcolor => STR (6-hexdigit RGB)

For example, any xterm is assumed to have white background (ffffff) by default,
while Konsole is assumed to have black (000000). Better heuristics will be done
in the future.

=item * unicode => BOOL

Whether terminal software supports Unicode/wide characters. Note that you should
also check encoding, e.g. using L<Term::Encoding>.

=item * box_chars => BOOL

Whether terminal supports box-drawing characters.

=back

=head2 detect_terminal_cached([$flag]) => ANY

Just like C<detect_terminal()> but will cache the result. Can be used by
applications or modules to avoid repeating detection process.

=head1 FAQ

=head2 What is this module for? Why not Term::Terminfo or Term::Encoding?

This module is first written for L<Text::ANSITable> so that the module can
provide good defaults when displaying formatted and colored tables, especially
on popular terminal emulation software like Konsole (KDE's default terminal),
gnome-terminal (GNOME's default), Terminal (XFCE's default), xterm, rxvt.

The module works by trying to figure out the terminal emulation software because
the information provided by L<Term::Terminfo> and L<Term::Encoding> are
sometimes not specific enough. For example, Term::Encoding can return L<utf-8>
when running under rxvt, but since the software currently lacks Unicode support
we shouldn't display Unicode characters. Another example is color depth:
Term::Terminfo currently doesn't recognize Konsole's 24bit color support and
only gives C<max_colors> 256.

=head1 SEE ALSO

L<Term::Terminfo>

L<Term::Encoding>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Term-Detect-Software>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Term-Detect-Software>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Term-Detect-Software>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
