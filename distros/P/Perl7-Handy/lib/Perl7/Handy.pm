package Perl7::Handy;
######################################################################
#
# Perl7::Handy - Handy Perl7 scripting environment on Perl5
#
# https://metacpan.org/dist/Perl7-Handy
#
# Copyright (c) 2020, 2021 INABA Hitoshi <ina@cpan.org>
######################################################################

use 5.00503;    # Universal Consensus 1998 for primetools
# use 5.008001; # Lancaster Consensus 2013 for toolchains

$VERSION = '0.10';
$VERSION = $VERSION;

BEGIN { pop @INC if $INC[-1] eq '.' } # CVE-2016-1238: Important unsafe module load path flaw
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 } use warnings; local $^W=1;
BEGIN { $INC{'feature.pm'}  = '' if $] < 5.010 } use feature ();
BEGIN {
    if ($] >= 5.008001) {
        eval q{
use bareword::filehandles; # pmake.bat catches /^use .../
use multidimensional;      # pmake.bat catches /^use .../
        };
    }
    else {
        $INC{'bareword/filehandles.pm'} = '';
        $INC{'multidimensional.pm'}     = '';
    }
}
use Fcntl;

#---------------------------------------------------------------------
# confess() for this module
sub Perl7::Handy::confess (@) {
    my $i = 0;
    my @confess = ();
    while (my($package,$filename,$line,$subroutine) = caller($i)) {
        push @confess, "[$i] $filename($line) $subroutine\n";
        $i++;
    }
    print STDERR "\n", @_, "\n";
    print STDERR CORE::reverse @confess;
    die;
}

#---------------------------------------------------------------------
# open() that can't use bareword
sub Perl7::Handy::open (*$;$) {
    my $handle;

    if (defined $_[0]) {
        Perl7::Handy::confess "Use of bareword handle in open";
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
        Perl7::Handy::confess "Use of bareword handle in opendir";
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
        Perl7::Handy::confess "Use of bareword handle in sysopen";
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
        Perl7::Handy::confess "Use of bareword handle (\$_[0]) in pipe";
    }
    else {
        $handle0 = $_[0] = \do { local *_ };
    }

    if (defined $_[1]) {
        Perl7::Handy::confess "Use of bareword handle (\$_[1]) in pipe";
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
        Perl7::Handy::confess "Use of bareword handle in socket";
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
        Perl7::Handy::confess "Use of bareword handle (\$_[0]) in accept";
    }
    else {
        $handle0 = $_[0] = \do { local *_ };
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
    Perl7::Handy::confess "Use of multidimensional array emulation";
}

#---------------------------------------------------------------------
# STORE to disable $; (internal use to "no multidimensional")
sub STORE {
    Perl7::Handy::confess "Use of multidimensional array emulation"
}

#---------------------------------------------------------------------
# gives:
#   use strict;
#   use warnings;
#   no bareword::filehandles;
#   no multidimensional;
#   use feature qw(signatures); no warnings qw(experimental::signatures);
#   no feature qw(indirect);
sub import {

    # gives caller package "use strict;"
    strict->import;

    # gives caller package "use warnings;" (only perl 5.006 or later)
    if ($] >= 5.006) {
        warnings->import;

        # gives caller package "use feature qw(signatures); no warnings qw(experimental::signatures);" (only perl 5.020 or later)
        if ($] >= 5.020) {
            feature->import('signatures');
            warnings->unimport('experimental::signatures');

            # disables indirect object syntax in caller package
            # Bug #138701 for Perl7-Handy: Consider disabling indirect object notation [rt.cpan.org #138701]
            if ($] >= 5.031009) {
                feature->unimport('indirect');
            }
        }
    }

    # new Perl called "Modern Perl"
    if ($] >= 5.008001) {

        # gives caller package "no bareword::filehandles;"
        bareword::filehandles->unimport;

        # gives caller package "no multidimensional;"
        multidimensional->unimport;
    }

    # support older Perl that we love :)
    else {

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

=item * gives caller package "use feature qw(signatures); no warnings qw(experimental::signatures);" (only perl 5.020 or later)

=item * gives caller package "no feature qw(indirect); (only perl 5.031009 or later)

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

 Announcing Perl 7
 https://www.perl.com/article/announcing-perl-7/
 
 Perl 7 is coming
 https://www.effectiveperlprogramming.com/2020/06/perl-7-is-coming/
 
 A vision for Perl 7 and beyond
 https://xdg.me/a-vision-for-perl-7-and-beyond/
 
 On Perl 7 and the Perl Steering Committee
 https://lwn.net/Articles/828384/
 
 Perl7 and the future of Perl
 http://www.softpanorama.org/Scripting/Language_wars/perl7_and_the_future_of_perl.shtml
 
 Perl 7: A Risk-Benefit Analysis
 http://blogs.perl.org/users/grinnz/2020/07/perl-7-a-risk-benefit-analysis.html
 
 Perl 7 By Default
 http://blogs.perl.org/users/grinnz/2020/08/perl-7-by-default.html
 
 Perl 7: A Modest Proposal
 https://dev.to/grinnz/perl-7-a-modest-proposal-434m
 
 Perl 7 FAQ
 https://gist.github.com/Grinnz/be5db6b1d54b22d8e21c975d68d7a54f
 
 Perl 7, not quite getting better yet
 http://blogs.perl.org/users/leon_timmermans/2020/06/not-quite-getting-better-yet.html
 
 Re: Announcing Perl 7
 https://www.nntp.perl.org/group/perl.perl5.porters/2020/06/msg257566.html
 https://www.nntp.perl.org/group/perl.perl5.porters/2020/06/msg257568.html
 https://www.nntp.perl.org/group/perl.perl5.porters/2020/06/msg257572.html
 
 Changed defaults - Are they best for newbies?
 https://www.nntp.perl.org/group/perl.perl5.porters/2020/08/msg258221.html
 
 A vision for Perl 7 and beyond
 https://web.archive.org/web/20200927044106/https://xdg.me/archive/2020-a-vision-for-perl-7-and-beyond/
 
 SC Notes 2020 07 14 Perl/perl5 Wiki GitHub
 https://github-wiki-see.page/m/Perl/perl5/wiki/SC-Notes-2020-07-14

 Import pragmas like strict and warnings into callers lexical scope
 https://www.perlmonks.org/?node_id=887663
 
 Perl import some modules in all subclasses
 https://stackoverflow.com/questions/22122390/perl-import-some-modules-in-all-subclasses
 
 open
 http://perldoc.perl.org/functions/open.html
 
 Three-arg open() (Migrating to Modern Perl)
 http://modernperlbooks.com/mt/2010/04/three-arg-open-migrating-to-modern-perl.html
 
 perl - open my $fh, "comand (pipe)"; # isn't modern
 http://blog.livedoor.jp/dankogai/archives/51176081.html
 
 bareword::filehandles - disables bareword filehandles
 https://metacpan.org/dist/bareword-filehandles
 
 multidimensional - disables multidimensional array emulation
 https://metacpan.org/dist/multidimensional
 
 13.15. Creating Magic Variables with tie - Perl Cookbook
 https://docstore.mik.ua/orelly/perl3/cookbook/ch13_16.htm
 
 13.15. Creating Magic Variables with tie - Perl Cookbook, 2nd Edition
 https://docstore.mik.ua/orelly/perl4/cook/ch13_16.htm
 
 CVE-2016-1238 - CVE
 https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-1238
 
 CVE-2016-1238: Important unsafe module load path flaw
 https://www.nntp.perl.org/group/perl.perl5.porters/2016/07/msg238271.html
 
 signatures - Subroutine signatures with no source filter
 https://metacpan.org/release/signatures
 
 indirect - Lexically warn about using the indirect method call syntax.
 https://metacpan.org/release/indirect
 
 ina
 http://search.cpan.org/~ina/
 
 BackPAN
 http://backpan.perl.org/authors/id/I/IN/INA/

=cut

