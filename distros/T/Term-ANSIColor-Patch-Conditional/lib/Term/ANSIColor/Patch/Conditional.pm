package Term::ANSIColor::Patch::Conditional;

our $DATE = '2018-12-02'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
no warnings;

use Module::Patch;
use base qw(Module::Patch);

our %config;

sub _color_enabled {
    return $config{-color} if defined $config{-color};
    return 0 if exists $ENV{NO_COLOR};
    return $ENV{COLOR} if defined $ENV{COLOR};
    return (-t STDOUT);
}

sub patch_data {
    return {
        v => 3,
        patches => [
            {
                action      => 'wrap',
                sub_name    => 'color',
                code        => sub {
                    my $ctx = shift;

                    return "" unless _color_enabled();
                    $ctx->{orig}->(@_);
                },
            },
            {
                action      => 'wrap',
                sub_name    => 'colored',
                code        => sub {
                    my $ctx = shift;

                    return do { ref $_[0] ? shift : pop; @_ }
                        unless _color_enabled();
                    $ctx->{orig}->(@_);
                },
            },
        ],
        config => {
            -color => {
                schema => 'bool*',
            },
        },
   };
}

1;
# ABSTRACT: Colorize text only if color is enabled

__END__

=pod

=encoding UTF-8

=head1 NAME

Term::ANSIColor::Patch::Conditional - Colorize text only if color is enabled

=head1 VERSION

This document describes version 0.001 of Term::ANSIColor::Patch::Conditional (from Perl distribution Term-ANSIColor-Patch-Conditional), released on 2018-12-02.

=head1 SYNOPSIS

 % PERL5OPT=-MTerm::ANSIColor::Patch::Conditional yourscript.pl ...

=head1 DESCRIPTION

This is a patch version of L<Term::ANSIColor::Conditional>. The difference is,
you don't have to change client code to specifically use
Term::ANSIColor::Conditional instead of L<Term::ANSIColor>.

=for Pod::Coverage ^(patch_data)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Term-ANSIColor-Patch-Conditional>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Term-ANSIColor-Patch-Conditional>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Term-ANSIColor-Patch-Conditional>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Term::ANSIColor::Conditional>

L<Term::ANSIColor>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
