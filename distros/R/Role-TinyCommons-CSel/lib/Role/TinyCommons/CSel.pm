package Role::TinyCommons::CSel;

our $DATE = '2016-03-23'; # DATE
our $VERSION = '0.02'; # VERSION

use Data::CSel ();
use Role::Tiny;
use Role::Tiny::With;

with 'Role::TinyCommons::Tree::Node';

sub select {
    my $self = shift;

    my $opts;
    if (ref($_[0]) eq 'HASH') {
        $opts = shift;
    } else {
        $opts = {};
    }

    my $expr = shift;

    Data::CSel::csel($opts, $expr, $self);
}

1;
# ABSTRACT: Role to add select() to select nodes using Data::CSel

__END__

=pod

=encoding UTF-8

=head1 NAME

Role::TinyCommons::CSel - Role to add select() to select nodes using Data::CSel

=head1 VERSION

This document describes version 0.02 of Role::TinyCommons::CSel (from Perl distribution Role-TinyCommons-CSel), released on 2016-03-23.

=head1 DESCRIPTION

This role adds a C<select()> method to select nodes using L<Data::CSel>.

=head1 REQUIRED ROLES

L<Role::TinyCommons::Tree::Node>

=head1 PROVIDED METHODS

=head2 select([ \%opts, ] $expr)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Role-TinyCommons-CSel>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Role-TinyCommons-CSel>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Role-TinyCommons-CSel>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Role::TinyCommons>

L<Data::CSel>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
