package Modern::Open;
######################################################################
#
# Modern::Open - Autovivification, Autodie, and 3-args open support
#
# http://search.cpan.org/dist/Modern-Open/
#
# Copyright (c) 2014, 2015, 2018, 2019 INABA Hitoshi <ina@cpan.org>
######################################################################

$VERSION = '0.09';
$VERSION = $VERSION;

use 5.00503;
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; $^W=1;

use Symbol;
use Fcntl;

sub Modern::Open::confess (@) {
    my $i = 0;
    my @confess = ();
    while (my($package,$filename,$line,$subroutine) = caller($i)) {
        push @confess, "[$i] $filename($line) $package::$subroutine\n";
        $i++;
    }
    print STDERR CORE::reverse @confess;
    print STDERR "\n";
    print STDERR @_;
}

sub Modern::Open::open(*$;$) {
    my $handle;

    if (defined $_[0]) {
        $handle = Symbol::qualify_to_ref($_[0], caller());
    }
    else {
        $handle = $_[0] = \do { local *_ };
    }

    if (@_ >= 4) {
        Modern::Open::confess "Too many arguments for open";
    }
    elsif (@_ == 3) {
        my($mode,$filename) = @_[1,2];

        if ($mode eq '-|') {
            my $return = CORE::open($handle,qq{$filename |});
            if ($return or defined wantarray) {
                return $return;
            }
            else {
                Modern::Open::confess "Can't open($_[0],$_[1],$_[2]): $!";
            }
        }
        elsif ($mode eq '|-') {
            my $return = CORE::open($handle,qq{| $filename});
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
            my $return = CORE::sysopen($handle,$filename,$flags{$mode});
            if ($return or defined wantarray) {
                return $return;
            }
            else {
                Modern::Open::confess "Can't open($_[0],$_[1],$_[2]): $!";
            }
        }
    }
    elsif (@_ == 2) {
        my $return = CORE::open($handle,$_[1]);
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

sub Modern::Open::opendir(*$) {
    my $handle;

    if (defined $_[0]) {
        $handle = Symbol::qualify_to_ref($_[0], caller());
    }
    else {
        $handle = $_[0] = \do { local *_ };
    }

    my $return = CORE::opendir($handle,$_[1]);
    if ($return or defined wantarray) {
        return $return;
    }
    else {
        Modern::Open::confess "Can't opendir($_[0],$_[1]): $!";
    }
}

sub Modern::Open::sysopen(*$$;$) {
    my $handle;

    if (defined $_[0]) {
        $handle = Symbol::qualify_to_ref($_[0], caller());
    }
    else {
        $handle = $_[0] = \do { local *_ };
    }

    if (@_ >= 5) {
        Modern::Open::confess "Too many arguments for sysopen";
    }
    elsif (@_ == 4) {
        my $return = CORE::sysopen($handle,$_[1],$_[2],$_[3]);
        if ($return or defined wantarray) {
            return $return;
        }
        else {
            Modern::Open::confess "Can't sysopen($_[0],$_[1],$_[2],$_[3]): $!";
        }
    }
    elsif (@_ == 3) {
        my $return = CORE::sysopen($handle,$_[1],$_[2]);
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

sub Modern::Open::pipe(**) {
    my($handle0,$handle1);

    if (defined $_[0]) {
        $handle0 = Symbol::qualify_to_ref($_[0], caller());
    }
    else {
        $handle0 = $_[0] = \do { local *_ };
    }

    if (defined $_[1]) {
        $handle1 = Symbol::qualify_to_ref($_[1], caller());
    }
    else {
        $handle1 = $_[1] = \do { local *_ };
    }

    my $return = CORE::pipe($handle0,$handle1);
    if ($return or defined wantarray) {
        return $return;
    }
    else {
        Modern::Open::confess "Can't pipe($_[0],$_[1]): $!";
    }
}

sub Modern::Open::socket(*$$$) {
    my $handle;

    if (defined $_[0]) {
        $handle = Symbol::qualify_to_ref($_[0], caller());
    }
    else {
        $handle = $_[0] = \do { local *_ };
    }

    # socket doesn't autodie
    return CORE::socket($handle,$_[1],$_[2],$_[3]);
}

sub Modern::Open::accept(**) {
    my($handle0,$handle1);

    if (defined $_[0]) {
        $handle0 = Symbol::qualify_to_ref($_[0], caller());
    }
    else {
        $handle0 = $_[0] = \do { local *_ };
    }

    if (defined $_[1]) {
        $handle1 = Symbol::qualify_to_ref($_[1], caller());
    }

    my $return = CORE::accept($handle0,$handle1);
    if ($return or defined wantarray) {
        return $return;
    }
    else {
        Modern::Open::confess "Can't accept($_[0],$_[1]): $!";
    }
}

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

=head1 SYNOPSIS

  use Modern::Open;

=head1 DESCRIPTION

Modern::Open provides autovivification and autodie support of open(),
opendir(), sysopen(), pipe(), socket(), and accept() on perl 5.00503
or later. And supports three-argument open(), too.

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

=item * L<open|http://perldoc.perl.org/functions/open.html> - Perl Programming Documentation

=item * L<Three-arg open() (Migrating to Modern Perl)|http://modernperlbooks.com/mt/2010/04/three-arg-open-migrating-to-modern-perl.html> - Modern Perl Programming

=item * L<Pre-Modern Perl VS Post-Modern Perl: FIGHT!|http://blogs.perl.org/users/buddy_burden/2013/06/pre-modern-perl-vs-post-modern-perl-fight.html> - A blog about the Perl programming language

=item * L<perl - open my $fh, "comand |"; # isn't modern|http://blog.livedoor.jp/dankogai/archives/51176081.html> - 404 Blog Not Found

=item * L<Migrating scripts back to Perl 5.005_03|http://www.perlmonks.org/?node_id=289351> - PerlMonks

=item * L<Goodnight, Perl 5.005|http://www.oreillynet.com/onlamp/blog/2007/11/goodnight_perl_5005.html> - ONLamp.com

=item * L<Perl 5.005_03 binaries|http://guest.engelschall.com/~sb/download/win32/> - engelschall.com

=item * L<Welcome to CP5.5.3AN|http://cp5.5.3an.barnyard.co.uk/> - cp5.5.3an.barnyard.co.uk

=item * L<Strict::Perl|http://search.cpan.org/dist/Strict-Perl/> - CPAN

=item * L<japerl|http://search.cpan.org/dist/japerl/> - CPAN

=item * L<ina|http://search.cpan.org/~ina/> - CPAN

=item * L<The BackPAN|http://backpan.perl.org/authors/id/I/IN/INA/> - A Complete History of CPAN

=back

=cut

