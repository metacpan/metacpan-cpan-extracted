#!perl
#PODNAME: Raisin::Util
#ABSTRACT: Utility subroutine for Raisin.

use strict;
use warnings;

package Raisin::Util;
$Raisin::Util::VERSION = '0.93';
use Plack::Util;

sub make_tag_from_path {
    my $path = shift;
    my @c = (split '/', $path);
    return 'none' unless scalar @c;
    $c[-2] || $c[1];
}

sub iterate_params {
    my $params = shift;
    my $index = 0;

    return sub {
        $index += 2;
        ($params->[$index-2], $params->[$index-1]);
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Raisin::Util - Utility subroutine for Raisin.

=head1 VERSION

version 0.93

=head1 FUNCTIONS

=head2 make_tag_from_path

Splits a path and returns the first part of it.

=head2 iterate_params

Iterates over route parameters.

=head1 AUTHOR

Artur Khabibullin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Artur Khabibullin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
