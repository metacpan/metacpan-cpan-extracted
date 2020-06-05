package Role::TinyCommons::TermAttr::Software;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-05'; # DATE
our $DIST = 'Role-TinyCommons-TermAttr-Software'; # DIST
our $VERSION = '0.001'; # VERSION

use Role::Tiny;

my $dt_cache;
sub termattr_software_info {
    my $self = shift;

    if (!$dt_cache) {
        require Term::Detect::Software;
        $dt_cache = Term::Detect::Software::detect_terminal_cached();
        #use Data::Dump; dd $dt_cache;
    }
    $dt_cache;
}

1;
# ABSTRACT: Find out information about terminal (emulator) software we run on

__END__

=pod

=encoding UTF-8

=head1 NAME

Role::TinyCommons::TermAttr::Software - Find out information about terminal (emulator) software we run on

=head1 VERSION

This document describes version 0.001 of Role::TinyCommons::TermAttr::Software (from Perl distribution Role-TinyCommons-TermAttr-Software), released on 2020-06-05.

=head1 DESCRIPTION

=head1 PROVIDED METHODS

=head2 termattr_software_info

Try to find out information about terminal (emulator) software we run on. Uses
L<Term::Detect::Software>. Return a hash.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Role-TinyCommons-TermAttr-Software>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Role-TinyCommons-TermAttr-Software>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Role-TinyCommons-TermAttr-Software>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Role::TinyCommons>

L<Term::Detect::Software>

L<Term::App::Role::Attrs>, an earlier project, uses L<Moo::Role>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
