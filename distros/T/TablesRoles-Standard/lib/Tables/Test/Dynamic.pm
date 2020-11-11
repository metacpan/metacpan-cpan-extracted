package Tables::Test::Dynamic;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-11-10'; # DATE
our $DIST = 'TablesRoles-Standard'; # DIST
our $VERSION = '0.006'; # VERSION

use 5.010001;
use strict;
use warnings;
use Role::Tiny::With;
with 'TablesRole::Source::Iterator';

sub new {
    my ($class, %args) = @_;
    $args{num_rows} //= 10;
    $args{random}   //= 0;

    $class->_new(
        gen_iterator => sub {
            my $i = 0;
            sub {
                $i++;
                return undef if $i > $args{num_rows};
                return {i=>$args{random} ? int(rand()*$args{num_rows} + 1) : $i};
            };
        },
    );
}

1;
# ABSTRACT: A dynamic table

__END__

=pod

=encoding UTF-8

=head1 NAME

Tables::Test::Dynamic - A dynamic table

=head1 VERSION

This document describes version 0.006 of Tables::Test::Dynamic (from Perl distribution TablesRoles-Standard), released on 2020-11-10.

=head1 SYNOPSIS

 use Tables::Test::Dynamic;

 my $table = Tables::Test::Dynamic->new(
     # num_rows => 100,   # default is 10
     # random => 1,       # if set to true, will return rows in a random order
 );

=head1 DESCRIPTION

=head2 new

Create object.

Usage:

 my $table = Tables::Test::Dynamic->new(%args);

Known arguments:

=over

=item * num_rows

Positive int. Default is 10.

=item * random

Bool. Default is 0.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TablesRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TablesRoles-Standard>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TablesRoles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
