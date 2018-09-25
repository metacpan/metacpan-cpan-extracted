package ShellCompleter::Util;

our $DATE = '2018-09-25'; # DATE
our $VERSION = '0.030'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                    run_shell_completer_for_getopt_long_app
               );

sub _complete {
    my ($comp0, $args) = @_;

    my $comp;
    if(ref($comp0) eq 'HASH') {
        $comp = $comp0->{completion};
    } else {
        $comp = $comp0;
    }

    if (ref($comp) eq 'ARRAY') {
        require Complete::Util;
        return Complete::Util::complete_array_elem(
            array => $comp,
            word  => $args->{word},
            ci    => $args->{ci},
        );
    } elsif (ref($comp) eq 'CODE') {
        return $comp->(%$args);
    } else {
        return undef;
    }
}

sub run_shell_completer_for_getopt_long_app {
    require Getopt::Long::Complete;

    my %f_args = @_;

    unless ($ENV{GETOPT_LONG_DUMP} || $ENV{COMP_LINE} || $ENV{COMMAND_LINE}) {
        die "Please run the script under shell completion\n";
    }

    Getopt::Long::Complete::GetOptionsWithCompletion(
        sub {
            my %c_args = @_;

            my $word = $c_args{word};
            my $type = $c_args{type};

            if ($type eq 'arg') {
                return _complete($f_args{'{arg}'}, \%c_args);
            } elsif ($type eq 'optval') {
                return _complete($f_args{ $c_args{ospec} }, \%c_args);
            }
            undef;
        },
        map {$_ => sub{}} grep {$_ ne '{arg}'} keys %f_args,
    );
}

1;
# ABSTRACT: Utility routines for App::ShellCompleter::*

__END__

=pod

=encoding UTF-8

=head1 NAME

ShellCompleter::Util - Utility routines for App::ShellCompleter::*

=head1 VERSION

This document describes version 0.030 of ShellCompleter::Util (from Perl distribution ShellCompleter-Util), released on 2018-09-25.

=head1 SYNOPSIS

=head1 DESCRIPTION

B<This module will be replaced by the newer Shell::Completer when it is ready.>

This module provides utility routines for C<App::ShellCompleter::*>
applications.

=head1 FUNCTIONS

=head2 run_shell_completer_for_getopt_long_app(%go_spec)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ShellCompleter-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ShellCompleter-Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ShellCompleter-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

C<App::ShellCompleter::*> modules which use this module, e.g.
L<App::ShellCompleter::mpv>.

L<Getopt::Long::Complete>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
