package String::CommonPrefix;

our $DATE = '2014-12-10'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       common_prefix
               );

sub common_prefix {
    return undef unless @_;
    my $i;
  L1:
    for ($i=0; $i < length($_[0]); $i++) {
        for (@_[1..$#_]) {
            if (length($_) < $i) {
                $i--; last L1;
            } else {
                last L1 if substr($_, $i, 1) ne substr($_[0], $i, 1);
            }
        }
    }
    substr($_[0], 0, $i);
}

1;
# ABSTRACT: Find prefix common to all strings

__END__

=pod

=encoding UTF-8

=head1 NAME

String::CommonPrefix - Find prefix common to all strings

=head1 VERSION

This document describes version 0.01 of String::CommonPrefix (from Perl distribution String-CommonPrefix), released on 2014-12-10.

=head1 FUNCTIONS

=head2 common_prefix(@LIST) => STR

Given a list of strings, return common prefix.

=head1 SEE ALSO

L<String::CommonSuffix>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/String-CommonPrefix>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-String-CommonPrefix>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=String-CommonPrefix>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
