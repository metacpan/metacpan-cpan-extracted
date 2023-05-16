package TableData::Test::Source::Iterator;

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-24'; # DATE
our $DIST = 'TableDataRoles-Standard'; # DIST
our $VERSION = '0.015'; # VERSION

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
                return undef if $i > $args{num_rows}; ## no critic: Subroutines::ProhibitExplicitReturnUndef
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

This document describes version 0.015 of TableData::Test::Source::Iterator (from Perl distribution TableDataRoles-Standard), released on 2023-02-24.

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

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2022, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableDataRoles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
