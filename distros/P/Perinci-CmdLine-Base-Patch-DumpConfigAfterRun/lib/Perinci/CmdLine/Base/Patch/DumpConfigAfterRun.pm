package Perinci::CmdLine::Base::Patch::DumpConfigAfterRun;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-16'; # DATE
our $DIST = 'Perinci-CmdLine-Base-Patch-DumpConfigAfterRun'; # DIST
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
                sub_name    => 'run',
                code        => sub {
                    my $ctx = shift;

                    my ($self, $r) = @_;

                    {
                        local $self->{exit} = 0;
                        $ctx->{orig}->(@_);
                    }

                    dd $r->{config};

                    my $exitcode = $r->{res}[3]{'x.perinci.cmdline.base.exit_code'};

                    if ($self->exit) {
                        #log_trace("[pericmd] exit(%s)", $exitcode);
                        exit $exitcode;
                    } else {
                        # so this can be tested
                        return $r->{res};
                    }
                },
            },
        ],
        config => {
        },
   };
}

1;
# ABSTRACT: (DEPRECATED) Patch Perinci::CmdLine::Base's run() to dump config after run

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::Base::Patch::DumpConfigAfterRun - (DEPRECATED) Patch Perinci::CmdLine::Base's run() to dump config after run

=head1 VERSION

This document describes version 0.002 of Perinci::CmdLine::Base::Patch::DumpConfigAfterRun (from Perl distribution Perinci-CmdLine-Base-Patch-DumpConfigAfterRun), released on 2020-10-16.

=head1 SYNOPSIS

 % PERL5OPT=-MPerinci::CmdLine::Base::Patch::DumpConfigAfterRun yourscript.pl ...

=head1 DESCRIPTION

B<DEPRECATION NOTICE.> Deprecated in favor of
L<Perinci::CmdLine::Plugin::DumpConfig>.

This patch can be used for debugging configuration reading. It wraps run()
to dump configuration after run.

=for Pod::Coverage ^(patch_data)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine-Base-Patch-DumpConfigAfterRun>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine-Base-Patch-DumpConfigAfterRun>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-Base-Patch-DumpConfigAfterRun>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
