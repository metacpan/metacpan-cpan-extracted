package Role::TinyCommons::TermAttr::Interactive;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-06'; # DATE
our $DIST = 'Role-TinyCommons-TermAttr-Interactive'; # DIST
our $VERSION = '0.003'; # VERSION

use Role::Tiny;

sub termattr_interactive {
    require Term::App::Util::Interactive;

    my $self = shift;

    my $res = Term::App::Util::Interactive::term_app_is_interactive();
    $self->{_termattr_debug_info} //= {};
    $self->{_termattr_debug_info}{$_} = $res->[3]{'func.debug_info'}{$_}
        for keys %{ $res->[3]{'func.debug_info'} };
    $res->[2];
}

1;
# ABSTRACT: Determine whether terminal application is running interactively

__END__

=pod

=encoding UTF-8

=head1 NAME

Role::TinyCommons::TermAttr::Interactive - Determine whether terminal application is running interactively

=head1 VERSION

This document describes version 0.003 of Role::TinyCommons::TermAttr::Interactive (from Perl distribution Role-TinyCommons-TermAttr-Interactive), released on 2020-06-06.

=head1 DESCRIPTION

Uses L<Term::App::Util::Interactive> as backend.

=head1 PROVIDED METHODS

=head2 termattr_interactive

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Role-TinyCommons-TermAttr-Interactive>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Role-TinyCommons-TermAttr-Interactive>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Role-TinyCommons-TermAttr-Interactive>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Term::App::Util::Interactive>

L<Role::TinyCommons>

L<Term::App::Role::Attrs>, an earlier project, uses L<Moo::Role>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
