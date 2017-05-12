# ABSTRACT: Create Spec objects from strings

package Pinto::Target;

use strict;
use warnings;

use Class::Load;

use Pinto::Exception;

#-------------------------------------------------------------------------------

our $VERSION = '0.12'; # VERSION

#-------------------------------------------------------------------------------


sub new {
    my ( $class, $arg ) = @_;

    my $type = ref $arg;
    my $target_class;

    if ( not $type ) {

        $target_class =
            ( $arg =~ m{/}x )
            ? 'Pinto::Target::Distribution'
            : 'Pinto::Target::Package';
    }
    elsif ( ref $arg eq 'HASH' ) {

        $target_class =
            ( exists $arg->{author} )
            ? 'Pinto::Target::Distribution'
            : 'Pinto::Target::Package';
    }
    else {

        # I would just use throw() here, but I need to avoid
        # creating a circular dependency between this package,
        # Pinto::Types and Pinto::Util.

        my $message = "Don't know how to make target from $arg";
        Pinto::Exception->throw( message => $message );

    }

    Class::Load::load_class($target_class);
    return $target_class->new($arg);
}

#-------------------------------------------------------------------------------
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Jeffrey Ryan Thalhammer

=head1 NAME

Pinto::Target - Create Spec objects from strings

=head1 VERSION

version 0.12

=head1 METHODS

=head2 new( $string )

[Class Method] Returns either a L<Pinto::Target::Distribution> or
L<Pinto::Target::Package> object constructed from the given C<$string>.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
