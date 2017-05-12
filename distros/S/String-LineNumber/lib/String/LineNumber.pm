package String::LineNumber;

our $DATE = '2014-12-10'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       linenum
               );

sub linenum {
    my ($str, $opts) = @_;
    $opts //= {};
    $opts->{width}      //= 4;
    $opts->{zeropad}    //= 0;
    $opts->{skip_empty} //= 1;

    my $i = 0;
    $str =~ s/^(([\t ]*\S)?.*)/
        sprintf(join("",
                     "%",
                     ($opts->{zeropad} && !($opts->{skip_empty}
                                                && !defined($2)) ? "0" : ""),
                     $opts->{width}, "s",
                     "|%s"),
                ++$i && $opts->{skip_empty} && !defined($2) ? "" : $i,
                $1)/meg;

    $str;
}

1;
# ABSTRACT: Give line number to each line of string

__END__

=pod

=encoding UTF-8

=head1 NAME

String::LineNumber - Give line number to each line of string

=head1 VERSION

This document describes version 0.01 of String::LineNumber (from Perl distribution String-LineNumber), released on 2014-12-10.

=head1 FUNCTIONS

=head2 linenum($str, \%opts) => STR

Add line numbers. For example:

     1|line1
     2|line2
      |
     4|line4

Known options:

=over 4

=item * width => INT (default: 4)

=item * zeropad => BOOL (default: 0)

If turned on, will output something like:

  0001|line1
  0002|line2
      |
  0004|line4

=item * skip_empty => BOOL (default: 1)

If set to false, keep printing line number even if line is empty:

     1|line1
     2|line2
     3|
     4|line4

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/String-LineNumber>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-String-LineNumber>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=String-LineNumber>

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
