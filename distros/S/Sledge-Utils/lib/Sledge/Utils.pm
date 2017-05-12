package Sledge::Utils;
use strict;
use warnings;
our $VERSION = '0.04';
use Carp;
use String::CamelCase ();

use 5.008001;

sub class2prefix {
    my $class = shift;

    my $proto = ref $class || $class;
    if ($proto =~ /.+::Pages::(.+)/) {
        if ($1 eq 'Index' || $1 eq 'Root') {
            return '/';
        }
        else {
            return '/' . join('/', map { String::CamelCase::decamelize($_) } split /::/, $1);
        }
    }
    croak "$class does not match";
}

sub class2appclass {
    my $class = shift;

    my $proto = ref $class || $class;
    $proto =~ s/::Pages.*$//;
    return $proto;
}

1;
__END__

=head1 NAME

Sledge::Utils - utility functions for Sledge

=head1 SYNOPSIS

    use Sledge::Utils;

=head1 DESCRIPTION

such as Catalyst::Utils.

=head1 METHODS

=head2 class2prefix

    Proj::Pages::Foo::Bar => /foo/bar

=head2 class2appclass

    Proj::Pages::Foo::Bar => Proj

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Tokuhiro Matsuno  C<< <tokuhiro __at__ mobilefactory.jp> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Tokuhiro Matsuno C<< <tokuhiro __at__ mobilefactory.jp> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

