package String::Wildcard::DOS;

use 5.010001;
use strict;
use warnings;

our $VERSION = '0.01'; # VERSION

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       contains_wildcard
               );

sub contains_wildcard {
    my $str = shift;

    $str =~ /[*?]/;
}

1;
# ABSTRACT: DOS wildcard string routines

__END__

=pod

=encoding UTF-8

=head1 NAME

String::Wildcard::DOS - DOS wildcard string routines

=head1 VERSION

This document describes version 0.01 of String::Wildcard::DOS (from Perl distribution String-Wildcard-DOS), released on 2014-07-26.

=head1 SYNOPSIS

    use String::Wildcard::DOS qw(contains_wildcard);

    say 1 if contains_wildcard(""));      # -> 0
    say 1 if contains_wildcard("ab*"));   # -> 1
    say 1 if contains_wildcard("ab\\*")); # -> 1

=head1 DESCRIPTION

=for Pod::Coverage ^(qqquote)$

=head1 FUNCTIONS

=head2 contains_wildcard($str) => bool

Return true if C<$str> contains DOS wildcard pattern. Wildcard patterns include
C<*> (meaning zero or more characters), C<?> (exactly one character). There is
no backslash escaping mechanism.

=head1 TODO

See L<String::Wildcard::Bash>'s TODO for the types of other functions which I
plan to add to this module.

=head1 SEE ALSO

L<Regexp::Wildcards> to convert a string with wildcard pattern to equivalent
regexp pattern. Can handle Unix wildcards as well as SQL and DOS/Win32. As of
this writing (v1.05), it does not handle character class (C<[...]>) and
interprets brace expansion differently than bash.

Other C<String::Wildcard::*> modules.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/String-Wildcard-DOS>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-String-Wildcard-DOS>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=String-Wildcard-DOS>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
