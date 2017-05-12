package Sah::Schema::cpan::meta20::version_range;

require Sah::Schema::cpan::meta20::version;
our $v_re = $Sah::Schema::cpan::meta20::version::v_re;

our $op_re = '(>=?|<=?|==|!=)';

our $schema = ['str', {
    summary => 'Version number range',
    match   => "\\A(($op_re\\s*)?$v_re)(\\s*,\\s*(($op_re\\s*)?$v_re))*\\z",
}, {}];

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::cpan::meta20::version_range

=head1 VERSION

This document describes version 0.003 of Sah::Schema::cpan::meta20::version_range (from Perl distribution Sah-Schemas-CPANMeta), released on 2017-01-08.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-CPANMeta>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-CPANMeta>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-CPANMeta>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
