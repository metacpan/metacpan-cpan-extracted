package PMVersions::Util;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-11-11'; # DATE
our $DIST = 'PMVersions-Util'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use Config::IOD::Reader;
use File::HomeDir;

use Exporter qw(import);
our @EXPORT_OK = qw(read_pmversions version_from_pmversions);

sub read_pmversions {
    my ($path) = @_;

    $path //= $ENV{PMVERSIONS_PATH};
    $path //= File::HomeDir->my_home . "/pmversions.ini";
    my $hoh;
    if (-e $path) {
        $hoh = Config::IOD::Reader->new->read_file($path);
    } else {
        warn "pmversions file '$path' does not exist";
    }

    $hoh->{GLOBAL} // {};
}

my $pmversions;
sub version_from_pmversions {
    my ($mod, $path) = @_;

    $pmversions //= read_pmversions($path);
    $pmversions->{$mod};
}

1;
# ABSTRACT: Utilities related to pmversions.ini

__END__

=pod

=encoding UTF-8

=head1 NAME

PMVersions::Util - Utilities related to pmversions.ini

=head1 VERSION

This document describes version 0.002 of PMVersions::Util (from Perl distribution PMVersions-Util), released on 2020-11-11.

=head1 SYNOPSIS

In F<~/pmversions.ini>:

 Log::ger=0.023
 File::Write::Rotate=0.28

In your code:

 use PMVersions::Util qw(version_from_pmversions);

 my $v1 = version_from_pmversions("Log::ger");  # => 0.023
 my $v2 = version_from_pmversions("Data::Sah"); # => undef

=head1 DESCRIPTION

F<pmversions.ini> is a file that list (minimum) version of modules. This module
provides routines related to this file.

=for Pod::Coverage .+

=head1 FUNCTIONS

=head2 read_pmversions

Usage:

 read_pmversions([ $path ]) => hash

Read F<pmversions.ini> and return a hash of module names and versions. If
C<$path> is not specified, will look at C<PMVERSIONS_PATH> environment variable,
or defaults to F<~/pmversions.ini>. Will warn if file does not exist. Will die
if file cannot be read or parsed.

=head2 version_from_pmversions

Usage:

 version_from_pmversions($mod [ , $path ]) => str

Check version from pmversions file. C<$path> will be passed to
L</"read_pmversions"> only the first time; after that, the contents of the file
is cached in a hash variable so the pmversions file is only read and parsed
once.

Will return undef if file does not exist or version for C<$mod> is not set in
the pmversions file.

=head1 ENVIRONMENT

=head2 PMVERSIONS_PATH

String. Set location of F<pmversions.ini> instead of the default
C<~/pmversions.ini>. Example: C</etc/minver.conf>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/PMVersions-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-PMVersions-Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=PMVersions-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
