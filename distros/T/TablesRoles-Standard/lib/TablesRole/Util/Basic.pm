package TablesRole::Util::Basic;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-11-10'; # DATE
our $DIST = 'TablesRoles-Standard'; # DIST
our $VERSION = '0.006'; # VERSION

# enabled by Role::Tiny
#use strict;
#use warnings;

use Role::Tiny;

requires 'get_row_arrayref';
requires 'get_row_hashref';

sub as_aoa {
    my $self = shift;
    $self->reset_iterator;
    my @aoa;
    while (my $row = $self->get_row_arrayref) {
        push @aoa, $row;
    }
    \@aoa;
}

sub as_aoh {
    my $self = shift;
    $self->reset_iterator;
    my @aoh;
    while (my $row = $self->get_row_hashref) {
        push @aoh, $row;
    }
    \@aoh;
}

1;
# ABSTRACT: Provide utility methods

__END__

=pod

=encoding UTF-8

=head1 NAME

TablesRole::Util::Basic - Provide utility methods

=head1 VERSION

This document describes version 0.006 of TablesRole::Util::Basic (from Perl distribution TablesRoles-Standard), released on 2020-11-10.

=head1 DESCRIPTION

This role provides some basic utility methods.

=head1 PROVIDED METHODS

=head2 as_aoa

Usage:

 my $aoa = $table->as_aoa;

Return table data as array of arrayrefs. Will reset row iterator.

=head2 as_aoh

Usage:

 my $aoh = $table->as_aoh;

Return table data as array of hashrefs. Will reset row iterator.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TablesRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TablesRoles-Standard>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TablesRoles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Other C<TablesRole::Util::*>

L<Tables>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
