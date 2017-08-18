package Patch::chdir::Print;

our $DATE = '2017-08-15'; # DATE
our $VERSION = '0.001'; # VERSION

use strict 'subs', 'vars';
use warnings;

sub import {
    my $pkg = shift;

    my $caller = caller();
    *{"$caller\::chdir"} = sub {
        warn "chdir($_[0])";
        CORE::chdir(@_);
    };
}

sub unimport {
    my $pkg = shift;

    my $caller = caller();
    # XXX find a better way to restore original chdir
    *{"$caller\::chdir"} = sub {
        CORE::chdir(@_);
    };
}

1;
# ABSTRACT: Wrap chdir() to print the argument first

__END__

=pod

=encoding UTF-8

=head1 NAME

Patch::chdir::Print - Wrap chdir() to print the argument first

=head1 VERSION

This document describes version 0.001 of Patch::chdir::Print (from Perl distribution Patch-chdir-Print), released on 2017-08-15.

=head1 SYNOPSIS

 % perl -MPatch::chdir::Print -e'...'

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Patch-chdir-Print>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Patch-chdir-Print>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Patch-chdir-Print>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
