package Path::Router::Types;
our $AUTHORITY = 'cpan:STEVAN';
# ABSTRACT: A set of types that Path::Router uses
$Path::Router::Types::VERSION = '0.15';
use strict;
use warnings;

use Carp            1.32            ();

use Type::Library   1.000005        -base,
                                    -declare => qw(PathRouterRouteValidationMap);
use Type::Utils     1.000005        -all;
use Types::Standard 1.000005        -types;
use Types::TypeTiny 1.000005        qw(TypeTiny);

declare PathRouterRouteValidationMap,
    as HashRef[TypeTiny];

# NOTE:
# canonicalize the route
# validators into a simple
# set of type constraints
# - SL
coerce PathRouterRouteValidationMap,
    from HashRef[Str | RegexpRef | TypeTiny],
    via {
        my %orig = %{ +shift };
        foreach my $key (keys %orig) {
            my $val = $orig{$key};
            if (ref $val eq 'Regexp') {
                $orig{$key} = declare(as Str, where{ /^$val$/ });
            }
            elsif (TypeTiny->check($val)) {
                $orig{$key} = $val;
            }
            else {
                $orig{$key} = dwim_type($val)
                    || Carp::confess "Could not locate type constraint named $val";
            }
        }
        return \%orig;
    };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Router::Types - A set of types that Path::Router uses

=head1 VERSION

version 0.15

=head1 SYNOPSIS

  use Path::Router::Types;

=head1 DESCRIPTION

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
