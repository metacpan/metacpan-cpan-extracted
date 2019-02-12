package Shorthand;

our $DATE = '2019-02-10'; # DATE
our $VERSION = '0.001'; # VERSION

1;
# ABSTRACT: Shorthand

__END__

=pod

=encoding UTF-8

=head1 NAME

Shorthand - Shorthand

=head1 VERSION

This document describes version 0.001 of Shorthand (from Perl distribution Shorthand), released on 2019-02-10.

=head1 DESCRIPTION

B<Shorthand> is namespace reserved for modules that perform a shorthand for
something. For example:

 use Shorthand::Entropy::UseLocal;

is a shorthand for:

 use Data::Entropy;
 use Data::Entropy::Source;
 use Data::Entropy::RawSource::Local;

 $Data::Entropy::entropy_source = Data::Entropy::Source->new(
     Data::Entropy::RawSource::Local->new, "sysread");

=head1 FAQ

=head2 Why not pragma?

Naming your module as a pragma might indicate that the effect of your module can
be scoped lexically.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Shorthand>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Shorthand>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Shorthand>

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
