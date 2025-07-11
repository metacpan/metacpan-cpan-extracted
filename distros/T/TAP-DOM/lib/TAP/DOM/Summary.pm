package TAP::DOM::Summary;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: Accessors for TAP::DOM summary part
$TAP::DOM::Summary::VERSION = '1.001';
use 5.006;
use strict;
use warnings;

use Class::XSAccessor
    chained     => 1,
    constructor => 'new',
    accessors   => [qw( failed
                        parse_errors
                        passed
                        skipped
                        todo
                        todo_passed
                        wait
                        exit
                        elapsed
                        elapsed_timestr
                        all_passed
                        status
                        total
                        has_problems
                        has_errors
                     )];

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TAP::DOM::Summary - Accessors for TAP::DOM summary part

=head1 DESCRIPTION

The C<summary> part covers aggregated results from TAP::Parser::Aggregator.

=head1 ACCESSORS & METHODS

=head2 new - constructor

=head2 all_passed

=head2 elapsed

=head2 elapsed_timestr

=head2 exit

=head2 failed

=head2 has_errors

=head2 has_problems

=head2 parse_errors

=head2 passed

=head2 skipped

=head2 status

=head2 todo

=head2 todo_passed

=head2 total

=head2 wait

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
