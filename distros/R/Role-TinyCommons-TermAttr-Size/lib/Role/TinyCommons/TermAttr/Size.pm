package Role::TinyCommons::TermAttr::Size;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-05'; # DATE
our $DIST = 'Role-TinyCommons-TermAttr-Size'; # DIST
our $VERSION = '0.001'; # VERSION

use Role::Tiny;

my $termw_cache;
my $termh_cache;
sub _termattr_size {
    my $self = shift;

    if (defined $termw_cache) {
        return ($termw_cache, $termh_cache);
    }

    ($termw_cache, $termh_cache) = (0, 0);
    if (eval { require Term::Size; 1 }) {
        ($termw_cache, $termh_cache) = Term::Size::chars(*STDOUT{IO});
    }
    ($termw_cache, $termh_cache);
}

sub termattr_width {
    my $self = shift;
    if ($ENV{COLUMNS}) {
        $self->{_termattr_debug_info}{term_width_from} = 'COLUMNS env';
        return $ENV{COLUMNS};
    }
    my ($termw, undef) = $self->_termattr_size;
    if ($termw) {
        $self->{_termattr_debug_info}{term_width_from} = 'term_size';
    } else {
        # sane default, on windows printing to rightmost column causes
        # cursor to move to the next line.
        $self->{_termattr_debug_info}{term_width_from} = 'default';
        $termw = $^O =~ /Win/ ? 79 : 80;
    }
    $termw;
}

sub termattr_height {
    my $self = shift;
    if ($ENV{LINES}) {
        $self->{_termattr_debug_info}{term_height_from} = 'LINES env';
        return $ENV{LINES};
    }
    my (undef, $termh) = $self->_termattr_size;
    if ($termh) {
        $self->{_termattr_debug_info}{term_height_from} = 'term_size';
    } else {
        $self->{_termattr_debug_info}{term_height_from} = 'default';
        # sane default
        $termh = 25;
    }
    $termh;
}

1;
# ABSTRACT: Determine the sane terminal size

__END__

=pod

=encoding UTF-8

=head1 NAME

Role::TinyCommons::TermAttr::Size - Determine the sane terminal size

=head1 VERSION

This document describes version 0.001 of Role::TinyCommons::TermAttr::Size (from Perl distribution Role-TinyCommons-TermAttr-Size), released on 2020-06-05.

=head1 DESCRIPTION

=head1 PROVIDED METHODS

=head2 termattr_height

Try to determine the sane terminal height. First observe the C<LINES>
environment variable, if unset then try using L<Term::Size> to determine the
terminal size, if fail then use default of 25.

=head2 termattr_width

Try to determine the sane terminal width. First observe the C<COLUMNS>
environment variable, if unset then try using L<Term::Size> to determine the
terminal size, if fail then use default of 80 (79 on Windows).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Role-TinyCommons-TermAttr-Size>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Role-TinyCommons-TermAttr-Size>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Role-TinyCommons-TermAttr-Size>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Role::TinyCommons>

L<Term::Size>

L<Term::App::Role::Attrs>, an earlier project, L<Moo::Role>, and currently more
complete version.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
