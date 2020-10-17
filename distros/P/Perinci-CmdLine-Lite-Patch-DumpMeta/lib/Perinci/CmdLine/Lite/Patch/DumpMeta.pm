package Perinci::CmdLine::Lite::Patch::DumpMeta;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-17'; # DATE
our $DIST = 'Perinci-CmdLine-Lite-Patch-DumpMeta'; # DIST
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
                sub_name    => 'action_call',
                code        => sub {
                    my $ctx = shift;
                    my ($self, $r) = @_;

                    dd $r->{meta};
                    $ctx->{orig}->(@_);
                },
            },
        ],
        config => {
        },
   };
}

1;
# ABSTRACT: (DEPRECATED) Patch Perinci::CmdLine::Lite's action_call() to dump meta first

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::Lite::Patch::DumpMeta - (DEPRECATED) Patch Perinci::CmdLine::Lite's action_call() to dump meta first

=head1 VERSION

This document describes version 0.002 of Perinci::CmdLine::Lite::Patch::DumpMeta (from Perl distribution Perinci-CmdLine-Lite-Patch-DumpMeta), released on 2020-10-17.

=head1 SYNOPSIS

 % PERL5OPT=-MPerinci::CmdLine::Lite::Patch::DumpMeta yourscript.pl ...

=head1 DESCRIPTION

B<DEPRECATION NOTICE.> Deprecated in favor of
L<Perinci::CmdLine::Plugin::DumpMeta>.

This patch can be used for debugging. It wraps action_call() to dump
Rinci metadata first.

=for Pod::Coverage ^(patch_data)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine-Lite-Patch-DumpMeta>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine-Lite-Patch-DumpMeta>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-Lite-Patch-DumpMeta>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
