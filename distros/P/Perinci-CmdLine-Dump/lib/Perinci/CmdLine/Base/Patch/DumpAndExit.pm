package Perinci::CmdLine::Base::Patch::DumpAndExit;

our $DATE = '2017-01-13'; # DATE
our $VERSION = '0.08'; # VERSION

use 5.010001;
use strict;
no warnings;

use Data::Dump;
use Module::Patch 0.19 qw();
use base qw(Module::Patch);

our %config;

sub _dump {
    print "# BEGIN DUMP $config{-tag}\n";
    dd @_;
    print "# END DUMP $config{-tag}\n";
}

sub patch_data {
    return {
        v => 3,
        patches => [
            {
                action      => 'replace',
                sub_name    => 'run',
                code        => sub {
                    my $self = shift;
                    _dump($self);
                    $config{-exit_method} eq 'exit' ? exit(0) : die;
                },
            },
        ],
        config => {
            -tag => {
                schema  => 'str*',
                default => 'TAG',
            },
            -exit_method => {
                schema  => 'str*',
                default => 'exit',
            },
        },
   };
}

1;
# ABSTRACT: Patch Perinci::CmdLine::Base to dump object + exit on run()

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::Base::Patch::DumpAndExit - Patch Perinci::CmdLine::Base to dump object + exit on run()

=head1 VERSION

This document describes version 0.08 of Perinci::CmdLine::Base::Patch::DumpAndExit (from Perl distribution Perinci-CmdLine-Dump), released on 2017-01-13.

=head1 DESCRIPTION

This patch can be used to extract Perinci::CmdLine object information from a
script by running the script but exiting early after getting the object dump.

=for Pod::Coverage ^(patch_data)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine-Dump>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine-Dump>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-Dump>

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
