package Patch::rand::Secure;

our $DATE = '2018-01-02'; # DATE
our $VERSION = '0.001'; # VERSION

use strict 'subs', 'vars';
use warnings;
use Math::Random::Secure;

sub import {
    my $pkg = shift;

    my $caller = caller();
    *{"$caller\::rand"} = \&Math::Random::Secure::rand;
}

sub unimport {
    my $pkg = shift;

    my $caller = caller();
    # XXX find a better way to restore original rand
    *{"$caller\::rand"} = sub {
        CORE::rand(@_);
    };
}

1;
# ABSTRACT: Replace rand() with Math::Random::Secure's version

__END__

=pod

=encoding UTF-8

=head1 NAME

Patch::rand::Secure - Replace rand() with Math::Random::Secure's version

=head1 VERSION

This document describes version 0.001 of Patch::rand::Secure (from Perl distribution Patch-rand-Secure), released on 2018-01-02.

=head1 SYNOPSIS

 % perl -MPatch::rand::Secure -e'...'

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Patch-rand-Secure>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Patch-rand-Secure>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Patch-rand-Secure>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Math::Random::Secure>

L<Random::Any>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
