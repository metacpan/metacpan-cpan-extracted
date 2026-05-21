package Modern::Open;
######################################################################
#
# Modern::Open - Autovivification, Autodie, and 3-args open support
#
# https://metacpan.org/dist/Modern-Open
#
# Copyright (c) 2014, 2015, 2018, 2019, 2020, 2021, 2023, 2026 INABA Hitoshi <ina@cpan.org>
######################################################################

use 5.00503;
use vars qw($VERSION $_fh_seq);
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub';
        eval 'package warnings; sub import {}' } } use warnings; local $^W=1;

$VERSION = '0.15';
$VERSION = $VERSION;
$_fh_seq = 0;

BEGIN { pop @INC if $INC[-1] eq '.' } # CVE-2016-1238: Important unsafe module load path flaw
use Fcntl;

#---------------------------------------------------------------------
sub Modern::Open::confess (@) {
    my $i = 0;
    my @confess = ();
    while (my($package, $filename, $line, $subroutine) = caller($i)) {
        push @confess, "[$i] $filename($line) $subroutine\n";
        $i++;
    }
    print STDERR "\n", @_, "\n";
    print STDERR CORE::reverse @confess;
    die;
}

#---------------------------------------------------------------------
sub Modern::Open::open (*$;$) {
    my $handle;

    if (defined $_[0]) {
        Modern::Open::confess "Bare handle no longer supported";
    }
    else {
        $_fh_seq++;
        my $fhn = "Modern::Open::FH::H${_fh_seq}";
        no strict 'refs';
        $handle = $fhn;
        $_[0] = \*{$fhn};
    }

    if (@_ >= 4) {
        Modern::Open::confess "Too many arguments for open";
    }
    elsif (@_ == 3) {
        my($mode, $filename) = @_[1, 2];

        if ($mode eq '-|') {
            no strict 'refs';
            my $return = CORE::open($handle, qq{$filename |});
            if ($return or defined wantarray) {
                return $return;
            }
            else {
                Modern::Open::confess "Can't open($_[0],$_[1],$_[2]): $!";
            }
        }
        elsif ($mode eq '|-') {
            no strict 'refs';
            my $return = CORE::open($handle, qq{| $filename});
            if ($return or defined wantarray) {
                return $return;
            }
            else {
                Modern::Open::confess "Can't open($_[0],$_[1],$_[2]): $!";
            }
        }
        else {
            my %flags = (
                '<'   => O_RDONLY,
                '>'   => O_WRONLY | O_TRUNC | O_CREAT,
                '>>'  => O_WRONLY |O_APPEND | O_CREAT,
                '+<'  => O_RDWR,
                '+>'  => O_RDWR | O_TRUNC  | O_CREAT,
                '+>>' => O_RDWR | O_APPEND | O_CREAT,
            );
            if (not exists $flags{$mode}) {
                Modern::Open::confess "Unknown open() mode '$mode'";
            }
            no strict 'refs';
            my $return = CORE::sysopen(*{$handle}, $filename, $flags{$mode});
            if ($return or defined wantarray) {
                return $return;
            }
            else {
                Modern::Open::confess "Can't open($_[0],$_[1],$_[2]): $!";
            }
        }
    }
    elsif (@_ == 2) {
        no strict 'refs';
        my $return = CORE::open($handle, $_[1]);
        if ($return or defined wantarray) {
            return $return;
        }
        else {
            Modern::Open::confess "Can't open($_[0],$_[1]): $!";
        }
    }
    else {
        Modern::Open::confess "Not enough arguments for open";
    }
}

#---------------------------------------------------------------------
sub Modern::Open::opendir (*$) {
    my $handle;

    if (defined $_[0]) {
        Modern::Open::confess "Bare handle no longer supported";
    }
    else {
        $_fh_seq++;
        my $fhn = "Modern::Open::FH::H${_fh_seq}";
        no strict 'refs';
        $handle = $fhn;
        $_[0] = \*{$fhn};
    }

    my $return;
    { no strict 'refs';
        if ($return = CORE::opendir(*{$handle}, $_[1])) {
        }
        elsif (($^O =~ /MSWin32/) and (-d qq{$_[1].})) {
            $return = CORE::opendir(*{$handle}, qq{$_[1].});
        }
    }

    if ($return or defined wantarray) {
        return $return;
    }
    else {
        Modern::Open::confess "Can't opendir($_[0],$_[1]): $!";
    }
}

#---------------------------------------------------------------------
sub Modern::Open::sysopen (*$$;$) {
    my $handle;

    if (defined $_[0]) {
        Modern::Open::confess "Bare handle no longer supported";
    }
    else {
        $_fh_seq++;
        my $fhn = "Modern::Open::FH::H${_fh_seq}";
        no strict 'refs';
        $handle = $fhn;
        $_[0] = \*{$fhn};
    }

    if (@_ >= 5) {
        Modern::Open::confess "Too many arguments for sysopen";
    }
    elsif (@_ == 4) {
        no strict 'refs';
        my $return = CORE::sysopen(*{$handle}, $_[1], $_[2], $_[3]);
        if ($return or defined wantarray) {
            return $return;
        }
        else {
            Modern::Open::confess "Can't sysopen($_[0],$_[1],$_[2],$_[3]): $!";
        }
    }
    elsif (@_ == 3) {
        no strict 'refs';
        my $return = CORE::sysopen(*{$handle}, $_[1], $_[2]);
        if ($return or defined wantarray) {
            return $return;
        }
        else {
            Modern::Open::confess "Can't sysopen($_[0],$_[1],$_[2]): $!";
        }
    }
    else {
        Modern::Open::confess "Not enough arguments for sysopen";
    }
}

#---------------------------------------------------------------------
sub Modern::Open::pipe (**) {
    my($handle0, $handle1);

    if (defined $_[0]) {
        Modern::Open::confess "Bare handle no longer supported";
    }
    else {
        $_fh_seq++;
        my $fhn0 = "Modern::Open::FH::P${_fh_seq}r";
        no strict 'refs';
        $handle0 = $fhn0;
        $_[0] = \*{$fhn0};
    }

    if (defined $_[1]) {
        Modern::Open::confess "Bare handle no longer supported";
    }
    else {
        my $fhn1 = "Modern::Open::FH::P${_fh_seq}w";
        no strict 'refs';
        $handle1 = $fhn1;
        $_[1] = \*{$fhn1};
    }

    no strict 'refs';
    my $return = CORE::pipe(*{$handle0}, *{$handle1});
    if ($return or defined wantarray) {
        return $return;
    }
    else {
        Modern::Open::confess "Can't pipe($_[0],$_[1]): $!";
    }
}

#---------------------------------------------------------------------
sub Modern::Open::socket (*$$$) {
    my $handle;

    if (defined $_[0]) {
        Modern::Open::confess "Bare handle no longer supported";
    }
    else {
        $_fh_seq++;
        my $fhn = "Modern::Open::FH::H${_fh_seq}";
        no strict 'refs';
        $handle = $fhn;
        $_[0] = \*{$fhn};
    }

    # socket doesn't autodie
    no strict 'refs';
    return CORE::socket(*{$handle}, $_[1], $_[2], $_[3]);
}

#---------------------------------------------------------------------
sub Modern::Open::accept (**) {
    my($handle0, $handle1);

    if (defined $_[0]) {
        Modern::Open::confess "Bare handle no longer supported";
    }
    else {
        $_fh_seq++;
        my $fhn = "Modern::Open::FH::H${_fh_seq}";
        no strict 'refs';
        $handle0 = $fhn;
        $_[0] = \*{$fhn};
    }

    no strict 'refs';
    my $return = CORE::accept(*{$handle0}, *{$_[1]});
    if ($return or defined wantarray) {
        return $return;
    }
    else {
        Modern::Open::confess "Can't accept($_[0],$_[1]): $!";
    }
}

#---------------------------------------------------------------------
sub import {

    # avoid: Can't use string ("main::open") as a symbol ref while "strict refs" in use
    no strict 'refs';
    {
        # avoid: Prototype mismatch: sub main::open (*;$) vs (*$;$)
        local $SIG{__WARN__} = sub {};
        *{caller() . '::open'} = \&Modern::Open::open;
    }
    *{caller() . '::opendir'}  = \&Modern::Open::opendir;
    *{caller() . '::sysopen'}  = \&Modern::Open::sysopen;
    *{caller() . '::pipe'}     = \&Modern::Open::pipe;
    *{caller() . '::socket'}   = \&Modern::Open::socket;
    *{caller() . '::accept'}   = \&Modern::Open::accept;
}

1;

__END__

=pod

=head1 NAME

Modern::Open - Autovivification, Autodie, and 3-args open support

=head1 VERSION

Version 0.15

=head1 SYNOPSIS

  use Modern::Open;

=head1 TABLE OF CONTENTS

=over 2

=item L</DESCRIPTION>

=item L</INSTALLATION>

=item L</COMPATIBILITY>

=item L</DIAGNOSTICS>

=item L</SEE ALSO>

=back

=head1 DESCRIPTION

Modern::Open provides autovivification and autodie support of open(), opendir(), sysopen(), pipe(), and accept() on perl 5.00503 or later.
And supports three-argument open(), too.
socket() supports autovivification of the filehandle but does not autodie; it returns the result of CORE::socket() directly.

=head1 INSTALLATION

To install this module, run the following commands:

  perl Makefile.PL
  make
  make test
  make install

=head1 COMPATIBILITY

This module requires Perl 5.00503 or later and runs on all versions through
the current release.

=head1 DIAGNOSTICS

=over 2

=item C<Bare handle no longer supported>

A bareword filehandle was passed to open(), opendir(), sysopen(), pipe(), socket(), or accept(). Use an undefined scalar variable instead.

=item C<Too many arguments for open>

More than three arguments were passed to open().

=item C<Too many arguments for sysopen>

More than four arguments were passed to sysopen().

=item C<Not enough arguments for open>

Fewer than two arguments were passed to open().

=item C<Not enough arguments for sysopen>

Fewer than three arguments were passed to sysopen().

=item C<Unknown open() mode '$mode'>

An unrecognized mode string was passed as the second argument to the three-argument form of open().

=item C<Can't open(<VAR>,<VAR>): <VAR>>

Died because 2-argument open() failed and the call was in void context.

=item C<Can't open(<VAR>,<VAR>,<VAR>): <VAR>>

Died because 3-argument open() failed and the call was in void context.

=item C<Can't opendir(<VAR>,<VAR>): <VAR>>

Died because opendir() failed and the call was in void context.

=item C<Can't sysopen(<VAR>,<VAR>,<VAR>): <VAR>>

Died because 3-argument sysopen() failed and the call was in void context.

=item C<Can't sysopen(<VAR>,<VAR>,<VAR>,<VAR>): <VAR>>

Died because 4-argument sysopen() failed and the call was in void context.

=item C<Can't pipe(<VAR>,<VAR>): <VAR>>

Died because pipe() failed and the call was in void context.

=item C<Can't accept(<VAR>,<VAR>): <VAR>>

Died because accept() failed and the call was in void context.

=back

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt>

This project was originated by INABA Hitoshi.

=head1 COPYRIGHT AND LICENSE

This software is free software; you can redistribute it and/or modify it under the same terms as Perl itself. See L<perlartistic>.

This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

=over 2

=item *

L<announcing-perl-7|https://www.perl.com/article/announcing-perl-7/> - Announcing Perl 7 Jun 24, 2020 by brian d foy

=item *

L<open|http://perldoc.perl.org/functions/open.html> - Perl Programming Documentation

=item *

L<Three-arg open() (Migrating to Modern Perl)|http://modernperlbooks.com/mt/2010/04/three-arg-open-migrating-to-modern-perl.html> - Modern Perl Programming

=item *

L<Pre-Modern Perl VS Post-Modern Perl: FIGHT!|http://blogs.perl.org/users/buddy_burden/2013/06/pre-modern-perl-vs-post-modern-perl-fight.html> - A blog about the Perl programming language

=item *

L<perl - open my $fh, "comand |"; # isn't modern|http://blog.livedoor.jp/dankogai/archives/51176081.html> - 404 Blog Not Found

=item *

L<Migrating scripts back to Perl 5.005_03|http://www.perlmonks.org/?node_id=289351> - PerlMonks

=item *

L<Goodnight, Perl 5.005|http://www.oreillynet.com/onlamp/blog/2007/11/goodnight_perl_5005.html> - ONLamp.com

=item *

L<Perl 5.005_03 binaries|http://guest.engelschall.com/~sb/download/win32/> - engelschall.com

=item *

L<Welcome to CP5.5.3AN|http://cp5.5.3an.barnyard.co.uk/> - cp5.5.3an.barnyard.co.uk

=item *

L<ina|http://search.cpan.org/~ina/> - CPAN

=item *

L<The BackPAN|http://backpan.perl.org/authors/id/I/IN/INA/> - A Complete History of CPAN

=back

=cut
