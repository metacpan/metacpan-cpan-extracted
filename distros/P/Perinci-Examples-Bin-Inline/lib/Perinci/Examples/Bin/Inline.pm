package Perinci::Examples::Bin::Inline;

our $DATE = '2015-11-28'; # DATE
our $VERSION = '0.01'; # VERSION

our %SPEC;

$SPEC{noop} = {
    v => 1.1,
    summary => 'Do nothing',
};

sub noop { [200] }

1;
# ABSTRACT: Sample Perinci::CmdLine::Inline-generated CLI scripts

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Examples::Bin::Inline - Sample Perinci::CmdLine::Inline-generated CLI scripts

=head1 VERSION

This document describes version 0.01 of Perinci::Examples::Bin::Inline (from Perl distribution Perinci-Examples-Bin-Inline), released on 2015-11-28.

=head1 DESCRIPTION

=over

=item * L<peri-eg-noop-inline>

=item * L<peri-eg-noop-inline-sf>

=back

=head1 FUNCTIONS


=head2 noop() -> [status, msg, result, meta]

Do nothing.

This function is not exportable.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 SEE ALSO

L<Perinci::CmdLine::Inline>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Examples-Bin-Inline>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Examples-Bin-Inline>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Examples-Bin-Inline>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
