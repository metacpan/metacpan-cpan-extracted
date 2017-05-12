package Pod::Elide;

our $DATE = '2017-01-29'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(elide);

sub _markup {
    my ($preamble, $cmd, $postamble, $opts) = @_;

    my $retain_level = $opts->{retain_level} // 9;

    my $prio;
    if ($cmd =~ /\Ahead(\d+)\z/) {
        $prio = $1 if $retain_level >= $1;
    }
    unless (defined $prio) {
        $prio = $retain_level >= 9 ? 10 : 999;
    }

    if ($prio < 999) {
        "$preamble<elspan prio=$prio>=$cmd$postamble</elspan>";
    } else {
        "$preamble$cmd$postamble";
    }
}

sub elide {
    require String::Elide::Lines;

    my ($str, $len, $opts) = @_;

    $opts //= {};

    $str =~ s/^(\A|\R)=(\w+)(.*\R(?:\R|\z))/_markup($1, $2, $3, $opts)/egm;
    #print $str;
    String::Elide::Lines::elide($str, $len, {
        marker => ["\n", ($opts->{marker} // "..")."\n", "\n"],
        truncate => $opts->{truncate} // 'bottom',
        default_prio=>999,
    });
}

1;
# ABSTRACT: Elide POD lines from a string, with options

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elide - Elide POD lines from a string, with options

=head1 VERSION

This document describes version 0.003 of Pod::Elide (from Perl distribution Pod-Elide), released on 2017-01-29.

=head1 SYNOPSIS

 use Pod::Elide qw(elide);
 print elide(<<EOP, 20);
 =head1 NAME

 Foo - Do something fooish

 =head1 VERSION

 1.23

 =head1 SYNOPSIS

  blah blah
  blah blah
  blah blah

 =head1 DESCRIPTION

 Some description some description some description. Some description some
 description some description some description. Some description some
 description some description. Some description some description some
 description some description. Some description some description some
 description. Some description some description some description some
 description.

 =head1 FUNCTIONS

 =head2 func1

 Blah blah blah
 Blah blah blah

 =head2 func2

 Blah blah blah
 Blah blah blah

 =head1 SEE ALSO

 L<Bar>

 =cut
 EOP

The output is something like:

 =head1 NAME

 =head1 VERSION

 =head1 SYNOPSIS

 =head1 DESCRIPTION

 Some description some description some description. Some description some
 description some description some description. Some description some
 ..
 =head1 FUNCTIONS

 =head2 func1

 =head2 func2

 =head1 SEE ALSO

 =cut

=head1 DESCRIPTION

This module can be used to elide lines from a POD string to reduce its number of
lines (e.g. for summarizing a POD). It will try to elide text lines first before
POD command lines. head3 will be elided before head2, head2 before head1, and so
on.

=head1 FUNCTIONS

=head2 elide($pod, $len[, \%opts]) => str

Elide lines from POD string C<$pod> if the string contains more than C<$len>
lines.

Known options:

=over

=item * marker => str (default: '..')

=item * truncate => 'top'|'middle'|'bottom'|'ends' (default: 'bottom')

=item * retain_level => int (1|2|3|9, default: 9)

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Elide>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Elide>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Elide>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
