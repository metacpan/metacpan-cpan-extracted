package TAP::Formatter::JUnit::Result;

use Moose;
use namespace::clean;

has 'time' => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
);

has 'result' => (
    is       => 'ro',
    isa      => 'TAP::Parser::Result',
    required => 1,
    handles  => [qw(
        name
        number
        description
        as_string
        raw

        is_test
        is_plan
        is_unplanned
        is_ok

        todo_passed
        explanation
    )],
);

1;

=head1 NAME

TAP::Formatter::JUnit::Result - Wrapper for a TAP result

=head1 DESCRIPTION

C<TAP::Formatter::JUnit::Result> is an internal class, used to wrap/augment
C<TAP::Parser::Result> objects with timing information.

B<NOT recommended for public consumption; internal use only.>

=head1 AUTHOR

Graham TerMarsch <cpan@howlingfrog.com>

=head1 COPYRIGHT

Copyright 2011, Graham TerMarsch.  All Rights Reserved.

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
