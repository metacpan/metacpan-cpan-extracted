package Sah::Schema::cpan::pause_id;

our $DATE = '2018-04-06'; # DATE
our $VERSION = '0.002'; # VERSION

 our $schema = ["str",{match=>qr([a-z][a-z0-9]{1,8}),summary=>"PAUSE author ID","x.perl.coerce_rules"=>["str_toupper"]},{}];


1;

# ABSTRACT: PAUSE author ID

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::cpan::pause_id - PAUSE author ID

=head1 VERSION

This document describes version 0.002 of Sah::Schema::cpan::pause_id (from Perl distribution Sah-Schemas-CPAN), released on 2018-04-06.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-CPAN>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-CPAN>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-CPAN>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Regexp::Pattern::CPAN>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
