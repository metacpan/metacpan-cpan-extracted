# ABSTRACT: Create Spec objects from strings

package Pinto::SpecFactory;

use strict;
use warnings;

use Class::Load;

use Pinto::Util qw(throw);

#-------------------------------------------------------------------------------

our $VERSION = '0.097'; # VERSION

#-------------------------------------------------------------------------------


sub make_spec {
    my ( $class, $arg ) = @_;

    my $type = ref $arg;
    my $spec_class;

    if ( not $type ) {

        $spec_class =
            ( $arg =~ m{/}x )
            ? 'Pinto::DistributionSpec'
            : 'Pinto::PackageSpec';
    }
    elsif ( ref $arg eq 'HASH' ) {

        $spec_class =
            ( exists $arg->{author} )
            ? 'Pinto::DistributionSpec'
            : 'Pinto::PackageSpec';
    }
    else {

        throw "Don't know how to make spec from $arg";
    }

    Class::Load::load_class($spec_class);
    return $spec_class->new($arg);
}

#-------------------------------------------------------------------------------
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Jeffrey Ryan Thalhammer

=head1 NAME

Pinto::SpecFactory - Create Spec objects from strings

=head1 VERSION

version 0.097

=head1 METHODS

=head2 make_spec( $string )

[Class Method] Returns either a L<Pinto::DistributionSpec> or
L<Pinto::PackageSpec> object constructed from the given C<$string>.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
