package Papery::Renderer;

use strict;
use warnings;

sub render {
    my ($class, $pulp, @options) = @_;
    $pulp->{meta}{_output} = $pulp->{meta}{_content};
    return $pulp;
}

1;

__END__

=head1 NAME

Papery::Renderer - Base class for Papery processors

=head1 SYNOPSIS

    package Papery::Renderer::MyRenderer;
    
    use strict;
    use warnings;
    
    use Papery::Renderer;
    our @ISA = qw( Papery::Renderer );
    
    sub render {
        my ( $class, $pulp ) = @_;
    
        # render $pulp->{meta}{_content}
        # update $pulp->{meta}{_output}
    
        return $pulp;
    }
    
    1;

=head1 DESCRIPTION

C<Papery::Renderer> is the base class for Papery renderer classes.
Subclasses only need to define an C<render()> method, taking a
C<Papery::Pulp> object as the single parameter.

The C<render()> method is expected to take the C<_content> key from the
C<Papery::Pulp> object and use it to update the C<_output> key, that will
be later saved to a file by the C<Papery::Pulp> object itself.

=head1 METHODS

This class provides a single method:

=over 4

=item render( $pulp )

Render the C<_content> metadata, and update the C<$pulp> metadata and
C<_output>.

=back

=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book at cpan.org> >>

=head1 COPYRIGHT

Copyright 2010 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

