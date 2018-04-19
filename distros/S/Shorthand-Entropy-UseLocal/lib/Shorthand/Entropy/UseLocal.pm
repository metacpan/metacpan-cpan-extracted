package Shorthand::Entropy::UseLocal;

use Data::Entropy;
use Data::Entropy::Source;
use Data::Entropy::RawSource::Local;

$Data::Entropy::entropy_source = Data::Entropy::Source->new(
    Data::Entropy::RawSource::Local->new, "sysread");

1;

# ABSTRACT: Use local entropy source

__END__

=pod

=encoding UTF-8

=head1 NAME

Shorthand::Entropy::UseLocal - Use local entropy source

=head1 VERSION

This document describes version 0.001 of Shorthand::Entropy::UseLocal (from Perl distribution Shorthand-Entropy-UseLocal), released on 2018-04-18.

=head1 SYNOPSIS

 use Shorthand::Entropy::UseLocal;

=head1 DESCRIPTION

 use Shorthand::Entropy::UseLocal;

is a shorthand for:

 use Data::Entropy;
 use Data::Entropy::Source;
 use Data::Entropy::RawSource::Local;

 $Data::Entropy::entropy_source = Data::Entropy::Source->new(
     Data::Entropy::RawSource::Local->new, "sysread");

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Shorthand-Entropy-UseLocal>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Shorthand-Entropy-UseLocal>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Shorthand-Entropy-UseLocal>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Entropy>

L<Data::Entropy::RawSource::Local>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
