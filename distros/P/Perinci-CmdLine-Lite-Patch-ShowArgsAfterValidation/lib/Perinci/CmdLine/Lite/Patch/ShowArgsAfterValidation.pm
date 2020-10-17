package Perinci::CmdLine::Lite::Patch::ShowArgsAfterValidation;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-16'; # DATE
our $DIST = 'Perinci-CmdLine-Lite-Patch-ShowArgsAfterValidation'; # DIST
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

                    $ctx->{orig}->(@_);
                    print "Arguments after validation: "; dd $r->{args};
                },
            },
        ],
        config => {
        },
   };
}

1;
# ABSTRACT: (DEPRECATED) Patch Perinci::CmdLine::Lite's hook_before_action() to show arguments after validation

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::Lite::Patch::ShowArgsAfterValidation - (DEPRECATED) Patch Perinci::CmdLine::Lite's hook_before_action() to show arguments after validation

=head1 VERSION

This document describes version 0.002 of Perinci::CmdLine::Lite::Patch::ShowArgsAfterValidation (from Perl distribution Perinci-CmdLine-Lite-Patch-ShowArgsAfterValidation), released on 2020-10-16.

=head1 SYNOPSIS

 % PERL5OPT=-MPerinci::CmdLine::Lite::Patch::ShowArgsAfterValidation yourscript.pl ...

=head1 DESCRIPTION

B<DEPRECATION NOTICE.> Deprecated in favor of
L<Perinci::CmdLine::Plugin::DumpArgs>.

This patch can be used for debugging.

=for Pod::Coverage ^(patch_data)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine-Lite-Patch-ShowArgsAfterValidation>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine-Lite-Patch-ShowArgsAfterValidation>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-Lite-Patch-ShowArgsAfterValidation>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Perinci::CmdLine::Lite::Patch::ShowArgsBeforeValidation>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
