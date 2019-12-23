package Perinci::CmdLine::Base::Patch::DumpGetoptLongSpec;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-23'; # DATE
our $DIST = 'Perinci-CmdLine-Base-Patch-DumpGetoptLongSpec'; # DIST
our $VERSION = '0.001'; # VERSION

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
                sub_name    => '_parse_argv2',
                code        => sub {
                    my $ctx = shift;

                    my ($self) = @_;

                    my $ga_res = $ctx->{orig}->(@_);

                    dd $ga_res->[3]{'func.gen_getopt_long_spec_result'};
                    $ga_res;
                },
            },
        ],
        config => {
        },
   };
}

1;
# ABSTRACT: Patch Perinci::CmdLine::Base's _parse_argv2() to dump Getopt::Long spec

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::Base::Patch::DumpGetoptLongSpec - Patch Perinci::CmdLine::Base's _parse_argv2() to dump Getopt::Long spec

=head1 VERSION

This document describes version 0.001 of Perinci::CmdLine::Base::Patch::DumpGetoptLongSpec (from Perl distribution Perinci-CmdLine-Base-Patch-DumpGetoptLongSpec), released on 2019-12-23.

=head1 SYNOPSIS

 % PERL5OPT=-MPerinci::CmdLine::Base::Patch::DumpGetoptLongSpec yourscript.pl ...

=head1 DESCRIPTION

This patch can be used for debugging.

=for Pod::Coverage ^(patch_data)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine-Base-Patch-DumpGetoptLongSpec>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine-Base-Patch-DumpGetoptLongSpec>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-Base-Patch-DumpGetoptLongSpec>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
