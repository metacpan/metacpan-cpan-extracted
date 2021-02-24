package Promise::AsyncAwait;

use strict;
use warnings;

our $VERSION = '0.01';

=encoding utf-8

=head1 NAME

Promise::AsyncAwait - Async/await with promises

=head1 SYNOPSIS

    use Promise::AsyncAwait;

    async sub get_number_plus_1 {
        my $number = await _get_number_p();

        return 1 + $number;
    }

    my $p = get_number_plus_1()->then( sub { say "number: " . shift } );

… and then use whatever mechanism you will for “unrolling” C<$p>.

=head1 DESCRIPTION

L<Future::AsyncAwait> implements JavaScript-like L<async|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/async_function>/L<await|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/await>
semantics
for Perl, but it defaults to using CPAN’s L<Future> rather than promises.
The two are similar but incompatible.

Use this module for a promise-oriented async/await instead. It’s actually
just a shim around Future::AsyncAwait that feeds it configuration options
for L<Promise::XS> promises rather than Future. This yields a friendlier
(and likely faster!) experience for those more accustomed to JavaScript
promises than to CPAN Future.

This should work with most CPAN promise implementations.

=cut

use Promise::XS 0.13;

use constant _MIN_FAA_VERSION => 0.47;

our @ISA;

BEGIN {

    # Future::AsyncAwait loads Future, which we don’t need.
    local $INC{'Future.pm'} = __FILE__;
    local *Future::VERSION = sub { '999.99' };

    @ISA = ('Future::AsyncAwait');
    require Future::AsyncAwait;
    Future::AsyncAwait->VERSION(_MIN_FAA_VERSION);
}

sub import {
    return $_[0]->SUPER::import(
        future_class => 'Promise::XS::Promise',
        @_[1 .. $#_],
    );
}

=head1 LICENSE & COPYRIGHT

Copyright 2021 Gasper Software Consulting. All rights reserved.

This library is licensed under the same license as Perl.

=cut

1;
