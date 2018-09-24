package PERLANCAR::File::HomeDir;

our $DATE = '2018-09-20'; # DATE
our $VERSION = '0.060'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(
                       get_my_home_dir
                       get_user_home_dir
               );

our $DIE_ON_FAILURE = 0;

# borrowed from File::HomeDir, with some modifications
sub get_my_home_dir {
    if ($^O eq 'MSWin32') {
        # File::HomeDir always uses exists($ENV{x}) first, does it want to avoid
        # accidentally creating env vars?
        return $ENV{HOME} if $ENV{HOME};
        return $ENV{USERPROFILE} if $ENV{USERPROFILE};
        return join($ENV{HOMEDRIVE}, "\\", $ENV{HOMEPATH})
            if $ENV{HOMEDRIVE} && $ENV{HOMEPATH};
    } else {
        return $ENV{HOME} if $ENV{HOME};
        my @pw;
        eval { @pw = getpwuid($>) };
        return $pw[7] if @pw;
    }

    if ($DIE_ON_FAILURE) {
        die "Can't get home directory";
    } else {
        return undef;
    }
}

# borrowed from File::HomeDir, with some modifications
sub get_user_home_dir {
    my ($name) = @_;

    if ($^O eq 'MSWin32') {
        # not yet implemented
        return undef;
    } else {
        # IF and only if we have getpwuid support, and the name of the user is
        # our own, shortcut to my_home. This is needed to handle HOME
        # environment settings.
        if ($name eq getpwuid($<)) {
            return get_my_home_dir();
        }

      SCOPE: {
            my $home = (getpwnam($name))[7];
            return $home if $home and -d $home;
        }

        return undef;
    }

}

1;
# ABSTRACT: Lightweight way to get current user's home directory

__END__

=pod

=encoding UTF-8

=head1 NAME

PERLANCAR::File::HomeDir - Lightweight way to get current user's home directory

=head1 VERSION

This document describes version 0.060 of PERLANCAR::File::HomeDir (from Perl distribution PERLANCAR-File-HomeDir), released on 2018-09-20.

=head1 SYNOPSIS

 use PERLANCAR::File::HomeDir qw(get_my_home_dir get_user_home_dir);

 my $dir = get_my_home_dir(); # e.g. "/home/ujang"

 $dir = get_user_home_dir("ujang");

=head1 DESCRIPTION

This is a (temporary?) module to get user's home directory. It is a lightweight
version of L<File::HomeDir> with fewer OS support (only Windows and Unix) and
fewer logic/heuristic.

=head1 VARIABLES

=head2 $DIE_ON_FAILURE => bool (default: 0)

If set to true, will die on failure. Else, function usually return undef on
failure.

=head1 FUNCTIONS

None are exported by default, but they are exportable.

=head2 get_my_home_dir

Usage:

 my $home_dir = get_my_home_dir();

Try several ways to get home directory of the current user. Return undef or die
(depends on C<$DIE_ON_FAILURE>) if everything fails.

=head2 get_user_home_dir

Usage:

 my $home_dir = get_user_home_dir($username);

Try several ways to get home directory of a specified user (C<$username>).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/PERLANCAR-File-HomeDir>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-PERLANCAR-File-HomeDir>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=PERLANCAR-File-HomeDir>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<File::HomeDir>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
