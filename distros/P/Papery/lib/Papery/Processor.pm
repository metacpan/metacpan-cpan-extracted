package Papery::Processor;

use strict;
use warnings;

sub process {
    my ($class, $pulp, @options) = @_;
    $pulp->{meta}{_content} = $pulp->{meta}{_text};
    return $pulp;
}

1;

__END__

=head1 NAME

Papery::Processor - Base class for Papery processors

=head1 SYNOPSIS

    package Papery::Processor::MyProcessor;
    
    use strict;
    use warnings;
    
    use Papery::Processor;
    our @ISA = qw( Papery::Processor );
    
    sub process {
        my ( $class, $pulp ) = @_;
    
        # process $pulp->{meta}{_text}
        # update $pulp->{meta}{_content}
    
        return $pulp;
    }
    
    1;

=head1 DESCRIPTION

C<Papery::Processor> is the base class for Papery processor classes.
Subclasses only need to define an C<process()> method, taking a
C<Papery::Pulp> object as the single parameter.

The C<process()> method is expected to take the C<_text> key from the
C<Papery::Pulp> object and use it to update the C<_content> key, that will
be later rendered by C<Papery::Renderer> classes.

=head1 METHODS

This class provides a single method:

=over 4

=item process( $pulp )

Process the C<_text> metadata, and update the C<$pulp> metadata and
C<_content>.

=back

=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book at cpan.org> >>

=head1 COPYRIGHT

Copyright 2010 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

