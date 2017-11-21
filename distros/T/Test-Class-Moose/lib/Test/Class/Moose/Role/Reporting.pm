package Test::Class::Moose::Role::Reporting;

# ABSTRACT: Reporting gathering role

use strict;
use warnings;
use namespace::autoclean;

use 5.10.0;

our $VERSION = '0.89';

use Moose::Role;
with 'Test::Class::Moose::Role::HasTimeReport';

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'notes' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has 'skipped' => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'is_skipped',
);

has 'passed' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Class::Moose::Role::Reporting - Reporting gathering role

=head1 VERSION

version 0.89

=head1 DESCRIPTION

Note that everything in here is experimental and subject to change.

=head1 IMPLEMENTS

L<Test::Class::Moose::Role::HasTimeReport>.

=head1 REQUIRES

None.

=head1 PROVIDED

=head1 ATTRIBUTES

=head2 C<name>

The "name" of the statistic. For a class, this should be the class name. For a
method, it should be the method name.

=head2 C<notes>

A hashref. The end user may use this to store anything desired.

=head2 C<skipped>

If the class or method is skipped, this will return the skip message.

=head2 C<is_skipped>

Returns true if the class or method is skipped.

=head2 C<passed>

Returns true if the class or method passed.

=head2 C<time>

(From L<Test::Class::Moose::Role::HasTimeReport>)

Returns a L<Test::Class::Moose::Report::Time> object. This object
represents the duration of this class or method.

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/houseabsolute/test-class-moose/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Test-Class-Moose can be found at L<https://github.com/houseabsolute/test-class-moose>.

=head1 AUTHORS

=over 4

=item *

Curtis "Ovid" Poe <ovid@cpan.org>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 - 2017 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
