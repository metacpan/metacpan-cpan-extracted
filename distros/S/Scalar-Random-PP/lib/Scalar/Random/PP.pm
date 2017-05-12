package Scalar::Random::PP;
use Scalar::Random::PP::OO;
use 5.008003;

our $VERSION = '0.11';

has 'limit' => ( is => 'ro' );

Scalar::Random::PP::OO::Exporter->setup_import_methods(
    as_is => [\&randomize],
);

use overload
    '""' => sub { int(rand($_[0]->limit + 1)) },
    fallback => 1;

sub randomize {
    $_[0] = Scalar::Random::PP->new(limit => $_[1]);    
}

1;

=encoding utf8

=head1 NAME

Scalar::Random::PP - Scalar::Random in Pure Perl

=head1 SYNOPSIS

    use Scalar::Random::PP 'randomize';

    my $random;
    my $MAX_RANDOM = 100;

    randomize( $random, $MAX_RANDOM );

    print $random, "\n"; # '42'
    print $random, "\n"; # '17'
    print $random, "\n"; # '88'
    print $random, "\n"; # '4'
    print $random, "\n"; # '50'

=head1 DESCRIPTION

This module is intended to be a pure Perl replacement for L<Scalar::Random>.

Please see L<Scalar::Random> for full details.

=head1 NOTES

This module was written as a pair programming excerise between
Webster Montego and Ingy döt Net.

The module passes all the same tests as L<Scalar::Random>, even though
we felt there could be more exhaustive testing. Perhaps we'll add the
tests we'd like to see, so that Alfie John can backport them. :)

We also thought it would be nice if randomize took a lower limit, but we
decided not to change the API unless Alfie did so first, so that the PP
module would be an exact replacement.

We used the speedy and zero-dep L<Mousse> module for OO goodness, and
packaged it all up with the lovely L<Module::Install> and friends.

=head1 RESOURCES

GitHub: L<http://github.com/websteris/scalar-random-pp-pm>

=head1 AUTHORS

Webster Montego <websteris@cpan.org>

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2010. Webster Montego and Ingy döt Net

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
