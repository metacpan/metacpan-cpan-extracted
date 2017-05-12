package PerlIO::via::as_is;

our $DATE = '2016-10-12'; # DATE
our $VERSION = '0.001'; # VERSION

sub PUSHED {
    my ($class, $mode, $fh) = @_;
    bless [], $class;
}

sub FILL {
    my ($self, $fh) = @_;
    <$fh>;
}

sub WRITE {
    my ($self, $buffer, $fh) = @_;
    if (print $fh $buffer) { length($buffer) } else { -1 }
}

1;
# ABSTRACT: PerlIO layer that passes everything as-is

__END__

=pod

=encoding UTF-8

=head1 NAME

PerlIO::via::as_is - PerlIO layer that passes everything as-is

=head1 VERSION

This document describes version 0.001 of PerlIO::via::as_is (from Perl distribution PerlIO-via-as_is), released on 2016-10-12.

=head1 SYNOPSIS

Reading:

 use PerlIO::via::as_is;
 open my($fh), "<:via(as_is)", "file";
 print while <$fh>;

Writing:

 open my($fh), ">:via(as_is)", "file";
 print $fh "one", "two\n";

=head1 DESCRIPTION

This PerlIO layer does nothing (reads/writes everything as-is). Created for
testing purpose.

=for Pod::Coverage ^(FILL|PUSHED|WRITE)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/PerlIO-via-as_is>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-PerlIO-via-as_is>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=PerlIO-via-as_is>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<PerlIO::via>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
