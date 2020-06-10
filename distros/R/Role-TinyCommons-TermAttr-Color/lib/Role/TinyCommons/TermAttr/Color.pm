package Role::TinyCommons::TermAttr::Color;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-06'; # DATE
our $DIST = 'Role-TinyCommons-TermAttr-Color'; # DIST
our $VERSION = '0.002'; # VERSION

use Role::Tiny;

sub termattr_use_color {
    require Term::App::Util::Color;

    my $self = shift;

    my $res = Term::App::Util::Color::term_app_should_use_color();
    $self->{_termattr_debug_info} //= {};
    $self->{_termattr_debug_info}{$_} = $res->[3]{'func.debug_info'}{$_}
        for keys %{ $res->[3]{'func.debug_info'} };
    $res->[2];
}

sub termattr_color_depth {
    require Term::App::Util::Color;

    my $self = shift;

    my $res = Term::App::Util::Color::term_app_color_depth();
    $self->{_termattr_debug_info} //= {};
    $self->{_termattr_debug_info}{$_} = $res->[3]{'func.debug_info'}{$_}
        for keys %{ $res->[3]{'func.debug_info'} };
    $res->[2];
}

1;
# ABSTRACT: Determine color depth and whether to use color or not

__END__

=pod

=encoding UTF-8

=head1 NAME

Role::TinyCommons::TermAttr::Color - Determine color depth and whether to use color or not

=head1 VERSION

This document describes version 0.002 of Role::TinyCommons::TermAttr::Color (from Perl distribution Role-TinyCommons-TermAttr-Color), released on 2020-06-06.

=head1 DESCRIPTION

These use L<Term::App::Util::Color> as backend.

=head1 PROVIDED METHODS

=head2 termattr_use_color

=head2 termattr_color_depth

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Role-TinyCommons-TermAttr-Color>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Role-TinyCommons-TermAttr-Color>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Role-TinyCommons-TermAttr-Color>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Term::App::Util::Color>

L<Role::TinyCommons>

L<Term::App::Role::Attrs>, an earlier project, L<Moo::Role>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
