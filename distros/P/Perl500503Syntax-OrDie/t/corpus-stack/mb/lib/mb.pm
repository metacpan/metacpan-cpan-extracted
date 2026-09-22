######################################################################
#
# EXCERPT -- corpus fixture for Perl500503Syntax-OrDie, not a usable copy
# of the module it was taken from.
#
# Source: mb 0.62
# 3773 of 9241 lines removed.
#
# Only lines the OrDie masker renders as dead were removed: POD bodies,
# non-interpolating heredoc bodies, data tables and everything after
# __END__.  Lines inside a regex literal or an interpolating string
# literal were kept, because stages 3 and 4 read those; so were POD
# directives, heredoc terminators, __END__ and three lines of context on
# each side of every removed run, so that the file still parses and still
# reads as the source it came from.
#
# The reduction is verified to be scanner-neutral: the masked live code,
# the list of regex bodies and the list of string bodies are byte-identical
# to the full source.  See t/0011-corpus-excerpt.t.
#
######################################################################
package mb;
'有朋自遠方来不亦楽乎'=~/^\xE6\x9C\x89/ or die "Perl script '@{[__FILE__]}' must be UTF-8 encoding.\n";
# You are welcome! MOJIBAKE-san, you are our friend forever!!
######################################################################
#
# mb - Can easy script in Big5, Big5-HKSCS, GBK, Sjis(also CP932), UHC, UTF-8, ...
#
# https://metacpan.org/release/mb
#
# Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2026 INABA Hitoshi <ina.cpan@gmail.com> in a CPAN
######################################################################

use 5.00503;    # Universal Consensus 1998 for primetools
# use 5.008001; # Lancaster Consensus 2013 for toolchains

$VERSION = '0.62';
$VERSION = $VERSION;

# internal use
$mb::last_s_passed = 0; # last s/// status (1 if s/// passed)

# filehandle sequence counter for _open_a/_open_r/_open_w
$mb::_fh_seq = 0;

BEGIN { pop @INC if $INC[-1] eq '.' } # CVE-2016-1238: Important unsafe module load path flaw
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } } use warnings; local $^W=1;

# set OSNAME
my $OSNAME = $^O;

# encoding name of operating system
my $system_encoding = undef;

# encoding name of MBCS script
my $script_encoding = undef;

# over US-ASCII
my $over_ascii = undef;

# supports qr/./ in MBCS script
my $x = undef;

# supports [\b] \d \h \s \v \w in MBCS script
my $bare_backspace = '\x08';
my $bare_d = '0123456789';
my $bare_h = '\x09\x20';
my $bare_s = '\t\n\f\r\x20';
my $bare_v = '\x0A\x0B\x0C\x0D';
my $bare_w = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_';

# as many escapes as possible to avoid perl's feature
my $escapee_in_qq_like = join('', map {"\\$_"} grep( ! /[A-Za-z0-9_]/, map { CORE::chr } 0x21..0x7E));

# as less escapes as possible to avoid over-escaping
my $escapee_in_q__like = '\\' . "\x5C";

# generic linebreak
my $R = '(?>\\r\\n|\\r|\\n)';

# check running perl interpreter
if ($^X =~ /jperl/i) {
    die "script '@{[__FILE__]}' can run on only perl, not JPerl\n";
}

# this file is used as command on command line
if ($0 eq __FILE__) {
    main();
}

######################################################################
# main program
######################################################################

#---------------------------------------------------------------------
# running as module, runtime routines
sub import {
    my $self = shift @_;

    # confirm version
    if (defined($_[0]) and ($_[0] =~ /\A [0-9] /xms)) {
        if ($_[0] ne $mb::VERSION) {
            my($package, $filename, $line) = caller;
            die "$filename requires @{[__PACKAGE__]} $_[0], however @{[__FILE__]} am only $mb::VERSION, stopped at $filename line $line.\n";
        }
        shift @_;
    }

    # set system encoding
    $system_encoding = detect_system_encoding();

    # set script encoding
    if (defined $_[0]) {
        my $encoding = $_[0];
        if ($encoding =~ /\A (?: big5 | big5hkscs | eucjp | gb18030 | gbk | rfc2279 | sjis | uhc | utf8 | wtf8 ) \z/xms) {
            mb::set_script_encoding($encoding);
        }
        else {
            die "@{[__FILE__]} script_encoding '$encoding' not supported.\n";
        }
    }
    else {
        mb::set_script_encoding($system_encoding);
    }

    # tie my %mb, __PACKAGE__; # makes: Parentheses missing around "my" list
    no strict qw(refs);
    tie my %mb, 'mb';
    *{caller().'::mb'} = { %mb };

    # $^X($EXECUTABLE_NAME) for execute MBCS Perl script
    $mb::PERL = qq{$^X @{[__FILE__]}};
    $mb::PERL = $mb::PERL; # to avoid: Name "mb::PERL" used only once: possible typo at ...

    # original $0($PROGRAM_NAME) before transpile
    ($mb::ORIG_PROGRAM_NAME = $0) =~ s/\.oo(\.[^.]+)\z/$1/;
    $mb::ORIG_PROGRAM_NAME = $mb::ORIG_PROGRAM_NAME; # to avoid: Name "mb::ORIG_PROGRAM_NAME" used only once: possible typo at ...

    # Sjis software compatible subroutines
    my $old_package = mb::get_old_package();
    for my $subroutine (qw( chop chr do dosglob eval getc index index_byte length ord require reverse rindex rindex_byte substr tr )) {
        *{$old_package . $subroutine} = \&{"mb::$subroutine"};
    }
}

#---------------------------------------------------------------------
# running as command
sub main {

    # usage
    if (scalar(@ARGV) == 0) {
        die <<END;
usage:

perl mb.pm              script_by_mbcs.pl (auto detect)
perl mb.pm -e big5      script_by_big5.pl
perl mb.pm -e big5hkscs script_by_big5hkscs.pl
perl mb.pm -e eucjp     script_by_eucjp.pl
perl mb.pm -e gb18030   script_by_gb18030.pl
perl mb.pm -e gbk       script_by_gbk.pl
perl mb.pm -e rfc2279   script_by_rfc2279.pl
perl mb.pm -e sjis      script_by_sjis.pl
perl mb.pm -e sjis      script_by_cp932.pl
perl mb.pm -e uhc       script_by_uhc.pl
perl mb.pm -e utf8      script_by_utf8.pl
perl mb.pm -e wtf8      script_by_wtf8.pl

perl mb.pm script.pl ??-DOS-like *wildcard* available

END
    }

    # set system encoding
    $system_encoding = detect_system_encoding();

    # set script encoding from command line
    my $encoding = '';
    if (($encoding) = $ARGV[0] =~ /\A -e ( .+ ) \z/xms) {
        if ($encoding =~ /\A (?: big5 | big5hkscs | eucjp | gb18030 | gbk | rfc2279 | sjis | uhc | utf8 | wtf8 ) \z/xms) {
            mb::set_script_encoding($encoding);
            shift @ARGV;
        }
        else {
            die "script_encoding '$encoding' not supported.\n";
        }
    }
    elsif ($ARGV[0] =~ /\A -e \z/xms) {
        $encoding = $ARGV[1];
        if ($encoding =~ /\A (?: big5 | big5hkscs | eucjp | gb18030 | gbk | rfc2279 | sjis | uhc | utf8 | wtf8 ) \z/xms) {
            mb::set_script_encoding($encoding);
            shift @ARGV;
            shift @ARGV;
        }
        else {
            die "script_encoding '$encoding' not supported.\n";
        }
    }
    else {
        mb::set_script_encoding($system_encoding);
    }

    # poor "make"
    (my $script_oo = $ARGV[0]) =~ s{\A (.*) \. ([^.]+) \z}{$1.oo.$2}xms;
    if (
        (not -e $script_oo)                    or
        (mtime($script_oo) <= mtime($ARGV[0])) or
        (mtime($script_oo) <= mtime(__FILE__))
    ) {

        # read application script
        my $fh = mb::_open_r($ARGV[0]) or die "$0(@{[__LINE__]}): can't open file: $ARGV[0]\n";

        # sysread(...) has hidden binmode($fh) that's not portable
        # local $_; sysread($fh, $_, -s $ARGV[0]);
        local $_ = CORE::do { local $/; no strict 'refs'; readline(*{$fh}) };
        { no strict 'refs'; close($fh) }

        # poor file locking
        local $SIG{__DIE__} = sub { rmdir "$ARGV[0].lock"; };
        if (mkdir "$ARGV[0].lock", 0755) {
            my $fh = mb::_open_w($script_oo) or die "$0(@{[__LINE__]}): can't open file: $script_oo\n";
            { no strict 'refs'; print {*{$fh}} mb::_insert_source_encoding_unimport(mb::parse()) }
            { no strict 'refs'; close($fh) }
            rmdir "$ARGV[0].lock";
        }
        else {
            die "$0(@{[__LINE__]}): can't mkdir: $ARGV[0].lock\n";
        }
    }

    # run octet-oriented script
    my $module_path = '';
    my $module_name = '';
    my $quote = '';
    if ($OSNAME =~ /MSWin32/) {
        if ($0 =~ m{ ([^\/\\]+)\.pm \z}xmsi) {
            ($module_path, $module_name) = ($`, $1);
            $module_path ||= '.';
            $module_path =~ s{ [\/\\] \z}{}xms;
        }
        else {
            die "$0(@{[__LINE__]}): can't run as module.\n";
        }
        $quote = q{"};
    }
    else {
        if ($0 =~ m{ ([^\/]+)\.pm \z}xmsi) {
            ($module_path, $module_name) = ($`, $1);
            $module_path ||= '.';
            $module_path =~ s{ / \z}{}xms;
        }
        else {
            die "$0(@{[__LINE__]}): can't run as module.\n";
        }
        $quote = q{'};
    }

    # @ARGV wildcard globbing
    if ($OSNAME =~ /MSWin32/) {
        my @argv = ();
        for (@ARGV) {

            # has space
            if (/\A (?:$x)*? [ ] /xms) {
                if (my @glob = mb::dosglob(qq{"$_"})) {
                    push @argv, @glob;
                }
                else {
                    push @argv, $_;
                }
            }

            # has wildcard metachar
            elsif (/\A (?:$x)*? [*?] /xms) {
                if (my @glob = mb::dosglob($_)) {
                    push @argv, @glob;
                }
                else {
                    push @argv, $_;
                }
            }

            # no wildcard globbing
            else {
                push @argv, $_;
            }
        }
        @ARGV = @argv;
    }

    # run octet-oriented script
    $| = 1;
    system($^X, "-I$module_path", "-M$module_name=$mb::VERSION,$script_encoding", map { / / ? "$quote$_$quote" : $_ } $script_oo, @ARGV[1..$#ARGV]);
    exit($? >> 8);
}

#---------------------------------------------------------------------
# cluck() for MBCS encoding
sub cluck {
    my $i = 0;
    my @cluck = ();
    while (my($package, $filename, $line, $subroutine) = caller($i)) {
        push @cluck, "[$i] $filename($line) $subroutine\n";
        $i++;
    }
    print STDERR "\n", @_, "\n";
    print STDERR CORE::reverse @cluck;
}

#---------------------------------------------------------------------
# confess() for MBCS encoding
sub confess {
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
# short cut of (stat(file))[9]
sub mtime {
    my($file) = @_;
    return ((stat $file)[9]);
}

######################################################################
# subroutines for MBCS application programmers
######################################################################

#---------------------------------------------------------------------
# chop() for MBCS encoding
sub mb::chop (@) {
    my $chop = '';
    for (@_ ? @_ : $_) {
        if (my @x = /\G$x/g) {
            $chop = pop @x;
            $_ = join '', @x;
        }
    }
    return $chop;
}

#---------------------------------------------------------------------
# chr() for MBCS encoding
sub mb::chr (;$) {
    my $number = @_ ? $_[0] : $_;

# Negative values give the Unicode replacement character (chr(0xfffd)),
# except under the bytes pragma, where the low eight bits of the value
# (truncated to an integer) are used.

    my @octet = ();
    CORE::do {
        unshift @octet, ($number % 0x100);
        $number = int($number / 0x100);
    } while ($number > 0);
    return pack 'C*', @octet;
}

#---------------------------------------------------------------------
# do FILE for MBCS encoding
sub mb::do ($) {
    my($file) = @_;
    for my $prefix_file ($file, map { "$_/$file" } @INC) {
        if (-f $prefix_file) {

            # poor "make"
            (my $prefix_file_oo = $prefix_file) =~ s{\A (.*) \. ([^.]+) \z}{$1.oo.$2}xms;
            if (
                (not -e $prefix_file_oo)                        or
                (mtime($prefix_file_oo) <= mtime($prefix_file)) or
                (mtime($prefix_file_oo) <= mtime(__FILE__))
            ) {
                my $fh = mb::_open_r($prefix_file) or confess "$0(@{[__LINE__]}): can't open file: $prefix_file\n";
                local $_ = CORE::do { local $/; no strict 'refs'; readline(*{$fh}) };
                { no strict 'refs'; close($fh) }

                # poor file locking
                local $SIG{__DIE__} = sub { rmdir "$prefix_file.lock"; };
                if (mkdir "$prefix_file.lock", 0755) {
                    my $fh = mb::_open_w($prefix_file_oo) or confess "$0(@{[__LINE__]}): can't open file: $prefix_file_oo\n";
                    { no strict 'refs'; print {*{$fh}} mb::_insert_source_encoding_unimport(mb::parse()) }
                    { no strict 'refs'; close($fh) }
                    rmdir "$prefix_file.lock";
                }
                else {
                    confess "$0(@{[__LINE__]}): can't mkdir: $prefix_file.lock\n";
                }
            }
            $INC{$file} = $prefix_file_oo;

            # run as Perl script
            # must use CORE::do to use <DATA>, because CORE::eval cannot do it
            # moreover "goto &CORE::do" doesn't work
            return CORE::eval sprintf(<<'END', (caller)[0,2,1]);
package %s;
#line %s "%s"
CORE::do "$prefix_file_oo";
END
        }
    }
    confess "Can't find $file in \@INC";
}

#---------------------------------------------------------------------
# DOS-like glob() for MBCS encoding
sub mb::dosglob (;$) {
    my $expr = @_ ? $_[0] : $_;
    my @glob = ();

    # works on not MSWin32
    if ($OSNAME !~ /MSWin32/) {
        @glob = CORE::glob($expr);
    }

    # works on MSWin32
    else {

        # gets pattern
        while ($expr =~ s{\A [\x20]* ( "(?:$x)+?" | (?:(?!["\x20])$x)+ ) }{}xms) {
            my $pattern = $1;

            # avoids command injection
            next if $pattern =~ /\G${mb::_anchor} \& /xms;
            next if $pattern =~ /\G${mb::_anchor} \( /xms;
            next if $pattern =~ /\G${mb::_anchor} \) /xms;
            next if $pattern =~ /\G${mb::_anchor} \< /xms;
            next if $pattern =~ /\G${mb::_anchor} \> /xms;
            next if $pattern =~ /\G${mb::_anchor} \^ /xms;
            next if $pattern =~ /\G${mb::_anchor} \| /xms;

            # makes globbing result
            mb::tr($pattern, '/', "\x5C");
            if (my($dir) = $pattern =~ m{\A ($x*) \\ }xms) {
                push @glob, map { "$dir\\$_" } CORE::split /\n/, `DIR /B $pattern 2>NUL`;
            }
            else {
                push @glob,                    CORE::split /\n/, `DIR /B $pattern 2>NUL`;
            }
        }
    }

    # returns globbing result
    my %glob = map { $_ => 1 } @glob;
    return sort { (mb::uc($a) cmp mb::uc($b)) || ($a cmp $b) } keys %glob;
}

#---------------------------------------------------------------------
# eval STRING for MBCS encoding
sub mb::eval (;$) {
    local $_ = @_ ? $_[0] : $_;

    # run as Perl script in caller package
    return CORE::eval sprintf(<<'END', (caller)[0,2,1], mb::parse());
package %s;
#line %s "%s"
%s
END
}

#---------------------------------------------------------------------
# getc() for MBCS encoding
sub mb::getc (;*) {
    my $fh = @_ ? shift(@_) : \*STDIN;
    confess 'Too many arguments for mb::getc' if @_ and not wantarray;
    my $getc = CORE::getc $fh;
    if ($script_encoding =~ /\A (?: sjis ) \z/xms) {
        if ($getc =~ /\A [\x81-\x9F\xE0-\xFC] \z/xms) {
            $getc .= CORE::getc $fh;
        }
    }
    elsif ($script_encoding =~ /\A (?: eucjp ) \z/xms) {
        if ($getc =~ /\A [\xA1-\xFE] \z/xms) {
            $getc .= CORE::getc $fh;
        }
    }
    elsif ($script_encoding =~ /\A (?: gbk | uhc | big5 | big5hkscs ) \z/xms) {
        if ($getc =~ /\A [\x81-\xFE] \z/xms) {
            $getc .= CORE::getc $fh;
        }
    }
    elsif ($script_encoding =~ /\A (?: gb18030 ) \z/xms) {
        if ($getc =~ /\A [\x81-\xFE] \z/xms) {
            $getc .= CORE::getc $fh;
            if ($getc =~ /\A [\x81-\xFE] [\x30-\x39] \z/xms) {
                $getc .= CORE::getc $fh;
                $getc .= CORE::getc $fh;
            }
        }
    }
    elsif ($script_encoding =~ /\A (?: rfc2279 | utf8 | wtf8 ) \z/xms) {
        if ($getc =~ /\A [\x00-\x7F\x80-\xC1\xF5-\xFF] \z/xms) {
        }
        elsif ($getc =~ /\A [\xC2-\xDF] \z/xms) {
            $getc .= CORE::getc $fh;
        }
        elsif ($getc =~ /\A [\xE0-\xEF] \z/xms) {
            $getc .= CORE::getc $fh;
            $getc .= CORE::getc $fh;
        }
        elsif ($getc =~ /\A [\xF0-\xF4] \z/xms) {
            $getc .= CORE::getc $fh;
            $getc .= CORE::getc $fh;
            $getc .= CORE::getc $fh;
        }
    }
    return wantarray ? ($getc,@_) : $getc;
}

#---------------------------------------------------------------------
# index() for MBCS encoding
sub mb::index ($$;$) {
    my $index = 0;
    if (@_ == 3) {
        $index = mb::index_byte($_[0], $_[1], CORE::length(mb::substr($_[0], 0, $_[2])));
    }
    else {
        $index = mb::index_byte($_[0], $_[1]);
    }
    if ($index == -1) {
        return -1;
    }
    else {
        return mb::length(CORE::substr $_[0], 0, $index);
    }
}

#---------------------------------------------------------------------
# JPerl like index() for MBCS encoding
sub mb::index_byte ($$;$) {
    my($str,$substr,$position) = @_;
    $position ||= 0;
    my $pos = 0;
    while ($pos < CORE::length($str)) {
        if (CORE::substr($str,$pos,CORE::length($substr)) eq $substr) {
            if ($pos >= $position) {
                return $pos;
            }
        }
        if (CORE::substr($str,$pos) =~ /\A($x)/xms) {
            $pos += CORE::length($1);
        }
        else {
            $pos += 1;
        }
    }
    return -1;
}

#---------------------------------------------------------------------
# universal lc() for MBCS encoding
sub mb::lc (;$) {
    local $_ = @_ ? $_[0] : $_;
    #                          A a B b C c D d E e F f G g H h I i J j K k L l M m N n O o P p Q q R r S s T t U u V v W w X x Y y Z z
    return join '', map { {qw( A a B b C c D d E e F f G g H h I i J j K k L l M m N n O o P p Q q R r S s T t U u V v W w X x Y y Z z )}->{$_}||$_ } /\G$x/g;
    #                          A a B b C c D d E e F f G g H h I i J j K k L l M m N n O o P p Q q R r S s T t U u V v W w X x Y y Z z
}

#---------------------------------------------------------------------
# universal lcfirst() for MBCS encoding
sub mb::lcfirst (;$) {
    local $_ = @_ ? $_[0] : $_;
    if (/\A($x)(.*)\z/s) {
        return mb::lc($1) . $2;
    }
    else {
        return '';
    }
}

#---------------------------------------------------------------------
# length() for MBCS encoding
sub mb::length (;$) {
    local $_ = @_ ? $_[0] : $_;
    return scalar(() = /\G$x/g);
}

#---------------------------------------------------------------------
# ord() for MBCS encoding
sub mb::ord (;$) {
    local $_ = @_ ? $_[0] : $_;
    my $ord = 0;
    if (/\A($x)/) {
        for my $octet (unpack 'C*', $1) {
            $ord = $ord * 0x100 + $octet;
        }
    }
    return $ord;
}

#---------------------------------------------------------------------
# require for MBCS encoding
sub mb::require (;$) {
    local $_ = @_ ? $_[0] : $_;

    # require perl version
    if (/^[0-9]/) {
        if ($] < $_) {
            confess "Perl $_ required--this is only version $], stopped";
        }
        else {
            undef $@;
            return 1;
        }
    }

    # require expr
    else {

        # find expr in @INC
        my $file = $_;
        if (($file =~ s{::}{/}g) or ($file !~ m{[\./\\]})) {
            $file .= '.pm';
        }
        if (exists $INC{$file}) {
            undef $@;
            return 1 if $INC{$file};
            confess "Compilation failed in require";
        }
        for my $prefix_file ($file, map { "$_/$file" } @INC) {
            if (-f $prefix_file) {

                # poor "make"
                (my $prefix_file_oo = $prefix_file) =~ s{\A (.*) \. ([^.]+) \z}{$1.oo.$2}xms;
                if (
                    (not -e $prefix_file_oo)                        or
                    (mtime($prefix_file_oo) <= mtime($prefix_file)) or
                    (mtime($prefix_file_oo) <= mtime(__FILE__))
                ) {
                    my $fh = mb::_open_r($prefix_file) or confess "$0(@{[__LINE__]}): can't open file: $prefix_file\n";
                    local $_ = CORE::do { local $/; no strict 'refs'; readline(*{$fh}) };
                    { no strict 'refs'; close($fh) }

                    # poor file locking
                    local $SIG{__DIE__} = sub { rmdir "$prefix_file.lock"; };
                    if (mkdir "$prefix_file.lock", 0755) {
                        my $fh = mb::_open_w($prefix_file_oo) or confess "$0(@{[__LINE__]}): can't open file: $prefix_file_oo\n";
                        { no strict 'refs'; print {*{$fh}} mb::_insert_source_encoding_unimport(mb::parse()) }
                        { no strict 'refs'; close($fh) }
                        rmdir "$prefix_file.lock";
                    }
                    else {
                        confess "$0(@{[__LINE__]}): can't mkdir: $prefix_file.lock\n";
                    }
                }
                $INC{$_} = $prefix_file_oo;

                # run as Perl script
                # must use CORE::do to use <DATA>, because CORE::eval cannot do it.
                local $@;
                my $result = CORE::eval sprintf(<<'END', (caller)[0,2,1]);
package %s;
#line %s "%s"
CORE::do "$prefix_file_oo";
END

                # return result
                if ($@) {
                    $INC{$_} = undef;
                    confess $@;
                }
                elsif (not $result) {
                    delete $INC{$_};
                    confess "$_ did not return true value";
                }
                else {
                    return $result;
                }
            }
        }
        confess "Can't find $_ in \@INC";
    }
}

#---------------------------------------------------------------------
# reverse() for MBCS encoding
sub mb::reverse (@) {

    # in list context,
    if (wantarray) {

        # returns a list value consisting of the elements of @_ in the opposite order
        return CORE::reverse @_;
    }

    # in scalar context,
    else {

        # returns a string value with all characters in the opposite order of
        return (join '',
            CORE::reverse(
                @_ ?
                join('',@_) =~ /\G$x/g : # concatenates the elements of @_
                /\G$x/g                  # $_ when without arguments
            )
        );
    }
}

#---------------------------------------------------------------------
# rindex() for MBCS encoding
sub mb::rindex ($$;$) {
    my $rindex = 0;
    if (@_ == 3) {
        $rindex = mb::rindex_byte($_[0], $_[1], CORE::length(mb::substr($_[0], 0, $_[2])));
    }
    else {
        $rindex = mb::rindex_byte($_[0], $_[1]);
    }
    if ($rindex == -1) {
        return -1;
    }
    else {
        return mb::length(CORE::substr $_[0], 0, $rindex);
    }
}

#---------------------------------------------------------------------
# JPerl like rindex() for MBCS encoding
sub mb::rindex_byte ($$;$) {
    my($str,$substr,$position) = @_;
    $position ||= CORE::length($str) - 1;
    my $pos = 0;
    my $rindex = -1;
    while (($pos < CORE::length($str)) and ($pos <= $position)) {
        if (CORE::substr($str,$pos,CORE::length($substr)) eq $substr) {
            $rindex = $pos;
        }
        if (CORE::substr($str,$pos) =~ /\A($x)/xms) {
            $pos += CORE::length($1);
        }
        else {
            $pos += 1;
        }
    }
    return $rindex;
}

#---------------------------------------------------------------------
# set OSNAME
sub mb::set_OSNAME ($) {
    $OSNAME = $_[0];
}

#---------------------------------------------------------------------
# get OSNAME
sub mb::get_OSNAME () {
    return $OSNAME;
}

#---------------------------------------------------------------------
# set script encoding name and more
sub mb::set_script_encoding ($) {
    $script_encoding = $_[0];

    # over US-ASCII
    $over_ascii = {
        'sjis'      => '(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])',                         # shift_jis ANSI/OEM Japanese; Japanese (Shift-JIS)
        'gbk'       => '(?>[\x81-\xFE][\x00-\xFF])',                                              # gb2312 ANSI/OEM Simplified Chinese (PRC, Singapore); Chinese Simplified (GB2312)
        'uhc'       => '(?>[\x81-\xFE][\x00-\xFF])',                                              # ks_c_5601-1987 ANSI/OEM Korean (Unified Hangul Code)
        'big5'      => '(?>[\x81-\xFE][\x00-\xFF])',                                              # big5 ANSI/OEM Traditional Chinese (Taiwan; Hong Kong SAR, PRC); Chinese Traditional (Big5)
        'big5hkscs' => '(?>[\x81-\xFE][\x00-\xFF])',                                              # HKSCS support on top of traditional Chinese Windows
        'eucjp'     => '(?>[\xA1-\xFE][\x00-\xFF])',                                              # EUC-JP Japanese (JIS 0208-1990 and 0121-1990)
        'gb18030'   => '(?>[\x81-\xFE][\x30-\x39][\x81-\xFE][\x30-\x39]|[\x81-\xFE][\x00-\xFF])', # GB18030 Windows XP and later: GB18030 Simplified Chinese (4 byte); Chinese Simplified (GB18030)
        'rfc2279'   => '(?>[\xC2-\xDF][\x80-\xBF]|[\xE0-\xEF][\x80-\xBF][\x80-\xBF]|[\xF0-\xF4][\x80-\xBF][\x80-\xBF][\x80-\xBF])', # utf-8 Unicode (UTF-8) RFC2279
        'utf8'      => '(?>[\xE1-\xEC][\x80-\xBF][\x80-\xBF]|[\xC2-\xDF][\x80-\xBF]|[\xEE-\xEF][\x80-\xBF][\x80-\xBF]|[\xF0-\xF0][\x90-\xBF][\x80-\xBF][\x80-\xBF]|[\xE0-\xE0][\xA0-\xBF][\x80-\xBF]|[\xED-\xED][\x80-\x9F][\x80-\xBF]|[\xF1-\xF3][\x80-\xBF][\x80-\xBF][\x80-\xBF]|[\xF4-\xF4][\x80-\x8F][\x80-\xBF][\x80-\xBF])', # utf-8 Unicode (UTF-8) optimized RFC3629 for ja_JP
        'wtf8'      => '(?>[\xE1-\xEF][\x80-\xBF][\x80-\xBF]|[\xC2-\xDF][\x80-\xBF]|[\xE0-\xE0][\xA0-\xBF][\x80-\xBF]|[\xF0-\xF0][\x90-\xBF][\x80-\xBF][\x80-\xBF]|[\xF1-\xF3][\x80-\xBF][\x80-\xBF][\x80-\xBF]|[\xF4-\xF4][\x80-\x8F][\x80-\xBF][\x80-\xBF])',                                                                     # optimized WTF-8 for ja_JP
    }->{$script_encoding} || '[\x80-\xFF]';

    # supports qr/./ in MBCS script
    $x = qr/(?>$over_ascii|[\x00-\x7F])/;

    # regexp of multi-byte anchoring

    # REG_INF has been raised from 65,536 to 2,147,483,647
    # https://perldoc.perl.org/perl5380delta#REG_INF-has-been-raised-from-65,536-to-2,147,483,647

    if ($script_encoding =~ /\A (?: rfc2279 | utf8 | wtf8 ) \z/xms) {
        ${mb::_anchor} = qr{.*?}xms;
    }
    elsif ($] >= 5.038000) {
        ${mb::_anchor} = {
            'sjis'      => qr{(?(?=.{0,2147483646}\z)(?:$x)*?|(?(?=[^\x81-\x9F\xE0-\xFC]+\z).*?|.*?[^\x81-\x9F\xE0-\xFC](?>[\x81-\x9F\xE0-\xFC][\x81-\x9F\xE0-\xFC])*?))}xms,
            'eucjp'     => qr{(?(?=.{0,2147483646}\z)(?:$x)*?|(?(?=[^\xA1-\xFE\xA1-\xFE]+\z).*?|.*?[^\xA1-\xFE\xA1-\xFE](?>[\xA1-\xFE\xA1-\xFE][\xA1-\xFE\xA1-\xFE])*?))}xms,
            'gbk'       => qr{(?(?=.{0,2147483646}\z)(?:$x)*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
            'uhc'       => qr{(?(?=.{0,2147483646}\z)(?:$x)*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
            'big5'      => qr{(?(?=.{0,2147483646}\z)(?:$x)*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
            'big5hkscs' => qr{(?(?=.{0,2147483646}\z)(?:$x)*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
            'gb18030'   => qr{(?(?=.{0,2147483646}\z)(?:$x)*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
        }->{$script_encoding} || die;
    }
    elsif ($] >= 5.030000) {
        ${mb::_anchor} = {
            'sjis'      => qr{(?(?=.{0,65534}\z)(?:$x)*?|(?(?=[^\x81-\x9F\xE0-\xFC]+\z).*?|.*?[^\x81-\x9F\xE0-\xFC](?>[\x81-\x9F\xE0-\xFC][\x81-\x9F\xE0-\xFC])*?))}xms,
            'eucjp'     => qr{(?(?=.{0,65534}\z)(?:$x)*?|(?(?=[^\xA1-\xFE\xA1-\xFE]+\z).*?|.*?[^\xA1-\xFE\xA1-\xFE](?>[\xA1-\xFE\xA1-\xFE][\xA1-\xFE\xA1-\xFE])*?))}xms,
            'gbk'       => qr{(?(?=.{0,65534}\z)(?:$x)*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
            'uhc'       => qr{(?(?=.{0,65534}\z)(?:$x)*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
            'big5'      => qr{(?(?=.{0,65534}\z)(?:$x)*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
            'big5hkscs' => qr{(?(?=.{0,65534}\z)(?:$x)*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
            'gb18030'   => qr{(?(?=.{0,65534}\z)(?:$x)*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
        }->{$script_encoding} || die;
    }
    elsif ($] >= 5.010001) {
        ${mb::_anchor} = {
            'sjis'      => qr{(?(?=.{0,32766}\z)(?:$x)*?|(?(?=[^\x81-\x9F\xE0-\xFC]+\z).*?|.*?[^\x81-\x9F\xE0-\xFC](?>[\x81-\x9F\xE0-\xFC][\x81-\x9F\xE0-\xFC])*?))}xms,
            'eucjp'     => qr{(?(?=.{0,32766}\z)(?:$x)*?|(?(?=[^\xA1-\xFE\xA1-\xFE]+\z).*?|.*?[^\xA1-\xFE\xA1-\xFE](?>[\xA1-\xFE\xA1-\xFE][\xA1-\xFE\xA1-\xFE])*?))}xms,
            'gbk'       => qr{(?(?=.{0,32766}\z)(?:$x)*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
            'uhc'       => qr{(?(?=.{0,32766}\z)(?:$x)*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
            'big5'      => qr{(?(?=.{0,32766}\z)(?:$x)*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
            'big5hkscs' => qr{(?(?=.{0,32766}\z)(?:$x)*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
            'gb18030'   => qr{(?(?=.{0,32766}\z)(?:$x)*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
        }->{$script_encoding} || die;
    }
    else {
        ${mb::_anchor} = qr{(?:$x)*?}xms;
    }

    # codepoint class shortcuts in qq-like regular expression
    @{mb::_dot} = "(?>$over_ascii|.)"; # supports /s modifier by /./
    @{mb::_B} = "(?:(?<![$bare_w])(?![$bare_w])|(?<=[$bare_w])(?=[$bare_w]))";
    @{mb::_D} = "(?:(?![0-9])$x)";
    @{mb::_H} = "(?:(?![\\x09\\x20])$x)";
    @{mb::_N} = "(?:(?!\\n)$x)";
    @{mb::_R} = "(?>\\r\\n|[\\x0A\\x0B\\x0C\\x0D])";
    @{mb::_S} = "(?:(?![\\t\\n\\f\\r\\x20])$x)";
    @{mb::_V} = "(?:(?![\\x0A\\x0B\\x0C\\x0D])$x)";
    @{mb::_W} = "(?:(?![A-Za-z0-9_])$x)";
    @{mb::_b} = "(?:(?<![$bare_w])(?=[$bare_w])|(?<=[$bare_w])(?![$bare_w]))";
    @{mb::_d} = "[0-9]";
    @{mb::_h} = "[\\x09\\x20]";
    @{mb::_s} = "[\\t\\n\\f\\r\\x20]";
    @{mb::_v} = "[\\x0A\\x0B\\x0C\\x0D]";
    @{mb::_w} = "[A-Za-z0-9_]";
}

#---------------------------------------------------------------------
# get script encoding name
sub mb::get_script_encoding () {
    return $script_encoding;
}

#---------------------------------------------------------------------
# get old package name
sub mb::get_old_package () {
    return {qw(
        sjis        Sjis::
        gbk         GBK::
        uhc         UHC::
        big5        Big5::
        big5hkscs   Big5HKSCS::
        eucjp       EUCJP::
        gb18030     GB18030::
        rfc2279     RFC2279::
        utf8        UTF2::
        wtf8        WTF8::
    )}->{mb::get_script_encoding()} || die;
}

#---------------------------------------------------------------------
# substr() for MBCS encoding
BEGIN {
    CORE::eval sprintf <<'END', ($] >= 5.014) ? ':lvalue' : '';
#                      VV------------------------AAAAAAA
sub mb::substr ($$;$$) %s {
    my @x = $_[0] =~ /\G$x/g;
    }
}
END
}

#---------------------------------------------------------------------
# tr/// and y/// for MBCS encoding
sub mb::tr ($$$;$) {
    my @x           = $_[0] =~ /\G($x)/xmsg;
    my @search      = list_all_ASCII_by_hyphen($_[1] =~ /\G(\\-|$x)/xmsg);
    my @replacement = list_all_ASCII_by_hyphen($_[2] =~ /\G(\\-|$x)/xmsg);
    my %modifier    = (defined $_[3]) ? (map { $_ => 1 } CORE::split //, $_[3]) : ();

    my %tr = ();
    for (my $i=0; $i <= $#search; $i++) {

        # tr/AAA/123/ works as tr/A/1/
        if (not exists $tr{$search[$i]}) {

            # tr/ABC/123/ makes %tr = ('A'=>'1','B'=>'2','C'=>'3',);
            if (defined($replacement[$i]) and ($replacement[$i] ne '')) {
                $tr{$search[$i]} = $replacement[$i];
            }

            # tr/ABC/12/d makes %tr = ('A'=>'1','B'=>'2','C'=>'',);
            elsif (exists $modifier{d}) {
                $tr{$search[$i]} = '';
            }

            # tr/ABC/12/ makes %tr = ('A'=>'1','B'=>'2','C'=>'2',);
            elsif (defined($replacement[-1]) and ($replacement[-1] ne '')) {
                $tr{$search[$i]} = $replacement[-1];
            }

            # tr/ABC// makes %tr = ('A'=>'A','B'=>'B','C'=>'C',);
            else {
                $tr{$search[$i]} = $search[$i];
            }
        }
    }

    my $tr = 0;
    my $replaced = '';

    # has /c modifier
    if (exists $modifier{c}) {

        # has /s modifier
        if (exists $modifier{s}) {
            my $last_transliterated = undef;
            while (defined(my $x = shift @x)) {

                # /c modifier works here
                if (exists $tr{$x}) {
                    $replaced .= $x;
                    $last_transliterated = undef;
                }
                else {

                    # /d modifier works here
                    if (exists $modifier{d}) {
                    }

                    elsif (defined $replacement[-1]) {

                        # /s modifier works here
                        if (defined($last_transliterated) and ($replacement[-1] eq $last_transliterated)) {
                        }

                        # tr/// works here
                        else {
                            $replaced .= ($last_transliterated = $replacement[-1]);
                        }
                    }
                    $tr++;
                }
            }
        }

        # has no /s modifier
        else {
            while (defined(my $x = shift @x)) {

                # /c modifier works here
                if (exists $tr{$x}) {
                    $replaced .= $x;
                }
                else {

                    # /d modifier works here
                    if (exists $modifier{d}) {
                    }

                    # tr/// works here
                    elsif (defined $replacement[-1]) {
                        $replaced .= $replacement[-1];
                    }
                    $tr++;
                }
            }
        }
    }

    # has no /c modifier
    else {

        # has /s modifier
        if (exists $modifier{s}) {
            my $last_transliterated = undef;
            while (defined(my $x = shift @x)) {
                if (exists $tr{$x}) {

                    # /d modifier works here
                    if ($tr{$x} eq '') {
                    }

                    # /s modifier works here
                    elsif (defined($last_transliterated) and ($tr{$x} eq $last_transliterated)) {
                    }

                    # tr/// works here
                    else {
                        $replaced .= ($last_transliterated = $tr{$x});
                    }
                    $tr++;
                }
                else {
                    $replaced .= $x;
                    $last_transliterated = undef;
                }
            }
        }

        # has no /s modifier
        else {
            while (defined(my $x = shift @x)) {
                if (exists $tr{$x}) {
                    $replaced .= $tr{$x};
                    $tr++;
                }
                else {
                    $replaced .= $x;
                }
            }
        }
    }

    # /r modifier works here
    if (exists $modifier{r}) {
        return $replaced;
    }

    # has no /r modifier
    else {
        $_[0] = $replaced;
        return $tr;
    }
}

#---------------------------------------------------------------------
# universal uc() for MBCS encoding
sub mb::uc (;$) {
    local $_ = @_ ? $_[0] : $_;
    #                          a A b B c C d D e E f F g G h H i I j J k K l L m M n N o O p P q Q r R s S t T u U v V w W x X y Y z Z
    return join '', map { {qw( a A b B c C d D e E f F g G h H i I j J k K l L m M n N o O p P q Q r R s S t T u U v V w W x X y Y z Z )}->{$_}||$_ } /\G$x/g;
    #                          a A b B c C d D e E f F g G h H i I j J k K l L m M n N o O p P q Q r R s S t T u U v V w W x X y Y z Z
}

#---------------------------------------------------------------------
# universal ucfirst() for MBCS encoding
sub mb::ucfirst (;$) {
    local $_ = @_ ? $_[0] : $_;
    if (/\A($x)(.*)\z/s) {
        return mb::uc($1) . $2;
    }
    else {
        return '';
    }
}

######################################################################
# runtime routines on all operating systems (used automatically)
######################################################################

#---------------------------------------------------------------------
# implement of special variable $1,$2,$3,...
sub mb::_CAPTURE (;$) {
    if ($mb::last_s_passed) {
        if (defined $_[0]) {

            # $1 is used for multi-byte anchoring
            return CORE::eval('$' . ($_[0] + 1));
        }
        else {
            my @capture = ();
            if ($] >= 5.006) {

                # $1 is used for multi-byte anchoring in s///
                push @capture, map { CORE::eval('$'.$_) } 2 .. CORE::eval('$#-');
            }
            else {

                # @{^CAPTURE} doesn't work enough in perl 5.005
                for (my $n_th=2; defined(CORE::eval('$'.$n_th)); $n_th++) {
                    push @capture, CORE::eval('$'.$n_th);
                }
            }
            return @capture;
        }
    }
    else {
        if (defined $_[0]) {
            return CORE::eval('$' . $_[0]);
        }
        else {
            my @capture = ();
            if ($] >= 5.006) {
                push @capture, map { CORE::eval('$'.$_) } 1 .. CORE::eval('$#-');
            }
            else {

                # @{^CAPTURE} doesn't work enough in perl 5.005
                for (my $n_th=1; defined(CORE::eval('$'.$n_th)); $n_th++) {
                    push @capture, CORE::eval('$'.$n_th);
                }
            }
            return @capture;
        }
    }
}

#---------------------------------------------------------------------
# implement of special variable @+
sub mb::_LAST_MATCH_END (@) {

    # perl 5.005 does not support @+, so it need CORE::eval

    if ($mb::last_s_passed) {
        if (scalar(@_) >= 1) {
            return CORE::eval q{ ($+[0], @+[2..$#-])[ @_ ] };
        }
        else {
            return CORE::eval q{ ($+[0], @+[2..$#-]) };
        }
    }
    else {
        if (scalar(@_) >= 1) {
            return CORE::eval q{ @+[ @_ ] };
        }
        else {
            return CORE::eval q{ @+ };
        }
    }
}

#---------------------------------------------------------------------
# implement of special variable @-
sub mb::_LAST_MATCH_START (@) {

    # perl 5.005 does not support @-, so it need CORE::eval

    if ($mb::last_s_passed) {
        if (scalar(@_) >= 1) {
            return CORE::eval q{ ($-[2], @-[2..$#-])[ @_ ] };
        }
        else {
            return CORE::eval q{ ($-[2], @-[2..$#-]) };
        }
    }
    else {
        if (scalar(@_) >= 1) {
            return CORE::eval q{ @-[ @_ ] };
        }
        else {
            return CORE::eval q{ @- };
        }
    }
}

#---------------------------------------------------------------------
# implement of special variable $&
sub mb::_MATCH () {
    if (defined $&) {
        if ($mb::last_s_passed) {
            if (defined($1) and (CORE::substr($&, 0, CORE::length($1)) eq $1)) {
                return CORE::substr($&, CORE::length($1));
            }
            else {
                confess 'Use of "$&", $MATCH, and ${^MATCH} need to /( capture all )/ in regexp';
            }
        }
        else {
            if (defined($1) and (CORE::substr($&, -CORE::length($1)) eq $1)) {
                return $1;
            }
            else {
                confess 'Use of "$&", $MATCH, and ${^MATCH} need to /( capture all )/ in regexp';
            }
        }
    }
    else {
        return '';
    }
}

#---------------------------------------------------------------------
# implement of special variable $`
sub mb::_PREMATCH () {
    if (defined $&) {
        if ($mb::last_s_passed) {
            return $1;
        }
        else {
            if (defined($1) and (CORE::substr($&,-CORE::length($1)) eq $1)) {
                return CORE::substr($&, 0, -CORE::length($1));
            }
            else {
                confess 'Use of "$`", $PREMATCH, and ${^PREMATCH} need to /( capture all )/ in regexp';
            }
        }
    }
    else {
        return '';
    }
}

#---------------------------------------------------------------------
# flag off if last m// was pass
sub mb::_m_passed () {
    $mb::last_s_passed = 0;
    return '';
}

#---------------------------------------------------------------------
# flag on if last s/// was pass
sub mb::_s_passed () {
    $mb::last_s_passed = 1;
    return '';
}

#---------------------------------------------------------------------
# ignore space of m/[here]/xx, qr/[here]/xx, s/[here]//xx
sub mb::_ignore_space ($) {
    my($has_space) = @_;
    my $has_no_space = '';

    # parse into elements
    while ($has_space =~ /\G (
        \(\? \^? [a-z]*        [:\)] | # cloister (?^x) (?^x: ...
        \(\? \^? [a-z]*-[a-z]+ [:\)] | # cloister (?^x-y) (?^x-y: ...
        \[ ((?: \\@{mb::_dot} | @{mb::_dot} )+?) \] |
        \\x\{ [0-9A-Fa-f]{2} \}      |
        \\o\{ [0-7]{3}       \}      |
        \\x   [0-9A-Fa-f]{2}         |
        \\    [0-7]{3}               |
        \\@{mb::_dot}                |
        @{mb::_dot}
    ) /xmsgc) {
        my($element, $classmate) = ($1, $2);

        # in codepoint class
        if (defined $classmate) {
            $has_no_space .= '[';
            while ($classmate =~ /\G (
                \\x\{ [0-9A-Fa-f]{2} \} |
                \\o\{ [0-7]{3}       \} |
                \\x   [0-9A-Fa-f]{2}    |
                \\    [0-7]{3}          |
                \\@{mb::_dot}           |
                @{mb::_dot}
            ) /xmsgc) {
                my $element = $1;
                if ($element !~ /\A[$bare_s]\z/) {
                    $has_no_space .= $element;
                }
            }
            $has_no_space .= ']';
        }

        # out of codepoint class
        else {
            $has_no_space .= $element;
        }
    }
    return $has_no_space;
}

#---------------------------------------------------------------------
# ignore case of m//i, qr//i, s///i
sub mb::_ignorecase ($) {
    my($has_case) = @_;
    my $has_no_case = '';

    # parse into elements
    while ($has_case =~ /\G (
        \(\? \^? [a-z]*        [:\)] | # cloister (?^x) (?^x: ...
        \(\? \^? [a-z]*-[a-z]+ [:\)] | # cloister (?^x-y) (?^x-y: ...
        \[ ((?: \\@{mb::_dot} | @{mb::_dot} )+?) \] |
        \\x\{ [0-9A-Fa-f]{2} \}      |
        \\o\{ [0-7]{3}       \}      |
        \\x   [0-9A-Fa-f]{2}         |
        \\    [0-7]{3}               |
        \\@{mb::_dot}                |
        @{mb::_dot}
    ) /xmsgc) {
        my($element, $classmate) = ($1, $2);

        # in codepoint class
        if (defined $classmate) {
            $has_no_case .= '[';
            while ($classmate =~ /\G (
                \\x\{ [0-9A-Fa-f]{2} \} |
                \\o\{ [0-7]{3}       \} |
                \\x   [0-9A-Fa-f]{2}    |
                \\    [0-7]{3}          |
                \\@{mb::_dot}           |
                @{mb::_dot}
            ) /xmsgc) {
                my $element = $1;
                $has_no_case .= {qw(
                    A Aa a Aa
                    B Bb b Bb
                    C Cc c Cc
                    X Xx x Xx
                    Y Yy y Yy
                    Z Zz z Zz
                )}->{$element} || $element;
            }
            $has_no_case .= ']';
        }

        # out of codepoint class
        else {
            $has_no_case .= {qw(
                A [Aa] a [Aa]
                B [Bb] b [Bb]
                C [Cc] c [Cc]
                X [Xx] x [Xx]
                Y [Yy] y [Yy]
                Z [Zz] z [Zz]
            )}->{$element} || $element;
        }
    }
    return qr{$has_no_case};
}

#---------------------------------------------------------------------
# custom codepoint class in qq-like regular expression
sub mb::_cc ($) {
    my($classmate) = @_;
    if ($classmate =~ s{\A \^ }{}xms) {
        return '(?:(?!' . parse_re_codepoint_class($classmate) . ")$x)";
    }
    else {
        return '(?:(?=' . parse_re_codepoint_class($classmate) . ")$x)";
    }
}

#---------------------------------------------------------------------
# makes clustered codepoint from string
sub mb::_clustered_codepoint ($) {
    if (my @codepoint = $_[0] =~ /\G($x)/xmsgc) {
        if (CORE::length($codepoint[$#codepoint]) == 1) {
            return $_[0];
        }
        else {
            return join '', @codepoint[ 0 .. $#codepoint-1 ], "(?:$codepoint[$#codepoint])";
        }
    }
    else {
        return '';
    }
}

#---------------------------------------------------------------------
# open for append -- returns glob-name string on success, "" on failure.
# Works on Perl 5.005_03 and all later versions.
# Always uses a unique numbered package glob (mb::FH::H<n>) so that
# concurrent callers each get their own IO slot.
sub mb::_open_a ($) {
    $mb::_fh_seq++;
    my $fhn = "mb::FH::H$mb::_fh_seq";
    { no strict 'refs'; open($fhn, ">> $_[0]") or return "" }
    return $fhn;
}

#---------------------------------------------------------------------
# open for read -- returns glob-name string on success, "" on failure.
sub mb::_open_r ($) {
    $mb::_fh_seq++;
    my $fhn = "mb::FH::H$mb::_fh_seq";
    { no strict 'refs'; open($fhn, $_[0]) or return "" }
    return $fhn;
}

#---------------------------------------------------------------------
# open for write -- returns glob-name string on success, "" on failure.
sub mb::_open_w ($) {
    $mb::_fh_seq++;
    my $fhn = "mb::FH::H$mb::_fh_seq";
    { no strict 'refs'; open($fhn, "> $_[0]") or return "" }
    return $fhn;
}

#---------------------------------------------------------------------
# split() for MBCS encoding
sub mb::_split (;$$$) {
    my $pattern = defined($_[0]) ? $_[0] : ' ';
    my $string  = defined($_[1]) ? $_[1] : $_;
    my @split = ();

    # split's first argument is more consistently interpreted
    #
    # After some changes earlier in v5.17, split's behavior has been simplified:
    # if the PATTERN argument evaluates to a string containing one space, it is
    # treated the way that a literal string containing one space once was.
    # https://search.cpan.org/dist/perl-5.18.0/pod/perldelta.pod#split's_first_argument_is_more_consistently_interpreted
    # if $pattern is also omitted or is the literal space, " ", the function splits
    # on whitespace, /\s+/, after skipping any leading whitespace

    if ($pattern eq ' ') {
        $pattern = qr/\s+/;
        $string =~ s{\A \s+ }{}xms;
    }

    # count '(' in pattern
    my @parsed = ();
    my $modifier = '';
    if ((($modifier) = $pattern =~ /\A \(\?\^? (.+?) [\)\-\:] /xms) and ($modifier =~ /x/xms)) {
        @parsed = $pattern =~ m{ \G (
            \\ $x              |
            \# .*? $           | # comment on /x modifier
            \(\?\# (?:$x)*? \) |
            \[ (?:$x)+? \]     |
            \(\?               |
            \(\+               |
            \(\*               |
            $x                 |
            [\x00-\xFF]
        ) }xgc;
    }
    else {
        @parsed = $pattern =~ m{ \G (
            \\ $x              |
            \(\?\# (?:$x)*? \) |
            \[ (?:$x)+? \]     |
            \(\?               |
            \(\+               |
            \(\*               |
            $x                 |
            [\x00-\xFF]
        ) }xgc;
    }
    my $last_match_no =
        1 +                                 # first '(' is for substring
        scalar(grep { $_ eq '(' } @parsed); # other '(' are for pattern of split()

    # Repeated Patterns Matching a Zero-length Substring
    # https://perldoc.perl.org/perlre.html#Repeated-Patterns-Matching-a-Zero-length-Substring
    my $substring_quantifier = ('' =~ / \A $pattern \z /xms) ? '+?' : '*?';

    # if $_[2] specified and positive
    if (defined($_[2]) and ($_[2] >= 1)) {
        my $limit = $_[2];

        CORE::eval q{ no warnings }; # avoid: Complex regular subexpression recursion limit (nnnnn) exceeded at ...

        # gets substrings by repeat chopping by pattern
        while ((--$limit > 0) and ($string =~ s<\A((?:$x)$substring_quantifier)$pattern><>)) {
            for (my $n_th=1; $n_th <= $last_match_no; $n_th++) {
                push @split, CORE::eval('$'.$n_th);
            }
        }
    }

    # if $_[2] is omitted or zero or negative
    else {
        CORE::eval q{ no warnings }; # avoid: Complex regular subexpression recursion limit (nnnnn) exceeded at ...

        # gets substrings by repeat chopping by pattern
        while ($string =~ s<\A((?:$x)$substring_quantifier)$pattern><>) {
            for (my $n_th=1; $n_th <= $last_match_no; $n_th++) {
                push @split, CORE::eval('$'.$n_th);
            }
        }
    }

    # get last substring
    if (CORE::length($string) > 0) {
        push @split, $string;
    }
    elsif (defined($_[2]) and ($_[2] >= 1)) {
        if (scalar(@split) < $_[2]) {
            push @split, ('') x ($_[2] - scalar(@split));
        }
    }

    # if $_[2] is omitted or zero, trailing null fields are stripped from the result
    if ((not defined $_[2]) or ($_[2] == 0)) {
        while ((scalar(@split) >= 1) and ($split[-1] eq '')) {
            pop @split;
        }
    }

    # old days, split had write its result to @_ on scalar context,
    # but this usage is no longer supported

    if (wantarray) {
        return @split;
    }
    else {
        return scalar @split;
    }
}

######################################################################
# runtime routines for MSWin32 (used automatically)
######################################################################

#---------------------------------------------------------------------
# chdir() for MSWin32
sub mb::_chdir (;$) {

    # not on MSWin32 or UTF-8
    if (($OSNAME !~ /MSWin32/) or ($script_encoding !~ /\A (?: sjis | gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms)) {
        if (@_ == 0) {
            return CORE::chdir;
        }
        else {
            return CORE::chdir $_[0];
        }
    }

    # on MSWin32
    if (@_ == 0) {
        return CORE::chdir;
    }
    elsif (($script_encoding =~ /\A (?: sjis ) \z/xms) and ($_[0] =~ /\A $x* [\x81-\x9F\xE0-\xFC][\x5C] \z/xms)) {
        if (defined wantarray) {
            return 0;
        }
        else {
            confess "mb::_chdir: Can't chdir '$_[0]'\n";
        }
    }
    elsif (($script_encoding =~ /\A (?: gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms) and ($_[0] =~ /\A $x* [\x81-\xFE][\x5C] \z/xms)) {
        if (defined wantarray) {
            return 0;
        }
        else {
            confess "mb::_chdir: Can't chdir '$_[0]'\n";
        }
    }
    else {
        return CORE::chdir $_[0];
    }
}

#---------------------------------------------------------------------
# stackable filetest -X -Y -Z for MSWin32
sub mb::_filetest {
    my @filetest = map { /(-[A-Za-z])/g } @{ shift(@_) };
    local $_ = @_ ? shift : (($filetest[-1] eq '-t') ? \*STDIN : $_);
    confess "Too many arguments for filetest @filetest" if @_ and not wantarray;

    # testee has "\x5C" octet at end
    if (
        ($OSNAME =~ /MSWin32/) and
        ($script_encoding =~ /\A (?: sjis | gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms) and
        /[\x5C]\z/
    ) {
        $_ = qq{$_.};
    }

    # supports stackable filetest
    my $result;
    my $filetest = pop @filetest;
    if ($result = CORE::eval($filetest . ' $_')) { # '$_' at 1st time, and ...
    }
    else {
        return wantarray ? ($result, @_) : $result;
    }
    for my $filetest (CORE::reverse @filetest) {
        if ($result = CORE::eval($filetest . ' _')) { # '_' at 2nd time or later
        }
        else {
            return wantarray ? ($result, @_) : $result;
        }
    }
    return wantarray ? ($result, @_) : $result;
}

#---------------------------------------------------------------------
# lstat() for MSWin32
sub mb::_lstat (;$) {
    local $_ = @_ ? $_[0] : $_;
    if ($_ eq '_') {
        confess qq{lstat doesn't support '_'\n};
    }

    # testee has "\x5C" octet at end
    if (
        ($OSNAME =~ /MSWin32/) and
        ($script_encoding =~ /\A (?: sjis | gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms) and
        /[\x5C]\z/
    ) {
        $_ = qq{$_.};
    }

    return CORE::lstat $_;
}

#---------------------------------------------------------------------
# opendir() for MSWin32
sub mb::_opendir ($$) {
    if (not defined $_[0]) {
        $_[0] = \do { local *_ };
    }

    # works on MSWin32 only
    if (($OSNAME !~ /MSWin32/) or ($script_encoding !~ /\A (?: sjis | gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms)) {
        return CORE::opendir $_[0], $_[1];
    }
    elsif (-d $_[1]) {
        return CORE::opendir $_[0], $_[1];
    }
    elsif (-d qq{$_[1].}) {
        return CORE::opendir $_[0], qq{$_[1].};
    }
    return undef;
}

#---------------------------------------------------------------------
# stat() for MSWin32
sub mb::_stat (;$) {
    local $_ = @_ ? $_[0] : $_;

    # testee has "\x5C" octet at end
    if (
        ($OSNAME =~ /MSWin32/) and
        ($script_encoding =~ /\A (?: sjis | gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms) and
        /[\x5C]\z/
    ) {
        $_ = qq{$_.};
    }

    return CORE::stat $_;
}

#---------------------------------------------------------------------
# unlink() for MSWin32
sub mb::_unlink (@) {

    # works on MSWin32 only
    if (($OSNAME !~ /MSWin32/) or ($script_encoding !~ /\A (?: sjis | gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms)) {
        return CORE::unlink(@_ ? @_ : $_);
    }

    my $unlink = 0;
    for (@_ ? @_ : $_) {
        if (CORE::unlink) {
            $unlink++;
        }
        elsif (CORE::unlink qq{$_.}) {
            $unlink++;
        }
    }
    return $unlink;
}

######################################################################
# source code filter
######################################################################

#---------------------------------------------------------------------
# detect system encoding any of big5, big5hkscs, eucjp, gb18030, gbk, rfc2279, sjis, uhc, utf8, wtf8
sub detect_system_encoding {

    # running on Microsoft Windows
    if ($OSNAME =~ /MSWin32/) {
        if (my($codepage) = qx{chcp} =~ m/[^0123456789](932|936|949|950|951|20932|54936)\Z/) {
            return {qw(
                932   sjis
                936   gbk
                949   uhc
                950   big5
                951   big5hkscs
                20932 eucjp
                54936 gb18030
            )}->{$codepage};
        }
        else {
            return 'utf8';
        }
    }

    # running on Oracle Solaris
    elsif ($OSNAME =~ /solaris/) {
        my $LANG =
            defined($ENV{'LC_ALL'})   ? $ENV{'LC_ALL'}   :
            defined($ENV{'LC_CTYPE'}) ? $ENV{'LC_CTYPE'} :
            defined($ENV{'LANG'})     ? $ENV{'LANG'}     :
            '';
        return {qw(
            ja_JP.PCK     sjis
            ja            eucjp
            japanese      eucjp
            ja_JP.eucJP   eucjp
            zh            gbk
            zh.GBK        gbk
            zh_CN.GBK     gbk
            zh_CN.EUC     gbk
            zh_CN.GB18030 gb18030
            ko            uhc
            ko_KR.EUC     uhc
            zh_TW.BIG5    big5
            zh_HK.BIG5HK  big5hkscs
        )}->{$LANG} || 'utf8';
    }

    # running on HP HP-UX
    elsif ($OSNAME =~ /hpux/) {
        my $LANG =
            defined($ENV{'LC_ALL'})   ? $ENV{'LC_ALL'}   :
            defined($ENV{'LC_CTYPE'}) ? $ENV{'LC_CTYPE'} :
            defined($ENV{'LANG'})     ? $ENV{'LANG'}     :
            '';
        return {qw(
            japanese      sjis
            ja_JP.SJIS    sjis
            japanese.euc  eucjp
            ja_JP.eucJP   eucjp
            zh_CN.hp15CN  gbk
            zh_CN.gb18030 gb18030
            ko_KR.eucKR   uhc
            zh_TW.big5    big5
            zh_HK.big5    big5hkscs
            zh_HK.hkbig5  big5hkscs
        )}->{$LANG} || 'utf8';
    }

    # running on IBM AIX
    elsif ($OSNAME =~ /aix/) {
        my $LANG =
            defined($ENV{'LC_ALL'})   ? $ENV{'LC_ALL'}   :
            defined($ENV{'LC_CTYPE'}) ? $ENV{'LC_CTYPE'} :
            defined($ENV{'LANG'})     ? $ENV{'LANG'}     :
            '';
        return {qw(
            Ja_JP            sjis
            Ja_JP.IBM-943    sjis
            ja_JP            eucjp
            ja_JP.IBM-eucJP  eucjp
            zh_CN            gbk
            zh_CN.IBM-eucCN  gbk
            Zh_CN            gb18030
            Zh_CN.GB18030    gb18030
            ko_KR            uhc
            ko_KR.IBM-eucKR  uhc
            Zh_TW            big5
            Zh_TW.big-5      big5
            Zh_HK            big5hkscs
            Zh_HK.BIG5-HKSCS big5hkscs
        )}->{$LANG} || 'utf8';
    }

    # running on Other Systems
    else {
        my $LANG =
            defined($ENV{'LC_ALL'})   ? $ENV{'LC_ALL'}   :
            defined($ENV{'LC_CTYPE'}) ? $ENV{'LC_CTYPE'} :
            defined($ENV{'LANG'})     ? $ENV{'LANG'}     :
            '';
        return {qw(
            japanese      sjis
            ja_JP.SJIS    sjis
            ja_JP.mscode  sjis
            zh_TW.Big5    big5
            zh_TW.big5    big5
            zh_HK.big5    big5hkscs
        )}->{$LANG} || 'utf8';
    }
}

my @here_document_delimiter = ();

#---------------------------------------------------------------------
# parse script
sub parse {
    local $_ = @_ ? $_[0] : $_;

    # Yes, I studied study yesterday, once again.
    study $_; # acts between perl 5.005 to perl 5.014

    @here_document_delimiter = ();

    # transpile JPerl script to Perl script
    my $parsed_script = '';
    while (not /\G \z /xmsgc) {
        $parsed_script .= parse_expr();
    }

    # return octet-oriented Perl script
    return $parsed_script;
}

#---------------------------------------------------------------------
# Perl 5.42 introduces source::encoding and automatically enables
# ASCII-only checking for "use v5.41" and later.
#
# mb transpiles scripts to mostly US-ASCII, but it intentionally keeps
# comments and POD as-is. Those may contain multibyte characters.
#
# source::encoding is only activated when "use v5.41" or later appears
# in the script. We append "no source::encoding;" on the same line as
# the "use VERSION" statement (replacing any trailing semicolon first)
# to avoid introducing extra lines that would shift line numbers in
# error messages.
sub _insert_source_encoding_unimport {
    my($script) = @_;

    # append "no source::encoding;" on the same line as "use v5.41" or later,
    # before any trailing comment, to avoid line number shifts in error messages.
    # matches: use v5.41; use v5.42; use 5.041; use 5.042; etc.
    $script =~ s{
        ( \buse \s+
          (?: v5\. (?:4[1-9]|[5-9]\d|\d{3,})   # use v5.41 and later
            | 5\.0(?:4[1-9]|[5-9]\d|\d{3,})      # use 5.041 and later
          )
          [^\n#;]*                                 # rest of statement (no # or ;)
        )
        ;?                                         # consume trailing semicolon
        ( [^\n]* )                                 # trailing comment (if any)
        ( (?:\r\n|\r|\n) )                         # line ending
    }{$1; no source::encoding;$2$3}xmsg;

    return $script;
}

#---------------------------------------------------------------------
# parse ambiguous characters
sub parse_ambiguous_char {
    my $parsed = '';

    # Ambiguous characters
    # --------------------------------------------------------
    # --------------------------------------------------------

    # any term then operator
    if (m{\G ( \s* (?:

    #   12345 | 12345 | 12345 | 12345 | 12345 | 12345 |
        %=    | %     |                                 # "\x25" [%] PERCENT SIGN   (U+0025)
        &&=   | &&    | &\.=  | &\.   | &=    | &     | # "\x26" [&] AMPERSAND      (U+0026)
        \*\*= | \*\*  | \*=   | \*    |                 # "\x2A" [*] ASTERISK       (U+002A)
        \.\.\.| \.\.  | \.=   | \.    |                 # "\x2E" [.] FULL STOP      (U+002E)
        \/\/= | \/\/  | \/=   | \/    |                 # "\x2F" [/] SOLIDUS        (U+002F)
        <=>   | <<    | <=    | <     |                 # "\x3C" [<] LESS-THAN SIGN (U+003C)
        \?                                              # "\x3F" [?] QUESTION MARK  (U+003F)
    )) }xmsgc) {
        $parsed .= $1;
    }

    return $parsed;
}

#---------------------------------------------------------------------
# parse expression in script
sub parse_expr {
    my $parsed = '';
    my $old_package = mb::get_old_package();

    # __END__ or __DATA__
    if (/\G ^ ( (?: __END__ | __DATA__ ) $R .* ) \z/xmsgc) {
        $parsed .= $1;
    }

    # =pod ... =cut
    elsif (/\G ^ ( = [A-Za-z_][A-Za-z_0-9]* [\x00-\xFF]*? $R =cut \b [^\n]* $R ) /xmsgc) {
        $parsed .= $1;
    }

    # "\r\n", "\r", "\n"
    elsif (/\G (?= $R ) /xmsgc) {
        while (my $here_document_delimiter = shift @here_document_delimiter) {
            my($delimiter, $quote_type) = @{$here_document_delimiter};
            if ($quote_type eq 'qq') {
                $parsed .= parse_heredocument_as_qq_endswith($delimiter);
            }
            elsif ($quote_type eq 'q') {

                # perlop > Quote-Like Operators > <<EOF > Single Quotes
                #
                # Single quotes indicate the text is to be treated literally
                # with no interpolation of its content. This is similar to
                # single quoted strings except that backslashes have no special
                # meaning, with \\ being treated as two backslashes and not
                # one as they would in every other quoting construct.
                # https://perldoc.perl.org/perlop.html#Quote-Like-Operators

                $parsed .= parse_heredocument_as_q_endswith($delimiter);
            }
            else {
                die "$0(@{[__LINE__]}): $ARGV[0] here document delimiter '$delimiter' not found.\n";
            }
        }
    }

    # "\t"
    # "\x20" [ ] SPACE (U+0020)
    elsif (/\G ( [\t ]+ ) /xmsgc) {
        $parsed .= $1;
    }

    # "\x3B" [;] SEMICOLON (U+003B)
    elsif (/\G ( ; ) /xmsgc) {
        $parsed .= $1;
    }

    # balanced brackets
    # "\x28" [(] LEFT PARENTHESIS    (U+0028)
    # "\x7B" [{] LEFT CURLY BRACKET  (U+007B)
    # "\x5B" [[] LEFT SQUARE BRACKET (U+005B)
    elsif (/\G ( [(\{\[] ) /xmsgc) {
        $parsed .= parse_expr_balanced($1);
        $parsed .= parse_ambiguous_char();
    }

    # version string
    # v102.111.111
    # 102.111.111
    elsif (/\G (
        v [0-9]+ (?: \.[0-9]+ ){1,} \b |
          [0-9]+ (?: \.[0-9]+ ){2,} \b
    ) /xmsgc) {
        my $v_string = $1;
        $parsed .= join('.', map { "mb::chr($_)" } ($v_string =~ /[0-9]+/g));
        $parsed .= parse_ambiguous_char();
    }

    # version string
    # v9786
    elsif (/\G v ( [0-9]+ ) \b (?! \s* => ) /xmsgc) {
        $parsed .= "mb::chr($1)";
        $parsed .= parse_ambiguous_char();
    }

    # numbers
    # "\x2E" [.] [0-9]
    # "\x30" [0] DIGIT ZERO  (U+0030)
    # "\x31" [1] DIGIT ONE   (U+0031)
    # "\x32" [2] DIGIT TWO   (U+0032)
    # "\x33" [3] DIGIT THREE (U+0033)
    # "\x34" [4] DIGIT FOUR  (U+0034)
    # "\x35" [5] DIGIT FIVE  (U+0035)
    # "\x36" [6] DIGIT SIX   (U+0036)
    # "\x37" [7] DIGIT SEVEN (U+0037)
    # "\x38" [8] DIGIT EIGHT (U+0038)
    # "\x39" [9] DIGIT NINE  (U+0039)
    elsif (m{\G (

# since Perl v5.22 adds hexadecimal floating point literals
# https://perldoc.perl.org/perl5220delta#Floating-point-parsing-has-been-improved
# https://perldoc.perl.org/5.32.0/perldata#Scalar-value-constructors

# https://qiita.com/mod_poppo/items/3fa4cdc35f9bfb352ad5
# https://qiita.com/mod_poppo/items/3fa4cdc35f9bfb352ad5#perl
#
# $ perl -l -e 'print(0x1.23); print(0x1.23p0)'
# makes ==> 123
# makes ==> 1.13671875

        0[Xx] [0-9A-Fa-f_]+ \. [0-9A-Fa-f_]* [Pp] [+-]? [0-9_]+ |
        0[Xx]               \. [0-9A-Fa-f_]+ [Pp] [+-]? [0-9_]+ |
        0[Xx] [0-9A-Fa-f_]+                                     |

# since perl v5.33.5 Core Enhancements New octal syntax 0oddddd

        0[Oo] [0-7_]+ |
        0     [0-7_]* |

        0[Bb] [01_]+  |

        [1-9] [0-9_]* \. [0-9_]* [Ee] [+-]? [0-9_]+ |
        [1-9] [0-9_]*                               |
                      \. [0-9_]+ [Ee] [+-]? [0-9_]+ |
                      \. [0-9_]+

    ) }xmsgc) {
        $parsed .= $1;
        $parsed .= parse_ambiguous_char();
    }

    # file test operators on MSWin32
    # "\x2D" [-] HYPHEN-MINUS (U+002D)
    # -X -Y -Z y///   --> mb::_filetest [qw( -X -Y -Z )], y///
    #          vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    #                                                               vvvvvvvvvvvv  vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    elsif (/\G ( (?: -[ABCMORSTWXbcdefgkloprstuwxz] \s* )+ \b ) (?= (?: \( \s* )* (?: ' | " | ` | \$ | (?: (?: m | q | qq | qr | qw | qx | s | tr | y ) \b )) ) /xmsgc) {
        $parsed .= "mb::_filetest [qw( $1 )], ";
    }

    # filetest file handle or directory handle
    # -X -Y -Z _    --> mb::_filetest [qw( -X -Y -Z )], \*_
    # -X -Y -Z FILE --> mb::_filetest [qw( -X -Y -Z )], \*FILE
    #          vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    #            vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv       vvvvvvvvvvvvvvvvvvvvvvvvvvvv
    elsif (/\G ( (?: -[ABCMORSTWXbcdefgkloprstuwxz] \s* )+ \b ) (?= [A-Za-z_][A-Za-z0-9_]* ) /xmsgc) {
        $parsed .= "mb::_filetest [qw( $1)], ";
        $parsed .= '\\*';
    }

    # -X -Y -Z ... --> mb::_filetest [qw( -X -Y -Z )], ...
    #          vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    #            vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    elsif (/\G ( (?: -[ABCMORSTWXbcdefgkloprstuwxz] \s* )+ \b ) /xmsgc) {
        $parsed .= "mb::_filetest [qw( $1)]";
        if (my $ambiguous_char = parse_ambiguous_char()) {
            $parsed .= $ambiguous_char;
        }
        else {
            $parsed .= ', ';
        }
    }

    # yada-yada or triple-dot operator
    elsif (/\G ( \.\.\. ) /xmsgc) {
        $parsed .= $1;
    }

    # -> and any method
    elsif (/\G ( -> \s* [A-Za-z_][A-Za-z_0-9]* ) /xmsgc) {
        $parsed .= $1;
    }

    # symbolic operators
    elsif (/\G (

    #   12345 | 12345 | 12345 | 12345 | 12345 | 12345 |
        !=    | !~    | !     |                         # "\x21" [!] EXCLAMATION MARK  (U+0021)
        \+\+  | \+=   | \+    |                         # "\x2B" [+] PLUS SIGN         (U+002B)
        ,     |                                         # "\x2C" [,] COMMA             (U+002C)
        --    | -=    | ->    | -     |                 # "\x2D" [-] HYPHEN-MINUS      (U+002D)
        ==    | =>    | =~    | =     |                 # "\x3D" [=] EQUALS SIGN       (U+003D)
        >>    | >=    | >     |                         # "\x3E" [>] GREATER-THAN SIGN (U+003E)
        \\    |                                         # "\x5C" [\] REVERSE SOLIDUS   (U+005C)
        \^\^= | \^\^  | \^\.= | \^\.  | \^=   | \^    | # "\x5E" [^] CIRCUMFLEX ACCENT (U+005E)
        \|\|= | \|\|  | \|\.= | \|\.  | \|=   | \|    | # "\x7C" [|] VERTICAL LINE     (U+007C)
        ~~    | ~\.   | ~=    | ~                       # "\x7E" [~] TILDE             (U+007E)

    ) /xmsgc) {
        $parsed .= $1;
    }

    # named operators
    elsif (/\G ( (?: and | cmp | eq | ge | gt | isa | le | lt | ne | not | or | x | x= | xor ) \b ) /xmsgc) {
        $parsed .= $1;
    }

    # $`           --> mb::_PREMATCH()
    # ${`}         --> mb::_PREMATCH()
    # $PREMATCH    --> mb::_PREMATCH()
    # ${PREMATCH}  --> mb::_PREMATCH()
    # ${^PREMATCH} --> mb::_PREMATCH()
    elsif (/\G (?: \$` | \$\{`\} | \$PREMATCH | \$\{PREMATCH\} | \$\{\^PREMATCH\} ) /xmsgc) {
        $parsed .= 'mb::_PREMATCH()';
        $parsed .= parse_ambiguous_char();
    }

    # $&        --> mb::_MATCH()
    # ${&}      --> mb::_MATCH()
    # $MATCH    --> mb::_MATCH()
    # ${MATCH}  --> mb::_MATCH()
    # ${^MATCH} --> mb::_MATCH()
    elsif (/\G (?: \$& | \$\{&\} | \$MATCH | \$\{MATCH\} | \$\{\^MATCH\} ) /xmsgc) {
        $parsed .= 'mb::_MATCH()';
        $parsed .= parse_ambiguous_char();
    }

    # $1 --> mb::_CAPTURE(1)
    # $2 --> mb::_CAPTURE(2)
    # $3 --> mb::_CAPTURE(3)
    elsif (/\G \$ ([1-9][0-9]*) /xmsgc) {
        $parsed .= "mb::_CAPTURE($1)";
        $parsed .= parse_ambiguous_char();
    }

    # @{^CAPTURE} --> mb::_CAPTURE()
    elsif (/\G \@\{\^CAPTURE\} /xmsgc) {
        $parsed .= 'mb::_CAPTURE()';
        $parsed .= parse_ambiguous_char();
    }

    # ${^CAPTURE}[0] --> mb::_CAPTURE(1)
    # ${^CAPTURE}[1] --> mb::_CAPTURE(2)
    # ${^CAPTURE}[2] --> mb::_CAPTURE(3)
    elsif (/\G \$\{\^CAPTURE\} \s* (\[) /xmsgc) {
        my $n_th = quotee_of(parse_expr_balanced($1));
        $parsed .= "mb::_CAPTURE($n_th+1)";
        $parsed .= parse_ambiguous_char();
    }

    # @-                   --> mb::_LAST_MATCH_START()
    # @LAST_MATCH_START    --> mb::_LAST_MATCH_START()
    # @{LAST_MATCH_START}  --> mb::_LAST_MATCH_START()
    # @{^LAST_MATCH_START} --> mb::_LAST_MATCH_START()
    elsif (/\G (?: \@- | \@LAST_MATCH_START | \@\{LAST_MATCH_START\} | \@\{\^LAST_MATCH_START\} ) /xmsgc) {
        $parsed .= 'mb::_LAST_MATCH_START()';
        $parsed .= parse_ambiguous_char();
    }

    # $-[1]                   --> mb::_LAST_MATCH_START(1)
    # $LAST_MATCH_START[1]    --> mb::_LAST_MATCH_START(1)
    # ${LAST_MATCH_START}[1]  --> mb::_LAST_MATCH_START(1)
    # ${^LAST_MATCH_START}[1] --> mb::_LAST_MATCH_START(1)
    elsif (/\G (?: \$- | \$LAST_MATCH_START | \$\{LAST_MATCH_START\} | \$\{\^LAST_MATCH_START\} ) \s* (\[) /xmsgc) {
        my $n_th = quotee_of(parse_expr_balanced($1));
        $parsed .= "mb::_LAST_MATCH_START($n_th)";
        $parsed .= parse_ambiguous_char();
    }

    # @+                 --> mb::_LAST_MATCH_END()
    # @LAST_MATCH_END    --> mb::_LAST_MATCH_END()
    # @{LAST_MATCH_END}  --> mb::_LAST_MATCH_END()
    # @{^LAST_MATCH_END} --> mb::_LAST_MATCH_END()
    elsif (/\G (?: \@\+ | \@LAST_MATCH_END | \@\{LAST_MATCH_END\} | \@\{\^LAST_MATCH_END\} ) /xmsgc) {
        $parsed .= 'mb::_LAST_MATCH_END()';
        $parsed .= parse_ambiguous_char();
    }

    # $+[1]                 --> mb::_LAST_MATCH_END(1)
    # $LAST_MATCH_END[1]    --> mb::_LAST_MATCH_END(1)
    # ${LAST_MATCH_END}[1]  --> mb::_LAST_MATCH_END(1)
    # ${^LAST_MATCH_END}[1] --> mb::_LAST_MATCH_END(1)
    elsif (/\G (?: \$\+ | \$LAST_MATCH_END | \$\{LAST_MATCH_END\} | \$\{\^LAST_MATCH_END\} ) \s* (\[) /xmsgc) {
        my $n_th = quotee_of(parse_expr_balanced($1));
        $parsed .= "mb::_LAST_MATCH_END($n_th)";
        $parsed .= parse_ambiguous_char();
    }

    # CORE::do      { block } --> CORE::do      { block }
    # CORE::eval    { block } --> CORE::eval    { block }
    # CORE::try     { block } --> CORE::try     { block }
    # CORE::finally { block } --> CORE::finally { block }
    elsif (/\G ( CORE:: (?: do | eval | try | finally ) \s* ) ( \{ ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_expr_balanced($2);
        $parsed .= parse_ambiguous_char();
    }

    # mb::do      { block } --> do      { block }
    # mb::eval    { block } --> eval    { block }
    # mb::try     { block } --> try     { block }
    # mb::finally { block } --> finally { block }
    # do          { block } --> do      { block }
    # eval        { block } --> eval    { block }
    # try         { block } --> try     { block }
    # finally     { block } --> finally { block }
    elsif (/\G (?: mb:: | $old_package )? ( (?: do | eval | try | finally ) \s* ) ( \{ ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_expr_balanced($2);
        $parsed .= parse_ambiguous_char();
    }

    # $#{}, ${}, @{}, %{}, &{}, *{}, defer {}, sub {}
    # "\x24" [$] DOLLAR SIGN (U+0024)
    elsif (/\G ((?: \$[#] | [\$\@%&*] | defer | sub ) \s* ) ( \{ ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_expr_balanced($2);
        $parsed .= parse_ambiguous_char();
    }

    # mb::do   --> mb::do
    # CORE::do --> CORE::do
    # do       --> do
    elsif (/\G ( (?: mb:: | CORE:: )? do ) \b /xmsgc) {
        $parsed .= $1;
    }

    # mb::eval   --> mb::eval
    # CORE::eval --> CORE::eval
    # eval       --> eval
    elsif (/\G ( (?: mb:: | CORE:: )? eval ) \b /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_ambiguous_char();
    }

    # last index of array
    elsif (/\G ( [\$] [#] (?: [A-Za-z_][A-Za-z_0-9]*(?:(?:'|::)[A-Za-z_][A-Za-z_0-9]*)* ) ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_ambiguous_char();
    }

    # scalar variable
    elsif (/\G (     [\$] [\$]* (?: [A-Za-z_][A-Za-z_0-9]*(?:(?:'|::)[A-Za-z_][A-Za-z_0-9]*)* | ^\{[A-Za-z_][A-Za-z_0-9]*\} | [0-9]+ | [!"#\$%&'()+,\-.\/:;<=>?\@\[\\\]\^_`|~] ) (?: \s* (?: \+\+ | -- ) )? ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_ambiguous_char();
    }

    # array variable
    # "\x40" [@] COMMERCIAL AT (U+0040)
    elsif (/\G (   [\@\$] [\$]* (?: [A-Za-z_][A-Za-z_0-9]*(?:(?:'|::)[A-Za-z_][A-Za-z_0-9]*)* | [_] ) ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_ambiguous_char();
    }

    # hash variable
    elsif (/\G ( [\%\@\$] [\$]* (?: [A-Za-z_][A-Za-z_0-9]*(?:(?:'|::)[A-Za-z_][A-Za-z_0-9]*)* | [!+\-] ) ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_ambiguous_char();
    }

    # user subroutine call
    # type glob
    elsif (/\G (     [&*] [\$]* (?: [A-Za-z_][A-Za-z_0-9]*(?:(?:'|::)[A-Za-z_][A-Za-z_0-9]*)* ) ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_ambiguous_char();
    }

    # comment
    # "\x23" [#] NUMBER SIGN (U+0023)
    elsif (/\G ( [#] [^\n]* ) /xmsgc) {
        $parsed .= $1;
    }

    # 2-quotes

    # '...'
    # "\x27" ['] APOSTROPHE (U+0027)
    elsif (m{\G ( ' ) }xmsgc) {
        $parsed .= parse_q__like_endswith($1);
        $parsed .= parse_ambiguous_char();
    }

    # "...", `...`
    # "\x22" ["] QUOTATION MARK (U+0022)
    # "\x60" [`] GRAVE ACCENT   (U+0060)
    elsif (m{\G ( ["`] ) }xmsgc) {
        $parsed .= parse_qq_like_endswith($1);
        $parsed .= parse_ambiguous_char();
    }

    # /.../
    elsif (m{\G ( [/] ) }xmsgc) {
        my $regexp = parse_re_endswith('m',$1);
        my($modifier_i, $modifier_not_cegir, $modifier_cegr) = parse_re_modifier();

        # /xx modifier
        if (($modifier_not_cegir =~ tr/x//) >= 2) {
            $regexp = mb::_ignore_space($regexp);
        }

        # /i modifier
        if ($modifier_i) {
            $parsed .= sprintf('m{\\G${mb::_anchor}@{[mb::_ignorecase(qr%s%s)]}@{[mb::_m_passed()]}}%s', $regexp, $modifier_not_cegir, $modifier_cegr);
        }
        else {
            $parsed .= sprintf('m{\\G${mb::_anchor}@{[' .            'qr%s%s ]}@{[mb::_m_passed()]}}%s', $regexp, $modifier_not_cegir, $modifier_cegr);
        }
        $parsed .= parse_ambiguous_char();
    }

    # ?...?
    elsif (m{\G ( [?] ) }xmsgc) {
        my $regexp = parse_re_endswith('m',$1);
        my($modifier_i, $modifier_not_cegir, $modifier_cegr) = parse_re_modifier();

        # /xx modifier
        if (($modifier_not_cegir =~ tr/x//) >= 2) {
            $regexp = mb::_ignore_space($regexp);
        }

        # /i modifier
        if ($modifier_i) {
            $parsed .= sprintf('m{\\G${mb::_anchor}@{[mb::_ignorecase(qr%s%s)]}@{[mb::_m_passed()]}}%s', $regexp, $modifier_not_cegir, $modifier_cegr);
        }
        else {
            $parsed .= sprintf('m{\\G${mb::_anchor}@{[' .            'qr%s%s ]}@{[mb::_m_passed()]}}%s', $regexp, $modifier_not_cegir, $modifier_cegr);
        }
        $parsed .= parse_ambiguous_char();
    }

    # <<>> double-diamond operator
    elsif (/\G ( <<>> ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_ambiguous_char();
    }

    # <FILE> diamond operator
    # <${file}>
    # <$file>
    # <fileglob>
    elsif (/\G (<) ((?:(?!\s)$x)*?) (>) /xmsgc) {
        my($open_bracket, $quotee, $close_bracket) = ($1, $2, $3);
        $parsed .= $open_bracket;
        while ($quotee =~ /\G ($x) /xmsgc) {
            $parsed .= escape_qq($1, $close_bracket);
        }
        $parsed .= $close_bracket;
        $parsed .= parse_ambiguous_char();
    }

    # qw/.../, q/.../
    elsif (/\G ( qw | q ) \b /xmsgc) {
        $parsed .= $1;
        if    (/\G ( [#] )        /xmsgc) { $parsed .= parse_q__like_endswith($1); }
        elsif (/\G ( ['] )        /xmsgc) { $parsed .= parse_q__like_endswith($1); }
        elsif (/\G ( [\(\{\[\<] ) /xmsgc) { $parsed .= parse_q__like_balanced($1); }
        elsif (m{\G( [/] )        }xmsgc) { $parsed .= parse_q__like_endswith($1); }
        elsif (/\G ( [\S] )       /xmsgc) { $parsed .= parse_q__like_endswith($1); }
        elsif (/\G ( \s+ )        /xmsgc) { $parsed .= $1;
            while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                $parsed .= $1;
            }
            if    (/\G ( [A-Za-z_0-9] ) /xmsgc) { $parsed .= parse_q__like_endswith($1); }
            elsif (/\G ( ['] )          /xmsgc) { $parsed .= parse_q__like_endswith($1); }
            elsif (/\G ( [\(\{\[\<] )   /xmsgc) { $parsed .= parse_q__like_balanced($1); }
            elsif (m{\G( [/] )          }xmsgc) { $parsed .= parse_q__like_endswith($1); }
            elsif (/\G ( [\S] )         /xmsgc) { $parsed .= parse_q__like_endswith($1); }
            else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        }
        else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        $parsed .= parse_ambiguous_char();
    }

    # qq/.../
    elsif (/\G ( qq ) \b /xmsgc) {
        $parsed .= $1;
        if    (/\G ( [#] )        /xmsgc) { $parsed .= parse_qq_like_endswith($1); }
        elsif (/\G ( ['] )        /xmsgc) { $parsed .= parse_qq_like_endswith($1); } # qq'...' works as "..."
        elsif (/\G ( [\(\{\[\<] ) /xmsgc) { $parsed .= parse_qq_like_balanced($1); }
        elsif (m{\G( [/] )        }xmsgc) { $parsed .= parse_qq_like_endswith($1); }
        elsif (/\G ( [\S] )       /xmsgc) { $parsed .= parse_qq_like_endswith($1); }
        elsif (/\G ( \s+ )        /xmsgc) { $parsed .= $1;
            while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                $parsed .= $1;
            }
            if    (/\G ( [A-Za-z_0-9] ) /xmsgc) { $parsed .= parse_qq_like_endswith($1); }
            elsif (/\G ( ['] )          /xmsgc) { $parsed .= parse_qq_like_endswith($1); } # qq'...' works as "..."
            elsif (/\G ( [\(\{\[\<] )   /xmsgc) { $parsed .= parse_qq_like_balanced($1); }
            elsif (m{\G( [/] )          }xmsgc) { $parsed .= parse_qq_like_endswith($1); }
            elsif (/\G ( [\S] )         /xmsgc) { $parsed .= parse_qq_like_endswith($1); }
            else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        }
        else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        $parsed .= parse_ambiguous_char();
    }

    # qx/.../
    elsif (/\G ( qx ) \b /xmsgc) {
        $parsed .= $1;
        if    (/\G ( [#] )        /xmsgc) { $parsed .= parse_qq_like_endswith($1); }
        elsif (/\G ( ['] )        /xmsgc) { $parsed .= parse_q__like_endswith($1); }
        elsif (/\G ( [\(\{\[\<] ) /xmsgc) { $parsed .= parse_qq_like_balanced($1); }
        elsif (m{\G( [/] )        }xmsgc) { $parsed .= parse_qq_like_endswith($1); }
        elsif (/\G ( [\S] )       /xmsgc) { $parsed .= parse_qq_like_endswith($1); }
        elsif (/\G ( \s+ )        /xmsgc) { $parsed .= $1;
            while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                $parsed .= $1;
            }
            if    (/\G ( [A-Za-z_0-9] ) /xmsgc) { $parsed .= parse_qq_like_endswith($1); }
            elsif (/\G ( ['] )          /xmsgc) { $parsed .= parse_q__like_endswith($1); }
            elsif (/\G ( [\(\{\[\<] )   /xmsgc) { $parsed .= parse_qq_like_balanced($1); }
            elsif (m{\G( [/] )          }xmsgc) { $parsed .= parse_qq_like_endswith($1); }
            elsif (/\G ( [\S] )         /xmsgc) { $parsed .= parse_qq_like_endswith($1); }
            else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        }
        else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        $parsed .= parse_ambiguous_char();
    }

    # m/.../, qr/.../
    elsif (/\G ( m | qr ) \b /xmsgc) {
        $parsed .= $1;
        my $regexp = '';
        if    (/\G ( [#] )        /xmsgc) { $regexp .= parse_re_endswith('m',$1);      }       # qr#...#
        elsif (/\G ( ['] )        /xmsgc) { $regexp .= parse_re_as_q_endswith('m',$1); }       # qr'...'
        elsif (/\G ( [\(\{\[\<] ) /xmsgc) { $regexp .= parse_re_balanced('m',$1);      }       # qr{...}
        elsif (m{\G( [/] )        }xmsgc) { $regexp .= parse_re_endswith('m',$1);      }       # qr/.../
        elsif (/\G ( [:\@] )      /xmsgc) { $regexp .= ('`' . quotee_of(parse_re_endswith('m',$1)) . '`'); } # qr@...@
        elsif (/\G ( [\S] )       /xmsgc) { $regexp .= parse_re_endswith('m',$1);      }       # qr?...?
        elsif (/\G ( \s+ )        /xmsgc) { $parsed .= $1; $regexp .= $1;                      # qr SPACE ...
            while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                $parsed .= $1;
            }
            if    (/\G ( [A-Za-z_0-9] ) /xmsgc) { $regexp .= parse_re_endswith('m',$1);      } # qr SPACE A...A
            elsif (/\G ( ['] )          /xmsgc) { $regexp .= parse_re_as_q_endswith('m',$1); } # qr SPACE '...'
            elsif (/\G ( [\(\{\[\<] )   /xmsgc) { $regexp .= parse_re_balanced('m',$1);      } # qr SPACE {...}
            elsif (m{\G( [/] )          }xmsgc) { $regexp .= parse_re_endswith('m',$1);      } # qr SPACE /.../
            elsif (/\G ( [:\@] )        /xmsgc) { $regexp .= ('`' . quotee_of(parse_re_endswith('m',$1)) . '`'); } # qr SPACE @...@
            elsif (/\G ( [\S] )         /xmsgc) { $regexp .= parse_re_endswith('m',$1);      } # qr SPACE ?...?
            else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        }
        else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }

        my($modifier_i, $modifier_not_cegir, $modifier_cegr) = parse_re_modifier();

        # /xx modifier
        if (($modifier_not_cegir =~ tr/x//) >= 2) {
            $regexp = mb::_ignore_space($regexp);
        }

        # /i modifier
        if ($modifier_i) {
            $parsed .= sprintf('{\\G${mb::_anchor}@{[mb::_ignorecase(qr%s%s)]}@{[mb::_m_passed()]}}%s', $regexp, $modifier_not_cegir, $modifier_cegr);
        }
        else {
            $parsed .= sprintf('{\\G${mb::_anchor}@{[' .            'qr%s%s ]}@{[mb::_m_passed()]}}%s', $regexp, $modifier_not_cegir, $modifier_cegr);
        }
        $parsed .= parse_ambiguous_char();
    }

    # 3-quotes

    # s/.../.../
    elsif (/\G ( s ) \b /xmsgc) {
        $parsed .= $1;
        my $regexp = '';
        my $comment = '';
        my @replacement = ();
        if    (/\G ( [#] )        /xmsgc) { $regexp .= parse_re_endswith('s',$1);      @replacement = parse_qq_like_endswith($1); }       # s#...#...#
        elsif (/\G ( ['] )        /xmsgc) { $regexp .= parse_re_as_q_endswith('s',$1); @replacement = parse_qq_like_endswith($1); }       # s'...'...'
        elsif (/\G ( [\(\{\[\<] ) /xmsgc) { $regexp .= parse_re_balanced('s',$1);                                                         # s{...}...
            if    (/\G ( [#] )        /xmsgc) { @replacement = parse_qq_like_endswith($1); }                                              # s{}#...#
            elsif (/\G ( ['] )        /xmsgc) { @replacement = parse_qq_like_endswith($1); }                                              # s{}'...'
            elsif (/\G ( [\(\{\[\<] ) /xmsgc) { @replacement = parse_qq_like_balanced($1); }                                              # s{}{...}
            elsif (m{\G( [/] )        }xmsgc) { @replacement = parse_qq_like_endswith($1); }                                              # s{}/.../
            elsif (/\G ( [\S] )       /xmsgc) { @replacement = parse_qq_like_endswith($1); }                                              # s{}?...?
            elsif (/\G ( \s+ )        /xmsgc) { $comment .= $1;                                                                           # s{} SPACE ...
                while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                    $comment .= $1;
                }
                if    (/\G ( [A-Za-z_0-9] ) /xmsgc) { @replacement = parse_qq_like_endswith($1); }                                        # s{} SPACE A...A
                elsif (/\G ( ['] )          /xmsgc) { @replacement = parse_qq_like_endswith($1); }                                        # s{} SPACE '...'
                elsif (/\G ( [\(\{\[\<] )   /xmsgc) { @replacement = parse_qq_like_balanced($1); }                                        # s{} SPACE {...}
                elsif (m{\G( [/] )          }xmsgc) { @replacement = parse_qq_like_endswith($1); }                                        # s{} SPACE /.../
                elsif (/\G ( [\S] )         /xmsgc) { @replacement = parse_qq_like_endswith($1); }                                        # s{} SPACE ?...?
                else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
            }
            else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        }
        elsif (m{\G( [/] )        }xmsgc) { $regexp .= parse_re_endswith('s',$1); @replacement = parse_qq_like_endswith($1); }            # s/.../.../
        elsif (/\G ( [:\@] )      /xmsgc) { $regexp .= ('`' . quotee_of(parse_re_endswith('s',$1)) . '`');
                                                                                  @replacement = parse_qq_like_endswith($1); }            # s@...@...@
        elsif (/\G ( [\S] )       /xmsgc) { $regexp .= parse_re_endswith('s',$1); @replacement = parse_qq_like_endswith($1); }            # s?...?...?
        elsif (/\G ( \s+ )        /xmsgc) { $parsed .= $1; $regexp .= $1;                                                                 # s SPACE ...
            while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                $parsed .= $1;
            }
            if    (/\G ( [A-Za-z_0-9] ) /xmsgc) { $regexp .= parse_re_endswith('s',$1);      @replacement = parse_qq_like_endswith($1); } # s SPACE A...A...A
            elsif (/\G ( ['] )          /xmsgc) { $regexp .= parse_re_as_q_endswith('s',$1); @replacement = parse_qq_like_endswith($1); } # s SPACE '...'...'
            elsif (/\G ( [\(\{\[\<] )   /xmsgc) { $regexp .= parse_re_balanced('s',$1);                                                   # s SPACE {...}...
                if    (/\G ( [#] )        /xmsgc) { @replacement = parse_qq_like_endswith($1); }                                          # s SPACE {}#...#
                elsif (/\G ( ['] )        /xmsgc) { @replacement = parse_qq_like_endswith($1); }                                          # s SPACE {}'...'
                elsif (/\G ( [\(\{\[\<] ) /xmsgc) { @replacement = parse_qq_like_balanced($1); }                                          # s SPACE {}{...}
                elsif (m{\G( [/] )        }xmsgc) { @replacement = parse_qq_like_endswith($1); }                                          # s SPACE {}/.../
                elsif (/\G ( [\S] )       /xmsgc) { @replacement = parse_qq_like_endswith($1); }                                          # s SPACE {}?...?
                elsif (/\G ( \s+ )        /xmsgc) { $comment .= $1;                                                                       # s SPACE {} SPACE ...
                    while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                        $comment .= $1;
                    }
                    if    (/\G ( [A-Za-z_0-9] ) /xmsgc) { @replacement = parse_qq_like_endswith($1); }                                    # s SPACE {} SPACE A...A
                    elsif (/\G ( ['] )          /xmsgc) { @replacement = parse_qq_like_endswith($1); }                                    # s SPACE {} SPACE '...'
                    elsif (/\G ( [\(\{\[\<] )   /xmsgc) { @replacement = parse_qq_like_balanced($1); }                                    # s SPACE {} SPACE {...}
                    elsif (m{\G( [/] )          }xmsgc) { @replacement = parse_qq_like_endswith($1); }                                    # s SPACE {} SPACE /.../
                    elsif (/\G ( [\S] )         /xmsgc) { @replacement = parse_qq_like_endswith($1); }                                    # s SPACE {} SPACE ?...?
                    else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
                }
                else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
            }
            elsif (m{\G( [/] )          }xmsgc) { $regexp .= parse_re_endswith('s',$1); @replacement = parse_qq_like_endswith($1); }      # s SPACE /.../.../
            elsif (/\G ( [:\@] )        /xmsgc) { $regexp .= ('`' . quotee_of(parse_re_endswith('s',$1)) . '`');
                                                                                        @replacement = parse_qq_like_endswith($1); }      # s SPACE @...@...@
            elsif (/\G ( [\S] )         /xmsgc) { $regexp .= parse_re_endswith('s',$1); @replacement = parse_qq_like_endswith($1); }      # s SPACE ?...?...?
            else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        }
        else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }

        my($modifier_i, $modifier_not_cegir, $modifier_cegr) = parse_re_modifier();
        my $replacement = '';
        my $eval = '';

        # has /e modifier
        if (my $e = $modifier_cegr =~ tr/e//d) {
            $replacement = 'q'. $replacement[1]; # q-type quotee
            $eval = 'mb::eval ' x $e;
        }

        # s''q-quotee'
        elsif ($replacement[0] =~ /\A ' /xms) {
            $replacement = $replacement[1]; # q-type quotee
        }

        # s##qq-quotee#
        elsif ($replacement[0] =~ /\A [#] /xms) {
            $replacement = 'qq' . $replacement[0]; # qq-type quotee
        }

        # s//qq-quotee/
        else {
            $replacement = 'qq ' . $replacement[0]; # qq-type quotee
        }

        # /xx modifier
        if (($modifier_not_cegir =~ tr/x//) >= 2) {
            $regexp = mb::_ignore_space($regexp);
        }

        # /i modifier
        if ($modifier_i) {
            $parsed .= sprintf('{(\\G${mb::_anchor})@{[mb::_ignorecase(qr%s%s)]}@{[mb::_s_passed()]}}%s{$1 . %s%s}e%s', $regexp, $modifier_not_cegir, $comment, $eval, $replacement, $modifier_cegr);
        }
        else {
            $parsed .= sprintf('{(\\G${mb::_anchor})@{[' .            'qr%s%s ]}@{[mb::_s_passed()]}}%s{$1 . %s%s}e%s', $regexp, $modifier_not_cegir, $comment, $eval, $replacement, $modifier_cegr);
        }
        $parsed .= parse_ambiguous_char();
    }

    # tr/.../.../, y/.../.../
    elsif (/\G (?: tr | y ) \b /xmsgc) {
        $parsed .= 's'; # not 'tr'
        my $search = '';
        my $comment = '';
        my $replacement = '';
        if    (/\G ( [#] )        /xmsgc) { $search .= parse_tr_like_endswith($1); $replacement .= parse_tr_like_endswith($1); }       # tr#...#...#
        elsif (/\G ( ['] )        /xmsgc) { $search .= parse_tr_like_endswith($1); $replacement .= parse_tr_like_endswith($1); }       # tr'...'...'
        elsif (/\G ( [\(\{\[\<] ) /xmsgc) { $search .= parse_tr_like_balanced($1);                                                     # tr{...}...
            if    (/\G ( [#] )        /xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                          # tr{}#...#
            elsif (/\G ( ['] )        /xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                          # tr{}'...'
            elsif (/\G ( [\(\{\[\<] ) /xmsgc) { $replacement .= parse_tr_like_balanced($1); }                                          # tr{}{...}
            elsif (m{\G( [/] )        }xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                          # tr{}/.../
            elsif (/\G ( [\S] )       /xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                          # tr{}?...?
            elsif (/\G ( \s+ )        /xmsgc) { $comment .= $1;                                                                        # tr{} SPACE ...
                while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                    $comment .= $1;
                }
                if    (/\G ( [A-Za-z_0-9] ) /xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                    # tr{} SPACE A...A
                elsif (/\G ( ['] )          /xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                    # tr{} SPACE '...'
                elsif (/\G ( [\(\{\[\<] )   /xmsgc) { $replacement .= parse_tr_like_balanced($1); }                                    # tr{} SPACE {...}
                elsif (m{\G( [/] )          }xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                    # tr{} SPACE /.../
                elsif (/\G ( [\S] )         /xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                    # tr{} SPACE ?...?
                else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
            }
            else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        }
        elsif (m{\G( [/] )        }xmsgc) { $search .= parse_tr_like_endswith($1); $replacement .= parse_tr_like_endswith($1); }       # tr/.../.../
        elsif (/\G ( [\S] )       /xmsgc) { $search .= parse_tr_like_endswith($1); $replacement .= parse_tr_like_endswith($1); }       # tr?...?...?
        elsif (/\G ( \s+ )        /xmsgc) { $parsed .= $1;                                                                             # tr SPACE ...
            while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                $parsed .= $1;
            }
            if    (/\G ( [A-Za-z_0-9] ) /xmsgc) { $search .= parse_tr_like_endswith($1); $replacement .= parse_tr_like_endswith($1); } # tr SPACE A...A...A
            elsif (/\G ( ['] )          /xmsgc) { $search .= parse_tr_like_endswith($1); $replacement .= parse_tr_like_endswith($1); } # tr SPACE '...'...'
            elsif (/\G ( [\(\{\[\<] )   /xmsgc) { $search .= parse_tr_like_balanced($1);                                               # tr SPACE {...}...
                if    (/\G ( [#] )        /xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                      # tr SPACE {}#...#
                elsif (/\G ( ['] )        /xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                      # tr SPACE {}'...'
                elsif (/\G ( [\(\{\[\<] ) /xmsgc) { $replacement .= parse_tr_like_balanced($1); }                                      # tr SPACE {}{...}
                elsif (m{\G( [/] )        }xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                      # tr SPACE {}/.../
                elsif (/\G ( [\S] )       /xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                      # tr SPACE {}?...?
                elsif (/\G ( \s+ )        /xmsgc) { $comment .= $1;                                                                    # tr SPACE {} SPACE ...
                    while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                        $comment .= $1;
                    }
                    if    (/\G ( [A-Za-z_0-9] ) /xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                # tr SPACE {} SPACE A...A
                    elsif (/\G ( ['] )          /xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                # tr SPACE {} SPACE '...'
                    elsif (/\G ( [\(\{\[\<] )   /xmsgc) { $replacement .= parse_tr_like_balanced($1); }                                # tr SPACE {} SPACE {...}
                    elsif (m{\G( [/] )          }xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                # tr SPACE {} SPACE /.../
                    elsif (/\G ( [\S] )         /xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                # tr SPACE {} SPACE ?...?
                    else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
                }
                else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
            }
            elsif (m{\G( [/] )          }xmsgc) { $search .= parse_tr_like_endswith($1); $replacement .= parse_tr_like_endswith($1); } # tr SPACE /.../.../
            elsif (/\G ( [\S] )         /xmsgc) { $search .= parse_tr_like_endswith($1); $replacement .= parse_tr_like_endswith($1); } # tr SPACE ?...?...?
            else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        }
        else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }

        # modifier
        my($modifier_not_r, $modifier_r) = parse_tr_modifier();
        if ($modifier_r) {
            $parsed .= sprintf(q<{[\x00-\xFF]*}%s{mb::tr($&,q%s,q%s,'%sr')}ser>, $comment, $search, $replacement, $modifier_not_r);
        }
        elsif ($modifier_not_r =~ /s/) {

            # this implementation cannot return right count of codepoints replaced.
            # if you want right count, you can call mb::tr() yourself.
            $parsed .= sprintf(q<{[\x00-\xFF]+}%s{mb::tr($&,q%s,q%s,'%sr')}se>,  $comment, $search, $replacement, $modifier_not_r);
        }
        else {

            # $parsed .= sprintf(q<{@{mb::_dot}}%s{mb::tr($&,q%s,q%s,'%sr')}msge>, $comment, $search, $replacement, $modifier_not_r);
            #------------------------------------------------------------------------------------------------------------------------------------------------
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/cds; ($r,$_) } => (2,AAABBCA)

            # better idea of mine
            if ($modifier_not_r =~ /c/) {
                $parsed .= sprintf(q<{(\\G${mb::_anchor})((?!%s)@{mb::_dot})}%s{$1.mb::tr($2,q%s,q%s,'%sr')}sge>, codepoint_tr($search), $comment, $search, $replacement, $modifier_not_r);
            }
            else {
                $parsed .= sprintf(q<{(\\G${mb::_anchor})((?=%s)@{mb::_dot})}%s{$1.mb::tr($2,q%s,q%s,'%sr')}sge>, codepoint_tr($search), $comment, $search, $replacement, $modifier_not_r);
            }
            #------------------------------------------------------------------------------------------------------------------------------------------------
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/;    ($r,$_) } => (7,111222DE1)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/s;   ($r,$_) } => (1,12DE1)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/d;   ($r,$_) } => (7,11122DE1)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/ds;  ($r,$_) } => (1,12DE1)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/c;   ($r,$_) } => (2,AAABBC22A)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/cs;  ($r,$_) } => (1,AAABBC2A)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/cd;  ($r,$_) } => (2,AAABBCA)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/cds; ($r,$_) } => (1,AAABBCA)
        }
        $parsed .= parse_ambiguous_char();
    }

    # indented here document
    elsif (/\G ( <<~ ) /xmsgc) {
        $parsed .= $1;
        if    (/\G (         ([A-Za-z_][A-Za-z_0-9]*)  ) /xmsgc) { $parsed .= $1; push @here_document_delimiter, ["[\\t ]*$2$R", 'qq']; }
        elsif (/\G (       \\([A-Za-z_][A-Za-z_0-9]*)  ) /xmsgc) { $parsed .= $1; push @here_document_delimiter, ["[\\t ]*$2$R", 'q' ]; }
        elsif (/\G ( [\t ]* '([A-Za-z_][A-Za-z_0-9]*)' ) /xmsgc) { $parsed .= $1; push @here_document_delimiter, ["[\\t ]*$2$R", 'q' ]; }
        elsif (/\G ( [\t ]* "([A-Za-z_][A-Za-z_0-9]*)" ) /xmsgc) { $parsed .= $1; push @here_document_delimiter, ["[\\t ]*$2$R", 'qq']; }
        elsif (/\G ( [\t ]* `([A-Za-z_][A-Za-z_0-9]*)` ) /xmsgc) { $parsed .= $1; push @here_document_delimiter, ["[\\t ]*$2$R", 'qq']; }
        else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        $parsed .= parse_ambiguous_char();
    }

    # here document
    elsif (/\G ( << ) /xmsgc) {
        $parsed .= $1;
        if    (/\G (         ([A-Za-z_][A-Za-z_0-9]*)  ) /xmsgc) { $parsed .= $1; push @here_document_delimiter, [       "$2$R", 'qq']; }
        elsif (/\G (       \\([A-Za-z_][A-Za-z_0-9]*)  ) /xmsgc) { $parsed .= $1; push @here_document_delimiter, [       "$2$R", 'q' ]; }
        elsif (/\G ( [\t ]* '([A-Za-z_][A-Za-z_0-9]*)' ) /xmsgc) { $parsed .= $1; push @here_document_delimiter, [       "$2$R", 'q' ]; }
        elsif (/\G ( [\t ]* "([A-Za-z_][A-Za-z_0-9]*)" ) /xmsgc) { $parsed .= $1; push @here_document_delimiter, [       "$2$R", 'qq']; }
        elsif (/\G ( [\t ]* `([A-Za-z_][A-Za-z_0-9]*)` ) /xmsgc) { $parsed .= $1; push @here_document_delimiter, [       "$2$R", 'qq']; }
        else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        $parsed .= parse_ambiguous_char();
    }

    # sub subroutine();
    elsif (/\G ( sub \s+ [A-Za-z_][A-Za-z_0-9]*(?:(?:'|::)[A-Za-z_][A-Za-z_0-9]*)* \s* ) /xmsgc) {
        $parsed .= $1;
    }

    # while (<<>>)
    elsif (/\G ( while \s* \( \s* ) ( <<>> ) ( \s* \) ) /xmsgc) {
        $parsed .= $1;
        $parsed .= $2;
        $parsed .= $3;
    }

    # while (<${file}>)
    # while (<$file>)
    # while (<FILE>)
    # while (<fileglob>)
    elsif (/\G ( while \s* \( \s* ) (<) ((?:(?!\s)$x)*?) (>) ( \s* \) ) /xmsgc) {
        $parsed .= $1;
        my($open_bracket, $quotee, $close_bracket) = ($2, $3, $4);
        my $close_bracket2 = $5;
        $parsed .= $open_bracket;
        while ($quotee =~ /\G ($x) /xmsgc) {
            $parsed .= escape_qq($1, $close_bracket);
        }
        $parsed .= $close_bracket;
        $parsed .= $close_bracket2;
    }

    # while <<>>
    elsif (/\G ( while \s* ) ( <<>> ) /xmsgc) {
        $parsed .= $1;
        $parsed .= $2;
    }

    # while <${file}>
    # while <$file>
    # while <FILE>
    # while <fileglob>
    elsif (/\G ( while \s* ) (<) ((?:(?!\s)$x)*?) (>) /xmsgc) {
        $parsed .= $1;
        my($open_bracket, $quotee, $close_bracket) = ($2, $3, $4);
        $parsed .= $open_bracket;
        while ($quotee =~ /\G ($x) /xmsgc) {
            $parsed .= escape_qq($1, $close_bracket);
        }
        $parsed .= $close_bracket;
    }

    # if          (expr)
    # elsif       (expr)
    # unless      (expr)
    # while       (expr)
    # until       (expr)
    # given       (expr)
    # when        (expr)
    # CORE::catch (expr)
    # catch       (expr)
    elsif (/\G ( (?: if | elsif | unless | while | until | given | when | (?: CORE:: )? catch ) \s* ) ( \( ) /xmsgc) {
        $parsed .= $1;

        # outputs expr
        my $expr = parse_expr_balanced($2);
        $parsed .= $expr;
    }

    # mb::catch (expr) --> catch (expr)
    elsif (/\G mb:: ( catch \s* ) ( \( ) /xmsgc) {
        $parsed .= $1;

        # outputs expr
        my $expr = parse_expr_balanced($2);
        $parsed .= $expr;
    }

    # else
    elsif (/\G ( else ) \b /xmsgc) {
        $parsed .= $1;
    }

    # ... if     expr;
    # ... unless expr;
    # ... while  expr;
    # ... until  expr;
    elsif (/\G ( if | unless | while | until ) \b /xmsgc) {
        $parsed .= $1;
    }

    # foreach my $var (expr) --> foreach my $var (expr)
    # for     my $var (expr) --> for     my $var (expr)
    elsif (/\G ( (?: foreach | for ) \s+ my \s* [\$] [A-Za-z_][A-Za-z_0-9]* ) ( \( ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_expr_balanced($2);
    }

    # foreach $var (expr) --> foreach $var (expr)
    # for     $var (expr) --> for     $var (expr)
    elsif (/\G ( (?: foreach | for ) \s* [\$] [\$]* (?: \{[A-Za-z_][A-Za-z_0-9]*(?:(?:'|::)[A-Za-z_][A-Za-z_0-9]*)*\} | [A-Za-z_][A-Za-z_0-9]*(?:(?:'|::)[A-Za-z_][A-Za-z_0-9]* ) ) ) ( \( ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_expr_balanced($2);
    }

    # foreach (expr1; expr2; expr3) --> foreach (expr1; expr2; expr3)
    # foreach (expr)                --> foreach (expr)
    # for     (expr1; expr2; expr3) --> for     (expr1; expr2; expr3)
    # for     (expr)                --> for     (expr)
    elsif (/\G ( (?: foreach | for ) \s* ) ( \( ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_expr_balanced($2);
    }

    # CORE::split --> mb::_split
    # mb::split   --> mb::_split
    # split       --> mb::_split
    elsif (/\G (?: CORE:: | mb:: | $old_package )? ( split ) \b /xmsgc) {
        $parsed .= "mb::_split";

        # parse \s and '('
        while (1) {
            if (/\G ( \s+ ) /xmsgc) {
                $parsed .= $1;
            }
            elsif (/\G ( \( ) /xmsgc) {
                $parsed .= $1;
            }
            elsif (/\G ( \# .* \n ) /xmgc) {
                $parsed .= $1;
                last;
            }
            else {
                last;
            }
        }
        my $regexp = '';

        # split /^/   --> mb::_split qr/^/m
        # split /.../ --> mb::_split qr/.../
        if (m{\G ( [/] )  }xmsgc) {
            $parsed .= "qr";
            $regexp = parse_re_endswith('m',$1);                                                   # split /.../
            my($modifier_i, $modifier_not_cegir, $modifier_cegr) = parse_re_modifier();

            # P.794 29.2.161. split
            # in Chapter 29: Functions
            # of ISBN 0-596-00027-8 Programming Perl Third Edition.

            # P.951 split
            # in Chapter 27: Functions
            # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

            # said "The //m modifier is assumed when you split on the pattern /^/",
            # but perl5.008 is not so. Therefore, this software adds //m.
            # (and so on)

            if ($modifier_not_cegir !~ /m/xms) {
                $modifier_not_cegir .= 'm';
            }

            # /xx modifier
            if (($modifier_not_cegir =~ tr/x//) >= 2) {
                $regexp = mb::_ignore_space($regexp);
            }

            # /i modifier
            if ($modifier_i) {
                $parsed .= sprintf('{@{[mb::_ignorecase(qr%s%s)]}}%s', $regexp, $modifier_not_cegir, $modifier_cegr);
            }
            else {
                $parsed .= sprintf('{@{[' .            'qr%s%s ]}}%s', $regexp, $modifier_not_cegir, $modifier_cegr);
            }
        }

        # split m/^/   --> mb::_split qr/^/m
        # split m/.../ --> mb::_split qr/.../
        elsif (/\G ( m | qr ) \b /xmsgc) {
            $parsed .= "qr";

            if    (/\G ( [#] )        /xmsgc) { $regexp = parse_re_endswith('m',$1);      }        # split qr#...#
            elsif (/\G ( ['] )        /xmsgc) { $regexp = parse_re_as_q_endswith('m',$1); }        # split qr'...'
            elsif (/\G ( [\(\{\[\<] ) /xmsgc) { $regexp = parse_re_balanced('m',$1);      }        # split qr{...}
            elsif (m{\G( [/] )        }xmsgc) { $regexp = parse_re_endswith('m',$1);      }        # split qr/.../
            elsif (/\G ( [:\@] )      /xmsgc) { $regexp = ('`' . quotee_of(parse_re_endswith('m',$1)) . '`'); } # split qr@...@
            elsif (/\G ( [\S] )       /xmsgc) { $regexp = parse_re_endswith('m',$1);      }        # split qr?...?
            elsif (/\G ( \s+ )        /xmsgc) { $parsed .= $1; $regexp = $1;                       # split qr SPACE ...
                while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                    $parsed .= $1;
                }
                if    (/\G ( [A-Za-z_0-9] ) /xmsgc) { $regexp .= parse_re_endswith('m',$1);      } # split qr SPACE A...A
                elsif (/\G ( ['] )          /xmsgc) { $regexp .= parse_re_as_q_endswith('m',$1); } # split qr SPACE '...'
                elsif (/\G ( [\(\{\[\<] )   /xmsgc) { $regexp .= parse_re_balanced('m',$1);      } # split qr SPACE {...}
                elsif (m{\G( [/] )          }xmsgc) { $regexp .= parse_re_endswith('m',$1);      } # split qr SPACE /.../
                elsif (/\G ( [:\@] )        /xmsgc) { $regexp .= ('`' . quotee_of(parse_re_endswith('m',$1)) . '`'); } # split qr SPACE @...@
                elsif (/\G ( [\S] )         /xmsgc) { $regexp .= parse_re_endswith('m',$1);      } # split qr SPACE ?...?
                else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
            }
            else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }

            my($modifier_i, $modifier_not_cegir, $modifier_cegr) = parse_re_modifier();

            if ($modifier_not_cegir !~ /m/xms) {
                $modifier_not_cegir .= 'm';
            }

            # /xx modifier
            if (($modifier_not_cegir =~ tr/x//) >= 2) {
                $regexp = mb::_ignore_space($regexp);
            }

            # /i modifier
            if ($modifier_i) {
                $parsed .= sprintf('{@{[mb::_ignorecase(qr%s%s)]}}%s', $regexp, $modifier_not_cegir, $modifier_cegr);
            }
            else {
                $parsed .= sprintf('{@{[' .            'qr%s%s ]}}%s', $regexp, $modifier_not_cegir, $modifier_cegr);
            }
        }

        $parsed .= parse_ambiguous_char();
    }

    # provides bare Perl and JPerl compatible functions
    elsif (/\G ( (?: lc | lcfirst | uc | ucfirst ) ) \b /xmsgc) {
        $parsed .= "mb::$1";
        $parsed .= parse_ambiguous_char();
    }

    # CORE::require, mb::require, require
    elsif (/\G ( (?: CORE:: | mb:: )? require ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_ambiguous_char();
    }

    # mb::use --> BEGIN { mb::require ... }
    # mb::no  --> BEGIN { mb::require ... }
    elsif (/\G ( mb::use | mb::no ) \b /xmsgc) {
        my $method = { 'mb::use'=>'import', 'mb::no'=>'unimport' }->{$1} || die;
        $parsed .= "BEGIN { mb::require";
        while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
            $parsed .= $1;
        }
        if (/\G ( [A-Za-z_][A-Za-z_0-9]* (?: ::[A-Za-z_][A-Za-z_0-9]*)* ) /xmsgc) {
            my $module = $1;
            $parsed .= qq{'$module';};
            while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                $parsed .= $1;
            }
            if (/\G ( [0-9]+ (?: \.[0-9]+)* ) /xmsgc) {
                my $version = $1;
                $parsed .= qq{$module->VERSION($version);};
                while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                    $parsed .= $1;
                }
            }
            my $list = parse_expr_endswith(qr< [;\}] | \z >xms);
            if ($list eq '') {
                $parsed .= qq{ $module->$method; };
            }
            elsif (scalar(CORE::eval("()=$list")) == 0) {
            }
            else {
                $parsed .= qq{ $module->$method($list); };
            }
        }
        $parsed .= "}";
    }

    # mb::getc() --> mb::getc()
    #                       vvvvvvvvvvvvvvvvvvvvvvvvvv
    #                           vvvvvvvvvvvv
    elsif (/\G ( mb::getc ) (?= (?: \s* \( )+ \s* \) ) /xmsgc) {
        $parsed .= $1;
    }

    # mb::getc($fh) --> mb::getc($fh)
    # mb::getc $fh  --> mb::getc $fh
    #                       vvvvvvvvvvvvvvvvvvvvvvvvvv
    #                           vvvvvvvvvvvv
    elsif (/\G ( mb::getc ) (?= (?: \s* \( )* \s* \$ ) /xmsgc) {
        $parsed .= $1;
    }

    # mb::getc(FILE) --> mb::getc(\*FILE)
    # mb::getc FILE  --> mb::getc \*FILE
    #                          vvvvvvvvvvvvvvvvvvvvv
    #                            vvvvvvvvvvvv        vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    elsif (/\G ( mb::getc ) \b ( (?: \s* \( )* \s* ) (?= [A-Za-z_][A-Za-z0-9_]* \b ) /xmsgc) {
        $parsed .= $1;
        $parsed .= $2;
        $parsed .= '\\*';
    }

    # mb::getc --> mb::getc
    elsif (/\G ( mb::getc ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_ambiguous_char();
    }

    # CORE::functions that allow zero parameters
    # mb::functions that allow zero parameters
    elsif (/\G ( (?: CORE:: | mb:: )? (?:
        chop    |
        chr     |
        getc    |
        lc      |
        lcfirst |
        length  |
        ord     |
        uc      |
        ucfirst
    ) ) \b /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_ambiguous_char();
    }

    # CORE::functions that must parameters
    # mb::functions that must parameters
    elsif (/\G ( (?: CORE:: | mb:: )? (?:
        index   |
        reverse |
        rindex  |
        substr
    ) ) \b /xmsgc) {
        $parsed .= $1;
    }

    # mb::subroutines
    elsif (/\G ( mb:: (?: index_byte | rindex_byte ) ) \b /xmsgc) {
        $parsed .= $1;
    }

    # CORE::functions that allow zero parameters
    # functions that allow zero parameters
    elsif (/\G ( (?: CORE:: )? (?:
        _         |
        abs       |
        chomp     |
        cos       |
        exp       |
        fc        |
        hex       |
        int       |
        __LINE__  |
        log       |
        oct       |
        pop       |
        pos       |
        quotemeta |
        rand      |
        rmdir     |
        shift     |
        sin       |
        sqrt      |
        tell      |
        time      |
        umask     |
        wantarray
    ) ) \b /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_ambiguous_char();
    }

    # lstat(), stat() on MSWin32

    # lstat() --> mb::_lstat()
    # stat()  --> mb::_stat()
    #                           vvvvvvvvvvvvvvvvvvvvvvvvvv
    #                               vvvvvvvvvvvv
    elsif (/\G ( lstat | stat ) (?= (?: \s* \( )+ \s* \) ) /xmsgc) {
        $parsed .= "mb::_$1";
    }

    # lstat(...) --> mb::_lstat(...)
    # stat(...)  --> mb::_stat(...)
    #                           vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    #                               vvvvvvvvvvvv     vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    elsif (/\G ( lstat | stat ) (?= (?: \s* \( )* \b (?: ' | " | ` | m | q | qq | qr | qw | qx | s | tr | y | \$ ) \b ) /xmsgc) {
        $parsed .= "mb::_$1";
    }

    # lstat(FILE)  --> mb::_lstat(\*FILE)
    # lstat FILE   --> mb::_lstat \*FILE
    # stat(FILE)   --> mb::_stat(\*FILE)
    # stat FILE    --> mb::_stat \*FILE
    #                              vvvvvvvvvvvvvvvvvvvvv
    #                                vvvvvvvvvvvv        vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    elsif (/\G ( lstat | stat ) \b ( (?: \s* \( )* \s* ) (?= [A-Za-z_][A-Za-z0-9_]* \b ) /xmsgc) {
        $parsed .= "mb::_$1";
        $parsed .= $2;
        $parsed .= '\\*';
    }

    # opendir(DIR, ...) --> mb::_opendir(\*DIR, ...)
    # opendir DIR, ...  --> mb::_opendir \*DIR, ...
    #                         vvvvvvvvvvvvvvvvvvvvv
    #                           vvvvvvvvvvvv        vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    elsif (/\G ( opendir ) \b ( (?: \s* \( )* \s* ) (?= [A-Za-z_][A-Za-z0-9_]* \s* , ) /xmsgc) {
        $parsed .= "mb::_$1";
        $parsed .= $2;
        $parsed .= '\\*';
    }

    # function --> mb::subroutine on MSWin32
    # implements run on any systems by transpiling once
    elsif (/\G ( chdir | lstat | stat | unlink ) \b /xmsgc) {
        $parsed .= "mb::_$1";
        $parsed .= parse_ambiguous_char();
    }
    elsif (/\G ( opendir ) \b /xmsgc) {
        $parsed .= "mb::_$1";
    }

    # Carp::carp    <<HEREDOC
    # Carp::cluck   <<HEREDOC
    # Carp::confess <<HEREDOC
    # Carp::croak   <<HEREDOC
    # carp          <<HEREDOC
    # cluck         <<HEREDOC
    # confess       <<HEREDOC
    # croak         <<HEREDOC
    # die           <<HEREDOC
    # print         <<HEREDOC
    # printf        <<HEREDOC
    # say           <<HEREDOC
    # warn          <<HEREDOC
    elsif (/\G (
        Carp::carp    |
        Carp::cluck   |
        Carp::confess |
        Carp::croak   |
        carp          |
        cluck         |
        confess       |
        croak         |
        die           |
        print         |
        printf        |
        say           |
        warn
    ) (?= (?: \s+ | [#] .* )* << ) /xgc) {
        $parsed .= $1;
        # without $parsed .= parse_ambiguous_char();
    }

    # printf FILEHANDLE <<HEREDOC
    # print  FILEHANDLE <<HEREDOC
    # say    FILEHANDLE <<HEREDOC
    elsif (/\G (
        (?: printf | print | say )
        (?: \s+ | [#] .* )*
        (?! [a-z]+ ) # lowercase is considered to be function
        (?: \b [A-Za-z_][A-Za-z_0-9]*(?: :: [A-Za-z_][A-Za-z_0-9]*)* |
            \$ [A-Za-z_][A-Za-z_0-9]*(?: :: [A-Za-z_][A-Za-z_0-9]*)*
        )
    ) /xgc) {
        $parsed .= $1;
        # without $parsed .= parse_ambiguous_char();
    }

    # printf {FILEHANDLE} <<HEREDOC
    # print  {FILEHANDLE} <<HEREDOC
    # say    {FILEHANDLE} <<HEREDOC
    elsif (/\G (
        (?: printf | print | say )
        (?: \s+ | [#] .* )*
        ) (\{)
    /xgc) {
        $parsed .= $1;
        $parsed .= parse_expr_balanced($2);
        # without $parsed .= parse_ambiguous_char();
    }

    # return
    elsif (/\G ( return ) /xmsgc) {
        $parsed .= $1;
    }

    # any word
    # "\x5F" [_] LOW LINE (U+005F)
    # "\x78" [x] LATIN SMALL LETTER X   (U+0078)
    # "\x79" [y] LATIN SMALL LETTER Y   (U+0079)
    # "\x7A" [z] LATIN SMALL LETTER Z   (U+007A)
    elsif (/\G ( [A-Za-z_][A-Za-z_0-9]*(?:(?:'|::)[A-Za-z_][A-Za-z_0-9]*)* ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_ambiguous_char();
    }

    # any right parenthesis
    # "\x29" [)] RIGHT PARENTHESIS    (U+0029)
    # "\x7D" [}] RIGHT CURLY BRACKET  (U+007D)
    # "\x5D" []] RIGHT SQUARE BRACKET (U+005D)
    elsif (/\G ([\)\}\]]) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_ambiguous_char();
    }

    # any US-ASCII
    # "\x3A" [:] COLON (U+003A)
    elsif (/\G ([\x00-\x7F]) /xmsgc) {
        $parsed .= $1;
    }

    # otherwise
    elsif (/\G ($x) /xmsgc) {
        die "$0(@{[__LINE__]}): can't parse not US-ASCII '$1'.\n";
    }

    return $parsed;
}

#---------------------------------------------------------------------
# parse expression in balanced blackets
sub parse_expr_balanced {
    my($open_bracket) = @_;
    my $close_bracket = {qw| ( ) { } [ ] < > |}->{$open_bracket} || die;
    my $parsed = $open_bracket;
    my $nest_bracket = 1;
    while (1) {

        # open bracket
        if (/\G (\Q$open_bracket\E) /xmsgc) {
            $parsed .= $1;
            $nest_bracket++;
        }

        # close bracket
        elsif (/\G (\Q$close_bracket\E) /xmsgc) {
            $parsed .= $1;
            $parsed .= parse_ambiguous_char();
            if (--$nest_bracket <= 0) {
                last;
            }
        }

        # otherwise
        else {
            $parsed .= parse_expr();
        }
    }
    return $parsed;
}

#---------------------------------------------------------------------
# parse expression that ends with a regexp
sub parse_expr_endswith {
    my($endswith) = @_;
    my $parsed = '';
    while (1) {
        if (/\G (?= $endswith ) /xmsgc) {
            last;
        }
        else {
            $parsed .= parse_expr();
        }
    }
    return $parsed;
}

#---------------------------------------------------------------------
# parse <<'HERE_DOCUMENT' as q-like
sub parse_heredocument_as_q_endswith {
    my($endswith) = @_;
    my $parsed = '';
    while (1) {
        if (/\G ( $R $endswith ) /xmsgc) {
            $parsed .= $1;
            last;
        }
        elsif (/\G ($x) /xmsgc) {
            $parsed .= $1;
        }

        # something wrong happened
        else {
            die sprintf(<<END, pos($_), CORE::substr($_,pos($_)));
$0(@{[__LINE__]}): something wrong happened in script at pos=%s
------------------------------------------------------------------------------
%s
------------------------------------------------------------------------------
END
        }
    }
    return $parsed;
}

#---------------------------------------------------------------------
# parse <<"HERE_DOCUMENT" as qq-like
sub parse_heredocument_as_qq_endswith {
    my($endswith) = @_;
    my $parsed = '';
    my $nest_escape = 0;
    while (1) {
        if (/\G ( $R $endswith ) /xmsgc) {
            $parsed .= ('>)]}' x $nest_escape);
            $parsed .= $1;
            last;
        }

        # \L\u --> \u\L
        elsif (/\G \\L \\u /xmsgc) {
            $parsed .= '@{[mb::ucfirst(qq<';
            $parsed .= '@{[mb::lc(qq<';
            $nest_escape++;
            $nest_escape++;
        }

        # \U\l --> \l\U
        elsif (/\G \\U \\l /xmsgc) {
            $parsed .= '@{[mb::lcfirst(qq<';
            $parsed .= '@{[mb::uc(qq<';
            $nest_escape++;
            $nest_escape++;
        }

        # \L
        elsif (/\G \\L /xmsgc) {
            $parsed .= '@{[mb::lc(qq<';
            $nest_escape++;
        }

        # \U
        elsif (/\G \\U /xmsgc) {
            $parsed .= '@{[mb::uc(qq<';
            $nest_escape++;
        }

        # \l
        elsif (/\G \\l /xmsgc) {
            $parsed .= '@{[mb::lcfirst(qq<';
            $nest_escape++;
        }

        # \u
        elsif (/\G \\u /xmsgc) {
            $parsed .= '@{[mb::ucfirst(qq<';
            $nest_escape++;
        }

        # \Q
        elsif (/\G \\Q /xmsgc) {
            $parsed .= '@{[quotemeta(qq<';
            $nest_escape++;
        }

        # \E
        elsif (/\G \\E /xmsgc) {
            $parsed .= ('>)]}' x $nest_escape);
            $nest_escape = 0;
        }

        # \o{...}
        elsif (/\G \\o\{ (.*?) \} /xmsgc) {
            $parsed .= escape_to_hex(mb::chr(oct $1), '\\');
        }

        # \x{...}
        elsif (/\G \\x\{ (.*?) \} /xmsgc) {
            $parsed .= escape_to_hex(mb::chr(hex $1), '\\');
        }

        # \any
        elsif (/\G (\\) ($x) /xmsgc) {
            $parsed .= ($1 . escape_qq($2, '\\'));
        }

        # $`           --> @{[mb::_PREMATCH()]}
        # ${`}         --> @{[mb::_PREMATCH()]}
        # $PREMATCH    --> @{[mb::_PREMATCH()]}
        # ${PREMATCH}  --> @{[mb::_PREMATCH()]}
        # ${^PREMATCH} --> @{[mb::_PREMATCH()]}
        elsif (/\G (?: \$` | \$\{`\} | \$PREMATCH | \$\{PREMATCH\} | \$\{\^PREMATCH\} ) /xmsgc) {
            $parsed .= '@{[mb::_PREMATCH()]}';
        }

        # $&        --> @{[mb::_MATCH()]}
        # ${&}      --> @{[mb::_MATCH()]}
        # $MATCH    --> @{[mb::_MATCH()]}
        # ${MATCH}  --> @{[mb::_MATCH()]}
        # ${^MATCH} --> @{[mb::_MATCH()]}
        elsif (/\G (?: \$& | \$\{&\} | \$MATCH | \$\{MATCH\} | \$\{\^MATCH\} ) /xmsgc) {
            $parsed .= '@{[mb::_MATCH()]}';
        }

        # $1 --> @{[mb::_CAPTURE(1)]}
        # $2 --> @{[mb::_CAPTURE(2)]}
        # $3 --> @{[mb::_CAPTURE(3)]}
        elsif (/\G \$ ([1-9][0-9]*) /xmsgc) {
            $parsed .= "\@{[mb::_CAPTURE($1)]}";
        }

        # @{^CAPTURE} --> @{[mb::_CAPTURE()]}
        elsif (/\G \@\{\^CAPTURE\} /xmsgc) {
            $parsed .= '@{[mb::_CAPTURE()]}';
        }

        # ${^CAPTURE}[0] --> @{[mb::_CAPTURE(1)]}
        # ${^CAPTURE}[1] --> @{[mb::_CAPTURE(2)]}
        # ${^CAPTURE}[2] --> @{[mb::_CAPTURE(3)]}
        elsif (/\G \$\{\^CAPTURE\} \s* (\[) /xmsgc) {
            my $n_th = quotee_of(parse_expr_balanced($1));
            $parsed .= "\@{[mb::_CAPTURE($n_th+1)]}";
        }

        # @-                   --> @{[mb::_LAST_MATCH_START()]}
        # @LAST_MATCH_START    --> @{[mb::_LAST_MATCH_START()]}
        # @{LAST_MATCH_START}  --> @{[mb::_LAST_MATCH_START()]}
        # @{^LAST_MATCH_START} --> @{[mb::_LAST_MATCH_START()]}
        elsif (/\G (?: \@- | \@LAST_MATCH_START | \@\{LAST_MATCH_START\} | \@\{\^LAST_MATCH_START\} ) /xmsgc) {
            $parsed .= '@{[mb::_LAST_MATCH_START()]}';
        }

        # $-[1]                   --> @{[mb::_LAST_MATCH_START(1)]}
        # $LAST_MATCH_START[1]    --> @{[mb::_LAST_MATCH_START(1)]}
        # ${LAST_MATCH_START}[1]  --> @{[mb::_LAST_MATCH_START(1)]}
        # ${^LAST_MATCH_START}[1] --> @{[mb::_LAST_MATCH_START(1)]}
        elsif (/\G (?: \$- | \$LAST_MATCH_START | \$\{LAST_MATCH_START\} | \$\{\^LAST_MATCH_START\} ) \s* (\[) /xmsgc) {
            my $n_th = quotee_of(parse_expr_balanced($1));
            $parsed .= "\@{[mb::_LAST_MATCH_START($n_th)]}";
        }

        # @+                 --> @{[mb::_LAST_MATCH_END()]}
        # @LAST_MATCH_END    --> @{[mb::_LAST_MATCH_END()]}
        # @{LAST_MATCH_END}  --> @{[mb::_LAST_MATCH_END()]}
        # @{^LAST_MATCH_END} --> @{[mb::_LAST_MATCH_END()]}
        elsif (/\G (?: \@\+ | \@LAST_MATCH_END | \@\{LAST_MATCH_END\} | \@\{\^LAST_MATCH_END\} ) /xmsgc) {
            $parsed .= '@{[mb::_LAST_MATCH_END()]}';
        }

        # $+[1]                 --> @{[mb::_LAST_MATCH_END(1)]}
        # $LAST_MATCH_END[1]    --> @{[mb::_LAST_MATCH_END(1)]}
        # ${LAST_MATCH_END}[1]  --> @{[mb::_LAST_MATCH_END(1)]}
        # ${^LAST_MATCH_END}[1] --> @{[mb::_LAST_MATCH_END(1)]}
        elsif (/\G (?: \$\+ | \$LAST_MATCH_END | \$\{LAST_MATCH_END\} | \$\{\^LAST_MATCH_END\} ) \s* (\[) /xmsgc) {
            my $n_th = quotee_of(parse_expr_balanced($1));
            $parsed .= "\@{[mb::_LAST_MATCH_END($n_th)]}";
        }

        # any
        elsif (/\G ($x) /xmsgc) {
            $parsed .= escape_qq($1, '\\');
        }

        # something wrong happened
        else {
            die sprintf(<<END, pos($_), CORE::substr($_,pos($_)));
$0(@{[__LINE__]}): something wrong happened in script at pos=%s
------------------------------------------------------------------------------
%s
------------------------------------------------------------------------------
END
        }
    }
    return $parsed;
}

#---------------------------------------------------------------------
# parse q{string} in balanced blackets
sub parse_q__like_balanced {
    my($open_bracket) = @_;
    my $close_bracket = {qw| ( ) { } [ ] < > |}->{$open_bracket} || die;
    my $parsed = $open_bracket;
    my $nest_bracket = 1;
    while (1) {
        if (/\G (\Q$open_bracket\E) /xmsgc) {
            $parsed .= $1;
            $nest_bracket++;
        }
        elsif (/\G (\Q$close_bracket\E) /xmsgc) {
            $parsed .= $1;
            if (--$nest_bracket <= 0) {
                last;
            }
        }
        elsif (/\G (\\ \Q$close_bracket\E) /xmsgc) {
            $parsed .= $1;
        }
        else {
            $parsed .= parse_q__like($close_bracket);
        }
    }
    return $parsed;
}

#---------------------------------------------------------------------
# parse q/string/ that ends with a character
sub parse_q__like_endswith {
    my($endswith) = @_;
    my $parsed = $endswith;
    while (1) {
        if (/\G (\Q$endswith\E) /xmsgc) {
            $parsed .= $1;
            last;
        }
        elsif (/\G (\\ \Q$endswith\E) /xmsgc) {
            $parsed .= $1;
        }
        else {
            $parsed .= parse_q__like($endswith);
        }
    }
    return $parsed;
}

#---------------------------------------------------------------------
# parse q/string/ common routine
sub parse_q__like {
    my($closewith) = @_;
    if (/\G (\\\\) /xmsgc) {
        return $1;
    }
    elsif (/\G ($x) /xmsgc) {
        return escape_q($1, $closewith);
    }

    # something wrong happened
    else {
        die sprintf(<<END, pos($_), CORE::substr($_,pos($_)));
$0(@{[__LINE__]}): something wrong happened in script at pos=%s
------------------------------------------------------------------------------
%s
------------------------------------------------------------------------------
END
    }
}

#---------------------------------------------------------------------
# parse qq{string} in balanced blackets
sub parse_qq_like_balanced {
    my($open_bracket) = @_;
    my $close_bracket = {qw| ( ) { } [ ] < > |}->{$open_bracket} || die;
    my $parsed_as_q  = $open_bracket;
    my $parsed_as_qq = $open_bracket;
    my $nest_bracket = 1;
    my $nest_escape = 0;
    while (1) {

        # blackets
        if (/\G (\\ \Q$open_bracket\E) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= $1;
        }
        elsif (/\G (\\ \Q$close_bracket\E) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= $1;
        }
        elsif (/\G (\Q$open_bracket\E) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= $1;
            $nest_bracket++;
        }
        elsif (/\G (\Q$close_bracket\E) /xmsgc) {
            if (--$nest_bracket <= 0) {
                $parsed_as_q  .= $1;
                $parsed_as_qq .= ('>)]}' x $nest_escape);
                $parsed_as_qq .= $1;
                last;
            }
            else {
                $parsed_as_q  .= $1;
                $parsed_as_qq .= $1;
            }
        }

        # \L\u --> \u\L
        elsif (/\G (\\L \\u) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= '@{[mb::ucfirst(qq<';
            $parsed_as_qq .= '@{[mb::lc(qq<';
            $nest_escape++;
            $nest_escape++;
        }

        # \U\l --> \l\U
        elsif (/\G (\\U \\l) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= '@{[mb::lcfirst(qq<';
            $parsed_as_qq .= '@{[mb::uc(qq<';
            $nest_escape++;
            $nest_escape++;
        }

        # \L
        elsif (/\G (\\L) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= '@{[mb::lc(qq<';
            $nest_escape++;
        }

        # \U
        elsif (/\G (\\U) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= '@{[mb::uc(qq<';
            $nest_escape++;
        }

        # \l
        elsif (/\G (\\l) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= '@{[mb::lcfirst(qq<';
            $nest_escape++;
        }

        # \u
        elsif (/\G (\\u) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= '@{[mb::ucfirst(qq<';
            $nest_escape++;
        }

        # \Q
        elsif (/\G (\\Q) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= '@{[quotemeta(qq<';
            $nest_escape++;
        }

        # \E
        elsif (/\G (\\E) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= ('>)]}' x $nest_escape);
            $nest_escape = 0;
        }

        else {
            my($as_qq, $as_q) = parse_qq_like($close_bracket);
            $parsed_as_q  .= $as_q;
            $parsed_as_qq .= $as_qq;
        }
    }

    # return qq-like and q-like quotee
    if (wantarray) {
        return ($parsed_as_qq, $parsed_as_q);
    }
    else {
        return $parsed_as_qq;
    }
}

#---------------------------------------------------------------------
# parse qq/string/ that ends with a character
sub parse_qq_like_endswith {
    my($endswith) = @_;
    my $parsed_as_q  = $endswith;
    my $parsed_as_qq = $endswith;
    my $nest_escape = 0;
    while (1) {

        # ends with
        if (/\G (\\ \Q$endswith\E) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= $1;
        }
        elsif (/\G (\Q$endswith\E) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= ('>)]}' x $nest_escape);
            $parsed_as_qq .= "\n" if CORE::length($1) >= 2; # here document
            $parsed_as_qq .= $1;
            last;
        }

        # \L\u --> \u\L
        elsif (/\G (\\L \\u) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= '@{[mb::ucfirst(qq<';
            $parsed_as_qq .= '@{[mb::lc(qq<';
            $nest_escape++;
            $nest_escape++;
        }

        # \U\l --> \l\U
        elsif (/\G (\\U \\l) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= '@{[mb::lcfirst(qq<';
            $parsed_as_qq .= '@{[mb::uc(qq<';
            $nest_escape++;
            $nest_escape++;
        }

        # \L
        elsif (/\G (\\L) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= '@{[mb::lc(qq<';
            $nest_escape++;
        }

        # \U
        elsif (/\G (\\U) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= '@{[mb::uc(qq<';
            $nest_escape++;
        }

        # \l
        elsif (/\G (\\l) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= '@{[mb::lcfirst(qq<';
            $nest_escape++;
        }

        # \u
        elsif (/\G (\\u) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= '@{[mb::ucfirst(qq<';
            $nest_escape++;
        }

        # \Q
        elsif (/\G (\\Q) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= '@{[quotemeta(qq<';
            $nest_escape++;
        }

        # \E
        elsif (/\G (\\E) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= ('>)]}' x $nest_escape);
            $nest_escape = 0;
        }

        else {
            my($as_qq, $as_q) = parse_qq_like($endswith);
            $parsed_as_q  .= $as_q;
            $parsed_as_qq .= $as_qq;
        }
    }

    # return qq-like and q-like quotee
    if (wantarray) {
        return ($parsed_as_qq, $parsed_as_q);
    }
    else {
        return $parsed_as_qq;
    }
}

#---------------------------------------------------------------------
# parse qq/string/ common routine
sub parse_qq_like {
    my($closewith) = @_;
    my $parsed_as_q  = '';
    my $parsed_as_qq = '';

    # \o{...}
    if (/\G ( \\o\{ (.*?) \} ) /xmsgc) {
        $parsed_as_q  .= $1;
        $parsed_as_qq .= escape_to_hex(mb::chr(oct $2), $closewith);
    }

    # \x{...}
    elsif (/\G ( \\x\{ (.*?) \} ) /xmsgc) {
        $parsed_as_q  .= $1;
        $parsed_as_qq .= escape_to_hex(mb::chr(hex $2), $closewith);
    }

    # \any
    elsif (/\G ( (\\) ($x) ) /xmsgc) {
        $parsed_as_q  .= $1;
        $parsed_as_qq .= ($2 . escape_qq($3, $closewith));
    }

    # $`           --> @{[mb::_PREMATCH()]}
    # ${`}         --> @{[mb::_PREMATCH()]}
    # $PREMATCH    --> @{[mb::_PREMATCH()]}
    # ${PREMATCH}  --> @{[mb::_PREMATCH()]}
    # ${^PREMATCH} --> @{[mb::_PREMATCH()]}
    elsif (/\G ( \$` | \$\{`\} | \$PREMATCH | \$\{PREMATCH\} | \$\{\^PREMATCH\} ) /xmsgc) {
        $parsed_as_q  .= $1;
        $parsed_as_qq .= '@{[mb::_PREMATCH()]}';
    }

    # $&        --> @{[mb::_MATCH()]}
    # ${&}      --> @{[mb::_MATCH()]}
    # $MATCH    --> @{[mb::_MATCH()]}
    # ${MATCH}  --> @{[mb::_MATCH()]}
    # ${^MATCH} --> @{[mb::_MATCH()]}
    elsif (/\G ( \$& | \$\{&\} | \$MATCH | \$\{MATCH\} | \$\{\^MATCH\} ) /xmsgc) {
        $parsed_as_q  .= $1;
        $parsed_as_qq .= '@{[mb::_MATCH()]}';
    }

    # $1 --> @{[mb::_CAPTURE(1)]}
    # $2 --> @{[mb::_CAPTURE(2)]}
    # $3 --> @{[mb::_CAPTURE(3)]}
    elsif (/\G ( \$ ([1-9][0-9]*) ) /xmsgc) {
        $parsed_as_q  .= $1;
        $parsed_as_qq .= "\@{[mb::_CAPTURE($2)]}";
    }

    # @{^CAPTURE} --> @{[mb::_CAPTURE()]}
    elsif (/\G ( \@\{\^CAPTURE\} ) /xmsgc) {
        $parsed_as_q  .= $1;
        $parsed_as_qq .= '@{[mb::_CAPTURE()]}';
    }

    # ${^CAPTURE}[0] --> @{[mb::_CAPTURE(1)]}
    # ${^CAPTURE}[1] --> @{[mb::_CAPTURE(2)]}
    # ${^CAPTURE}[2] --> @{[mb::_CAPTURE(3)]}
    elsif (/\G (\$\{\^CAPTURE\}) \s* (\[) /xmsgc) {
        my $indexing = parse_expr_balanced($2);
        $parsed_as_q  .= ($1 . $indexing);
        my $n_th = quotee_of($indexing);
        $parsed_as_qq .= "\@{[mb::_CAPTURE($n_th)]}";
    }

    # @-                   --> @{[mb::_LAST_MATCH_START()]}
    # @LAST_MATCH_START    --> @{[mb::_LAST_MATCH_START()]}
    # @{LAST_MATCH_START}  --> @{[mb::_LAST_MATCH_START()]}
    # @{^LAST_MATCH_START} --> @{[mb::_LAST_MATCH_START()]}
    elsif (/\G (?: \@- | \@LAST_MATCH_START | \@\{LAST_MATCH_START\} | \@\{\^LAST_MATCH_START\} ) /xmsgc) {
        $parsed_as_q  .= $&;
        $parsed_as_qq .= '@{[mb::_LAST_MATCH_START()]}';
    }

    # $-[1]                   --> @{[mb::_LAST_MATCH_START(1)]}
    # $LAST_MATCH_START[1]    --> @{[mb::_LAST_MATCH_START(1)]}
    # ${LAST_MATCH_START}[1]  --> @{[mb::_LAST_MATCH_START(1)]}
    # ${^LAST_MATCH_START}[1] --> @{[mb::_LAST_MATCH_START(1)]}
    elsif (/\G ( \$- | \$LAST_MATCH_START | \$\{LAST_MATCH_START\} | \$\{\^LAST_MATCH_START\} ) \s* (\[) /xmsgc) {
        my $indexing = parse_expr_balanced($2);
        $parsed_as_q  .= ($1 . $indexing);
        my $n_th = quotee_of($indexing);
        $parsed_as_qq .= "\@{[mb::_LAST_MATCH_START($n_th)]}";
    }

    # @+                 --> @{[mb::_LAST_MATCH_END()]}
    # @LAST_MATCH_END    --> @{[mb::_LAST_MATCH_END()]}
    # @{LAST_MATCH_END}  --> @{[mb::_LAST_MATCH_END()]}
    # @{^LAST_MATCH_END} --> @{[mb::_LAST_MATCH_END()]}
    elsif (/\G ( \@\+ | \@LAST_MATCH_END | \@\{LAST_MATCH_END\} | \@\{\^LAST_MATCH_END\} ) /xmsgc) {
        $parsed_as_q  .= $1;
        $parsed_as_qq .= '@{[mb::_LAST_MATCH_END()]}';
    }

    # $+[1]                 --> @{[mb::_LAST_MATCH_END(1)]}
    # $LAST_MATCH_END[1]    --> @{[mb::_LAST_MATCH_END(1)]}
    # ${LAST_MATCH_END}[1]  --> @{[mb::_LAST_MATCH_END(1)]}
    # ${^LAST_MATCH_END}[1] --> @{[mb::_LAST_MATCH_END(1)]}
    elsif (/\G ( \$\+ | \$LAST_MATCH_END | \$\{LAST_MATCH_END\} | \$\{\^LAST_MATCH_END\} ) \s* (\[) /xmsgc) {
        my $indexing = parse_expr_balanced($2);
        $parsed_as_q  .= ($1 . $indexing);
        my $n_th = quotee_of($indexing);
        $parsed_as_qq .= "\@{[mb::_LAST_MATCH_END($n_th)]}";
    }

    # any
    elsif (/\G ($x) /xmsgc) {
        $parsed_as_q  .= escape_q ($1, $closewith);
        $parsed_as_qq .= escape_qq($1, $closewith);
    }

    # something wrong happened
    else {
        die sprintf(<<END, pos($_), CORE::substr($_,pos($_)));
$0(@{[__LINE__]}): something wrong happened in script at pos=%s
------------------------------------------------------------------------------
%s
------------------------------------------------------------------------------
END
    }

    # return qq-like and q-like quotee
    if (wantarray) {
        return ($parsed_as_qq, $parsed_as_q);
    }
    else {
        return $parsed_as_qq;
    }
}

#---------------------------------------------------------------------
# tr/A-C/1-3/ for US-ASCII codepoint
sub list_all_ASCII_by_hyphen {
    my @hyphened = @_;
    my @list_all = ();
    for (my $i=0; $i <= $#hyphened; ) {
        if (
            ($i+1 < $#hyphened)      and
            ($hyphened[$i+1] eq '-') and
        1) {
            $hyphened[$i+0] = ($hyphened[$i+0] eq '\\-') ? '-' : $hyphened[$i+0];
            $hyphened[$i+2] = ($hyphened[$i+2] eq '\\-') ? '-' : $hyphened[$i+2];
            if (0) { }
            elsif ($hyphened[$i+0] !~ m/\A [\x00-\x7F] \z/xms) {
                confess sprintf(qq{@{[__FILE__]}: "$hyphened[$i+0]-$hyphened[$i+2]" in tr/// is not US-ASCII});
            }
            elsif ($hyphened[$i+2] !~ m/\A [\x00-\x7F] \z/xms) {
                confess sprintf(qq{@{[__FILE__]}: "$hyphened[$i+0]-$hyphened[$i+2]" in tr/// is not US-ASCII});
            }
            elsif ($hyphened[$i+0] gt $hyphened[$i+2]) {
                confess sprintf(qq{@{[__FILE__]}: "$hyphened[$i+0]-$hyphened[$i+2]" in tr/// is not "$hyphened[$i+0]" le "$hyphened[$i+2]"});
            }
            else {
                push @list_all, map { CORE::chr($_) } (CORE::ord($hyphened[$i+0]) .. CORE::ord($hyphened[$i+2]));
                $i += 3;
            }
        }
        else {
            if ($hyphened[$i] eq '\\-') {
                push @list_all, '-';
            }
            else {
                push @list_all, $hyphened[$i];
            }
            $i++;
        }
    }
    return @list_all;
}

#---------------------------------------------------------------------
# parse tr{here}{here} in balanced blackets
sub parse_tr_like_balanced {
    my($open_bracket) = @_;
    my $close_bracket = {qw| ( ) { } [ ] < > |}->{$open_bracket} || die;
    my @x = ();
    my $nest_bracket = 1;
    while (1) {

        # blackets
        if (/\G (\\ \Q$open_bracket\E) /xmsgc) {
            push @x, $1;
        }
        elsif (/\G (\\ \Q$close_bracket\E) /xmsgc) {
            push @x, $1;
        }
        elsif (/\G (\Q$open_bracket\E) /xmsgc) {
            push @x, $1;
            $nest_bracket++;
        }
        elsif (/\G (\Q$close_bracket\E) /xmsgc) {
            if (--$nest_bracket <= 0) {
                last;
            }
            push @x, $1;
        }

        # \-
        elsif (/\G (\\ -) /xmsgc) {
            push @x, $1;
        }

        else {
            push @x, parse_tr_like($close_bracket);
        }
    }
    return join('', $open_bracket, @x, $close_bracket);
}

#---------------------------------------------------------------------
# parse tr/here/here/ that ends with a character
sub parse_tr_like_endswith {
    my($endswith) = @_;
    my $openwith = $endswith;
    my @x = ();
    while (1) {
        if (/\G (\\ \Q$endswith\E) /xmsgc) {
            push @x, $1;
        }
        elsif (/\G (\Q$endswith\E) /xmsgc) {
            last;
        }

        # \-
        elsif (/\G (\\ -) /xmsgc) {
            push @x, $1;
        }

        else {
            push @x, parse_tr_like($endswith);
        }
    }
    return join('', $openwith, @x, $endswith);
}

#---------------------------------------------------------------------
# parse tr/here/here/ common routine
sub parse_tr_like {
    my($closewith) = @_;

    if (0) {
    }

    # https://perldoc.perl.org/perlop#Interpolation
    # tr///, y///
    # No variable interpolation occurs.
    # String modifying combinations for case and quoting such as \Q, \U, and \E are not recognized.
    # The other escape sequences such as \200 and \t and backslashed characters such as \\ and \- are converted to appropriate literals.
    # The character "-" is treated specially and therefore \- is treated as a literal "-".

    # \ddd
    elsif (/\G \\ ( [0-3][0-7][0-7] | [0-7][0-7] | [0-7] ) /xmsgc) {
        return escape_tr(mb::chr(oct $1), $closewith);
    }

    # \oddd
    elsif (/\G \\o ( [0-3][0-7][0-7] | [0-7][0-7] | [0-7] ) /xmsgc) {
        return escape_tr(mb::chr(oct $1), $closewith);
    }

    # \o{...}
    elsif (/\G \\o\{ (.*?) \} /xmsgc) {
        return escape_tr(mb::chr(oct $1), $closewith);
    }

    # \xhh
    elsif (/\G \\x ( [0-9A-Fa-f][0-9A-Fa-f] | [0-9A-Fa-f] ) /xmsgc) {
        return escape_tr(mb::chr(hex $1), $closewith);
    }

    # \x{...}
    elsif (/\G \\x\{ (.*?) \} /xmsgc) {
        return escape_tr(mb::chr(hex $1), $closewith);
    }

    # \cX
    elsif (/\G ( \\c [\@ABCDEFGHIJKLMNOPQRSTUVWXYZ\[\\\]^_?] ) /xmsgc) {
        return {
            '\\c@'  => "\c@",
            '\\cA'  => "\cA",
            '\\cB'  => "\cB",
            '\\cC'  => "\cC",
            '\\cD'  => "\cD",
            '\\cE'  => "\cE",
            '\\cF'  => "\cF",
            '\\cG'  => "\cG",
            '\\cH'  => "\cH",
            '\\cI'  => "\cI",
            '\\cJ'  => "\cJ",
            '\\cK'  => "\cK",
            '\\cL'  => "\cL",
            '\\cM'  => "\cM",
            '\\cN'  => "\cN",
            '\\cO'  => "\cO",
            '\\cP'  => "\cP",
            '\\cQ'  => "\cQ",
            '\\cR'  => "\cR",
            '\\cS'  => "\cS",
            '\\cT'  => "\cT",
            '\\cU'  => "\cU",
            '\\cV'  => "\cV",
            '\\cW'  => "\cW",
            '\\cX'  => "\cX",
            '\\cY'  => "\cY",
            '\\cZ'  => "\cZ",
            '\\c['  => "\c[",
            '\\c\\' => CORE::chr(0x1C),
            '\\c]'  => "\c]",
            '\\c^'  => "\c^",
            '\\c_'  => "\c_",
            '\\c?'  => CORE::chr(0x7F),
        }->{$1} || die;
    }

    # \\ \a \b \e \f \n \r \t \E \l \L \u \U \Q
    elsif (/\G ( \\ ([\\abefnrtElLuUQ]) ) /xmsgc) {
        return {
            "\x5C\x5C" => "\x5C\x5C",
            '\a'       => "\a",
            '\b'       => "\b",
            '\e'       => "\e",
            '\f'       => "\f",
            '\n'       => "\n",
            '\r'       => "\r",
            '\t'       => "\t",
        }->{$1} || $2;
    }

    # any
    elsif (/\G ($x) /xmsgc) {
        return escape_tr($1, $closewith);
    }

    # something wrong happened
    else {
        die sprintf(<<END, pos($_), CORE::substr($_,pos($_)));
$0(@{[__LINE__]}): something wrong happened in script at pos=%s
------------------------------------------------------------------------------
%s
------------------------------------------------------------------------------
END
    }
}

#---------------------------------------------------------------------
# qr/ [A-Z] / for Shift_JIS-like encoding
sub list_all_by_hyphen_sjis_like {
    my($a, $b) = @_;
    my @a = (undef, unpack 'C*', $a);
    my @b = (undef, unpack 'C*', $b);

    if (0) { }
    elsif (CORE::length($a) == 1) {
        if (0) { }
        elsif (CORE::length($b) == 1) {
            return (
(($a[1] <= 0x80) and (0xA0 <= $b[1])) ?
                sprintf(join('', qw( [\x%02x-\x80\xA0-\x%02x] )), $a[1],
                                                                  $b[1]) :
$a[1]<=$b[1] ?  sprintf(join('', qw( [\x%02x-\x%02x]          )), $a[1],
                                                                  $b[1]) : (),
            );
        }
        elsif (CORE::length($b) == 2) {
            return (
                sprintf(join('', qw(       \x%02x           [\x00-\x%02x] )), $b[1], $b[2]),
0x81 <  $b[1] ? sprintf(join('', qw( [\x81-\x%02x]          [\x00-\xFF  ] )), $b[1]-1     ) : (),
$a[1] <= 0x80 ? sprintf(join('', qw( [\x%02x-\x80\xA0-\xDF]               )), $a[1]) :
$a[1] <  0xA0 ? ()                                                                   :
$a[1] <= 0xDF ? sprintf(join('', qw( [\x%02x-\xDF]                        )), $a[1]) : (),
            );
        }
    }
    elsif (CORE::length($a) == 2) {
        if (0) { }
        elsif (CORE::length($b) == 2) {
            my $lower_limit = join('|',
$a[1] < 0xFC ?  sprintf(join('', qw( [\x%02x-\xFC] [\x00-\xFF  ] )), $a[1]+1     ) : (),
                sprintf(join('', qw(  \x%02x       [\x%02x-\xFF] )), $a[1], $a[2]),
            );
            my $upper_limit = join('|',
                sprintf(join('', qw(       \x%02x  [\x00-\x%02x] )), $b[1], $b[2]),
0x81 < $b[1] ?  sprintf(join('', qw( [\x81-\x%02x] [\x00-\xFF  ] )), $b[1]-1     ) : (),
            );
            return qq{(?=$lower_limit)(?=$upper_limit)};
        }
    }

    # over range of codepoint
    confess sprintf(qq{@{[__FILE__]}: codepoint class [$_[0]-$_[1]] is not 1 to 4 octets (%d-%d)}, CORE::length($a), CORE::length($b));
}

#---------------------------------------------------------------------
# qr/ [A-Z] / for EUC-JP-like encoding
sub list_all_by_hyphen_eucjp_like {
    my($a, $b) = @_;
    my @a = (undef, unpack 'C*', $a);
    my @b = (undef, unpack 'C*', $b);

    if (0) { }
    elsif (CORE::length($a) == 1) {
        if (0) { }
        elsif (CORE::length($b) == 1) {
            return (
$a[1]<=$b[1] ?  sprintf(join('', qw( [\x%02x-\x%02x]             )), $a[1],
                                                                     $b[1]) : (),
            );
        }
        elsif (CORE::length($b) == 2) {
            return (
                sprintf(join('', qw(       \x%02x  [\x00-\x%02x] )), $b[1], $b[2]),
0xA1 < $b[1] ?  sprintf(join('', qw( [\xA1-\x%02x] [\x00-\xFF  ] )), $b[1]-1     ) : (),
                sprintf(join('', qw( [\x%02x-\x7F]               )), $a[1]       ),
            );
        }
    }
    elsif (CORE::length($a) == 2) {
        if (0) { }
        elsif (CORE::length($b) == 2) {
            my $lower_limit = join('|',
$a[1] < 0xFE ?  sprintf(join('', qw( [\x%02x-\xFE] [\x00-\xFF  ] )), $a[1]+1     ) : (),
                sprintf(join('', qw(  \x%02x       [\x%02x-\xFF] )), $a[1], $a[2]),
            );
            my $upper_limit = join('|',
                sprintf(join('', qw(       \x%02x  [\x00-\x%02x] )), $b[1], $b[2]),
0xA1 < $b[1] ?  sprintf(join('', qw( [\xA1-\x%02x] [\x00-\xFF  ] )), $b[1]-1     ) : (),
            );
            return qq{(?=$lower_limit)(?=$upper_limit)};
        }
    }

    # over range of codepoint
    confess sprintf(qq{@{[__FILE__]}: codepoint class [$_[0]-$_[1]] is not 1 to 4 octets (%d-%d)}, CORE::length($a), CORE::length($b));
}

#---------------------------------------------------------------------
# qr/ [A-Z] / for Big5-like encoding
sub list_all_by_hyphen_big5_like {
    my($a, $b) = @_;
    my @a = (undef, unpack 'C*', $a);
    my @b = (undef, unpack 'C*', $b);

    if (0) { }
    elsif (CORE::length($a) == 1) {
        if (0) { }
        elsif (CORE::length($b) == 1) {
            return (
$a[1]<=$b[1] ?  sprintf(join('', qw( [\x%02x-\x%02x]             )), $a[1],
                                                                     $b[1]) : (),
            );
        }
        elsif (CORE::length($b) == 2) {
            return (
                sprintf(join('', qw(       \x%02x  [\x00-\x%02x] )), $b[1], $b[2]),
0x81 < $b[1] ?  sprintf(join('', qw( [\x81-\x%02x] [\x00-\xFF  ] )), $b[1]-1     ) : (),
                sprintf(join('', qw( [\x%02x-\x7F]               )), $a[1]       ),
            );
        }
    }
    elsif (CORE::length($a) == 2) {
        if (0) { }
        elsif (CORE::length($b) == 2) {
            my $lower_limit = join('|',
$a[1] < 0xFE ?  sprintf(join('', qw( [\x%02x-\xFE] [\x00-\xFF  ] )), $a[1]+1     ) : (),
                sprintf(join('', qw(  \x%02x       [\x%02x-\xFF] )), $a[1], $a[2]),
            );
            my $upper_limit = join('|',
                sprintf(join('', qw(       \x%02x  [\x00-\x%02x] )), $b[1], $b[2]),
0x81 < $b[1] ?  sprintf(join('', qw( [\x81-\x%02x] [\x00-\xFF  ] )), $b[1]-1     ) : (),
            );
            return qq{(?=$lower_limit)(?=$upper_limit)};
        }
    }

    # over range of codepoint
    confess sprintf(qq{@{[__FILE__]}: codepoint class [$_[0]-$_[1]] is not 1 to 4 octets (%d-%d)}, CORE::length($a), CORE::length($b));
}

#---------------------------------------------------------------------
# qr/ [A-Z] / for GB18030-like encoding
sub list_all_by_hyphen_gb18030_like {
    my($a, $b) = @_;
    my @a = (undef, unpack 'C*', $a);
    my @b = (undef, unpack 'C*', $b);

    if (0) { }
    elsif (CORE::length($a) == 1) {
        if (0) { }
        elsif (CORE::length($b) == 1) {
            return (
$a[1]<=$b[1] ?  sprintf(join('', qw( [\x%02x-\x%02x]                                         )), $a[1],
                                                                                                 $b[1]) : (),
            );
        }
        elsif (CORE::length($b) == 2) {
            return (
                sprintf(join('', qw(       \x%02x  [\x00-\x2F\x3A-\x%02x]                    )), $b[1], $b[2]),
0x81 < $b[1] ?  sprintf(join('', qw( [\x81-\x%02x] [^\x30-\x39 ]                             )), $b[1]-1     ) : (),
                sprintf(join('', qw( [\x%02x-\x7F]                                           )), $a[1]       ),
            );
        }
        elsif (CORE::length($b) == 4) {
            return (
                sprintf(join('', qw(       \x%02x        \x%02x        \x%02x  [\x30-\x%02x] )), $b[1], $b[2], $b[3], $b[4]),
0x81 < $b[3] ?  sprintf(join('', qw(       \x%02x        \x%02x  [\x81-\x%02x] [\x30-\x39  ] )), $b[1], $b[2], $b[3]-1     ) : (),
0x30 < $b[2] ?  sprintf(join('', qw(       \x%02x  [\x30-\x%02x] [\x81-\xFE  ] [\x30-\x39  ] )), $b[1], $b[2]-1            ) : (),
0x81 < $b[1] ?  sprintf(join('', qw( [\x81-\x%02x] [\x30-\x39  ] [\x81-\xFE  ] [\x30-\x39  ] )), $b[1]-1                   ) : (),
                sprintf(join('', qw( [\x81-\xFE  ] [^\x30-\x39 ]                             )),                           ),
                sprintf(join('', qw( [\x%02x-\x7F]                                           )), $a[1]                     ),
            );
        }
    }
    elsif (CORE::length($a) == 2) {
        if (0) { }
        elsif (CORE::length($b) == 2) {
            my $lower_limit = join('|',
$a[1] < 0xFE ?  sprintf(join('', qw( [\x%02x-\xFE] [^\x30-\x39 ]                             )), $a[1]+1     ) : (),
                sprintf(join('', qw(  \x%02x       [\x%02x-\xFF]                             )), $a[1], $a[2]),
            );
            my $upper_limit = join('|',
                sprintf(join('', qw(       \x%02x  [\x00-\x%02x]                             )), $b[1], $b[2]),
0x81 < $b[1] ?  sprintf(join('', qw( [\x81-\x%02x] [^\x30-\x39 ]                             )), $b[1]-1     ) : (),
            );
            return qq{(?=$lower_limit)(?=$upper_limit)};
        }
        elsif (CORE::length($b) == 4) {
            return (
                sprintf(join('', qw(       \x%02x        \x%02x        \x%02x  [\x30-\x%02x] )), $b[1], $b[2], $b[3], $b[4]),
0x81  < $b[3] ? sprintf(join('', qw(       \x%02x        \x%02x  [\x81-\x%02x] [\x30-\x39  ] )), $b[1], $b[2], $b[3]-1     ) : (),
0x30  < $b[2] ? sprintf(join('', qw(       \x%02x  [\x30-\x%02x] [\x81-\xFE  ] [\x30-\x39  ] )), $b[1], $b[2]-1            ) : (),
0x81  < $b[1] ? sprintf(join('', qw( [\x81-\x%02x] [\x30-\x39  ] [\x81-\xFE  ] [\x30-\x39  ] )), $b[1]-1                   ) : (),
$a[1] < 0xFE  ? sprintf(join('', qw( [\x%02x-\xFE] [^\x30-\x39 ]                             )), $a[1]+1                   ) : (),
                sprintf(join('', qw(  \x%02x       [\x%02x-\xFF]                             )), $a[1], $a[2]              ),
            );
        }
    }
    elsif (CORE::length($a) == 4) {
        if (0) { }
        elsif (CORE::length($b) == 4) {
            my $lower_limit = join('|',
$a[1] < 0xFE ?  sprintf(join('', qw( [\x%02x-\xFE] [\x30-\x39  ] [\x81-\xFE  ] [\x30-\x39  ] )), $a[1]+1                   ) : (),
$a[2] < 0x39 ?  sprintf(join('', qw(  \x%02x       [\x%02x-\x39] [\x81-\xFE  ] [\x30-\x39  ] )), $a[1], $a[2]+1            ) : (),
$a[3] < 0xFE ?  sprintf(join('', qw(  \x%02x        \x%02x       [\x%02x-\xFE] [\x30-\x39  ] )), $a[1], $a[2], $a[3]+1     ) : (),
                sprintf(join('', qw(  \x%02x        \x%02x        \x%02x       [\x%02x-\x39] )), $a[1], $a[2], $a[3], $a[4]),
            );
            my $upper_limit = join('|',
                sprintf(join('', qw(       \x%02x        \x%02x        \x%02x  [\x30-\x%02x] )), $b[1], $b[2], $b[3], $b[4]),
0x81 < $b[3] ?  sprintf(join('', qw(       \x%02x        \x%02x  [\x81-\x%02x] [\x30-\x39  ] )), $b[1], $b[2], $b[3]-1     ) : (),
0x30 < $b[2] ?  sprintf(join('', qw(       \x%02x  [\x30-\x%02x] [\x81-\xFE  ] [\x30-\x39  ] )), $b[1], $b[2]-1            ) : (),
0x81 < $b[1] ?  sprintf(join('', qw( [\x81-\x%02x] [\x30-\x39  ] [\x81-\xFE  ] [\x30-\x39  ] )), $b[1]-1                   ) : (),
            );
            return qq{(?=$lower_limit)(?=$upper_limit)};
        }
    }

    # over range of codepoint
    confess sprintf(qq{@{[__FILE__]}: codepoint class [$_[0]-$_[1]] is not 1 to 4 octets (%d-%d)}, CORE::length($a), CORE::length($b));
}

#---------------------------------------------------------------------
# qr/ [A-Z] / for UTF-8-like encoding
sub list_all_by_hyphen_utf8_like {
    my($a, $b) = @_;
    my @a = (undef, unpack 'C*', $a);
    my @b = (undef, unpack 'C*', $b);

    if (0) { }
    elsif (CORE::length($a) == 1) {
        if (0) { }
        elsif (CORE::length($b) == 1) {
            return (
$a[1]<=$b[1] ?  sprintf(join('', qw( [\x%02x-\x%02x]                                         )), $a[1],
                                                                                                 $b[1]) : (),
            );
        }
        elsif (CORE::length($b) == 2) {
            return (
                sprintf(join('', qw(       \x%02x  [\x80-\x%02x]                             )), $b[1], $b[2]),
0xC2 < $b[1] ?  sprintf(join('', qw( [\xC2-\x%02x] [\x80-\xBF  ]                             )), $b[1]-1     ) : (),
                sprintf(join('', qw( [\x%02x-\x7F]                                           )), $a[1]       ),
            );
        }
        elsif (CORE::length($b) == 3) {
            return (
                sprintf(join('', qw(       \x%02x        \x%02x  [\x80-\x%02x]               )), $b[1], $b[2], $b[3]),
0x80 < $b[2] ?  sprintf(join('', qw(       \x%02x  [\x80-\x%02x] [\x80-\xBF  ]               )), $b[1], $b[2]-1     ) : (),
0xE0 < $b[1] ?  sprintf(join('', qw( [\xE0-\x%02x] [\x80-\xBF  ] [\x80-\xBF  ]               )), $b[1]-1            ) : (),
                sprintf(join('', qw( [\xC2-\xDF  ] [\x80-\xBF  ]                             )),                    ),
                sprintf(join('', qw( [\x%02x-\x7F]                                           )), $a[1]              ),
            );
        }
        elsif (CORE::length($b) == 4) {
            return (
                sprintf(join('', qw(       \x%02x        \x%02x        \x%02x  [\x80-\x%02x] )), $b[1], $b[2], $b[3], $b[4]),
0x80 < $b[3] ?  sprintf(join('', qw(       \x%02x        \x%02x  [\x80-\x%02x] [\x80-\xBF  ] )), $b[1], $b[2], $b[3]-1     ) : (),
0x80 < $b[2] ?  sprintf(join('', qw(       \x%02x  [\x80-\x%02x] [\x80-\xBF  ] [\x80-\xBF  ] )), $b[1], $b[2]-1            ) : (),
0xF0 < $b[1] ?  sprintf(join('', qw( [\xF0-\x%02x] [\x80-\xBF  ] [\x80-\xBF  ] [\x80-\xBF  ] )), $b[1]-1                   ) : (),
                sprintf(join('', qw( [\xE0-\xEF  ] [\x80-\xBF  ] [\x80-\xBF  ]               )),                           ),
                sprintf(join('', qw( [\xC2-\xDF  ] [\x80-\xBF  ]                             )),                           ),
                sprintf(join('', qw( [\x%02x-\x7F]                                           )), $a[1]                     ),
            );
        }
    }
    elsif (CORE::length($a) == 2) {
        if (0) { }
        elsif (CORE::length($b) == 2) {
            my $lower_limit = join('|',
$a[1] < 0xDF ?  sprintf(join('', qw( [\x%02x-\xDF] [\x80-\xBF  ]                             )), $a[1]+1     ) : (),
                sprintf(join('', qw(  \x%02x       [\x%02x-\xBF]                             )), $a[1], $a[2]),
            );
            my $upper_limit = join('|',
                sprintf(join('', qw(       \x%02x  [\x80-\x%02x]                             )), $b[1], $b[2]),
0xC2 < $b[1] ?  sprintf(join('', qw( [\xC2-\x%02x] [\x80-\xBF  ]                             )), $b[1]-1     ) : (),
            );
            return qq{(?=$lower_limit)(?=$upper_limit)};
        }
        elsif (CORE::length($b) == 3) {
            return (
                sprintf(join('', qw(       \x%02x        \x%02x  [\x80-\x%02x]               )), $b[1], $b[2], $b[3] ),
0x80 < $b[2] ?  sprintf(join('', qw(       \x%02x  [\x80-\x%02x] [\x80-\xBF  ]               )), $b[1], $b[2]-1      ) : (),
0xE0 < $b[1] ?  sprintf(join('', qw( [\xE0-\x%02x] [\x80-\xBF  ] [\x80-\xBF  ]               )), $b[1]-1             ) : (),
$a[1] < 0xDF ?  sprintf(join('', qw( [\x%02x-\xDF] [\x80-\xBF  ]                             )), $a[1]+1             ) : (),
                sprintf(join('', qw(  \x%02x       [\x%02x-\xBF]                             )), $a[1], $a[2]        ),
            );
        }
        elsif (CORE::length($b) == 4) {
            return (
                sprintf(join('', qw(       \x%02x        \x%02x        \x%02x  [\x80-\x%02x] )), $b[1], $b[2], $b[3], $b[4]),
0x80 < $b[3] ?  sprintf(join('', qw(       \x%02x        \x%02x  [\x80-\x%02x] [\x80-\xBF  ] )), $b[1], $b[2], $b[3]-1     ) : (),
0x80 < $b[2] ?  sprintf(join('', qw(       \x%02x  [\x80-\x%02x] [\x80-\xBF  ] [\x80-\xBF  ] )), $b[1], $b[2]-1            ) : (),
0xF0 < $b[1] ?  sprintf(join('', qw( [\xF0-\x%02x] [\x80-\xBF  ] [\x80-\xBF  ] [\x80-\xBF  ] )), $b[1]-1                   ) : (),
                sprintf(join('', qw( [\xE0-\xEF  ] [\x80-\xBF  ] [\x80-\xBF  ]               )),                           ),
$a[1] < 0xDF ?  sprintf(join('', qw( [\x%02x-\xDF] [\x80-\xBF  ]                             )), $a[1]+1                   ) : (),
                sprintf(join('', qw(  \x%02x       [\x%02x-\xBF]                             )), $a[1], $a[2]              ),
            );
        }
    }
    elsif (CORE::length($a) == 3) {
        if (0) { }
        elsif (CORE::length($b) == 3) {
            my $lower_limit = join('|',
$a[1] < 0xEF ?  sprintf(join('', qw( [\x%02x-\xEF] [\x80-\xBF  ] [\x80-\xBF  ]               )), $a[1]+1            ) : (),
$a[2] < 0xBF ?  sprintf(join('', qw(  \x%02x       [\x%02x-\xBF] [\x80-\xBF  ]               )), $a[1], $a[2]+1     ) : (),
                sprintf(join('', qw(  \x%02x        \x%02x       [\x%02x-\xBF]               )), $a[1], $a[2], $a[3]),
            );
            my $upper_limit = join('|',
                sprintf(join('', qw(       \x%02x        \x%02x  [\x80-\x%02x]               )), $b[1], $b[2], $b[3]),
0x80 < $b[2] ?  sprintf(join('', qw(       \x%02x  [\x80-\x%02x] [\x80-\xBF  ]               )), $b[1], $b[2]-1     ) : (),
0xE0 < $b[1] ?  sprintf(join('', qw( [\xE0-\x%02x] [\x80-\xBF  ] [\x80-\xBF  ]               )), $b[1]-1            ) : (),
            );
            return qq{(?=$lower_limit)(?=$upper_limit)};
        }
        elsif (CORE::length($b) == 4) {
            return (
                sprintf(join('', qw(       \x%02x        \x%02x        \x%02x  [\x80-\x%02x] )), $b[1], $b[2], $b[3], $b[4]),
0x80 < $b[3] ?  sprintf(join('', qw(       \x%02x        \x%02x  [\x80-\x%02x] [\x80-\xBF  ] )), $b[1], $b[2], $b[3]-1     ) : (),
0x80 < $b[2] ?  sprintf(join('', qw(       \x%02x  [\x80-\x%02x] [\x80-\xBF  ] [\x80-\xBF  ] )), $b[1], $b[2]-1            ) : (),
0xF0 < $b[1] ?  sprintf(join('', qw( [\xF0-\x%02x] [\x80-\xBF  ] [\x80-\xBF  ] [\x80-\xBF  ] )), $b[1]-1                   ) : (),
$a[1] < 0xEF ?  sprintf(join('', qw( [\x%02x-\xEF] [\x80-\xBF  ] [\x80-\xBF  ]               )), $a[1]+1                   ) : (),
$a[2] < 0xBF ?  sprintf(join('', qw(  \x%02x       [\x%02x-\xBF] [\x80-\xBF  ]               )), $a[1], $a[2]+1            ) : (),
                sprintf(join('', qw(  \x%02x        \x%02x       [\x%02x-\xBF]               )), $a[1], $a[2], $a[3]       ),
            );
        }
    }
    elsif (CORE::length($a) == 4) {
        if (0) { }
        elsif (CORE::length($b) == 4) {
            my $lower_limit = join('|',
$a[1] < 0xF4 ?  sprintf(join('', qw( [\x%02x-\xF4] [\x80-\xBF  ] [\x80-\xBF  ] [\x80-\xBF  ] )), $a[1]+1                   ) : (),
$a[2] < 0xBF ?  sprintf(join('', qw(  \x%02x       [\x%02x-\xBF] [\x80-\xBF  ] [\x80-\xBF  ] )), $a[1], $a[2]+1            ) : (),
$a[3] < 0xBF ?  sprintf(join('', qw(  \x%02x        \x%02x       [\x%02x-\xBF] [\x80-\xBF  ] )), $a[1], $a[2], $a[3]+1     ) : (),
                sprintf(join('', qw(  \x%02x        \x%02x        \x%02x       [\x%02x-\xBF] )), $a[1], $a[2], $a[3], $a[4]),
            );
            my $upper_limit = join('|',
                sprintf(join('', qw(       \x%02x        \x%02x        \x%02x  [\x80-\x%02x] )), $b[1], $b[2], $b[3], $b[4]),
0x80 < $b[3] ?  sprintf(join('', qw(       \x%02x        \x%02x  [\x80-\x%02x] [\x80-\xBF  ] )), $b[1], $b[2], $b[3]-1     ) : (),
0x80 < $b[2] ?  sprintf(join('', qw(       \x%02x  [\x80-\x%02x] [\x80-\xBF  ] [\x80-\xBF  ] )), $b[1], $b[2]-1            ) : (),
0xF0 < $b[1] ?  sprintf(join('', qw( [\xF0-\x%02x] [\x80-\xBF  ] [\x80-\xBF  ] [\x80-\xBF  ] )), $b[1]-1                   ) : (),
            );
            return qq{(?=$lower_limit)(?=$upper_limit)};
        }
    }

    # over range of codepoint
    confess sprintf(qq{@{[__FILE__]}: codepoint class [$_[0]-$_[1]] is not 1 to 4 octets (%d-%d)}, CORE::length($a), CORE::length($b));
}

#---------------------------------------------------------------------
# parse codepoint class
sub parse_re_codepoint_class {
    my($codepoint_class) = @_;
    my @sbcs = ();
    my @xbcs = (); # "xbcs" means DBCS, TBCS, QBCS, ...

    # get members from class
    my @classmate = ();
    while ($codepoint_class !~ /\G \z /xmsgc) {
        if (0) { }
        elsif ($codepoint_class =~ /\G\\o\{([01234567]+)\}/xmsgc) {
            push @classmate, mb::chr(oct $1);
        }
        elsif ($codepoint_class =~ /\G\\x\{([0123456789ABCDEFabcdef]+)\}/xmsgc) {
            push @classmate, mb::chr(hex $1);
        }
        elsif ($codepoint_class =~ /\G(\[:.+?:\])/xmsgc) {
            push @classmate, $1;
        }
        elsif ($codepoint_class =~ /\G((?>\\$x))/xmsgc) {
            push @classmate, $1;
        }
        elsif ($codepoint_class =~ /\G($x)/xmsgc) {
            push @classmate, $1;
        }
        else {
            confess qq{@{[__FILE__]}: codepoint_class=($codepoint_class), classmate=(@classmate)};
        }
    }

    # get regular expression for MBCS codepoint class
    for (my $i=0; $i <= $#classmate; $i++) {
        my $classmate = $classmate[$i];

        # hyphen of [A-Z] or [^A-Z]
        if (($i < $#classmate) and ($classmate[$i+1] eq '-')) {
            my $a = $classmate[$i];
            my $b = $classmate[$i+2];
            if (0) { }
            elsif ($script_encoding =~ /\A (?: sjis ) \z/xms) {
                push @xbcs, list_all_by_hyphen_sjis_like   ($a, $b);
            }
            elsif ($script_encoding =~ /\A (?: eucjp ) \z/xms) {
                push @xbcs, list_all_by_hyphen_eucjp_like  ($a, $b);
            }
            elsif ($script_encoding =~ /\A (?: gbk | uhc | big5 | big5hkscs ) \z/xms) {
                push @xbcs, list_all_by_hyphen_big5_like   ($a, $b);
            }
            elsif ($script_encoding =~ /\A (?: gb18030 ) \z/xms) {
                push @xbcs, list_all_by_hyphen_gb18030_like($a, $b);
            }
            elsif ($script_encoding =~ /\A (?: rfc2279 | utf8 | wtf8 ) \z/xms) {
                push @xbcs, list_all_by_hyphen_utf8_like   ($a, $b);
            }
            else {
                push @sbcs, "$a-$b";
            }
            $i += 2;
        }

        # classic perl codepoint class shortcuts
        elsif ($classmate eq '\\D') { push @xbcs, "(?:(?![$bare_d])$x)";  }
        elsif ($classmate eq '\\H') { push @xbcs, "(?:(?![$bare_h])$x)";  }
#       elsif ($classmate eq '\\N') { push @xbcs, "(?:(?!\\n)$x)";        } # \N in a codepoint class must be a named character: \N{...} in regex
#       elsif ($classmate eq '\\R') { push @xbcs, "(?>\\r\\n|[$bare_v])"; } # Unrecognized escape \R in codepoint class passed through in regex
        elsif ($classmate eq '\\S') { push @xbcs, "(?:(?![$bare_s])$x)";  }
        elsif ($classmate eq '\\V') { push @xbcs, "(?:(?![$bare_v])$x)";  }
        elsif ($classmate eq '\\W') { push @xbcs, "(?:(?![$bare_w])$x)";  }
        elsif ($classmate eq '\\b') { push @sbcs, $bare_backspace;        }
        elsif ($classmate eq '\\d') { push @sbcs, $bare_d;                }
        elsif ($classmate eq '\\h') { push @sbcs, $bare_h;                }
        elsif ($classmate eq '\\s') { push @sbcs, $bare_s;                }
        elsif ($classmate eq '\\v') { push @sbcs, $bare_v;                }
        elsif ($classmate eq '\\w') { push @sbcs, $bare_w;                }

        # [:POSIX:]
        elsif ($classmate eq '[:alnum:]' ) { push @sbcs, '\x30-\x39\x41-\x5A\x61-\x7A';                  }
        elsif ($classmate eq '[:alpha:]' ) { push @sbcs, '\x41-\x5A\x61-\x7A';                           }
        elsif ($classmate eq '[:ascii:]' ) { push @sbcs, '\x00-\x7F';                                    }
        elsif ($classmate eq '[:blank:]' ) { push @sbcs, '\x09\x20';                                     }
        elsif ($classmate eq '[:cntrl:]' ) { push @sbcs, '\x00-\x1F\x7F';                                }
        elsif ($classmate eq '[:digit:]' ) { push @sbcs, '\x30-\x39';                                    }
        elsif ($classmate eq '[:graph:]' ) { push @sbcs, '\x21-\x7F';                                    }
        elsif ($classmate eq '[:lower:]' ) { push @sbcs, 'abcdefghijklmnopqrstuvwxyz';                   } # /i modifier requires 'a' to 'z' literally
        elsif ($classmate eq '[:print:]' ) { push @sbcs, '\x20-\x7F';                                    }
        elsif ($classmate eq '[:punct:]' ) { push @sbcs, '\x21-\x2F\x3A-\x3F\x40\x5B-\x5F\x60\x7B-\x7E'; }
        elsif ($classmate eq '[:space:]' ) { push @sbcs, '\s\x0B';                                       } # "\s" and vertical tab ("\cK")
        elsif ($classmate eq '[:upper:]' ) { push @sbcs, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';                   } # /i modifier requires 'A' to 'Z' literally
        elsif ($classmate eq '[:word:]'  ) { push @sbcs, '\x30-\x39\x41-\x5A\x5F\x61-\x7A';              }
        elsif ($classmate eq '[:xdigit:]') { push @sbcs, '\x30-\x39\x41-\x46\x61-\x66';                  }

        # [:^POSIX:]
        elsif ($classmate eq '[:^alnum:]' ) { push @xbcs, "(?:(?![\\x30-\\x39\\x41-\\x5A\\x61-\\x7A])$x)";                      }
        elsif ($classmate eq '[:^alpha:]' ) { push @xbcs, "(?:(?![\\x41-\\x5A\\x61-\\x7A])$x)";                                 }
        elsif ($classmate eq '[:^ascii:]' ) { push @xbcs, "(?:(?![\\x00-\\x7F])$x)";                                            }
        elsif ($classmate eq '[:^blank:]' ) { push @xbcs, "(?:(?![\\x09\\x20])$x)";                                             }
        elsif ($classmate eq '[:^cntrl:]' ) { push @xbcs, "(?:(?![\\x00-\\x1F\\x7F])$x)";                                       }
        elsif ($classmate eq '[:^digit:]' ) { push @xbcs, "(?:(?![\\x30-\\x39])$x)";                                            }
        elsif ($classmate eq '[:^graph:]' ) { push @xbcs, "(?:(?![\\x21-\\x7F])$x)";                                            }
        elsif ($classmate eq '[:^lower:]' ) { push @xbcs, "(?:(?![abcdefghijklmnopqrstuvwxyz])$x)";                             } # /i modifier requires 'a' to 'z' literally
        elsif ($classmate eq '[:^print:]' ) { push @xbcs, "(?:(?![\\x20-\\x7F])$x)";                                            }
        elsif ($classmate eq '[:^punct:]' ) { push @xbcs, "(?:(?![\\x21-\\x2F\\x3A-\\x3F\\x40\\x5B-\\x5F\\x60\\x7B-\\x7E])$x)"; }
        elsif ($classmate eq '[:^space:]' ) { push @xbcs, "(?:(?![\\s\\x0B])$x)";                                               } # "\s" and vertical tab ("\cK")
        elsif ($classmate eq '[:^upper:]' ) { push @xbcs, "(?:(?![ABCDEFGHIJKLMNOPQRSTUVWXYZ])$x)";                             } # /i modifier requires 'A' to 'Z' literally
        elsif ($classmate eq '[:^word:]'  ) { push @xbcs, "(?:(?![\\x30-\\x39\\x41-\\x5A\\x5F\\x61-\\x7A])$x)";                 }
        elsif ($classmate eq '[:^xdigit:]') { push @xbcs, "(?:(?![\\x30-\\x39\\x41-\\x46\\x61-\\x66])$x)";                      }

        # \any
        elsif ($classmate =~ /\G (\\) ($x) /xmsgc) {
            if (CORE::length($2) == 1) {
                push @sbcs, ($1 . $2);
            }
            else {
                push @xbcs, '(?:' . $1 . escape_to_hex($2, ']') . ')';
            }
        }

        # any
        elsif ($classmate =~ /\G ($x) /xmsgc) {
            if (CORE::length($1) == 1) {
                push @sbcs, $1;
            }
            else {
                push @xbcs, '(?:' . escape_to_hex($1, ']') . ')';
            }
        }

        # something wrong happened
        else {
            die sprintf(<<END, pos($_), CORE::substr($_,pos($_)));
$0(@{[__LINE__]}): something wrong happened in script at pos=%s
------------------------------------------------------------------------------
%s
------------------------------------------------------------------------------
END
        }
    }

    # return codepoint class
    my $parsed =
        ( @sbcs and  @xbcs) ? join('|', @xbcs, '['.join('',@sbcs).']') :
        (!@sbcs and  @xbcs) ? join('|', @xbcs                        ) :
        ( @sbcs and !@xbcs) ?                  '['.join('',@sbcs).']'  :
        die;
    return $parsed;
}

#---------------------------------------------------------------------
# parse qr'regexp' as q-like
sub parse_re_as_q_endswith {
    my($operator, $endswith) = @_;
    my $parsed = $endswith;
    while (1) {
        if (/\G (\Q$endswith\E) /xmsgc) {
            $parsed .= $1;
            last;
        }

        # get codepoint class
        elsif (/\G \[ /xmsgc) {
            my $classmate = '';
            while (1) {
                if (/\G \] /xmsgc) {
                    last;
                }
                elsif (/\G (\[:\^[a-z]*:\]) /xmsgc) {
                    $classmate .= $1;
                }
                elsif (/\G (\[:[a-z]*:\]) /xmsgc) {
                    $classmate .= $1;
                }
                elsif (/\G ($x) /xmsgc) {
                    $classmate .= $1;
                }

                # something wrong happened
                else {
                    die sprintf(<<END, pos($_), CORE::substr($_,pos($_)));
$0(@{[__LINE__]}): something wrong happened in script at pos=%s
------------------------------------------------------------------------------
%s
------------------------------------------------------------------------------
END
                }
            }

            # parse codepoint class
            $parsed .= mb::_cc($classmate);
        }

        # /./ or \any
        elsif (/\G \.  /xmsgc) { $parsed .= "(?:$over_ascii|.)";    } # after $over_ascii, /s modifier wants "." (not [\x00-\xFF])
        elsif (/\G \\B /xmsgc) { $parsed .= "(?:(?<![$bare_w])(?![$bare_w])|(?<=[$bare_w])(?=[$bare_w]))"; }
        elsif (/\G \\D /xmsgc) { $parsed .= "(?:(?![$bare_d])$x)";  }
        elsif (/\G \\H /xmsgc) { $parsed .= "(?:(?![$bare_h])$x)";  }
        elsif (/\G \\N /xmsgc) { $parsed .= "(?:(?!\\n)$x)";        }
        elsif (/\G \\R /xmsgc) { $parsed .= "(?>\\r\\n|[$bare_v])"; }
        elsif (/\G \\S /xmsgc) { $parsed .= "(?:(?![$bare_s])$x)";  }
        elsif (/\G \\V /xmsgc) { $parsed .= "(?:(?![$bare_v])$x)";  }
        elsif (/\G \\W /xmsgc) { $parsed .= "(?:(?![$bare_w])$x)";  }
        elsif (/\G \\b /xmsgc) { $parsed .= "(?:(?<![$bare_w])(?=[$bare_w])|(?<=[$bare_w])(?![$bare_w]))"; }
        elsif (/\G \\d /xmsgc) { $parsed .= "[$bare_d]";            }
        elsif (/\G \\h /xmsgc) { $parsed .= "[$bare_h]";            }
        elsif (/\G \\s /xmsgc) { $parsed .= "[$bare_s]";            }
        elsif (/\G \\v /xmsgc) { $parsed .= "[$bare_v]";            }
        elsif (/\G \\w /xmsgc) { $parsed .= "[$bare_w]";            }

        # \o{...}
        elsif (/\G \\o\{ (.*?) \} /xmsgc) {
            $parsed .= '(?:';
            $parsed .= escape_to_hex(mb::chr(oct $1), $endswith);
            $parsed .= ')';
        }

        # \x{...}
        elsif (/\G \\x\{ (.*?) \} /xmsgc) {
            $parsed .= '(?:';
            $parsed .= escape_to_hex(mb::chr(hex $1), $endswith);
            $parsed .= ')';
        }

        # \0... octal escape
        elsif (/\G (\\ 0[1-7]*) /xmsgc) {
            $parsed .= $1;
        }

        # \100...\x377 octal escape
        elsif (/\G (\\ [1-3][0-7][0-7]) /xmsgc) {
            $parsed .= $1;
        }

        # \1...\99, ... n-th previously captured string (decimal)
        elsif (/\G (\\) ([1-9][0-9]*) /xmsgc) {
            $parsed .= $1;
            if ($operator eq 's') {
                $parsed .= ($2 + 1);
            }
            else {
                $parsed .= $2;
            }
        }

        # any
        elsif (/\G ($x) /xmsgc) {
            if (CORE::length($1) == 1) {
                $parsed .= $1;
            }
            else {
                $parsed .= '(?:';
                $parsed .= escape_to_hex($1, $endswith);
                $parsed .= ')';
            }
        }

        # something wrong happened
        else {
            die sprintf(<<END, pos($_), CORE::substr($_,pos($_)));
$0(@{[__LINE__]}): something wrong happened in script at pos=%s
------------------------------------------------------------------------------
%s
------------------------------------------------------------------------------
END
        }
    }
    return $parsed;
}

#---------------------------------------------------------------------
# parse qr{regexp} in balanced blackets
sub parse_re_balanced {
    my($operator, $open_bracket) = @_;
    my $close_bracket = {qw| ( ) { } [ ] < > |}->{$open_bracket} || die;
    my $parsed = $open_bracket;
    my $nest_bracket = 1;
    my $nest_escape = 0;
    while (1) {
        if (/\G (\Q$open_bracket\E) /xmsgc) {
            $parsed .= $1;
            $nest_bracket++;
        }
        elsif (/\G (\Q$close_bracket\E) /xmsgc) {
            if (--$nest_bracket <= 0) {
                $parsed .= ('>)]}' x $nest_escape);
                $parsed .= $1;
                last;
            }
            else {
                $parsed .= $1;
            }
        }

        # \L\u --> \u\L
        elsif (/\G \\L \\u /xmsgc) {
            $parsed .= '@{[mb::ucfirst(qq<';
            $parsed .= '@{[mb::lc(qq<';
            $nest_escape++;
            $nest_escape++;
        }

        # \U\l --> \l\U
        elsif (/\G \\U \\l /xmsgc) {
            $parsed .= '@{[mb::lcfirst(qq<';
            $parsed .= '@{[mb::uc(qq<';
            $nest_escape++;
            $nest_escape++;
        }

        # \L
        elsif (/\G \\L /xmsgc) {
            $parsed .= '@{[mb::lc(qq<';
            $nest_escape++;
        }

        # \U
        elsif (/\G \\U /xmsgc) {
            $parsed .= '@{[mb::uc(qq<';
            $nest_escape++;
        }

        # \l
        elsif (/\G \\l /xmsgc) {
            $parsed .= '@{[mb::lcfirst(qq<';
            $nest_escape++;
        }

        # \u
        elsif (/\G \\u /xmsgc) {
            $parsed .= '@{[mb::ucfirst(qq<';
            $nest_escape++;
        }

        # \Q
        elsif (/\G \\Q /xmsgc) {
            $parsed .= '@{[quotemeta(qq<';
            $nest_escape++;
        }

        # \E
        elsif (/\G \\E /xmsgc) {
            $parsed .= ('>)]}' x $nest_escape);
            $nest_escape = 0;
        }

        else {
            $parsed .= parse_re($operator, $open_bracket);
        }
    }
    return $parsed;
}

#---------------------------------------------------------------------
# parse qr/regexp/ that ends with a character
sub parse_re_endswith {
    my($operator, $endswith) = @_;
    my $parsed = $endswith;
    my $nest_escape = 0;
    while (1) {
        if (/\G (\Q$endswith\E) /xmsgc) {
            $parsed .= ('>)]}' x $nest_escape);
            $parsed .= $1;
            last;
        }

        # \L\u --> \u\L
        elsif (/\G \\L \\u /xmsgc) {
            $parsed .= '@{[mb::ucfirst(qq<';
            $parsed .= '@{[mb::lc(qq<';
            $nest_escape++;
            $nest_escape++;
        }

        # \U\l --> \l\U
        elsif (/\G \\U \\l /xmsgc) {
            $parsed .= '@{[mb::lcfirst(qq<';
            $parsed .= '@{[mb::uc(qq<';
            $nest_escape++;
            $nest_escape++;
        }

        # \L
        elsif (/\G \\L /xmsgc) {
            $parsed .= '@{[mb::lc(qq<';
            $nest_escape++;
        }

        # \U
        elsif (/\G \\U /xmsgc) {
            $parsed .= '@{[mb::uc(qq<';
            $nest_escape++;
        }

        # \l
        elsif (/\G \\l /xmsgc) {
            $parsed .= '@{[mb::lcfirst(qq<';
            $nest_escape++;
        }

        # \u
        elsif (/\G \\u /xmsgc) {
            $parsed .= '@{[mb::ucfirst(qq<';
            $nest_escape++;
        }

        # \Q
        elsif (/\G \\Q /xmsgc) {
            $parsed .= '@{[quotemeta(qq<';
            $nest_escape++;
        }

        # \E
        elsif (/\G \\E /xmsgc) {
            $parsed .= ('>)]}' x $nest_escape);
            $nest_escape = 0;
        }

        else {
            $parsed .= parse_re($operator, $endswith);
        }
    }
    return $parsed;
}

#---------------------------------------------------------------------
# parse qr/regexp/ common routine
sub parse_re {
    my($operator, $closewith) = @_;
    my $parsed = '';

    # codepoint class
    if (/\G \[ /xmsgc) {
        my $classmate = '';
        while (1) {
            if (/\G \] /xmsgc) {
                last;
            }
            elsif (/\G (\\) /xmsgc) {
                $classmate .= "\\$1";
            }
            elsif (/\G (\[:\^[a-z]*:\]) /xmsgc) {
                $classmate .= $1;
            }
            elsif (/\G (\[:[a-z]*:\]) /xmsgc) {
                $classmate .= $1;
            }
            elsif (/\G ($x) /xmsgc) {
                $classmate .= escape_qq($1, ']');
            }

            # something wrong happened
            else {
                die sprintf(<<END, pos($_), CORE::substr($_,pos($_)));
$0(@{[__LINE__]}): something wrong happened in script at pos=%s
------------------------------------------------------------------------------
%s
------------------------------------------------------------------------------
END
            }
        }

        # quote by (?: ... ) to avoid syntax error: Can't coerce array into hash at ...
        #
        # [ABC]{3} --> @{[mb::_cc(qq[ABC])]}{3}     # makes: Can't coerce array into hash at ...
        # [ABC]{3} --> (?:@{[mb::_cc(qq[ABC])]}){3} # ok

        $parsed .= "(?:\@{[mb::_cc(qq[$classmate])]})";
    }

    # /./ or \any
    elsif (/\G \.  /xmsgc) { $parsed .= '(?:@{[@mb::_dot]})'; }
    elsif (/\G \\B /xmsgc) { $parsed .= '(?:@{[@mb::_B]})';   }
    elsif (/\G \\D /xmsgc) { $parsed .= '(?:@{[@mb::_D]})';   }
    elsif (/\G \\H /xmsgc) { $parsed .= '(?:@{[@mb::_H]})';   }
    elsif (/\G \\N /xmsgc) { $parsed .= '(?:@{[@mb::_N]})';   }
    elsif (/\G \\R /xmsgc) { $parsed .= '(?:@{[@mb::_R]})';   }
    elsif (/\G \\S /xmsgc) { $parsed .= '(?:@{[@mb::_S]})';   }
    elsif (/\G \\V /xmsgc) { $parsed .= '(?:@{[@mb::_V]})';   }
    elsif (/\G \\W /xmsgc) { $parsed .= '(?:@{[@mb::_W]})';   }
    elsif (/\G \\b /xmsgc) { $parsed .= '(?:@{[@mb::_b]})';   }
    elsif (/\G \\d /xmsgc) { $parsed .= '(?:@{[@mb::_d]})';   }
    elsif (/\G \\h /xmsgc) { $parsed .= '(?:@{[@mb::_h]})';   }
    elsif (/\G \\s /xmsgc) { $parsed .= '(?:@{[@mb::_s]})';   }
    elsif (/\G \\v /xmsgc) { $parsed .= '(?:@{[@mb::_v]})';   }
    elsif (/\G \\w /xmsgc) { $parsed .= '(?:@{[@mb::_w]})';   }

    # \o{...}
    elsif (/\G \\o\{ (.*?) \} /xmsgc) {
        $parsed .= '(?:';
        $parsed .= escape_to_hex(mb::chr(oct $1), $closewith);
        $parsed .= ')';
    }

    # \x{...}
    elsif (/\G \\x\{ (.*?) \} /xmsgc) {
        $parsed .= '(?:';
        $parsed .= escape_to_hex(mb::chr(hex $1), $closewith);
        $parsed .= ')';
    }

    # \0... octal escape
    elsif (/\G (\\ 0[1-7]*) /xmsgc) {
        $parsed .= $1;
    }

    # \100...\x377 octal escape
    elsif (/\G (\\ [1-3][0-7][0-7]) /xmsgc) {
        $parsed .= $1;
    }

    # \1...\99, ... n-th previously captured string (decimal)
    elsif (/\G (\\) ([1-9][0-9]*) /xmsgc) {
        $parsed .= $1;
        if ($operator eq 's') {
            $parsed .= ($2 + 1);
        }
        else {
            $parsed .= $2;
        }
    }

    # \any
    elsif (/\G (\\) ($x) /xmsgc) {
        if (CORE::length($2) == 1) {
            $parsed .= ($1 . $2);
        }
        else {
            $parsed .= ('(?:' . $1 . escape_qq($2, $closewith) . ')');
        }
    }

    # $`           --> @{[mb::_clustered_codepoint(mb::_PREMATCH())]}
    # ${`}         --> @{[mb::_clustered_codepoint(mb::_PREMATCH())]}
    # $PREMATCH    --> @{[mb::_clustered_codepoint(mb::_PREMATCH())]}
    # ${PREMATCH}  --> @{[mb::_clustered_codepoint(mb::_PREMATCH())]}
    # ${^PREMATCH} --> @{[mb::_clustered_codepoint(mb::_PREMATCH())]}
    elsif (/\G (?: \$` | \$\{`\} | \$PREMATCH | \$\{PREMATCH\} | \$\{\^PREMATCH\} ) /xmsgc) {
        $parsed .= '@{[mb::_clustered_codepoint(mb::_PREMATCH())]}';
    }

    # $&        --> @{[mb::_clustered_codepoint(mb::_MATCH())]}
    # ${&}      --> @{[mb::_clustered_codepoint(mb::_MATCH())]}
    # $MATCH    --> @{[mb::_clustered_codepoint(mb::_MATCH())]}
    # ${MATCH}  --> @{[mb::_clustered_codepoint(mb::_MATCH())]}
    # ${^MATCH} --> @{[mb::_clustered_codepoint(mb::_MATCH())]}
    elsif (/\G (?: \$& | \$\{&\} | \$MATCH | \$\{MATCH\} | \$\{\^MATCH\} ) /xmsgc) {
        $parsed .= '@{[mb::_clustered_codepoint(mb::_MATCH())]}';
    }

    # $1 --> @{[mb::_clustered_codepoint(mb::_CAPTURE(1))]}
    # $2 --> @{[mb::_clustered_codepoint(mb::_CAPTURE(2))]}
    # $3 --> @{[mb::_clustered_codepoint(mb::_CAPTURE(3))]}
    elsif (/\G \$ ([1-9][0-9]*) /xmsgc) {
        $parsed .= "\@{[mb::_clustered_codepoint(mb::_CAPTURE($1))]}";
    }

    # ${^CAPTURE}[0] --> @{[mb::_clustered_codepoint(mb::_CAPTURE(1))]}
    # ${^CAPTURE}[1] --> @{[mb::_clustered_codepoint(mb::_CAPTURE(2))]}
    # ${^CAPTURE}[2] --> @{[mb::_clustered_codepoint(mb::_CAPTURE(3))]}
    elsif (/\G \$\{\^CAPTURE\} \s* (\[) /xmsgc) {
        my $n_th = quotee_of(parse_expr_balanced($1));
        $parsed .= "\@{[mb::_clustered_codepoint(mb::_CAPTURE($n_th+1))]}";
    }

    # @-                   --> @{[mb::_LAST_MATCH_START()]}
    # @LAST_MATCH_START    --> @{[mb::_LAST_MATCH_START()]}
    # @{LAST_MATCH_START}  --> @{[mb::_LAST_MATCH_START()]}
    # @{^LAST_MATCH_START} --> @{[mb::_LAST_MATCH_START()]}
    elsif (/\G (?: \@- | \@LAST_MATCH_START | \@\{LAST_MATCH_START\} | \@\{\^LAST_MATCH_START\} ) /xmsgc) {
        $parsed .= '@{[mb::_LAST_MATCH_START()]}';
    }

    # $-[1]                   --> @{[mb::_LAST_MATCH_START(1)]}
    # $LAST_MATCH_START[1]    --> @{[mb::_LAST_MATCH_START(1)]}
    # ${LAST_MATCH_START}[1]  --> @{[mb::_LAST_MATCH_START(1)]}
    # ${^LAST_MATCH_START}[1] --> @{[mb::_LAST_MATCH_START(1)]}
    elsif (/\G (?: \$- | \$LAST_MATCH_START | \$\{LAST_MATCH_START\} | \$\{\^LAST_MATCH_START\} ) \s* (\[) /xmsgc) {
        my $n_th = quotee_of(parse_expr_balanced($1));
        $parsed .= "\@{[mb::_LAST_MATCH_START($n_th)]}";
    }

    # @+                 --> @{[mb::_LAST_MATCH_END()]}
    # @LAST_MATCH_END    --> @{[mb::_LAST_MATCH_END()]}
    # @{LAST_MATCH_END}  --> @{[mb::_LAST_MATCH_END()]}
    # @{^LAST_MATCH_END} --> @{[mb::_LAST_MATCH_END()]}
    elsif (/\G (?: \@\+ | \@LAST_MATCH_END | \@\{LAST_MATCH_END\} | \@\{\^LAST_MATCH_END\} ) /xmsgc) {
        $parsed .= '@{[mb::_LAST_MATCH_END()]}';
    }

    # $+[1]                 --> @{[mb::_LAST_MATCH_END(1)]}
    # $LAST_MATCH_END[1]    --> @{[mb::_LAST_MATCH_END(1)]}
    # ${LAST_MATCH_END}[1]  --> @{[mb::_LAST_MATCH_END(1)]}
    # ${^LAST_MATCH_END}[1] --> @{[mb::_LAST_MATCH_END(1)]}
    elsif (/\G (?: \$\+ | \$LAST_MATCH_END | \$\{LAST_MATCH_END\} | \$\{\^LAST_MATCH_END\} ) \s* (\[) /xmsgc) {
        my $n_th = quotee_of(parse_expr_balanced($1));
        $parsed .= "\@{[mb::_LAST_MATCH_END($n_th)]}";
    }

    # any
    elsif (/\G ($x) /xmsgc) {
        if (CORE::length($1) == 1) {
            $parsed .= $1;
        }
        else {
            $parsed .= ('(?:' . escape_qq($1, $closewith) . ')');
        }
    }

    # something wrong happened
    else {
        die sprintf(<<END, pos($_), CORE::substr($_,pos($_)));
$0(@{[__LINE__]}): something wrong happened in script at pos=%s
------------------------------------------------------------------------------
%s
------------------------------------------------------------------------------
END
    }
    return $parsed;
}

#---------------------------------------------------------------------
# parse modifiers of qr///here
sub parse_re_modifier {
    my $modifier_i = '';
    my $modifier_not_cegir = '';
    my $modifier_cegr = '';
    while (1) {
        if (/\G [adlpu] /xmsgc) {
            # drop modifiers
        }
        elsif (/\G ([i]) /xmsgc) {
            $modifier_i .= $1;
        }
        elsif (/\G ([cegr]) /xmsgc) {
            $modifier_cegr .= $1;
        }
        elsif (/\G ([a-z]) /xmsgc) {
            $modifier_not_cegir .= $1;
        }
        else {
            last;
        }
    }
    return ($modifier_i, $modifier_not_cegir, $modifier_cegr);
}

#---------------------------------------------------------------------
# parse modifiers of tr///here
sub parse_tr_modifier {
    my $modifier_not_r = '';
    my $modifier_r = '';
    while (1) {
        if (/\G ([r]) /xmsgc) {
            $modifier_r .= $1;
        }
        elsif (/\G ([a-z]) /xmsgc) {
            $modifier_not_r .= $1;
        }
        else {
            last;
        }
    }
    return ($modifier_not_r, $modifier_r);
}

#---------------------------------------------------------------------
# makes codepoint class from string
sub codepoint_tr {
    my $searchlist = quotee_of($_[0]);

    my @sbcs = ();
    my @xbcs = (); # "xbcs" means DBCS, TBCS, QBCS, ...
    while ($searchlist !~ /\G \z /xmsgc) {

        # \-
        if ($searchlist =~ /\G (\\-) /xmsgc) {
            push @sbcs, $1;
        }

        # -
        elsif ($searchlist =~ /\G (-) /xmsgc) {
            push @sbcs, $1;
        }

        # any qq escapee
        elsif ($searchlist =~ /\G ([$escapee_in_qq_like]) /xmsgc) {
            push @sbcs, "\\$1";
        }

        # any
        elsif ($searchlist =~ /\G ($x) /xmsgc) {
            if (CORE::length($1) == 1) {
                push @sbcs, $1;
            }
            else {
                push @xbcs, escape_qq($1, '\\');
            }
        }

        # something wrong happened
        else {
            die sprintf(<<END, pos($_), CORE::substr($_,pos($_)));
$0(@{[__LINE__]}): something wrong happened in script at pos=%s
------------------------------------------------------------------------------
%s
------------------------------------------------------------------------------
END
        }
    }

    # return codepoint class
    return
        ( @sbcs and  @xbcs) ? join('|', @xbcs, '['.join('',@sbcs).']') :
        (!@sbcs and  @xbcs) ? join('|', @xbcs                        ) :
        ( @sbcs and !@xbcs) ?                  '['.join('',@sbcs).']'  :
        die;
}

#---------------------------------------------------------------------
# get quotee from quoted "quotee"
sub quotee_of {
    if (CORE::length($_[0]) >= 2) {
        return CORE::substr($_[0],1,-1);
    }
    else {
        die;
    }
}

#---------------------------------------------------------------------
# escape q/string/ as q-like quote
sub escape_q {
    my($codepoint, $endswith) = @_;
    if ($codepoint =~ /\A ([^\x00-\x7F]) (\Q$endswith\E) \z/xms) {
        return "$1\\$2";
    }
    elsif ($codepoint =~ /\A ([^\x00-\x7F]) ($escapee_in_q__like) \z/xms) {
        return "$1\\$2";
    }
    else {
        return $codepoint;
    }
}

#---------------------------------------------------------------------
# escape qq/string/ as qq-like quote
sub escape_qq {
    my($codepoint, $endswith) = @_;

    # m@`@    --> m`\x60`
    # qr@`@   --> qr`\x60`
    # s@`@``@ --> s`\x60`\x60\x60`
    # m:`:    --> m`\x60`
    # qr:`:   --> qr`\x60`
    # s:`:``: --> s`\x60`\x60\x60`
    if ($codepoint eq '`') {
        return '\\x60';
    }
    elsif ($codepoint =~ /\A ([^\x00-\x7F]) (\Q$endswith\E) \z/xms) {
        return "$1\\$2";
    }
    elsif ($codepoint =~ /\A ([^\x00-\x7F]) ([$escapee_in_qq_like]) \z/xms) {
        return "$1\\$2";
    }
    else {
        return $codepoint;
    }
}

#---------------------------------------------------------------------
# escape tr/here/here/ as tr-like quote
sub escape_tr {
    my($codepoint, $endswith) = @_;
    if ($codepoint =~ /\A (\Q$endswith\E) \z/xms) {
        return "\\$1";
    }
    elsif ($codepoint =~ /\A ([^\x00-\x7F]) (\Q$endswith\E) \z/xms) {
        return "$1\\$2";
    }
    elsif ($codepoint =~ /\A ([^\x00-\x7F]) ($escapee_in_q__like) \z/xms) {
        return "$1\\$2";
    }
    else {
        return $codepoint;
    }
}

#---------------------------------------------------------------------
# escape qq/string/ or qr/regexp/ to hex
sub escape_to_hex {
    my($codepoint, $endswith) = @_;
    if ($codepoint =~ /\A ([^\x00-\x7F]) (\Q$endswith\E) \z/xms) {
        return sprintf('\x%02X\x%02X', CORE::ord($1), CORE::ord($2));
    }

    # in qr'...', $escapee_in_qq_like is right, not $escapee_in_q__like
    elsif ($codepoint =~ /\A ([^\x00-\x7F]) ([$escapee_in_qq_like]) \z/xms) {
        return sprintf('\x%02X\x%02X', CORE::ord($1), CORE::ord($2));
    }
    else {
        return $codepoint;
    }
}

#---------------------------------------------------------------------
# compatible routines for %mb of UTF8::R2 module
#
# tie my %mb, 'mb';
# $result = $_ =~ $mb{qr/$utf8regex/imsxo}
# $result = $_ =~ m<\G$mb{qr/$utf8regex/imsxo}>gc
# $result = $_ =~ s<$mb{qr/before/imsxo}><after>egr

sub TIEHASH  { bless { }, $_[0] }
sub FETCH    { $_[1] }
sub STORE    { }
sub FIRSTKEY { }
sub NEXTKEY  { }
sub EXISTS   { }
sub DELETE   { }
sub CLEAR    { }
sub UNTIE    { }
sub DESTROY  { }
sub SCALAR   { }

#---------------------------------------------------------------------

1;

__END__

=pod
=encoding utf-8
=head1 NAME
=head1 SYNOPSIS
=head1 INSTALLATION BY MAKE-COMMAND
=head1 INSTALLATION WITHOUT MAKE-COMMAND (for DOS-like system)
=head1 DESCRIPTION
=over 2
=item *
=item *
=item *
=item *
=item *
=back
=over 2
=item *
=item *
=item *
=item *
=back
=over 2
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=back
=head1 Larry Wall-san's way
=head1 Perl 5.42 and source::encoding
=head1 TERMINOLOGY
=over 2
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=back
=head1 Differences and History between jcode.pl and JPerl
=head2 General Model of Information Processing
=head2 History of Supporting MBCS I/O on Perl
=over 2
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=back
=head2 History of Supporting MBCS Literal in Perl Script
=over 2
=item *
=item *
=item *
=item *
=item *
=item *
=back
=head1 Which US-ASCII code makes DAMEMOJI?
=head1 MBCS Encodings supported by this software
=head2 big5 (Big5)
=over 2
=item *
=item *
=item *
=item *
=back
=head2 big5hkscs (Big5-HKSCS)
=over 2
=item *
=item *
=item *
=item *
=back
=head2 eucjp (EUC-JP)
=over 2
=item *
=item *
=item *
=back
=head2 gb18030 (GB18030)
=over 2
=item *
=item *
=item *
=item *
=back
=head2 gbk (GBK)
=over 2
=item *
=item *
=item *
=item *
=back
=head2 rfc2279 (UTF-8 RFC2279)
=over 2
=item *
=item *
=item *
=item *
=back
=head2 sjis (Shift_JIS-like encodings, ex. cp932)
=over 2
=item *
=item *
=item *
=item *
=back
=head2 uhc (UHC)
=over 2
=item *
=item *
=item *
=back
=head2 utf8 (UTF-8 RFC3629)
=over 2
=item *
=item *
=item *
=item *
=back
=head2 wtf8 (WTF-8)
=over 2
=item *
=item *
=item *
=item *
=back
=head1 MBCS subroutines provided by this software
=head1 MBCS special variables provided by this software
=over 2
=item *
=item *
=back
=head1 Porting from script in bare Perl4, and bare Perl5
=head2 If you want to write US-ASCII scripts from now on, or port existing US-ASCII scripts to mb.pm
=head2 On other hand, if you want to write octet-oriented scripts from now on, or port existing octet-oriented scripts to mb.pm
=head1 Porting from script in JPerl4, and JPerl5
=head2 If you want to port existing JPerl scripts to mb.pm
=head1 Porting from script with utf8 pragma
=head2 If you want to port existing scripts that has utf8 pragma to mb.pm
=head1 Porting from script with UTF8::R2 module
=head2 Remove this line first
=head2 Use "mb::use" or "mb::no" to support modules in UTF-8
=head2 Use $mb::* variables to support modules in UTF-8
=head1 Porting from script with Sjis software
=over 2
=item *
=item *
=back
=over 2
=item *
=back
=over 2
=item *
=item *
=item *
=back
=head1 Syntax Sugar of mb.pm modulino
=head1 What are DAMEMOJI?
=head1 How to escape 2nd octet of DAMEMOJI
=over 2
=item 1
=item 2
=item 3
=back
=head2 on big5 encoding
=head2 on big5hkscs encoding
=head2 on gb18030 encoding
=head2 on gbk encoding
=head2 on sjis encoding
=head1 What are CHANTOSHITAMOJI?
=head1 MBCS character casing (solves CHANTOSHITAMOJI problem)
=head2 lc() works as
=head2 uc() works as
=head1 What transpiles to what by this software?
=head2 on every encodings
=head2 on big5 encoding
=head2 on big5hkscs encoding
=head2 on eucjp encoding
=head2 on gb18030 encoding
=head2 on gbk encoding
=head2 on rfc2279 encoding
=head2 on sjis encoding
=head2 on uhc encoding
=head2 on utf8 encoding
=head2 on wtf8 encoding
=head1 Command-line Wildcard Expansion on Microsoft Windows
=head1 DEPENDENCIES
=head1 Fatal Bugs Unavoidable
=over 2
=item *
=item *
=back
=head1 Small Bugs (Avoidable by Your Scripting)
=over 2
=item *
=item *
=item *
=back
=head1 Comming Features (Tell us Good Idea)
=over 2
=item *
=item *
=back
=head1 Lost Features
=over 2
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=back
=head1 Our Goals
=over 2
=item *
=item *
=back
=over 2
=item *
=item *
=item *
=back
=over 2
=item *
=item *
=back
=over 2
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=back
=over 2
=item *
=item *
=item *
=item *
=item *
=back
=head1 Perl's Motto
=head1 Combinations of mb.pm Modulino and Other Modules
=head1 Using mb.pm Modulino vs. Using UTF8::R2 Module
=head2 Advantages of mb.pm Modulino
=over 2
=item *
=item *
=item *
=item *
=item *
=back
=head2 Disadvantages of mb.pm Modulino
=over 2
=item *
=item *
=back
=head2 Advantages of UTF8::R2 Module
=over 2
=item *
=item *
=back
=head2 Disadvantages of UTF8::R2 Module
=over 2
=item *
=item *
=item *
=item *
=item *
=item *
=back
=head1 GIVE US BUG REPORT
=head1 From 1998 To You
=head1 How To Update This Distribution
=over 2
=item 1
=item 2
=item 3
=item 4
=item 5
=item 6
=item 7
=item 8
=item 9
=back
=head1 AUTHOR
=head1 LICENSE AND COPYRIGHT
=head1 SEE ALSO
=head1 ACKNOWLEDGEMENTS

=cut
