package Random::Any;

our $DATE = '2018-01-02'; # DATE
our $VERSION = '0.003'; # VERSION

use strict 'subs', 'vars';
#use warnings;

my $warn;
my $sub;

sub rand(;$) {
    $sub->(@_);
}

sub import {
    my $pkg = shift;

    my $caller = caller();

    while (@_) {
        my $arg = shift;
        if ($arg eq '-warn') {
            $warn = shift;
        } elsif ($arg eq 'rand') {
            *{"$caller\::rand"} = \&rand;
        } else {
            die "'$_' is not exported by " . __PACKAGE__;
        }
    }

    unless ($sub) {
        if (eval { require Math::Random::Secure; 1 }) {
            $sub = \&Math::Random::Secure::rand;
        } else {
            warn __PACKAGE__ . ": Math::Random::Secure is not available: $@, falling back on builtin rand()" if $warn;
            $sub = \&CORE::rand;
        }
    }
}

1;
# ABSTRACT: Try to use Math::Random::Secure::rand(), fallback on builtin rand()

__END__

=pod

=encoding UTF-8

=head1 NAME

Random::Any - Try to use Math::Random::Secure::rand(), fallback on builtin rand()

=head1 VERSION

This document describes version 0.003 of Random::Any (from Perl distribution Random-Any), released on 2018-01-02.

=head1 SYNOPSIS

 use Random::Any qw(rand);

 say rand();

=head1 DESCRIPTION

This module provides a single export C<rand()> that tries to use
L<Math::Random::Secure>'s C<rand()> first and, if that module is not available,
falls back on the builtin rand().

=head1 EXPORTS

=head2 -warn => bool

Can be set to true to emit a warning if Math::Random::Secure is not available.

=head1 FUNCTIONS

=head2 rand

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Random-Any>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Random-Any>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Random-Any>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Math::Random::Secure>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
