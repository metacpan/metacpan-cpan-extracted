package Perl7::Handy;
######################################################################
#
# Perl7::Handy - Handy Perl7 scripting environment on Perl5
#
# https://metacpan.org/release/Perl7-Handy
#
# Copyright (c) 2020 INABA Hitoshi <ina@cpan.org>
######################################################################

use 5.00503;    # Universal Consensus 1998 for primetools
# use 5.008001; # Lancaster Consensus 2013 for toolchains

$VERSION = '0.03';
$VERSION = $VERSION;

BEGIN { pop @INC if $INC[-1] eq '.' } # CVE-2016-1238: Important unsafe module load path flaw
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 } use warnings; local $^W=1;

use Fcntl;

#---------------------------------------------------------------------
# confess() for this module
sub Perl7::Handy::confess (@) {
    my $i = 0;
    my @confess = ();
    while (my($package,$filename,$line,$subroutine) = caller($i)) {
        push @confess, "[$i] $filename($line) ${package}::$subroutine\n";
        $i++;
    }
    print STDERR __PACKAGE__, " says:\n";
    print STDERR CORE::reverse @confess;
    print STDERR "\n";
    print STDERR @_, "\n";
    die "\n";
}

#---------------------------------------------------------------------
# open() that can't use bareword
sub Perl7::Handy::open (*$;$) {
    my $handle;

    if (defined $_[0]) {
        Perl7::Handy::confess "Bare handle no longer supported";
    }
    else {
        $handle = $_[0] = \do { local *_ };
    }

    if (@_ >= 4) {
        Perl7::Handy::confess "Too many arguments for open";
    }
    elsif (@_ == 3) {
        my($mode,$filename) = @_[1,2];

        if ($mode eq '-|') {
            my $return = CORE::open($handle,qq{$filename |});
            if ($return or defined wantarray) {
                return $return;
            }
            else {
                Perl7::Handy::confess "Can't open($_[0],$_[1],$_[2]): $!";
            }
        }
        elsif ($mode eq '|-') {
            my $return = CORE::open($handle,qq{| $filename});
            if ($return or defined wantarray) {
                return $return;
            }
            else {
                Perl7::Handy::confess "Can't open($_[0],$_[1],$_[2]): $!";
            }
        }
        else {
            my %flags = (
                '<'   => O_RDONLY,
                '>'   => O_WRONLY | O_TRUNC  | O_CREAT,
                '>>'  => O_WRONLY | O_APPEND | O_CREAT,
                '+<'  => O_RDWR,
                '+>'  => O_RDWR   | O_TRUNC  | O_CREAT,
                '+>>' => O_RDWR   | O_APPEND | O_CREAT,
            );
            if (not exists $flags{$mode}) {
                Perl7::Handy::confess "Unknown open() mode '$mode'";
            }
            my $return = CORE::sysopen($handle,$filename,$flags{$mode});
            if ($return or defined wantarray) {
                return $return;
            }
            else {
                Perl7::Handy::confess "Can't open($_[0],$_[1],$_[2]): $!";
            }
        }
    }
    elsif (@_ == 2) {
        my $return = CORE::open($handle,$_[1]);
        if ($return or defined wantarray) {
            return $return;
        }
        else {
            Perl7::Handy::confess "Can't open($_[0],$_[1]): $!";
        }
    }
    else {
        Perl7::Handy::confess "Not enough arguments for open";
    }
}

#---------------------------------------------------------------------
# opendir() that can't use bareword
sub Perl7::Handy::opendir (*$) {
    my $handle;

    if (defined $_[0]) {
        Perl7::Handy::confess "Bare handle no longer supported";
    }
    else {
        $handle = $_[0] = \do { local *_ };
    }

    my $return;
    if ($return = CORE::opendir($handle,$_[1])) {
    }
    elsif (($^O =~ /MSWin32/) and (-d qq{$_[1].})) {
        $return = CORE::opendir($handle,qq{$_[1].});
    }

    if ($return or defined wantarray) {
        return $return;
    }
    else {
        Perl7::Handy::confess "Can't opendir($_[0],$_[1]): $!";
    }
}

#---------------------------------------------------------------------
# sysopen() that can't use bareword
sub Perl7::Handy::sysopen (*$$;$) {
    my $handle;

    if (defined $_[0]) {
        Perl7::Handy::confess "Bare handle no longer supported";
    }
    else {
        $handle = $_[0] = \do { local *_ };
    }

    if (@_ >= 5) {
        Perl7::Handy::confess "Too many arguments for sysopen";
    }
    elsif (@_ == 4) {
        my $return = CORE::sysopen($handle,$_[1],$_[2],$_[3]);
        if ($return or defined wantarray) {
            return $return;
        }
        else {
            Perl7::Handy::confess "Can't sysopen($_[0],$_[1],$_[2],$_[3]): $!";
        }
    }
    elsif (@_ == 3) {
        my $return = CORE::sysopen($handle,$_[1],$_[2]);
        if ($return or defined wantarray) {
            return $return;
        }
        else {
            Perl7::Handy::confess "Can't sysopen($_[0],$_[1],$_[2]): $!";
        }
    }
    else {
        Perl7::Handy::confess "Not enough arguments for sysopen";
    }
}

#---------------------------------------------------------------------
# pipe() that can't use bareword
sub Perl7::Handy::pipe (**) {
    my($handle0,$handle1);

    if (defined $_[0]) {
        Perl7::Handy::confess "Bare handle no longer supported";
    }
    else {
        $handle0 = $_[0] = \do { local *_ };
    }

    if (defined $_[1]) {
        Perl7::Handy::confess "Bare handle no longer supported";
    }
    else {
        $handle1 = $_[1] = \do { local *_ };
    }

    my $return = CORE::pipe($handle0,$handle1);
    if ($return or defined wantarray) {
        return $return;
    }
    else {
        Perl7::Handy::confess "Can't pipe($_[0],$_[1]): $!";
    }
}

#---------------------------------------------------------------------
# socket() that can't use bareword
sub Perl7::Handy::socket (*$$$) {
    my $handle;

    if (defined $_[0]) {
        Perl7::Handy::confess "Bare handle no longer supported";
    }
    else {
        $handle = $_[0] = \do { local *_ };
    }

    # socket doesn't autodie
    return CORE::socket($handle,$_[1],$_[2],$_[3]);
}

#---------------------------------------------------------------------
# accept() that can't use bareword
sub Perl7::Handy::accept (**) {
    my($handle0,$handle1);

    if (defined $_[0]) {
        Perl7::Handy::confess "Bare handle no longer supported";
    }
    else {
        $handle0 = $_[0] = \do { local *_ };
    }

    if (defined $_[1]) {
        Perl7::Handy::confess "Bare handle no longer supported";
    }

    my $return = CORE::accept($handle0,$handle1);
    if ($return or defined wantarray) {
        return $return;
    }
    else {
        Perl7::Handy::confess "Can't accept($_[0],$_[1]): $!";
    }
}

#---------------------------------------------------------------------
# TIESCALAR to disable $; (internal use to "no multidimensional")
sub TIESCALAR {
    my $class = shift;
    my $dummy;
    return bless \$dummy => $class;
}

#---------------------------------------------------------------------
# FETCH to disable $; (internal use to "no multidimensional")
sub FETCH {
    Perl7::Handy::confess "Can't use Perl4-style multidimensional arrays";
}

#---------------------------------------------------------------------
# STORE to disable $; (internal use to "no multidimensional")
sub STORE {
    Perl7::Handy::confess "Can't use Perl4-style multidimensional arrays"
}

#---------------------------------------------------------------------
# gives:
#   use strict;
#   use warnings;
#   no bareword::filehandles;
#   no multidimensional;
sub import {

    # gives caller package "use strict;"
    strict->import;

    # gives caller package "use warnings;" (only perl 5.006 or later)
    if ($] >= 5.006) {
        warnings->import;
    }

    # gives caller package "no bareword::filehandles;"

    # avoid: Can't use string ("main::open") as a symbol ref while "strict refs" in use
    no strict 'refs';
    {
        # avoid: Prototype mismatch: sub main::open (*;$) vs (*$;$)
        local $SIG{__WARN__} = sub {};
        *{caller() . '::open'} = \&Perl7::Handy::open;
    }
    *{caller() . '::opendir'}  = \&Perl7::Handy::opendir;
    *{caller() . '::sysopen'}  = \&Perl7::Handy::sysopen;
    *{caller() . '::pipe'}     = \&Perl7::Handy::pipe;
    *{caller() . '::socket'}   = \&Perl7::Handy::socket;
    *{caller() . '::accept'}   = \&Perl7::Handy::accept;

    # gives caller package "no multidimensional;"
    tie $;, __PACKAGE__;
}

1;

__END__

=pod

=head1 NAME

Perl7::Handy - Handy Perl7 scripting environment on Perl5

=head1 SYNOPSIS

  use Perl7::Handy;

=head1 DESCRIPTION

Perl7::Handy module provides easy Perl7 scripting environment onto perl
5.00503 or later.

=over 4

=item * gives caller package "use strict;"

=item * gives caller package "use warnings;" (only perl 5.006 or later)

=item * gives caller package "no bareword::filehandles;"

=item * gives caller package "no multidimensional;"

=item * removes ".(dot)" from @INC (CVE-2016-1238: Important unsafe module load path flaw)

=back

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt>

This project was originated by INABA Hitoshi.

=head1 LICENSE AND COPYRIGHT

This software is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

=over 4

=item * L<Announcing Perl 7|https://www.perl.com/article/announcing-perl-7/> - perl.com

=item * L<Import pragmas like strict and warnings into callers lexical scope|https://www.perlmonks.org/?node_id=887663> - perlmonks.org

=item * L<Perl import some modules in all subclasses|https://stackoverflow.com/questions/22122390/perl-import-some-modules-in-all-subclasses> - stackoverflow.com

=item * L<open|http://perldoc.perl.org/functions/open.html> - perldoc.perl.org

=item * L<Three-arg open() (Migrating to Modern Perl)|http://modernperlbooks.com/mt/2010/04/three-arg-open-migrating-to-modern-perl.html> - modernperlbooks.com

=item * L<perl - open my $fh, "comand |"; # isn't modern|http://blog.livedoor.jp/dankogai/archives/51176081.html> - 404 Blog Not Found

=item * L<13.15. Creating Magic Variables with tie|https://docstore.mik.ua/orelly/perl3/cookbook/ch13_16.htm> - Perl Cookbook

=item * L<13.15. Creating Magic Variables with tie|https://docstore.mik.ua/orelly/perl4/cook/ch13_16.htm> - Perl Cookbook, 2nd Edition

=item * L<CVE-2016-1238|https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-1238> - CVE

=item * L<CVE-2016-1238: Important unsafe module load path flaw|https://www.nntp.perl.org/group/perl.perl5.porters/2016/07/msg238271.html> - perl.org

=item * L<ina|http://search.cpan.org/~ina/> - cpan.org

=item * L<BackPAN|http://backpan.perl.org/authors/id/I/IN/INA/> - backpan.perl.org

=back

=cut

