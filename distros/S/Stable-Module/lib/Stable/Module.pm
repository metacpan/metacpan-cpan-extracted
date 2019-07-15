package Stable::Module;
######################################################################
#
# Stable::Module - frequently used modules on Perl5 application
#
# http://search.cpan.org/dist/Stable-Module/
#
# Copyright (c) 2014, 2016, 2017, 2018, 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

$VERSION = '0.09';
$VERSION = $VERSION;

use 5.00503;
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; $^W=1;
use Carp;
use FindBin;
use IO::File;

use vars qw($re_char $hide_stderr);

sub VERSION {
    my($self,$version) = @_;
    if ($version != $Stable::Module::VERSION) {
        my($package,$filename,$line) = caller;
        die "$filename requires Stable::Module $version, this is version $Stable::Module::VERSION, stopped at $filename line $line.\n";
    }
}

sub BEGIN {
    if (($^O eq 'MSWin32') and (defined $ENV{'OS'}) and ($ENV{'OS'} eq 'Windows_NT')) {
        $hide_stderr = '2>NUL';
    }
    else {
        $hide_stderr = '';
    }
}

sub import {
    my($caller,$filename,$line) = caller;

    # verify that we're called correctly so that strictures will work.
    if (__FILE__ !~ m{ \b Stable[/\\]Module\.pm \z}x) {
        die "Incorrect use of module '${\__PACKAGE__}' at $filename line $line.\n";
    }

    # get /./ (dot: one character) regexp
    $re_char = qr/[\x00-\xFF]/;

    # Code Page Identifiers (Microsoft Windows)
    # Identifier .NET Name Additional information
    my %re_char = (

        # Sjis     shift_jis ANSI/OEM Japanese; Japanese (Shift-JIS)
          '932' => qr{[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x00-\xFF]},

        # GBK      gb2312 ANSI/OEM Simplified Chinese (PRC, Singapore); Chinese Simplified (GB2312)
          '936' => qr{[\x81-\xFE][\x00-\xFF]|[\x00-\xFF]},

        # UHC      ks_c_5601-1987 ANSI/OEM Korean (Unified Hangul Code)
          '949' => qr{[\x81-\xFE][\x00-\xFF]|[\x00-\xFF]},

        # Big5Plus big5 ANSI/OEM Traditional Chinese (Taiwan; Hong Kong SAR, PRC); Chinese Traditional (Big5)
          '950' => qr{[\x81-\xFE][\x00-\xFF]|[\x00-\xFF]},

        # Big5HKSCS HKSCS support on top of traditional Chinese Windows
          '951' => qr{[\x81-\xFE][\x00-\xFF]|[\x00-\xFF]},

        # GB18030  GB18030 Windows XP and later: GB18030 Simplified Chinese (4 byte); Chinese Simplified (GB18030)
        '54936' => qr{[\x81-\xFE][\x30-\x39][\x81-\xFE][\x30-\x39]|[\x81-\xFE][\x00-\xFF]|[\x00-\xFF]},
    );

    my $codepage = 'File System Safe';
    if ($^O =~ m{\A (?:MSWin32|NetWare|symbian|dos) \z}oxms) {
        $codepage = (qx{chcp} =~ m{ ([0-9]{3,5}) \Z}oxms)[0];
        $re_char = $re_char{$codepage} || $re_char;
    }

    no strict 'refs';

    # use Cwd qw(cwd);
    require Cwd;
    if ($^O =~ m{\A (?:MSWin32|NetWare|symbian|dos) \z}oxms) {
        *{$caller.'::cwd'} = sub { _dos_path(Cwd::cwd) };
    }
    else {
        *{$caller.'::cwd'} = \&Cwd::cwd;
    }

    # use FindBin qw($Bin);
    require FindBin;
    if ($^O =~ m{\A (?:MSWin32|NetWare|symbian|dos) \z}oxms) {
        $FindBin::Bin = _dos_path($FindBin::Bin);
    }
    *{$caller.'::Bin'} = \$FindBin::Bin;

    # use File::Basename qw(fileparse basename dirname);
    # use internal routines always for compatibility -- for example, perl 5.6 has incompatible File::Basename
    if (1 or exists $re_char{$codepage}) {
        $INC{'File/Basename.pm'} = join '/', $FindBin::Bin, __FILE__;
        *{$caller.'::fileparse'} = \&_fileparse;
        *{$caller.'::basename'}  = \&_basename;
        *{$caller.'::dirname'}   = \&_dirname;
    }
    else {
        require File::Basename;
        *{$caller.'::fileparse'} = \&File::Basename::fileparse;
        *{$caller.'::basename'}  = \&File::Basename::basename;
        *{$caller.'::dirname'}   = \&File::Basename::dirname;
    }

    # use File::Path qw(mkpath rmtree);
    if (exists $re_char{$codepage}) {
        $INC{'File/Path.pm'}  = join '/', $FindBin::Bin, __FILE__;
        *{$caller.'::mkpath'} = \&_mkpath;
        *{$caller.'::rmtree'} = \&_rmtree;
    }
    else {
        require File::Path;
        *{$caller.'::mkpath'} = \&File::Path::mkpath;
        *{$caller.'::rmtree'} = \&File::Path::rmtree;
    }

    # use File::Copy qw(copy move);
    if (exists $re_char{$codepage}) {
        $INC{'File/Copy.pm'} = join '/', $FindBin::Bin, __FILE__;
        *{$caller.'::copy'}  = \&_copy;
        *{$caller.'::move'}  = \&_move;
    }
    else {
        require File::Copy;
        *{$caller.'::copy'} = \&File::Copy::copy;
        *{$caller.'::move'} = \&File::Copy::move;
    }

    # use File::Compare qw(compare);
    require File::Compare;
    *{$caller.'::compare'} = \&File::Compare::compare;

    # use Sys::Hostname qw(hostname);
    require Sys::Hostname;
    *{$caller.'::hostname'} = \&Sys::Hostname::hostname;

    # use Time::Local qw(timelocal);
    require Time::Local;
    *{$caller.'::timelocal'} = \&Time::Local::timelocal;

    # internal List::Util::reduce
    sub _reduce (&@) {
        my $coderef = shift @_;
        local $a    = shift @_;
        for $b (@_) {
            $a = $coderef->();
        }
        return $a;
    }

    # use List::Util qw(reduce first shuffle max maxstr min minstr sum);
    *{$caller.'::first'}   = \&_first;
    *{$caller.'::shuffle'} = \&_shuffle;
    *{$caller.'::max'}     = sub { _reduce { $a >  $b ? $a : $b } @_ };
    *{$caller.'::maxstr'}  = sub { _reduce { $a gt $b ? $a : $b } @_ };
    *{$caller.'::min'}     = sub { _reduce { $a <  $b ? $a : $b } @_ };
    *{$caller.'::minstr'}  = sub { _reduce { $a lt $b ? $a : $b } @_ };
    *{$caller.'::sum'}     = sub { _reduce { $a +  $b }           @_ };

    # use List::MoreUtils qw(all any none notall uniq);
    *{$caller.'::all'}    = sub (&@) { my $coderef = shift @_; for (@_) { return 0 if not $coderef->($_) } return 1; }; # All arguments are true
    *{$caller.'::any'}    = sub (&@) { my $coderef = shift @_; for (@_) { return 1 if     $coderef->($_) } return 0; }; # One argument is true
    *{$caller.'::none'}   = sub (&@) { my $coderef = shift @_; for (@_) { return 0 if     $coderef->($_) } return 1; }; # All arguments are false
    *{$caller.'::notall'} = sub (&@) { my $coderef = shift @_; for (@_) { return 1 if not $coderef->($_) } return 0; }; # One argument is false
    *{$caller.'::uniq'}   = \&_uniq;

    # use feature qw(say);
    *{$caller.'::say'} = \&_say;
    *IO::Handle::say   = \&_say if not defined(*IO::Handle::say);
}

sub unimport {
    # nothing
}

sub _fileparse {
    my($fullname,@suffixlist) = @_;

    if (not defined $fullname) {
        croak "fileparse(): need a valid pathname";
    }
    my $taint = substr($fullname,0,0); # Is $fullname tainted?

    my $dirname = '';
    my $subdir  = '';
    while ($fullname =~ m{\G ($re_char) }oxmsgc) {
        my $char = $1;
        if ($char =~ m{\A [:\\/] \z}oxms) {
            $dirname .= $subdir;
            $dirname .= $char;
            $subdir = '';
        }
        else {
            $subdir .= $char;
        }
    }
    my $name = $subdir;

    if (($dirname eq '') or ($dirname =~ m{ : \z}oxms)) {
        $dirname .= '.\\';
    }

    # ignore case of name
    my @char = $name =~ m{\G ($re_char) }oxmsgc;
    my $name_lc = join '', map { lcfirst } @char;
    my $suffix = '';
    if (@suffixlist) {
        for my $s (@suffixlist) {

            # ignore case of suffix
            my @char = $s =~ m{\G ($re_char) }oxmsgc;
            my $s_lc = join '', map { lcfirst } @char;
            if (substr($name_lc,-length($s_lc),length($s_lc)) eq $s_lc) {
                $taint .= substr($s,0,0);
                $suffix = substr($name,-length($s_lc),length($s_lc)) . $suffix;
                $name   = substr($name,0,length($name)-length($s_lc));
            }
        }
    }

    # Ensure taint is propagated from the path to its pieces.
    $name    .= $taint;
    $dirname .= $taint;
    $suffix  .= $taint;
    if (wantarray) {
        return ($name,$dirname,$suffix);
    }
    else {
        return $name;
    }
}

sub _basename {
    my($fullname,@suffixlist) = @_;

    if (not defined $fullname) {
        croak "basename(): need a valid pathname";
    }
    my $taint = substr($fullname,0,0); # Is $fullname tainted?

    # From BSD basename(1)
    # The basename utility deletes any prefix ending with the last slash '/'
    # character present in string (after first stripping trailing slashes)
    $fullname = _strip_trailing_sep($fullname);

    my $dirname = '';
    my $subdir  = '';
    while ($fullname =~ m{\G ($re_char) }oxmsgc) {
        my $char = $1;
        if ($char =~ m{\A [:\\/] \z}oxms) {
            $dirname .= $subdir;
            $dirname .= $char;
            $subdir = '';
        }
        else {
            $subdir .= $char;
        }
    }
    my $name = $subdir;

    if (($dirname eq '') or ($dirname =~ m{ : \z}oxms)) {
        $dirname .= '.\\';
    }

    # ignore case of name
    my @char = $name =~ m{\G ($re_char) }oxmsgc;
    my $name_lc = join '', map { lcfirst } @char;
    my $suffix = '';
    if (@suffixlist) {
        for my $s (@suffixlist) {

            # ignore case of suffix
            my @char = $s =~ m{\G ($re_char) }oxmsgc;
            my $s_lc = join '', map { lcfirst } @char;
            if (substr($name_lc,-length($s_lc),length($s_lc)) eq $s_lc) {
                $taint .= substr($s,0,0);
                $suffix = substr($name,-length($s_lc),length($s_lc)) . $suffix;
                $name   = substr($name,0,length($name)-length($s_lc));
            }
        }
    }

    # From BSD basename(1)
    # The suffix is not stripped if it is identical to the remaining
    # characters in string.
    if (($name eq '') and ($suffix ne '')) {
        $name = $suffix;
    }

    # Ensure that basename '/' == '/'
    if ($name eq '') {
        $name = $dirname;
    }

    # Ensure taint is propagated from the path to its pieces.
    $name .= $taint;
    return $name;
}

sub _dirname {
    my($fullname) = @_;

    if (not defined $fullname) {
        croak "dirname(): need a valid pathname";
    }
    my $taint = substr($fullname,0,0); # Is $fullname tainted?

    my($basename,$dirname) = _fileparse($fullname);
    $dirname = _strip_trailing_sep($dirname);

    if ($basename eq '') {
        ($basename,$dirname) = _fileparse($dirname);
        $dirname = _strip_trailing_sep($dirname);
    }

    # Ensure taint is propagated from the path to its pieces.
    $dirname .= $taint;
    return $dirname;
}

sub _strip_trailing_sep {
    my($dirname) = @_;

    my @char = $dirname =~ m{\G ([\\\/]+|$re_char) }oxmsgc;
    if (scalar(@char) >= 2) {
        if (($char[-1] =~ m{\A [\\\/]+ \z}oxms) and ($char[-2] ne ':')) {
            pop @char;
        }
    }

    return join '', @char;
}

sub _mkpath {
    my $path = _dos_path($_[0]);

    if (_is_directory($_[0])) { # *NOT* _is_directory($path)
        return 1;
    }

    # cmd.exe on Windows NT, Windows 2000, Windows XP, Windows 2003 or later
    elsif ((defined $ENV{'OS'}) and ($ENV{'OS'} eq 'Windows_NT')) {
        if (CORE::system(qq{cmd.exe /E:ON /C mkdir $path >NUL $hide_stderr}) == 0) {
            return 1;
        }
    }

    # COMMAND.COM on Windows 95, Windows 98, Windows 98 Second Edition, Windows Millennium Edition
    else {
        my @subdir = ();
        my $i = 0;
        while ($_[0] =~ m{\G ($re_char) }oxmsgc) {
            my $char = $1;
            if ($char =~ m{\A [\\/] \z}oxms) {
                $i++;
            }
            else {
                $subdir[$i] .= $char;
            }
        }
        if (@subdir >= 2) {
            for my $i (0 .. $#subdir-1) {
                my $path = _dos_path(join '\\',@subdir[0..$i]);
                if (not _is_directory($path)) {
                    CORE::system(qq{mkdir $path >NUL});
                }
            }
        }
        my $path = _dos_path(join '\\',@subdir);
        if (CORE::system(qq{mkdir $path >NUL}) == 0) {
            return 1;
        }
    }

    if (exists $INC{'Strict/Perl.pm'}) {
        croak "mkpath: $path";
    }
    else {
        return undef;
    }
}

sub _rmtree {
    my $root = _dos_path($_[0]);

    if (not _is_directory($_[0])) { # *NOT* not _is_directory($root)
        return 1;
    }

    # cmd.exe on Windows NT, Windows 2000, Windows XP, Windows 2003 or later
    elsif ((defined $ENV{'OS'}) and ($ENV{'OS'} eq 'Windows_NT')) {
        if (CORE::system(qq{rmdir /S /Q $root >NUL $hide_stderr}) == 0) {
            return 1;
        }
    }

    # COMMAND.COM on Windows 95, Windows 98, Windows 98 Second Edition, Windows Millennium Edition
    else {
        my @file = split /\n/, qx{dir /s /b /a-d $root};
        for my $file (@file) {
            $file = _dos_path($file);
            CORE::system(qq{del $file >NUL});
        }
        my @dir = split /\n/, qx{dir /s /b /ad $root};
        for my $dir (sort { length($b) <=> length($a) } @dir) {
            $dir = _dos_path($dir);
            CORE::system(qq{rmdir $dir >NUL});
        }
        if (CORE::system(qq{rmdir $root >NUL}) == 0) {
            return 1;
        }
    }

    if (exists $INC{'Strict/Perl.pm'}) {
        croak "rmdir: $root";
    }
    else {
        return undef;
    }
}

sub _copy {
    my $source = _dos_path($_[0]);
    my $dest   = _dos_path($_[1]);

    if (CORE::system(qq{copy /Y $source $dest >NUL $hide_stderr}) == 0) {
        return 1;
    }
    elsif (exists $INC{'Strict/Perl.pm'}) {
        croak "copy: $source $dest";
    }
    else {
        return undef;
    }
}

sub _move {
    my $source = _dos_path($_[0]);
    my $dest   = _dos_path($_[1]);

    if (CORE::system(qq{move /Y $source $dest >NUL $hide_stderr}) == 0) {
        return 1;
    }
    elsif (exists $INC{'Strict/Perl.pm'}) {
        croak "move: $source $dest";
    }
    else {
        return undef;
    }
}

sub _dos_path {
    my($path) = @_;

    my @char = $path =~ m{\G ($re_char) }oxmsg;
    $path = join '', map {{'/' => '\\'}->{$_} || $_} @char;
    $path = qq{"$path"} if $path =~ m{ };
    return $path;
}

sub _is_directory {
    my($unknown) = @_;

    if (-e $unknown) {
        return -d _;
    }
    elsif (_MSWin32_5Cended_path($unknown)) {
        return -d "$unknown/.";
    }
    return undef;
}

sub _MSWin32_5Cended_path {
    if ((@_ >= 1) and ($_[0] ne '')) {
        if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
            my @char = $_[0] =~ m{\G ($re_char) }oxmsg;
            if ($char[-1] =~ m{ \x5C \z}oxms) {
                return 1;
            }
        }
    }
    return undef;
}

sub _first(&@) {
    my $coderef = shift @_;
    for (@_) {
        if ($coderef->()) {
            return $_;
        }
    }
    return undef;
}

sub _shuffle(@) {
    my @a = \(@_);
    my $n;
    my $i=@_;
    return map { $n = rand($i--); (${$a[$n]}, $a[$n] = $a[$i])[0]; } @_;
}

sub _uniq {
    my %seen = ();
    return grep { not $seen{$_}++ } @_;
}

sub _say {
    my $currfh = select();
    my $handle;
    {
        no strict 'refs';
        $handle = defined(fileno($_[0])) ? shift : \*$currfh;
    }
    @_ = ($_) unless @_;
    return print {$handle} @_, "\n";
}

1;

__END__

=pod

=head1 NAME

Stable::Module - frequently used modules on Perl5 application

=head1 SYNOPSIS

  use Stable::Module;          # any version
  use Stable::Module ver.sion; # match or die

=head1 DESCRIPTION

Stable::Module provides frequently used modules on Perl5 application, on both
modern Perl and traditional Perl.

Stable::Module works as:

  use Cwd             qw(cwd);
  use FindBin         qw($Bin);
  use File::Basename  qw(fileparse basename dirname);
  use File::Path      qw(mkpath rmtree);
  use File::Copy      qw(copy move);
  use File::Compare   qw(compare);
  use Sys::Hostname   qw(hostname);
  use Time::Local     qw(timelocal);
  use List::Util      qw(first shuffle max maxstr min minstr sum);
  use List::MoreUtils qw(all any none notall uniq);
  use feature         qw(say);

fileparse, basename, dirname, mkpath, rmtree, copy, and move can treat multibyte
encoding of path name.

=head1 BUGS

  It is not possible to specify a regular expression to @suffixes.
  my @fileparse = fileparse($path, @suffixes);
  my $basename  = basename($path, @suffixes);

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt> in a CPAN

This project was originated by INABA Hitoshi.

=head1 LICENSE AND COPYRIGHT

This software is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

=over 4

=item * L<ina|http://search.cpan.org/~ina/> - CPAN

=item * L<The BackPAN|http://backpan.perl.org/authors/id/I/IN/INA/> - A Complete History of CPAN

=back

=cut

