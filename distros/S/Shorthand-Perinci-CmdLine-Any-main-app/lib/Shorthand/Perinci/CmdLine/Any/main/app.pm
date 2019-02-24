package Shorthand::Perinci::CmdLine::Any::main::app;

our $DATE = '2019-02-23'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

use Perinci::CmdLine::Any;

my %extra_args;

sub import {
    my $class = shift;
    %extra_args = @_;
}

END {
    no warnings 'once';
    if ($main::SPEC{app}) {
        Perinci::CmdLine::Any->new(
            url => '/main/app',
            %extra_args,
        )->run;
    }
}

1;
# ABSTRACT: Load Perinci::CmdLine::Any and run main's app

__END__

=pod

=encoding UTF-8

=head1 NAME

Shorthand::Perinci::CmdLine::Any::main::app - Load Perinci::CmdLine::Any and run main's app

=head1 VERSION

This document describes version 0.001 of Shorthand::Perinci::CmdLine::Any::main::app (from Perl distribution Shorthand-Perinci-CmdLine-Any-main-app), released on 2019-02-23.

=head1 SYNOPSIS

 use Shorthand::Perinci::CmdLine::Any::main::app;

=head1 DESCRIPTION

B<EXPERIMENTAL.>

 use Shorthand::Perinci::CmdLine::Any::main::app;

is a shorthand for:

 use Perinci::CmdLine::Any;
 END { Perinci::CmdLine::Any->new(url => '/main/app')->run; }

You can pass extra arguments to new() via import arguments, e.g.:

 use Shorthand::Perinci::CmdLine::Any::main::app log=>1;

is a shorthand for:

 use Perinci::CmdLine::Any;
 END { Perinci::CmdLine::Any->new(url => '/main/app', log=>1)->run; }

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Shorthand-Perinci-CmdLine-Any-main-app>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Shorthand-Perinci-CmdLine-Any-main-app>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Shorthand-Perinci-CmdLine-Any-main-app>

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
