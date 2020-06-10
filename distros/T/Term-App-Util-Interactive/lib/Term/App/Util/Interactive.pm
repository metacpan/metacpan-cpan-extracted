package Term::App::Util::Interactive;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-06'; # DATE
our $DIST = 'Term-App-Util-Interactive'; # DIST
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

our %SPEC;

$SPEC{term_app_is_interactive} = {
    v => 1.1,
    summary => 'Determine whether terminal application is running interactively',
    args => {},
    description => <<'_',

Try to determine whether terminal application is running interactively. Will
first check the INTERACTIVE environment variable, and use that if defined.
Otherwise will check using C<-t STDOUT>.

_
};
sub term_app_is_interactive {
    my $res = [200, "OK", undef, {}];

    if (defined $ENV{INTERACTIVE}) {
        $res->[2] = $ENV{INTERACTIVE};
        $res->[3]{'func.debug_info'}{interactive_from} = 'INTERACTIVE env';
        goto RETURN_RES;
    } else {
        $res->[2] = (-t STDOUT) ? 1:0;
        $res->[3]{'func.debug_info'}{interactive_from} = '-t STDOUT';
        goto RETURN_RES;
    }

  RETURN_RES:
    $res;
}

1;
# ABSTRACT: Determine whether terminal application is running interactively

__END__

=pod

=encoding UTF-8

=head1 NAME

Term::App::Util::Interactive - Determine whether terminal application is running interactively

=head1 VERSION

This document describes version 0.002 of Term::App::Util::Interactive (from Perl distribution Term-App-Util-Interactive), released on 2020-06-06.

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 term_app_is_interactive

Usage:

 term_app_is_interactive() -> [status, msg, payload, meta]

Determine whether terminal application is running interactively.

Try to determine whether terminal application is running interactively. Will
first check the INTERACTIVE environment variable, and use that if defined.
Otherwise will check using C<-t STDOUT>.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 ENVIRONMENT

=head2 INTERACTIVE

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Term-App-Util-Interactive>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Term-App-Util-Interactive>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Term-App-Util-Interactive>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Other C<Term::App::Util::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
