package Perinci::CmdLine::Lite::Patch::ShowArgsBeforeValidation;

our $DATE = '2020-01-01'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
no warnings;

use Data::Dump::Color;
use Module::Patch;
use base qw(Module::Patch);

our %config;

sub patch_data {
    return {
        v => 3,
        patches => [
            {
                action      => 'wrap',
                sub_name    => 'hook_before_action',
                code        => sub {
                    my $ctx = shift;

                    my ($self, $r) = @_;

                    print "Arguments before validation: "; dd $r->{args};
                    $ctx->{orig}->(@_);
                },
            },
        ],
        config => {
        },
   };
}

1;
# ABSTRACT: Patch Perinci::CmdLine::Lite's hook_before_action() to show arguments before validation

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::Lite::Patch::ShowArgsBeforeValidation - Patch Perinci::CmdLine::Lite's hook_before_action() to show arguments before validation

=head1 VERSION

This document describes version 0.002 of Perinci::CmdLine::Lite::Patch::ShowArgsBeforeValidation (from Perl distribution Perinci-CmdLine-Lite-Patch-ShowArgsBeforeValidation), released on 2020-01-01.

=head1 SYNOPSIS

 % PERL5OPT=-MPerinci::CmdLine::Lite::Patch::ShowArgsBeforeValidation yourscript.pl ...

=head1 DESCRIPTION

This patch can be used for debugging.

=for Pod::Coverage ^(patch_data)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine-Lite-Patch-ShowArgsBeforeValidation>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine-Lite-Patch-ShowArgsBeforeValidation>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-Lite-Patch-ShowArgsBeforeValidation>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Perinci::CmdLine::Lite::Patch::ShowArgsAfterValidation>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
