## no critic: ()

package PerlX::ifor;

our $DATE = '2019-04-16'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT = qw(ifor);

sub ifor(&$) {
    my ($code, $iterator) = @_;

    if (ref $iterator eq 'CODE') {
        local $_;
        while (defined($_ = $iterator->())) {
            $code->();
        }
    } else {
        die "Only coderef iterator is supported at the moment";
    }
}

1;
# ABSTRACT: A version of for() that accepts iterator instead of list

__END__

=pod

=encoding UTF-8

=head1 NAME

PerlX::ifor - A version of for() that accepts iterator instead of list

=head1 VERSION

This document describes version 0.001 of PerlX::ifor (from Perl distribution PerlX-ifor), released on 2019-04-16.

=head1 SYNOPSIS

With L<Array::Iter> or L<Range::Iter> which generates a coderef iterator:

 use PerlX::ifor;
 use Array::Iter qw(array_iter list_iter);
 use Range::Iter qw(range_iter);

 ifor { say } iter_range("a", "z");

=head1 DESCRIPTION

CAVEAT: Yes, it's ugly and doesn't look like a regular for(). Sue Perl :-)

TODO: Support other iterator, e.g. L<Array::Iterator>.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/PerlX-ifor>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-PerlX-ifor>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=PerlX-ifor>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
