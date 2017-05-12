package Perinci::CmdLine;

our $DATE = '2016-12-10'; # DATE
our $VERSION = '1.50'; # VERSION

sub new {
    die "This module is currently empty, for now please use Perinci::CmdLine::{Lite,Classic,Any} instead. There is also Perinci::CmdLine::Inline.";
}

1;
1;
# ABSTRACT: Rinci/Riap-based command-line application framework

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine - Rinci/Riap-based command-line application framework

=head1 VERSION

This document describes version 1.50 of Perinci::CmdLine (from Perl distribution Perinci-CmdLine), released on 2016-12-10.

=head1 DESCRIPTION

This module is currently empty, because the implementation is currently split
into L<Perinci::CmdLine::Lite> (the lightweight version) and
L<Perinci::CmdLine::Classic> (the full but heavier version). There's also
L<Perinci::CmdLine::Any> that lets you choose between the two dynamically, à la
Any::Moose. And finally there's also L<Perinci::CmdLine::Inline>, the even more
lightweight version.

This module exists solely for convenience of linking purposes.

=for Pod::Coverage ^(new)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Perinci::CmdLine::Lite>

L<Perinci::CmdLine::Classic>

L<Perinci::CmdLine::Any>

L<Perinci::CmdLine::Inline>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
