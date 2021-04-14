package TableData::Test::Source::Iterator;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-13'; # DATE
our $DIST = 'TableDataRoles-Standard'; # DIST
our $VERSION = '0.008'; # VERSION

use 5.010001;
use strict;
use warnings;
use Role::Tiny::With;
with 'TableDataRole::Source::Iterator';

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
# ABSTRACT: A test table

__END__

=pod

=encoding UTF-8

=head1 NAME

TableData::Test::Source::Iterator - A test table

=head1 VERSION

This document describes version 0.008 of TableData::Test::Source::Iterator (from Perl distribution TableDataRoles-Standard), released on 2021-04-13.

=head1 SYNOPSIS

 use TableData::Test::Source::Iterator;

 my $table = TableData::Test::Source::Iterator->new(
     # num_rows => 100,   # default is 10
     # random => 1,       # if set to true, will return rows in a random order
 );

=head1 DESCRIPTION

=head2 new

Create object.

Usage:

 my $table = TableData::Test::Source::Iterator->new(%args);

Known arguments:

=over

=item * num_rows

Positive int. Default is 10.

=item * random

Bool. Default is 0.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableDataRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableDataRoles-Standard>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-TableDataRoles-Standard/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
