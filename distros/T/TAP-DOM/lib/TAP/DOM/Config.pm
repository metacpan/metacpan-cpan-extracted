package TAP::DOM::Config;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: Accessors for TAP::DOM specific parse config
$TAP::DOM::Config::VERSION = '1.001';
use 5.006;
use strict;
use warnings;

use Class::XSAccessor
    chained     => 1,
    constructor => 'new',
    accessors   => [qw( ignore
                        ignorelines
                        usebitsets
                        sparse
                     )];

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TAP::DOM::Config - Accessors for TAP::DOM specific parse config

=head1 DESCRIPTION

The C<tapdom_config> part covers TAP::DOM specific parse options.

=head1 ACCESSORS & METHODS

=head2 new - constructor

=head2 ignore

=head2 ignorelines

=head2 usebitsets

=head2 sparse

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
